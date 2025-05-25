import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'manage_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  String selectedRole = 'Premium Host'; // default category
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 🔹 Category Selector
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Premium Host', 'Host', 'renter'].map((role) {
                  bool isSelected = selectedRole == role;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRole = role;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 🔹 Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.trim();
                  });
                },
              ),
            ),

            // 🔹 Users List
            Expanded(
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No users found"));
                  }

                  // Filter users by selected role AND username search substring (case insensitive)
                  final filteredUsers = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final roleMatch = data['role'] == selectedRole;
                    final username = (data['username'] ?? '').toString();
                    final searchMatch = searchText.isEmpty
                        ? true
                        : username
                            .toLowerCase()
                            .contains(searchText.toLowerCase());
                    return roleMatch && searchMatch;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                        child: Text(
                            "No $selectedRole users found matching \"$searchText\""));
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      var userDoc = filteredUsers[index];
                      var data = userDoc.data() as Map<String, dynamic>;
                      String userId = userDoc.id;
                      String name = data['username'] ?? 'Unknown';
                      String email = data['email'] ?? 'No email available';
                      bool isActive = data['status'] ?? false;
                      String profilePicPath = 'profiles/$userId.jpg';

                      return FutureBuilder<String>(
                        future: FirebaseStorage.instance
                            .ref(profilePicPath)
                            .getDownloadURL(),
                        builder: (context, imageSnapshot) {
                          String profilePicUrl =
                              imageSnapshot.hasData ? imageSnapshot.data! : '';

                          return ListTile(
                            leading: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profilePicUrl.isNotEmpty
                                    ? profilePicUrl
                                    : '',
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
                                backgroundColor:
                                    isActive ? Colors.red : Colors.green,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                String adminId =
                                    FirebaseAuth.instance.currentUser!.uid;
                                bool newStatus = !isActive;

                                // Update user status
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .update({
                                  'status': newStatus,
                                  'adminId': adminId,
                                });

                                // Reference to the Service collection
                                final serviceRef = FirebaseFirestore.instance
                                    .collection('Service');

                                if (!newStatus) {
                                  // 🔻 Deactivating user: mark all their services as deleted
                                  final userServices = await serviceRef
                                      .where('UserID', isEqualTo: userId)
                                      .get();

                                  WriteBatch batch =
                                      FirebaseFirestore.instance.batch();
                                  for (var doc in userServices.docs) {
                                    batch.update(
                                        doc.reference, {'Deleted': true});
                                  }
                                  await batch.commit();
                                } else {
                                  // 🔼 Activating user: only restore services NOT deleted by user or created by admin
                                  final userServices = await serviceRef
                                      .where('UserID', isEqualTo: userId)
                                      .get();

                                  for (var doc in userServices.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    // Skip services if deleted by user or created by admin
                                    if (data['deletedbyuser'] == true ||
                                        data.containsKey('adminId')) {
                                      continue;
                                    }

                                    await doc.reference
                                        .update({'Deleted': false});
                                  }
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      newStatus
                                          ? 'User Activated and Services Restored'
                                          : 'User Deactivated and Services Hidden',
                                    ),
                                  ),
                                );
                              },
                              child: Text(isActive ? 'Deactivate' : 'Activate'),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserServicesPage(userId: userId),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
