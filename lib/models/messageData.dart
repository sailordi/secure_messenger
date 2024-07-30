
import 'package:secure_messenger/models/userData.dart';
import 'package:uuid/uuid.dart';

import '../helper/helper.dart';

enum MessageStatus{read,unread}

typedef Messages = List<MessageData>;

class MessageData {
  String id = "";
  final String roomId;
  final UserData sender;
  final DateTime sent;
  final DateTime? edited;
  final String message;
  final MessageStatus status;

  MessageData({String id = "",required this.roomId,required this.sender,required this.sent,required this.edited,required this.message,required this.status}) {
    if(id == "") {
      this.id = const Uuid().v4();
    }else {
      this.id = id;
    }

  }

  MessageData copyWith({DateTime? edited,String? message,MessageStatus? status}) {
    return MessageData(
        roomId: roomId,
        sender: sender,
        sent: sent,
        edited: edited ?? this.edited,
        message: message ?? this.message,
        status: status ?? this.status,
    );

  }

  MessageData.fromDb(Map<String,dynamic> data,this.sender) :
                      id=data['id'],
                      roomId=data['room'],
                      sent = Helper.timestampFromDb(data['sent']),
                      edited = (data['edited'] == "") ? null :
                                  Helper.timestampFromDb(data['edited']),
                      message = data['message'],
                      status = statusFromString(data['status']);

  Map<String,dynamic> toDb() {
    return {
      'id':id,
      'room':roomId,
      'sender':sender.id,
      'sent':Helper.timestampToDb(sent),
      'edited': (edited == null) ? "" : Helper.timestampToDb(edited!),
      'message':message,
      'status': statusToString(status),
    };

  }

  static String statusToString(MessageStatus s) {
    return (s == MessageStatus.read) ? 'read' : 'unread';
  }

  static MessageStatus statusFromString(String s) {
    return (s == "read") ? MessageStatus.read : MessageStatus.unread;
  }

}