
import 'messageData.dart';
import 'userData.dart';

class RoomData {
  UserData? otherUser;
  Messages messages;

  RoomData({required this.otherUser,required this.messages});

  RoomData copyWith({UserData? otherUser,Messages? messages}) {
    return RoomData(
        otherUser: otherUser ?? this.otherUser,
        messages: messages ?? this.messages
    );
  }

}