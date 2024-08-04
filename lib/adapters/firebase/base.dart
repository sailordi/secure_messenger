import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Base {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final CollectionReference users = FirebaseFirestore.instance.collection("users");
  final CollectionReference rooms = FirebaseFirestore.instance.collection("rooms");
  final CollectionReference requests = FirebaseFirestore.instance.collection("requests");
  final CollectionReference typingInProgress = FirebaseFirestore.instance.collection("typingInProgress");

  String get userId => auth.currentUser!.uid;

  WriteBatch batch() { return FirebaseFirestore.instance.batch(); }

  Future<void> batchCommit(WriteBatch b) async {
    try {
      await b.commit();
      print("Batch update successful");
    } catch (e) {
      print("Failed to update batch: $e");
    }

  }

  CollectionReference contacts(String userId) {
    return users.doc(userId).collection("friends");
  }

  CollectionReference roomMembers(String roomId) {
    return rooms.doc(roomId).collection("members");
  }

  CollectionReference messages(String roomId) {
    return rooms.doc(roomId).collection("messages");
  }

  String parentDocumentId(DocumentReference doc) {
    // Get the full path of the document
    String fullPath = doc.path;

    // Split the path to get parts
    List<String> pathParts = fullPath.split('/');

    // Assuming the subcollection 'orders' is always under a parent document
    // The parent document ID would be the second last element in the path
    String parentId = pathParts[pathParts.length - 3];

      return parentId;
  }

}