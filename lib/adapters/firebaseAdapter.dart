import 'dart:async';
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

  Future<void> register(String userName,String email,String password,File? image,String pubicKey,String privateKey) async {
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
      var data = u.toDb();

      data["pubKey"] = pubicKey;
      data["enKey"] = privateKey;

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

  Future<void> sendMessage(MessageData m) async {
    var messageR = base.messages(m.roomId);

     await messageR.doc(m.id).set(m.toDb() );
  }

  Future<void> sendRequest(RequestData r) async{
    await base.requests.doc(r.id).set(r.toDb() );
  }

  Future<void> createRoom(RoomData r) async {
    String userId = base.userId;
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
          throw MyError("Error: Already have a chat of this type with this user");
        }

      }

      WriteBatch b = base.batch();

      b.set(base.rooms.doc(r.id),{
        "id":SteganographyAdapter.encodeMessage(r.id,RoomData.typeToString(r.type) ),
      });
      b.set(base.roomMembers(r.id,).doc(userId),{"id":userId});
      b.set(base.roomMembers(r.id,).doc(otherId),{"id":otherId});
      b.set(base.typingInProgress.doc(),{"room":r.id,"user":userId,"typing":false});
      b.set(base.typingInProgress.doc(),{"room":r.id,"user":otherId,"typing":false});

      await base.batchCommit(b);
  }

  Future<void> updateRequest(RequestData r,{bool addFriend = false}) async {
    String userId = base.userId;
    String friedId = r.sender!.id;
    var receivedRequestR = base.receivedRequests(userId);
    WriteBatch b = base.batch();

      b.update(receivedRequestR.doc(r.id),{"status":RequestData.statusToString(r.status)});

      if(addFriend) {
        b.set(base.contacts(userId).doc(friedId),{"id":friedId});
        b.set(base.contacts(friedId).doc(userId),{"id":userId});
      }

      await base.batchCommit(b);
  }

  Future<void> updateTypingInProgress(RoomData r,bool typing) async {
    String userId = base.userId;

      var q = await base.typingInProgress
              .where("room",isEqualTo: r.id)
              .where("user",isEqualTo: userId)
              .get();
      var b = base.batch();

      for(var doc in q.docs) {
        doc.reference.update({"typing":typing});
      }

      await base.batchCommit(b);
  }

  Future<void> updateMessage(MessageData m) async {
    var messageR = base.messages(m.roomId);

      await messageR.doc(m.id).update({
        "edited":Helper.timestampToDb(m.edited!),
        "message":m.message,
        "seen":false
      });
  }

  Future<void> deleteMessage(MessageData m) async {
    await base.messages(m.roomId).doc(m.id).delete();
  }

  Future<(UserModel,(String,String))> getYourData() async {
    var doc = await base.users.doc(base.userId).get();
    var docData = doc.data() as Map<String, dynamic>;
    var data = UserData.fromDb(docData);
    String pubKey = docData["pubKey"];
    String privKey = docData["enKey"];

    Users contacts = await getContacts();
    Rooms rooms = await getRooms();

    var requests = await Future.wait([
      getRequests(data,sent: true),
      getRequests(data,sent: false),
    ]);

    return (
            UserModel.fresh(data: data,contacts: contacts,sentRequests: requests.first,receivedRequests: requests.last,rooms: rooms),
            (pubKey,privKey)
          );
  }

  Future<Users> getContacts() async {
    Users ret = [];
    String userId = base.userId;
    var contactIds = await base.contacts(userId).get();

      for(var doc in contactIds.docs) {
        var contactId = doc.id;
        ret.add(await getUser(contactId) );
      }

      return ret;
  }

  Future<Rooms> getRooms() async {
    Rooms ret = [];
    String userId = base.userId;
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
    var userId = base.userId;
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
    String userId = base.userId;
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

  Future<Requests> getRequests(UserData user,{required bool sent}) async {
    String userId = user.id;
    Requests ret = [];
    QuerySnapshot q;

    if(sent) {
      q = await base.requests.where("sender",isEqualTo:userId).get();
    } else {
      q = await base.requests.where("receiver",isEqualTo:userId).get();
    }

    for(var doc in q.docs) {
      var reqId = doc.id;
      var data = doc.data() as Map<String,dynamic>;

      var senderId = data['sender'];
      var receiverId = data['receiver'];
      var sentDateTime = Helper.timestampFromDb(data["sent"]);
      var status = RequestData.statusFromString(data["status"]);

      UserData otherUser = (sent) ? await getUser(receiverId) : await getUser(senderId);

      if(sent) {
        ret.add(RequestData(id:reqId,sender: user,receiver: otherUser,sent: sentDateTime,status: status) );
      }else {
        ret.add(RequestData(id:reqId,sender: otherUser,receiver: user,sent: sentDateTime,status: status) );
      }

    }

    return ret;
  }

  Future<UserData> getUser(String userId) async {
    var doc = await base.users.doc(userId).get();

      return UserData.fromDb(doc.data() as Map<String, dynamic>);
  }

  StreamSubscription contactsStream(void Function() contacts) {
    String userId = base.userId;

      return base.contacts(userId).snapshots(includeMetadataChanges: false)
                    .listen((event) { contacts(); } );
  }

  StreamSubscription requestStream({required bool sent,required UserData user,required void Function(UserData,bool) requestChange}) {
    String userId = base.userId;

    if(sent) {
      return base.requests.where("sender",isEqualTo:userId).snapshots(includeMetadataChanges: false).listen( (event) {
        requestChange(user,sent);
      });
    }else {
      return base.requests.where("receiver",isEqualTo:userId).snapshots(includeMetadataChanges: false).listen( (event) {
        requestChange(user,sent);
      });
    }

  }

  StreamSubscription messageStream(RoomData r,void Function(String) messages) {
    return base.messages(r.id).snapshots(includeMetadataChanges: false)
                .listen( (event) { messages(r.id); } );
  }

  StreamSubscription typingStream(String userId,RoomData r,void Function() typing) {
    return base.typingInProgress.where("room",isEqualTo: r.id)
              .where("user",isNotEqualTo: userId).snapshots()
              .listen( (event) { typing(); } );
  }

}