import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageUsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userDoc = snapshot.data!.docs[index];
              var data = userDoc.data() as Map<String, dynamic>;
              String userId = userDoc.id;
              String name = data['username'] ?? 'Unknown';
              String email = data['email'] ?? 'No email available';
              bool isActive =
                  data['status'] ?? false; // Check the user's active status
              String profilePicPath = 'profiles/$userId.jpg';

              // Fetch the user's profile picture from Firebase Storage
              return FutureBuilder<String>(
                future: FirebaseStorage.instance
                    .ref(profilePicPath)
                    .getDownloadURL(),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      leading: CircleAvatar(child: CircularProgressIndicator()),
                      title: Text(name),
                      subtitle: Text(email),
                    );
                  }

                  String profilePicUrl =
                      imageSnapshot.hasData ? imageSnapshot.data! : '';

                  return ListTile(
                    leading: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profilePicUrl.isNotEmpty
                            ? profilePicUrl
                            : '', // Use empty string if no URL
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.person),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text(email),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.red
                            : Colors.green, // Set background color
                        foregroundColor:
                            Colors.black, // Set text color to black
                      ),
                      onPressed: () {
                        // Toggle the active status when the button is pressed
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({
                          'status': !isActive, // Toggle the status
                        }).then((_) {
                          // Show a Snackbar or toast for confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isActive
                                    ? 'User Deactivated'
                                    : 'User Activated')),
                          );
                        });
                      },
                      child: Text(isActive ? 'Deactivate' : 'Activate'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
