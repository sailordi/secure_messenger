import 'userData.dart';

enum RequestStatus{pending,accepted,rejected}

typedef Requests = List<RequestData>;

class RequestData {
  final UserData sender;
  final UserData receiver;
  final String sent;
  final bool seen;
  final RequestStatus status;

  const RequestData({required this.sender,required this.receiver,required this.sent,required this.seen,required this.status});

  RequestData copyWith({UserData? sender,UserData? receiver,String? sent,bool? seen,RequestStatus? status}) {
    return RequestData(
        sender: sender ?? this.sender,
        receiver: receiver ?? this.receiver,
        sent: sent ?? this.sent,
        seen: seen ?? this.seen,
        status: status ?? this.status
    );

  }

}