import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior/chat/chat_service.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserId;
  final String receiverUsername;
  final String receiverImageUrl;

  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserId,
    required this.receiverUsername,
    required this.receiverImageUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverUserId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverImageUrl.isNotEmpty
                  ? NetworkImage(widget.receiverImageUrl)
                  : const AssetImage('assests/default_avatar.jpg')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(widget.receiverUsername),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final currentUserId = _firebaseAuth.currentUser!.uid;
    final otherUserId = widget.receiverUserId;

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(currentUserId, otherUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            final isCurrentUser = data['senderId'] == currentUserId;
            final messageText = data['message'] ?? '';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final timeString =
                timestamp != null ? DateFormat.jm().format(timestamp) : '';

            return Align(
              alignment:
                  isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.green[200] : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isCurrentUser ? 12 : 0),
                    bottomRight: Radius.circular(isCurrentUser ? 0 : 12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(messageText, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(timeString,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Message",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
