import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DeletedServicesPage extends StatelessWidget {
  final String userId;

  DeletedServicesPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text('Deleted Services'),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Service')
              .where('UserID', isEqualTo: userId)
              .where('Deleted', isEqualTo: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No deleted services found"));
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
      
                    String imageUrl = imageSnapshot.hasData
                        ? imageSnapshot.data!
                        : 'https://via.placeholder.com/150';
      
                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenImagePage(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
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
                        icon: Icon(Icons.restore, color: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('Service')
                              .doc(serviceId)
                              .update({'Deleted': false}).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Service restored')),
                            );
                          });
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
    );
  }

  Future<String?> _getServiceImageUrl(String serviceId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Service Images')
        .where('ServiceID', isEqualTo: serviceId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['URL'];
    }
    return null;
  }
}

// Reuse your existing full screen image viewer
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
