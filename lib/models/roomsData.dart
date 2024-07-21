import 'userData.dart';

typedef Rooms = List<RoomsData>;

class RoomsData {
  String id;
  UserData? otherUser;
  int numberOfMessages;

  RoomsData({required this.id,required this.otherUser,required this.numberOfMessages});

  RoomsData copyWith({String? id,UserData? otherUser,int? numberOfMessages}) {
    return RoomsData(
        id: id ?? this.id,
        otherUser: otherUser ?? this.otherUser,
        numberOfMessages: numberOfMessages ?? this.numberOfMessages
    );
  }

}