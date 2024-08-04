import 'package:secure_messenger/helper/helper.dart';
import 'package:uuid/uuid.dart';

import 'userData.dart';

enum RequestStatus{pending,accepted,rejected}

typedef Requests = List<RequestData>;

class RequestData {
  String id = "";
  final UserData? sender;
  final UserData? receiver;

  RequestData({String id = "",required this.sender,required this.receiver}) {
    if(id == "") {
      this.id = const Uuid().v4();
    }else {
      this.id = id;
    }

  }

  RequestData copyWith({RequestStatus? status}) {
    return RequestData(
        id: id,
        sender: sender,
        receiver: receiver,
    );

  }

  Map<String,dynamic> toDb() {
    return {
      'id':id,
      'sender':sender!.id,
      'receiver':receiver!.id,
    };

  }

}