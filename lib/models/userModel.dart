

import 'messageData.dart';
import 'requestData.dart';
import 'roomData.dart';
import 'roomsData.dart';
import 'userData.dart';

class UserModel {
  UserData data;
  Users contacts;
  Users foundUsers;
  UserData? selectedUser;
  Rooms rooms;
  String roomId;
  RoomData? room;
  Requests sentRequests;
  Requests receivedRequests;

  UserModel({required this.data,required this.contacts,
        required this.foundUsers,required this.selectedUser,required this.sentRequests,
        required this.receivedRequests,required this.rooms,required this.roomId,
        required this.room});

  UserModel.empty() : data = UserData.empty(),contacts = [],selectedUser = null,sentRequests = [],receivedRequests = [],foundUsers = [],rooms = [],roomId ="",room = null;

  UserModel.fresh({required this.data,required this.contacts,required this.sentRequests,required this.receivedRequests,required this.rooms}) : foundUsers = [],selectedUser = null,roomId = "",room = null;

  UserModel copyWith({UserData? data,Users? contacts,Messages? messages,Users? foundUsers,UserData? selectedUser,Requests? sentRequests,Requests? receivedRequests,Rooms? rooms,String? roomId,RoomData? room}) {
    return UserModel(
        data: data ?? this.data,
        contacts: contacts ?? this.contacts,
        selectedUser: selectedUser ?? this.selectedUser,
        sentRequests: sentRequests ?? this.sentRequests,
        receivedRequests: receivedRequests ?? this.receivedRequests,
        foundUsers: foundUsers ?? this.foundUsers,
        rooms: rooms ?? this.rooms,
        roomId: roomId ?? this.roomId,
        room: room ?? this.room
    );

  }

}