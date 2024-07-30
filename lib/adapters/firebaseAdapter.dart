import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:secure_messenger/adapters/steganographyAdapter.dart';
import 'package:secure_messenger/models/roomData.dart';

import '../helper/helper.dart';
import '../models/messageData.dart';
import '../models/myError.dart';
import '../models/requestData.dart';
import '../models/roomsData.dart';
import '../models/userData.dart';
import '../models/userModel.dart';
import 'firebase/base.dart';

class FirebaseAdapter {
  final Base base = Base();

  Future<void> register(String userName,String email,String password,File? image) async {
    try {
      UserCredential c = await base.auth.createUserWithEmailAndPassword(email: email,password: password);
      String id = c.user!.uid;
      String imageUrl = "";
      UploadTask uploadTask;

      if(image == null) {
        var ref = base.storage.ref().child('defaultProfileImage.png');
        imageUrl = await ref.getDownloadURL();
      }else {
        var ref = base.storage.ref().child("profileImage").child(id);

        uploadTask = ref.putFile(image);
        final taskSnapshot = await uploadTask.whenComplete(() {});
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      var u = UserData.fresh(id: id,userName: userName,email: email,profilePicUrl: imageUrl);

      base.users.doc(id).set(u.toDb() );

    } on FirebaseAuthException catch(e) {
      throw MyError(e.code);
    }

  }

  Future<void> login(String user,String password) async {
    try {
      await base.auth.signInWithEmailAndPassword(email: user,password: password);
    } on FirebaseAuthException catch(e) {
      throw MyError(e.code);
    }

  }

  Future<void> logOut() async {
    await base.auth.signOut();
  }

  Future<void> sendMessage(String roomId,MessageData m) async {
    var messageR = base.messages(roomId);

     await messageR.doc(m.id).set(m.toDb() );
  }

  Future<void> sendRequest(RequestData r,String toId) async{
    var sentRequestR = base.sentRequests(r.user!.id);
    var receivedRequestR = base.receivedRequests(toId);
    WriteBatch b = base.batch();

      b.set(sentRequestR.doc(r.id),{"id":toId});
      b.set(receivedRequestR.doc(r.id),r.toDb()  );

      await base.batchCommit(b);

  }

  Future<void> createRoom(RoomData r) async {
    String userId = base.auth.currentUser!.uid;
    String otherId = r.otherUser!.id;

    var q = await FirebaseFirestore.instance.collectionGroup("members")
          .where("id",isNotEqualTo: userId)
          .where("id",isNotEqualTo: otherId)
          .get();

      for(var doc in q.docs) {
        var parentId = base.parentDocumentId(doc.reference);
        var roomDoc = await base.rooms.doc(parentId).get();
        var data = roomDoc.data() as Map<String,dynamic>;
        var type = RoomData.typeFromString(SteganographyAdapter.decodeMessage(data["id"]) );

        if(type == r.type) {
          throw "Error: Already have a chat of this type with this user";
        }

      }

      WriteBatch b = base.batch();

      b.set(base.rooms.doc(r.id),{
        "id":SteganographyAdapter.encodeMessage(r.id,RoomData.typeToString(r.type) ),
      });
      b.set(base.roomMembers(r.id,).doc(userId),{"id":userId});
      b.set(base.roomMembers(r.id,).doc(otherId),{"id":otherId});

      await base.batchCommit(b);
  }

  Future<UserModel> getYourData() async {
    var data = await getUser(base.auth.currentUser!.uid);

    Users contacts = await getContacts();
    Rooms rooms = await getRooms();

    var requests = await Future.wait([
      getRequests(sent: true),
      getRequests(sent: false),
    ]);

    return UserModel.fresh(data: data,contacts: contacts,sentRequests: requests.first,receivedRequests: requests.last,rooms: rooms);
  }

  Future<Users> getContacts() async {
    Users ret = [];
    String userId = base.auth.currentUser!.uid;
    var contactIds = await base.contacts(userId).get();

      for(var doc in contactIds.docs) {
        var contactId = doc.id;
        ret.add(await getUser(contactId) );
      }

      return ret;
  }

  Future<Rooms> getRooms() async {
    Rooms ret = [];
    String userId = base.auth.currentUser!.uid;
    var memberDocs = await FirebaseFirestore.instance.collectionGroup("members")
        .where("id",isNotEqualTo: userId)
        .get();

        //Get roomsData
        for(var doc in memberDocs.docs) {
          var parentId = base.parentDocumentId(doc.reference);
          var roomDoc = await base.rooms.doc(parentId).get();

          var roomId = roomDoc.id;
          var messagesDocs = await base.messages(roomId).get();
          var messages = messagesDocs.docs.length;
          var members = await base.roomMembers(roomId).get();
          UserData? otherUser;

          for(var doc in members.docs) {
            var otherId = doc.id;

            if(otherId == userId) {
              continue;
            }

            otherUser = await getUser(otherId);
          }

          ret.add(RoomsData(id: roomId,numberOfMessages: messages,otherUser: otherUser) );
        }

        return ret;
  }

  Future<RoomData> getRoom(String roomId) async {
    var userId = base.auth.currentUser!.uid;
    var membersIds = await base.roomMembers(roomId).get();
    var doc = await base.rooms.doc(roomId).get();
    UserData? otherUser;
    Messages messages = await getMessages(roomId);

      var data = doc.data() as Map<String,dynamic>;

      var id = data["id"];
      var roomType = RoomData.typeFromString(SteganographyAdapter.decodeMessage(id) );
      id = doc.id;

      for(var doc2 in membersIds.docs) {
        var otherId = doc2.id;

        if(otherId == userId) { continue; }

        otherUser = await getUser(otherId);
      }

      return RoomData(otherUser: otherUser,messages: messages, type: roomType);
  }

  Future<Messages> getMessages(String roomId) async {
    Messages ret = [];
    String userId = base.auth.currentUser!.uid;
    var q = await base.messages(roomId).get();
    WriteBatch b = base.batch();

      for(var doc in q.docs) {
        var data = doc.data() as Map<String,dynamic>;
        var senderId = data['sender'];

        ret.add(MessageData.fromDb(data,await getUser(senderId) ) );

        if(senderId != userId) {
          b.update(doc.reference,{"sent":MessageData.statusToString(MessageStatus.read) });
        }

      }
      await base.batchCommit(b);

      return ret;
  }

  Future<Requests> getRequests({required bool sent}) async {
    String userId = base.auth.currentUser!.uid;
    Requests ret = [];

    if(sent) {
      var sentReqIds = await base.sentRequests(userId).get();

      for(var doc in sentReqIds.docs) {
        var reqId = doc.id;
        var data = doc.data() as Map<String,dynamic>;
        var sentTo = data['id'];

        var doc2 = await base.sentRequests(sentTo).doc(reqId).get();

        data = doc2.data() as Map<String,dynamic>;

        var reqUserId = data['user'];
        var sent = Helper.timestampFromDb(data["sent"]);
        var status = RequestData.statusFromString(data["status"]);

        var user = await getUser(reqUserId);

        ret.add(RequestData(id:reqId,user: user,sent: sent,status: status) );
      }
    } else {
      var receivedReq = await base.receivedRequests(userId).get();

      for(var doc in receivedReq.docs) {
        var reqId = doc.id;
        var data = doc.data() as Map<String,dynamic>;

        var reqUserId = data['user'];
        var sent = Helper.timestampFromDb(data["sent"]);
        var status = RequestData.statusFromString(data["status"]);

        var user = await getUser(reqUserId);

        ret.add(RequestData(id:reqId,user: user,sent: sent,status: status) );
      }

    }

    return ret;
  }

  Future<UserData> getUser(String userId) async {
    var doc = await base.users.doc(userId).get();

      return UserData.fromDb(doc.data() as Map<String, dynamic>);
  }

}