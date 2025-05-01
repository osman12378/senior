import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'deleted_services.dart';

class UserServicesPage extends StatelessWidget {
  final String userId;

  UserServicesPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Services'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.archive,
                color: Colors.red,
              ), // or Icons.delete_outline
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeletedServicesPage(userId: userId),
                  ),
                );
              },
            )
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Service')
              .where('UserID', isEqualTo: userId)
              .where('Deleted', isEqualTo: false)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                var serviceData = serviceDoc.data() as Map<String, dynamic>;
                String serviceId = serviceDoc.id;
                String description =
                    serviceData['Description'] ?? 'No description';
                String price = serviceData['Price']?.toString() ?? '0';
                String type = serviceData['Type'] ?? 'N/A';
      
                // Fetch the service image from 'Service Images' collection
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
                            // When the image is tapped, navigate to FullScreenImagePage
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
                                          .update({'Deleted': true}).then((_) {
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
                        ));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Function to fetch image URL from 'Service Images' collection
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

// FullScreenImagePage to display the image in full-screen mode
class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Screen Image'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close the full screen view
          },
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
