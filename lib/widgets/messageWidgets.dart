import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_messenger/helper/helper.dart';
import 'package:secure_messenger/models/myError.dart';
import 'package:video_player/video_player.dart';

import '../manager/userManager.dart';
import '../models/messageData.dart';

class MessagesWidget extends ConsumerStatefulWidget {
  final String userId;
  final Future<void> Function(String,MessageData)? edit;
  final Future<void> Function(bool,MessageData)? typing;
  final Future<void> Function(MessageData)? delete;

  const MessagesWidget({super.key,required this.userId,required this.edit,required this.delete,this.typing});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends ConsumerState<MessagesWidget> {

  @override
  Widget build(BuildContext context) {
    var messagesM = ref.watch(messagesManager);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: ListView.builder(
          reverse: true,
          itemCount: messagesM!.length,
          itemBuilder: (context,index) {
            final m = messagesM[index];
            final isUser = widget.userId != m.sender.id;
            final alignment =
            isUser ? Alignment.centerRight : Alignment.centerLeft;
            final Color bgColor = isUser ? Colors.greenAccent : Colors.lightBlueAccent;
            const borderRadius = BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            );

            return _MessageWidget(
                message: m,
                alignment: alignment,
                isCurrentUser: isUser,
                borderRadius: borderRadius,
                bgColor: bgColor,
                edit: widget.edit,
                typing: widget.typing,
                delete: widget.delete
            );

          }
      )
    );

  }

}


class _MessageWidget extends StatelessWidget {
  final MessageData message;
  final Alignment alignment;
  final bool isCurrentUser;
  final BorderRadius borderRadius;
  final Color bgColor;
  final Future<void> Function(String,MessageData)? edit;
  final Future<void> Function(bool,MessageData)? typing;
  final Future<void> Function(MessageData)? delete;

  const _MessageWidget({
      super.key,
      required this.message,
      required this.alignment,
      required this.isCurrentUser,
      required this.borderRadius,
      required this.bgColor,
      required this.edit,
      required this.typing,
      required this.delete
    }
  );

  @override
  Widget build(BuildContext context) {
    bool editingDisabled = message.message != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      alignment: alignment,
      child: !isCurrentUser ? _buildMessageWidget() :
        GestureDetector(
          onLongPress: () => _longPress(context,editingDisabled),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMessageWidget(),
              _MessageSeenStatusWidget(status: message.status)
            ],
          ),
        )
    );
  }

  Widget _buildMessageWidget() {
    if(message.message != null) {
      return _TextMessageWidget(
          message: message.message!,
          borderRadius: borderRadius,
          bgColor: bgColor);
    }
    else if(message.fileUrl != null && message.fileType == FileType.image) {
      return _ImageMessageWidget(url: message.fileUrl!);
    }
    else if(message.fileUrl != null && message.fileType == FileType.video) {
      return _VideoMessageWidget(url: message.fileUrl!);
    }
    return const Text('Invalid message type');
  }

  Future<dynamic> _longPress(BuildContext context,bool editingDisabled) {
    return showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(130),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: !editingDisabled
                      ? () => showDialog(
                    context: context,
                    builder: (context) =>
                        _EditMessageWidget(message:message,edit:edit,typing: typing)
                    ) : null,
                    icon: Icon(
                      Icons.edit,
                      color: editingDisabled
                          ? const Color.fromARGB(255, 110, 110, 110)
                          : Colors.white,
                    ),
                ),
                IconButton(
                  onPressed: () async {
                    await delete!(message);
                    if(context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
              ]
          ),
        )
    );
  }

}

class _ImageMessageWidget extends StatelessWidget {
  final String url;

  const _ImageMessageWidget({super.key,required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          width: 200,
          height: 250,
          imageUrl: url,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        )
    );

  }

}

class _VideoMessageWidget extends StatefulWidget {
  final String url;

  const _VideoMessageWidget({super.key,required this.url});

  @override
  State<_VideoMessageWidget> createState() => _VideoMessageWidgetState();

}

class _VideoMessageWidgetState extends State<_VideoMessageWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
    VideoPlayerController.networkUrl(Uri.parse(widget.url) )
      ..initialize().then((_) {
        setState(() {});
      });
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      showControls: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Chewie(controller: _chewieController),
      ),
    );

  }

}

class _TextMessageWidget extends StatelessWidget {
  final String message;
  final BorderRadius borderRadius;
  final Color bgColor;

  const _TextMessageWidget({
      super.key,
      required this.message,
      required this.borderRadius,
      required this.bgColor,
    }
  );

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          constraints:
          const BoxConstraints(minWidth: 50, minHeight: 30, maxWidth: 170),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: bgColor,
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        );
  }

}

class _EditMessageWidget extends StatelessWidget {
  final MessageData message;
  final Future<void> Function(String,MessageData)? edit;
  final Future<void> Function(bool,MessageData)? typing;
  
  const _EditMessageWidget({super.key,required this.message,required this.edit,required this.typing});
  
  @override
  Widget build(BuildContext context) {
    final initialText = message.message!;
    final TextEditingController textEditingController =
    TextEditingController.fromValue(TextEditingValue(text: initialText) );

    if(typing != null) {
      textEditingController.addListener( () async {
        await typing!(textEditingController.text.isNotEmpty,message);
      });
    }
    
    return Dialog(
      child: TextField(
        controller: textEditingController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () async {
                try {
                  await edit!(textEditingController.text,message);
                } on MyError catch (e) {
                  if(context.mounted) {
                    Helper.messageToUser(e.text,context);
                  }
                  return;
                }
                if(context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            )),
      ),
    );
  }

}

class _MessageSeenStatusWidget extends StatelessWidget {
  final MessageStatus status;

  const _MessageSeenStatusWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.done_all,
      color: (status == MessageStatus.read) ? Colors.green : Colors.red,
      size: 18,
    );
  }
}