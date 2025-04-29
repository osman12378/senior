import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:senior/chat/chat_page.dart';
import 'package:senior/after_login/wishlist.dart';
import 'package:senior/after_login/Explore.dart';
import 'package:senior/profile/profile.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ExplorePage()));
    } else if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => WishlistPage()));
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ProfilePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'messages page',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _buildUserList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        iconSize: 30,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explore"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: "Wishlists"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    if (_auth.currentUser!.email == data['email']) return Container();

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: data['image_url'] != null &&
                    (data['image_url'] as String).isNotEmpty
                ? NetworkImage(data['image_url'])
                : const AssetImage('assests/default_avatar.jpg')
                    as ImageProvider,
          ),
          title: Text(
            data['username'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(data['email'] ?? 'No email'),
          onTap: () {
            print("Receiver UID: ${document.id}"); // Add this
            print("Receiver Email: ${data['email']}");
            print("Receiver Username: ${data['username']}");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverUserEmail: data['email'] ?? '',
                  receiverUserId: document.id,
                  receiverUsername: data['username'] ?? '',
                  receiverImageUrl: data['image_url'] ?? '',
                ),
              ),
            );
          },
        ),
        const Divider(
          height: 1,
          thickness: 2,
          indent: 72,
          endIndent: 16,
          color: Colors.grey,
        ),
      ],
    );
  }
}
