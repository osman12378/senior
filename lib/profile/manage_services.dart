import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'EditServicePage.dart'; // Import the EditServicePage

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({Key? key}) : super(key: key);

  @override
  _ManageServicesPageState createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  late String userId;
  late Future<List<DocumentSnapshot>> _services; // Change to DocumentSnapshot

  @override
  void initState() {
    super.initState();
    userId =
        FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user ID
    _services = getUserServices(); // Fetch services data for this user
  }

  // Fetch services for the current user from Firestore
  Future<List<DocumentSnapshot>> getUserServices() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Service')
        .where('UserID', isEqualTo: userId)
        .where('Deleted', isEqualTo: false) // Only fetch non-deleted services
        .get();

    return snapshot.docs; // Return the docs directly
  }

  // Function to fetch image URL for each service from the service_images collection
  Future<String> _getServiceImageUrl(String serviceId) async {
    QuerySnapshot imageQuery = await FirebaseFirestore.instance
        .collection('Service Images')
        .where('ServiceID', isEqualTo: serviceId)
        .get();

    if (imageQuery.docs.isNotEmpty) {
      return imageQuery.docs.first['URL'];
    } else {
      return 'https://via.placeholder.com/150'; // Default placeholder image
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading services"));
          }

          final services = snapshot.data ?? [];

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final serviceId = service.id; // Get the document ID directly

              return FutureBuilder<String>(
                // Fetch image URL for each service
                future: _getServiceImageUrl(serviceId),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      leading: const CircularProgressIndicator(),
                      title: Text(service['Description'] ?? 'No name'),
                      subtitle: Text("\$${service['Price']}"),
                    );
                  }

                  String imageUrl =
                      imageSnapshot.data ?? 'https://via.placeholder.com/150';

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade300,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image, size: 40),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      service['Description'] ?? 'Untitled Service',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("\$${service['Price']}"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to EditServicePage with the serviceId
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditServicePage(serviceId: serviceId),
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
    );
  }
}
