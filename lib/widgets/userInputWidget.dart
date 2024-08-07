import 'dart:io';

import 'package:flutter/material.dart';
import 'package:secure_messenger/adapters/mediaAdapter.dart';
import 'package:secure_messenger/helper/helper.dart';
import 'package:secure_messenger/models/messageData.dart';
import 'package:secure_messenger/models/myError.dart';

class UserInputWidget extends StatelessWidget {
  final Future<void> Function(bool)? typing;
  final Future<void> Function(String)? send;
  final Future<void> Function(File,FileType)? pickFile;
  final TextEditingController _textEditingController = TextEditingController();

  UserInputWidget({super.key,required this.typing,required this.send,required this.pickFile});

  @override
  Widget build(BuildContext context) {
    _textEditingController.addListener( () async {
      if(_textEditingController.text.isNotEmpty) {
        await typing!(true);
      }else {
        await typing!(false);
      }
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PickImageButtonWidget(pickFile: pickFile),
          _PickVideoButtonWidget(pickFile: pickFile),
          _InputBar(textEditingController:_textEditingController),
          _SendButtonWidget(textEditingController: _textEditingController,send: send),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController textEditingController;

  const _InputBar({super.key,required this.textEditingController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 45,
        child: TextField(
              keyboardType: TextInputType.multiline,
              controller: textEditingController,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(bottom: 3, left: 20),
                fillColor: Colors.greenAccent,
                filled: true,
                hintText: 'Type a message...',
                hintStyle:
                const TextStyle(color: Color.fromARGB(193, 255, 255, 255)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            )
        ),
      );
  }

}

class _PickImageButtonWidget extends StatelessWidget {
  final Future<void> Function(File,FileType)? pickFile;

  const _PickImageButtonWidget({super.key,required this.pickFile});

  @override
  Widget build(BuildContext context) {
    return IconButton(
          onPressed: () async {
            MediaAdapter.showImageSourceDialog(context,(File file) async {
              await pickFile!(file,FileType.image);
            });

          },
          icon: const Icon(
            Icons.image,
            color: Colors.white,
          ),
          style: IconButton.styleFrom(backgroundColor: Colors.greenAccent),
          color: Colors.white,
        );
  }

}

class _PickVideoButtonWidget extends StatelessWidget {
  final Future<void> Function(File,FileType)? pickFile;

  const _PickVideoButtonWidget({super.key,required this.pickFile});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        MediaAdapter.showVideoSourceDialog(context,(File file) async {
          await pickFile!(file,FileType.video);
        });

      },
      icon: const Icon(
        Icons.video_file,
        color: Colors.white,
      ),
      style: IconButton.styleFrom(backgroundColor: Colors.greenAccent),
      color: Colors.white,
    );
  }

}

class _SendButtonWidget extends StatelessWidget {
  final Future<void> Function(String)? send;
  final TextEditingController textEditingController;

  const _SendButtonWidget({super.key, required this.textEditingController,required this.send});

  @override
  Widget build(BuildContext context) {
    return IconButton(
          onPressed: () async {
            try {
              await send!(textEditingController.text);
              textEditingController.clear();
            } on MyError catch (e) {
              if(context.mounted) {
                Helper.messageToUser(e.text,context)
              }
            }
            return;
          },
          icon: const Icon(Icons.arrow_forward),
          style: IconButton.styleFrom(backgroundColor: Colors.greenAccent),
          color: Colors.white,
        );
  }

}