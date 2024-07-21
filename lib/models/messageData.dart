
enum MessageStatus{read,unread}
enum MessageType{normal,sec}

typedef Messages = List<MessageData>;

class MessageData {
  final String senderId;
  final String receiverId;
  final String key;
  final String sent;
  final String edited;
  final String message;
  final MessageStatus status;
  final MessageType type;

  const MessageData({required this.senderId,required this.receiverId,required this.key,required this.sent,required this.edited,required this.message,required this.status,required this.type});

  MessageData copyWith({String? senderId,String? receiverId,String? key,String? sent,String? edited,String? message,MessageStatus? status}) {
    return MessageData(
        senderId: senderId ?? this.senderId,
        receiverId: receiverId ?? this.receiverId,
        key: key ?? this.key,
        sent: sent ?? this.sent,
        edited: edited ?? this.edited,
        message: message ?? this.message,
        status: status ?? this.status,
        type: type
    );

  }

}