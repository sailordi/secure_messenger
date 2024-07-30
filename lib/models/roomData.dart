import 'package:uuid/uuid.dart';

import 'messageData.dart';
import 'userData.dart';

enum RoomType{normal,secure}

class RoomData {
  String id = "";
  final UserData? otherUser;
  final Messages messages;
  final RoomType type;

  RoomData({String id = "",this.otherUser,required this.messages,required this.type}) {
    if(id == "") {
      this.id = const Uuid().v4();
    }else {
      this.id = id;
    }

  }

  RoomData copyWith({UserData? otherUser,Messages? messages}) {
    return RoomData(
        id: id,
        otherUser: otherUser ?? this.otherUser,
        messages: messages ?? this.messages,
        type: type
    );

  }

  static String typeToString(RoomType t) {
    return (t == RoomType.normal) ? "normal" : "secure";
  }

  static RoomType typeFromString(String t) {
    return (t == "normal") ? RoomType.normal : RoomType.secure;
  }

}