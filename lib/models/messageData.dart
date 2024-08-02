import 'package:uuid/uuid.dart';

import 'userData.dart';

enum MessageStatus{read,unread}
enum FileType{video,image}

typedef Messages = List<MessageData>;

class MessageData {
  String id = "";
  final String roomId;
  final UserData sender;
  final DateTime sent;
  final DateTime? edited;
  final String? message;
  final String? fileUrl;
  final String? fileName;
  final FileType? fileType;
  final MessageStatus status;

  MessageData({String id = "",required this.roomId,required this.sender,required this.sent,required this.edited,required this.message,required this.fileUrl,required this.fileName,required this.fileType,required this.status}) {
    if(id == "") {
      this.id = const Uuid().v4();
    }else {
      this.id = id;
    }

  }

  MessageData copyWith({DateTime? edited,String? message,String? fileUrl,String? fileName,FileType? fileType,MessageStatus? status}) {
    return MessageData(
        roomId: roomId,
        sender: sender,
        sent: sent,
        edited: edited ?? this.edited,
        message: message ?? this.message,
        fileUrl: fileUrl ?? this.fileUrl,
        fileName: fileName ?? this.fileName,
        fileType: fileType ?? this.fileType,
        status: status ?? this.status,
    );

  }

  static String statusToString(MessageStatus s) {
    return (s == MessageStatus.read) ? 'read' : 'unread';
  }

  static MessageStatus statusFromString(String s) {
    return (s == "read") ? MessageStatus.read : MessageStatus.unread;
  }

  static String fileTypeToString(FileType f) {
    return (f == FileType.image) ? "image" : "video";
  }

  static FileType fileTypeFromString(String f) {
    return (f == "image") ? FileType.image : FileType.video;
  }



}