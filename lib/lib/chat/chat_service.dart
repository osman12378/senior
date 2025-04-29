import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior/model/message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a message to another user
  Future<void> sendMessage(String receiverId, String message) async {
    try {
      // Get current user info
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      final String currentUserEmail =
          _firebaseAuth.currentUser!.email.toString();
      final Timestamp timestamp = Timestamp.now();

      // Create new message
      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp,
      );

      // Construct chat room id from current user id and receiver id(sorted to ensure uniqueness)
      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatroomId = ids.join("_");

      // Add new message to database
      await _firestore
          .collection('chat_rooms')
          .doc(chatroomId)
          .collection("messages")
          .add(newMessage.toMap());

      print("Message sent successfully");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  /// Get messages between two users
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    // Construct chatroom ID (alphabetically sorted for consistency)
    List<String> ids = [userId, otherUserId]..sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
