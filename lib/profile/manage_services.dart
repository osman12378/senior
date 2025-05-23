import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'EditServicePage.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({Key? key}) : super(key: key);

  @override
  _ManageServicesPageState createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  late String userId;
  List<DocumentSnapshot> _allServices = [];
  List<DocumentSnapshot> _filteredServices = [];
  List<DocumentSnapshot> _categories = [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    // Fetch categories
    QuerySnapshot categorySnapshot =
        await FirebaseFirestore.instance.collection('Category').get();

    // Fetch services
    QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
        .collection('Service')
        .where('UserID', isEqualTo: userId)
        .where('Deleted', isEqualTo: false)
        .get();

    setState(() {
      _categories = categorySnapshot.docs;
      _allServices = serviceSnapshot.docs;
      _filteredServices = _allServices;
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == null) {
        _filteredServices = _allServices;
      } else {
        _filteredServices = _allServices
            .where((doc) => doc['CategoryID'] == categoryId)
            .toList();
      }
    });
  }

  Future<String> _getServiceImageUrl(String serviceId) async {
    QuerySnapshot imageQuery = await FirebaseFirestore.instance
        .collection('Service Images')
        .where('ServiceID', isEqualTo: serviceId)
        .get();

    if (imageQuery.docs.isNotEmpty) {
      return imageQuery.docs.first['URL'];
    } else {
      return 'https://via.placeholder.com/150';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
        title: const Text(
          'Manage Services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _onCategorySelected(null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategoryId == null
                            ? Colors.deepPurple
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          "All",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ..._categories.map((category) {
                    String categoryId = category.id;
                    String name = category['Name'];
                    bool isSelected = _selectedCategoryId == categoryId;

                    return GestureDetector(
                      onTap: () => _onCategorySelected(categoryId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredServices.isEmpty
                ? const Center(child: Text("No services found"))
                : ListView.builder(
                    itemCount: _filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = _filteredServices[index];
                      final serviceId = service.id;

                      return FutureBuilder<String>(
                        future: _getServiceImageUrl(serviceId),
                        builder: (context, imageSnapshot) {
                          if (imageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text("Loading..."),
                            );
                          }

                          String imageUrl = imageSnapshot.data ??
                              'https://via.placeholder.com/150';

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
                  ),
          ),
        ],
      ),
    );
  }
}
