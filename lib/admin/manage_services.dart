import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'deleted_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserServicesPage extends StatefulWidget {
  final String userId;
  UserServicesPage({required this.userId});

  @override
  State<UserServicesPage> createState() => _UserServicesPageState();
}

class _UserServicesPageState extends State<UserServicesPage> {
  String? selectedCategoryId; // Currently selected category ID
  static const String allCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text('Manage Services'),
          actions: [
            IconButton(
              icon: Icon(Icons.archive, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          DeletedServicesPage(userId: widget.userId)),
                );
              },
            )
          ],
        ),
        body: Column(
          children: [
            // Categories Horizontal List with AnimatedContainer
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Category')
                    .snapshots(),
                builder: (context, categorySnapshot) {
                  if (categorySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!categorySnapshot.hasData ||
                      categorySnapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No categories found'));
                  }
                  final categories = categorySnapshot.data!.docs;

                  // Add a fake "All" category at the start
                  final allCategoryDoc = {
                    'id': allCategoryId,
                    'Name': 'All',
                  };

                  // Compose categories list with "All" first
                  final allCategories = [
                    allCategoryDoc,
                    ...categories.map((doc) => {
                          'id': doc.id,
                          'Name': doc['Name'] ?? 'Unnamed',
                        })
                  ];

                  // If no category selected yet, select "All"
                  selectedCategoryId ??= allCategoryId;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allCategories.length,
                    itemBuilder: (context, index) {
                      final categoryId = allCategories[index]['id']!;
                      final categoryName = allCategories[index]['Name']!;

                      final isSelected = selectedCategoryId == categoryId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = categoryId;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.indigo
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.indigo.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Divider for separation
            Divider(height: 1),

            // Expanded list of services filtered by selectedCategoryId
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getServicesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No services found"));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var serviceDoc = snapshot.data!.docs[index];
                      var serviceData =
                          serviceDoc.data()! as Map<String, dynamic>;
                      String serviceId = serviceDoc.id;
                      String description =
                          serviceData['Description'] ?? 'No description';
                      String price = serviceData['Price']?.toString() ?? '0';
                      String type = serviceData['Type'] ?? 'N/A';

                      return FutureBuilder<String?>(
                        future: _getServiceImageUrl(serviceId),
                        builder: (context, imageSnapshot) {
                          if (imageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text(description),
                              subtitle: Text('Price: $price, Type: $type'),
                            );
                          }

                          String serviceImageUrl = imageSnapshot.hasData
                              ? imageSnapshot.data!
                              : 'https://via.placeholder.com/150';

                          return ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImagePage(
                                        imageUrl: serviceImageUrl),
                                  ),
                                );
                              },
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: serviceImageUrl,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.image),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(description),
                            subtitle: Text('Price: $price, Type: $type'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                String adminId =
                                    FirebaseAuth.instance.currentUser!.uid;

                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('Delete Service'),
                                    content: Text(
                                        'Are you sure you want to delete this service?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection('Service')
                                              .doc(serviceId)
                                              .update({
                                            'Deleted': true,
                                            'adminId': adminId,
                                          }).then((_) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Service marked as deleted')),
                                            );
                                          });
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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

  Stream<QuerySnapshot> _getServicesStream() {
    final baseQuery = FirebaseFirestore.instance
        .collection('Service')
        .where('UserID', isEqualTo: widget.userId)
        .where('Deleted', isEqualTo: false);

    if (selectedCategoryId == allCategoryId) {
      // Return all services for this user
      return baseQuery.snapshots();
    } else {
      // Filter by selected category
      return baseQuery
          .where('CategoryID', isEqualTo: selectedCategoryId)
          .snapshots();
    }
  }

  Future<String?> _getServiceImageUrl(String serviceId) async {
    final imageSnapshot = await FirebaseFirestore.instance
        .collection('Service Images')
        .where('ServiceID', isEqualTo: serviceId)
        .limit(1)
        .get();

    if (imageSnapshot.docs.isNotEmpty) {
      return imageSnapshot.docs.first.data()['URL'];
    }
    return null;
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: Text('Full Screen Image'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.image),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
