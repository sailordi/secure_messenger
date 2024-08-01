import 'package:secure_messenger/helper/helper.dart';
import 'package:uuid/uuid.dart';

import 'userData.dart';

enum RequestStatus{pending,accepted,rejected}

typedef Requests = List<RequestData>;

class RequestData {
  String id = "";
  final UserData? sender;
  final UserData? receiver;
  final DateTime sent;
  final RequestStatus status;

  RequestData({String id = "",required this.sender,required this.receiver,required this.sent,required this.status}) {
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
        sent: sent,
        status: status ?? this.status
    );

  }

  Map<String,dynamic> toDb() {
    return {
      'id':id,
      'sender':sender!.id,
      'receiver':receiver!.id,
      'sent':Helper.timestampToDb(sent),
      'status': statusToString(status),
    };

  }

  static RequestStatus statusFromString(String s) {
    switch(s) {
      case "pending": return RequestStatus.pending;
      case "accepted": return RequestStatus.accepted;
      default: return RequestStatus.rejected;
    }

  }

  static String statusToString(RequestStatus s) {
    switch(s) {
      case RequestStatus.pending: return "pending";
      case RequestStatus.accepted: return "accepted";
      default: return "rejected";
    }

  }

}