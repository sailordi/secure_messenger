import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'encryptionAdapter.dart';
import 'steganographyAdapter.dart';
import '../helper/helper.dart';
import '../models/messageData.dart';
import '../models/myError.dart';
import '../models/requestData.dart';
import '../models/roomData.dart';
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

      base.users.doc(id).set(data);

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

  Future<void> sendMessage(MessageData m,File? f,FileType? t,{required EncryptionAdapter? enA}) async {
    var messageR = base.messages(m.roomId);
    Map<String,dynamic> data = {
      "id":m.id,
      "sender":m.sender.id,
      "sent":Helper.timestampToDb(m.sent),
      "edited":null,
      "status":MessageData.statusToString(MessageStatus.unread),
      "fileUrl":null,
      "fileName":null,
      "fileType":null,
      "message":null
    };

      if(f != null) {
        Reference ref;
        UploadTask uploadTask;

        if(t! == FileType.image) {
          ref = base.storage.ref().child("video").child(m.roomId).child(m.sender.id);
        } else {
          ref = base.storage.ref().child("image").child(m.roomId).child(m.sender.id);
        }

        String fileName = path.basename(f.path);
        String fileUrl = "";

        if(enA == null) {
          uploadTask = ref.putFile(f);
          final taskSnapshot = await uploadTask.whenComplete(() {});
          fileUrl = await taskSnapshot.ref.getDownloadURL();
        }else {
          uploadTask = ref.putData(await enA.encryptFile(f) );
          final taskSnapshot = await uploadTask.whenComplete(() {});
          fileUrl = await taskSnapshot.ref.getDownloadURL();
        }

        data["fileUrl"] = (enA == null) ? fileUrl : enA.encryptText(fileUrl);
        data["fileName"] = (enA == null) ? fileName : enA.encryptText(fileName);
      }

      if(t != null) {
        String type = MessageData.fileTypeToString(t);
        data["fileType"] = (enA == null) ? type : enA.encryptText(type);
      }

      if(m.message != null) {
        data["message"] = (enA == null) ? m.message! : enA.encryptText(m.message!);
      }

     await messageR.doc(m.id).set(data);
  }

  Future<void> sendRequest(RequestData r) async{
    var userId = r.sender!.id;
    var contactId = r.receiver!.id;
    var contactQ = await base.contacts(userId).where("id",isEqualTo: contactId).get();
    var requestRecQ = await base.requests
                          .where("sender",isEqualTo: contactId)
                          .where("receiver",isEqualTo: userId)
                          .get();
    var requestSentQ = await base.requests
        .where("sender",isEqualTo: userId)
        .where("receiver",isEqualTo: contactId)
        .get();

    if (contactQ.docs.isNotEmpty) {
      var user = await getUser(contactId);
      throw MyError("Error: ${user.userName}(${user.email}) has already been added as a contact");
    }
    if(requestRecQ.docs.isNotEmpty) {
      var user = await getUser(contactId);
      throw MyError("Error: You already have received a request from ${user.userName}(${user.email})");
    }
    if(requestSentQ.docs.isNotEmpty) {
      var user = await getUser(contactId);
      throw MyError("Error: You already have sent a request to ${user.userName}(${user.email})");
    }

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

  Future<void> acceptRequests(RequestData r) async {
    var userId = r.receiver!.id;
    var contactId = r.sender!.id;
    var contactQ = await base.contacts(userId).doc(contactId).get();
    var requestRecQ = await base.requests
        .where("sender",isEqualTo: contactId)
        .where("receiver",isEqualTo: userId)
        .get();
    var requestSentQ = await base.requests
        .where("sender",isEqualTo: userId)
        .where("receiver",isEqualTo: contactId)
        .get();

    if (contactQ.exists) {
      var user = await getUser(contactId);
      throw MyError("Error: ${user.userName}(${user.email}) has already been added as a contact");
    }
    if(requestRecQ.docs.isNotEmpty) {
      var user = await getUser(contactId);
      throw MyError("Error: You already have received a request from ${user.userName}(${user.email})");
    }
    if(requestSentQ.docs.isNotEmpty) {
      var user = await getUser(contactId);
      throw MyError("Error: You already have sent a request to ${user.userName}(${user.email})");
    }

    var requestDoc = await base.requests.doc(r.id).get();

    await requestDoc.reference.delete();

    await Future.wait([
      base.contacts(userId).doc(contactId).set({"id":contactId,"updated":Helper.timestampToDb(DateTime.now() ) }),
      base.contacts(contactId).doc(userId).set({"id":userId,"updated":Helper.timestampToDb(DateTime.now() ) })
    ]);

  }

  Future<void> declineRequests(RequestData r) async {
    var requestDoc = await base.requests.doc(r.id).get();

      await requestDoc.reference.delete();
  }

  Future<void> updateTypingInProgress(String userId,String roomId,bool typing) async {
    var q = await base.typingInProgress
                .where("room",isEqualTo: roomId)
                .where("user",isNotEqualTo: userId)
                .get();

      for(var doc in q.docs) {
        await doc.reference.update({"typing":typing});
      }

  }

  Future<void> updateMessage(MessageData m,File? f,FileType? t,EncryptionAdapter? enA,{bool remove = false}) async {
    var messageR = base.messages(m.roomId);
      Map<String,dynamic> data = {
        "edited":Helper.timestampToDb(m.edited!),
        "status":MessageData.statusToString(MessageStatus.unread),
      };

      if(f == null && remove == true) {
        if(m.fileUrl != null) {
          Reference ref = base.storage.refFromURL(m.fileUrl!);

          await ref.delete();
        }

        data["fileUrl"] = null;
        data["fileName"] = null;
        data["fileType"] = null;
      }

      if(f != null) {
        Reference ref;
        UploadTask uploadTask;

          if(m.fileUrl != null) {
            ref = base.storage.refFromURL(m.fileUrl!);

            await ref.delete();
          }

          if(t! == FileType.image) {
            ref = base.storage.ref().child("video").child(m.roomId).child(m.sender.id);
          } else {
            ref = base.storage.ref().child("image").child(m.roomId).child(m.sender.id);
          }

          String fileName = path.basename(f.path);
          String fileUrl;

          if(enA == null) {
            uploadTask = ref.putFile(f);
            final taskSnapshot = await uploadTask.whenComplete(() {});
            fileUrl = await taskSnapshot.ref.getDownloadURL();
          }else {
            uploadTask = ref.putData(await enA.encryptFile(f) );
            final taskSnapshot = await uploadTask.whenComplete(() {});
            fileUrl = await taskSnapshot.ref.getDownloadURL();
          }

          data["fileUrl"] = (enA == null) ? fileUrl : enA.encryptText(fileUrl);
          data["fileName"] = (enA == null) ? fileName : enA.encryptText(fileName);

        if(t != null) {
          String type = MessageData.fileTypeToString(t);
          data["fileType"] = (enA == null) ? type : enA.encryptText(type);
        }

      }

      if(m.message == null) {
        data["message"] = null;
      } else {
        data["message"] = (enA == null) ? m.message! : enA.encryptText(m.message!);
      }

      await messageR.doc(m.id).update(data);
  }

  Future<void> deleteMessage(MessageData m) async {
    if(m.fileUrl != null) {
      Reference ref = base.storage.refFromURL(m.fileUrl!);

      await ref.delete();
    }

    await base.messages(m.roomId).doc(m.id).delete();
  }

  Future<void> deleteContact(UserData c) async {
    String userId = base.userId;

      await base.contacts(userId).doc(c.id).delete();
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
          var roomData =roomDoc.data() as Map<String, dynamic>;
          var roomTypeStr = SteganographyAdapter.decodeMessage(roomData["id"]);
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

          ret.add(RoomsData(id: roomId,numberOfMessages: messages,otherUser: otherUser,type: RoomData.typeFromString(roomTypeStr) ) );
        }

        return ret;
  }

  Future<RoomData> getRoom(String roomId,EncryptionAdapter enA) async {
    var userId = base.userId;
    var membersIds = await base.roomMembers(roomId).get();
    var doc = await base.rooms.doc(roomId).get();
    UserData? otherUser;

      var data = doc.data() as Map<String,dynamic>;

      var id = data["id"];
      var roomType = RoomData.typeFromString(SteganographyAdapter.decodeMessage(id) );
      id = doc.id;

      Messages messages = await getMessages(roomId,(roomType == RoomType.normal) ? null : enA);

      for(var doc2 in membersIds.docs) {
        var otherId = doc2.id;

        if(otherId == userId) { continue; }

        otherUser = await getUser(otherId);
      }

      return RoomData(otherUser: otherUser,messages: messages, type: roomType);
  }

  Future<Messages> getMessages(String roomId,EncryptionAdapter? enA) async {
    Messages ret = [];
    String userId = base.userId;
    var q = await base.messages(roomId).get();
    WriteBatch b = base.batch();

      for(var doc in q.docs) {
        var data = doc.data() as Map<String,dynamic>;

        var id = data['id'];
        var senderId = data['sender'];
        var sent = Helper.timestampFromDb(data['sent']);
        DateTime? edited = (data['edited'] == null) ? null : Helper.timestampFromDb(data['edited']);
        MessageStatus status = MessageData.statusFromString(data['status']);
        var fileUrlV = data["fileUrl"];
        var fileNameV = data["fileUrl"];
        var fileTypeV = data["fileUrl"];
        var messageV = data["message"];
        String? fileUrl,fileName,message;
        FileType? fileType;

        if(fileTypeV != null) {
          var fileTypeStr = (enA == null) ? fileTypeV : enA.decryptText(fileTypeV);
          fileType = MessageData.fileTypeFromString(fileTypeStr);
        }

        if(fileUrlV != null) {
          fileUrl = (enA == null) ? fileUrlV : enA.decryptText(fileUrlV);
        }

        if(fileNameV != null) {
          fileName = (enA == null) ? fileNameV : enA.decryptText(fileNameV);
        }

        if(messageV != null) {
          message = (enA == null) ? messageV : enA.decryptText(messageV);
        }

        var sender = await getUser(senderId);

        ret.add(MessageData(roomId: roomId,id: id,sender: sender,sent: sent, edited: edited, message: message, fileUrl: fileUrl,fileName:fileName,fileType: fileType, status: status) );

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

      UserData otherUser = (sent) ? await getUser(receiverId) : await getUser(senderId);

      if(sent) {
        ret.add(RequestData(id:reqId,sender: user,receiver: otherUser) );
      }else {
        ret.add(RequestData(id:reqId,sender: otherUser,receiver: user) );
      }

    }

    return ret;
  }

  Future<UserData> getUser(String userId) async {
    var doc = await base.users.doc(userId).get();

      return UserData.fromDb(doc.data() as Map<String, dynamic>);
  }

  Future<bool> getTyping(String userId,String roodId,bool typing) async {
    var q = await base.typingInProgress
        .where("room",isEqualTo: roodId)
        .where("user",isNotEqualTo: userId)
        .get();

      for(var doc in q.docs) {
        var data = doc.data() as Map<String, dynamic>;

        return data["typing"];
      }

      return false;
  }

  Future<Users> findUser(String user) async {
    var q = await Future.wait({
        base.users.where("email",isEqualTo: user).get(),
        base.users.where("userName",isEqualTo: user).get(),
    });

    Users ret = [];
    String userId = base.userId;

      for(var doc in q.first.docs) {
        if(doc.id == userId) { continue; }

        ret.add(await getUser(doc.id) );
      }

      for(var doc in q.last.docs) {
        if(doc.id == userId) { continue; }

        ret.add(await getUser(doc.id) );
      }

      return ret;
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