import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaAdapter {

  static Future _getImage(ImageSource source,void Function(File) addFile) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      addFile(File(pickedFile.path) );
    }

  }

  static Future _getVideo(ImageSource source,void Function(File) addFile) async {
    final pickedFile = await ImagePicker().pickVideo(source: source);

    if (pickedFile != null) {
      addFile(File(pickedFile.path) );
    }

  }

  static void showImageSourceDialog(BuildContext context,void Function(File) addFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select image source"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera,addFile);
              },
              child: const Text("Camera"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery,addFile);
              },
              child: const Text("Gallery"),
            ),
          ],
        );
      },
    );
  }

  static void showVideoSourceDialog(BuildContext context,void Function(File) addFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select video source"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getVideo(ImageSource.camera,addFile);
              },
              child: const Text("Camera"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getVideo(ImageSource.gallery,addFile);
              },
              child: const Text("Gallery"),
            ),
          ],
        );
      },
    );
  }

}