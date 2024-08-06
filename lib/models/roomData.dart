import 'package:uuid/uuid.dart';

import 'messageData.dart';
import 'userData.dart';

enum RoomType{normal,secure}

typedef Rooms = List<RoomData>;

class RoomData {
  String id = "";
  final UserData? otherUser;
  final RoomType type;

  RoomData({String id = "",this.otherUser,required this.type}) {
    if(id == "") {
      this.id = const Uuid().v4();
    }else {
      this.id = id;
    }

  }

  static String typeToString(RoomType t) {
    return (t == RoomType.normal) ? "normal" : "secure";
  }

  static RoomType typeFromString(String t) {
    return (t == "normal") ? RoomType.normal : RoomType.secure;
  }

}