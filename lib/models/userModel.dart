

import 'messageData.dart';
import 'requestData.dart';
import 'roomData.dart';
import 'userData.dart';

class UserModel {
  UserData data;
  Users contacts;
  Users foundUsers;
  UserData? selectedUser;
  Rooms rooms;
  String? roomId;
  RoomData? room;
  Messages messages;
  bool otherUserTyping = false;
  Requests sentRequests;
  Requests receivedRequests;

  UserModel({required this.data,required this.contacts,
        required this.foundUsers,required this.selectedUser,required this.sentRequests,
        required this.receivedRequests,required this.rooms,required this.roomId,
        required this.room,required this.messages,required this.otherUserTyping});

  UserModel.empty() : data = UserData.empty(),contacts = [],selectedUser = null,sentRequests = [],receivedRequests = [],foundUsers = [],rooms = [],roomId = null,room = null,messages=[],otherUserTyping = false;

  UserModel.fresh({required this.data,required this.contacts,required this.sentRequests,required this.receivedRequests,required this.rooms}) : foundUsers = [],selectedUser = null,roomId = null,room = null,messages = [],otherUserTyping = false;

  UserModel copyWith({UserData? data,Users? contacts,Users? foundUsers,UserData? selectedUser,Requests? sentRequests,Requests? receivedRequests,Rooms? rooms,String? roomId,RoomData? room,Messages? messages,bool? otherUserTyping}) {
    return UserModel(
        data: data ?? this.data,
        contacts: contacts ?? this.contacts,
        selectedUser: selectedUser ?? this.selectedUser,
        sentRequests: sentRequests ?? this.sentRequests,
        receivedRequests: receivedRequests ?? this.receivedRequests,
        foundUsers: foundUsers ?? this.foundUsers,
        rooms: rooms ?? this.rooms,
        roomId: roomId ?? this.roomId,
        room: room ?? this.room,
        messages: messages ?? this.messages,
        otherUserTyping: otherUserTyping ?? this.otherUserTyping
    );

  }

}