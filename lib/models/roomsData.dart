import 'roomData.dart';
import 'userData.dart';

typedef Rooms = List<RoomsData>;

class RoomsData {
  final String id;
  final UserData? otherUser;
  final int numberOfMessages;
  final RoomType type;

  RoomsData({required this.id,required this.otherUser,required this.numberOfMessages,required this.type});

  RoomsData copyWith({String? id,UserData? otherUser,int? numberOfMessages}) {
    return RoomsData(
        id: id ?? this.id,
        otherUser: otherUser ?? this.otherUser,
        numberOfMessages: numberOfMessages ?? this.numberOfMessages,
        type: type
    );
  }

}