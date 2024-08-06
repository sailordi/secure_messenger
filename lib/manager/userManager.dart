import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_messenger/models/messageData.dart';
import 'package:secure_messenger/models/myError.dart';
import 'package:secure_messenger/models/requestData.dart';
import 'package:secure_messenger/models/roomData.dart';

import '../adapters/biometricAuthAdapter.dart';
import '../adapters/encryptionAdapter.dart';
import '../adapters/firebaseAdapter.dart';
import '../adapters/secureStorageAdapter.dart';
import '../models/userData.dart';
import '../models/userModel.dart';

class UserManager extends StateNotifier<UserModel> {
  final StateNotifierProviderRef ref;
  final FirebaseAdapter firebaseA = FirebaseAdapter();
  final SecureStorageAdapter storageA = SecureStorageAdapter();
  late EncryptionAdapter encryptDecryptA = EncryptionAdapter();
  StreamSubscription? contactsStream;
  StreamSubscription? chatsStream;
  StreamSubscription? sentRequestsStream;
  StreamSubscription? receivedRequestsStream;
  StreamSubscription? messageStream;
  StreamSubscription? typingStream;

  UserManager(this.ref) : super(UserModel.empty() );

  Future<void> logIn(String email,String password) async {
    try {
      await firebaseA.login(email, password);
      await _initData();
    } on MyError catch(e) {
      rethrow;
    }

  }

  Future<void> logInBio() async {
    bool canUse = await BiometricAuthAdapter.canUse();

    if(!canUse) {
      throw MyError("Biometric authentication can't be used");
    }

    bool loggedIn = await BiometricAuthAdapter.login();

    if(!loggedIn) {
      throw MyError("Can not use biometric authentication to login");
    }
    var emailPass = await storageA.getUser();

    if(emailPass.$1 == null) {
      throw MyError("Not registered/app newly installed please login/register normally");
    }
    String? email = emailPass.$1,password = emailPass.$2;

    await logIn(email!,password!);
  }

  Future<void> register(String username,String email,String password,File? image) async {
    encryptDecryptA.generateKeyPair();

    await firebaseA.register(username,email,password,image,
                              encryptDecryptA.encryptPublicKey(),
                              encryptDecryptA.encryptPrivateKey()
                            );

    await storageA.storeUser(email,password);
  }

  void logOut() {
    _disposeStreams();
    state = UserModel.empty();

    firebaseA.logOut();
  }

  Future<void> startTyping() async {
    String userId = state.data.id;
    var roomId = state.roomId!;

      await firebaseA.updateTypingInProgress(userId,roomId,true);
  }

  Future<void> stopTyping() async {
    String userId = state.data.id;
    var roomId = state.roomId!;

      await firebaseA.updateTypingInProgress(userId,roomId,false);
  }

  Future<void> createRoom(int index,RoomType t) async {
    Users contacts = state.contacts;

    RoomData r = RoomData(otherUser: contacts[index],type: t);

    state = state.copyWith(roomId: r.id,room: r,messages: []);

    _createRoomStream();
  }

  Future<void> selectRoom(int index) async {
    RoomData roomsData = state.rooms.elementAt(index);
    String roomId = roomsData.id;
    (RoomData,Messages) data = await firebaseA.getRoom(roomId,encryptDecryptA);

    state = state.copyWith(roomId: roomId,room: data.$1,messages: data.$2);

    _createRoomStream();
  }

  Future<void> unselectRoom() async {
    _disposeRoomStreams();

    state = state.copyWith(roomId: null,room: null,messages: []);
  }

  Future<void> findUser(String find) async {
    if(find.isEmpty) {
      state = state.copyWith(foundUsers: []);
    }

    var users =  await firebaseA.findUser(find);

    state = state.copyWith(foundUsers: users);
  }

  Future<UserData> sendRequest(int index) async {
    var foundU = state.foundUsers;

    try {
      await firebaseA.sendRequest(RequestData(sender: state.data, receiver: foundU.elementAt(index) ) );
    } on String catch(e) {
      rethrow;
    }

    return foundU.elementAt(index);
  }

  Future<UserData> acceptRequest(int index) async {
    var rec = state.receivedRequests;

      await firebaseA.acceptRequests(rec.elementAt(index) );

      return rec.elementAt(index).sender!;
  }

  Future<UserData> declineRequest(int index) async {
    var rec = state.receivedRequests;

      await firebaseA.declineRequests(rec.elementAt(index) );

      return rec.elementAt(index).sender!;
  }

  Future<UserData> removeContact(int index) async {
    var contacts = state.contacts;

      await firebaseA.deleteContact(contacts.elementAt(index) );

      return contacts.elementAt(index);
  }

  Future<void> _initData() async{
    try {
      var dataAndKey = await firebaseA.getYourData();
      UserModel userM = dataAndKey.$1;

      encryptDecryptA.decodeKeys(dataAndKey.$2);

      state = userM;

      _createStreams();
    } catch(e) {
      logOut();
    }

  }

  void _createStreams() {
    contactsStream = firebaseA.contactsStream( () async {
        var c = await firebaseA.getContacts();

        state = state.copyWith(contacts: c);
      }
    );

    chatsStream = firebaseA.chatsStream( () async {
          var r = await firebaseA.getRooms();

          state = state.copyWith(rooms: r);
      }
    );

    receivedRequestsStream = firebaseA.requestStream(
        sent:false,
        user: state.data,
        requestChange: (UserData user,bool sent)  async {
          var requests = await firebaseA.getRequests(user,sent: sent);

          state = state.copyWith(receivedRequests: requests);
        }
    );

    sentRequestsStream = firebaseA.requestStream(
        sent:true,
        user: state.data,
        requestChange: (UserData user,bool sent)  async {
          var requests = await firebaseA.getRequests(user,sent: sent);

          state = state.copyWith(receivedRequests: requests);
        }
    );

  }

  void _createRoomStream() {
    messageStream = firebaseA.messageStream(state.room!,(String roomId) async {
      var room = state.room!;
      var messages = await firebaseA.getMessages(roomId,
                      (room.type == RoomType.normal) ? null : encryptDecryptA);

        state = state.copyWith(messages: messages);
    });

    typingStream = firebaseA.typingStream(state.data.id,state.room!,() async {

    });

  }

  void _disposeStreams() {
    if(contactsStream != null) {
      contactsStream!.cancel();
      contactsStream = null;
    }

    if(chatsStream != null) {
      chatsStream!.cancel();
      chatsStream = null;
    }

    if(sentRequestsStream != null) {
      sentRequestsStream!.cancel();
      sentRequestsStream = null;
    }

    if(receivedRequestsStream != null) {
      receivedRequestsStream!.cancel();
      receivedRequestsStream = null;
    }

    _disposeRoomStreams();
  }

  void _disposeRoomStreams() {
    if(messageStream != null) {
      messageStream!.cancel();
      messageStream = null;
    }

    if(typingStream != null) {
      typingStream!.cancel();
      typingStream = null;
    }

  }

}

final userDataManager = Provider<UserData>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.data;
});

final receivedReqManager = Provider<Requests>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.receivedRequests;
});

final sentReqManager = Provider<Requests>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.sentRequests;
});

final contactsManager = Provider<Users>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.contacts;
});

final roomsManager = Provider<Rooms>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.rooms;
});

final messagesManager = Provider<Messages?>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.messages;
});

final foundUsersManager = Provider<Users>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.foundUsers;
});

final userManager = StateNotifierProvider<UserManager,UserModel>( (ref) {
  return UserManager(ref);
});