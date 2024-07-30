import 'userData.dart';

typedef Rooms = List<RoomsData>;

class RoomsData {
  final String id;
  final UserData? otherUser;
  final int numberOfMessages;

  RoomsData({required this.id,required this.otherUser,required this.numberOfMessages});

  RoomsData copyWith({String? id,UserData? otherUser,int? numberOfMessages}) {
    return RoomsData(
        id: id ?? this.id,
        otherUser: otherUser ?? this.otherUser,
        numberOfMessages: numberOfMessages ?? this.numberOfMessages
    );
  }

}