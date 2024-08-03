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
import '../models/roomsData.dart';
import '../models/userData.dart';
import '../models/userModel.dart';

class UserManager extends StateNotifier<UserModel> {
  final StateNotifierProviderRef ref;
  final FirebaseAdapter firebaseA = FirebaseAdapter();
  final SecureStorageAdapter storageA = SecureStorageAdapter();
  late EncryptionAdapter encryptDecryptA = EncryptionAdapter();
  StreamSubscription? contactsStream;
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

  Future<void> selectRoom(int index) async {
    RoomsData roomsData = state.rooms.elementAt(index);
    String roomId = roomsData.id;
    RoomData room = await firebaseA.getRoom(roomId,encryptDecryptA);

    state = state.copyWith(roomId: roomId,room: room);

    _createRoomStream();
  }

  Future<void> unselectRoom() async {
    _disposeRoomStreams();

    state = state.copyWith(roomId: null,room: null);
  }

  Future<void> _initData() async{
    var dataAndKey = await firebaseA.getYourData();
    UserModel userM = dataAndKey.$1;

    encryptDecryptA.decodeKeys(dataAndKey.$2);

    state = userM;

    _createStreams();
  }

  void _createStreams() {
    contactsStream = firebaseA.contactsStream(() async {
      var c = await firebaseA.getContacts();

      state = state.copyWith(contacts: c);
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

        room = room.copyWith(messages: messages);

        state = state.copyWith(room: room);
    });

    typingStream = firebaseA.typingStream(state.data.id,state.room!,() async {

    });

  }

  void _disposeStreams() {
    if(contactsStream != null) {
      contactsStream!.cancel();
      contactsStream = null;
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

final messagesManager = Provider<Messages?>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.room?.messages;
});

final foundUsersManager = Provider<Users>((ref) {
  final userModel = ref.watch(userManager);
  return userModel.foundUsers;
});

final userManager = StateNotifierProvider<UserManager,UserModel>( (ref) {
  return UserManager(ref);
});