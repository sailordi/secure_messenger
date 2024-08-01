import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_messenger/models/messageData.dart';
import 'package:secure_messenger/models/myError.dart';
import 'package:secure_messenger/models/requestData.dart';

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
  StreamSubscription? sentRequestsStream;
  StreamSubscription? receivedRequestsStream;
  StreamSubscription? messageStream;
  StreamSubscription? typingStream;

  UserManager(this.ref) : super(UserModel.empty() );

  Future<void> logIn(String email,String password) async {
    try {
      await firebaseA.login(email, password);
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

  Future<void> init() async{
    var dataAndKey = await firebaseA.getYourData();
    UserModel userM = dataAndKey.$1;

    encryptDecryptA.decodeKeys(dataAndKey.$2);

    contactsStream = firebaseA.contactsStream(() async {
      var c = await firebaseA.getContacts();

        state = state.copyWith(contacts: c);
      }
    );

    receivedRequestsStream = firebaseA.requestStream(
        sent:false,
        user: userM.data,
        requestChange: (UserData user,bool sent)  async {
          var requests = await firebaseA.getRequests(user,sent: sent);

          state = state.copyWith(receivedRequests: requests);
        }
    );

    sentRequestsStream = firebaseA.requestStream(
        sent:true,
        user: userM.data,
        requestChange: (UserData user,bool sent)  async {
          var requests = await firebaseA.getRequests(user,sent: sent);

          state = state.copyWith(receivedRequests: requests);
        }
    );

    state = userM;
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

    disposeRoomStreams();
  }

  void disposeRoomStreams() {
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