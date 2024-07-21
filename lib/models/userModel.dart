

import 'messageData.dart';
import 'requestData.dart';
import 'roomData.dart';
import 'roomsData.dart';
import 'userData.dart';

class UserModel {
  UserData data;
  Users contacts;
  UserData? selectedUser;
  Rooms rooms;
  String roomId;
  RoomData? room;
  Requests requests;

  UserModel({required this.data,required this.contacts,required this.selectedUser,required this.requests,required this.rooms,required this.roomId,required this.room});

  UserModel.empty() : data = UserData.empty(),contacts = [],selectedUser = null,requests = [],rooms = [],roomId ="",room = null;

  UserModel.fresh({required this.data,required this.contacts,required this.requests,required this.rooms}) : selectedUser = null,roomId = "",room = null;

  UserModel copyWith({UserData? data,Users? contacts,Messages? messages,UserData? selectedUser,Requests? requests,Rooms? rooms,String? roomId,RoomData? room}) {
    return UserModel(
        data: data ?? this.data,
        contacts: contacts ?? this.contacts,
        selectedUser: selectedUser ?? this.selectedUser,
        requests: requests ?? this.requests,
        rooms: rooms ?? this.rooms,
        roomId: roomId ?? this.roomId,
        room: room ?? this.room
    );

  }

}