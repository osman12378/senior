import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senior/after_login/wishlist.dart';
import 'package:senior/chat/messages.dart';
import 'package:senior/profile/profile.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  List<Map<String, dynamic>> _services = [];
  
  // To track the heart state for each service
  Map<String, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final snapshot = await _firestore.collection('Category').get();

      final categories = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['Name'],
          'type': doc['Type'],
        };
      }).toList();

      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first['name'];
          loadServicesByCategory(_selectedCategory!);
        }
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> loadServicesByCategory(String categoryName) async {
    try {
      // Get CategoryID
      final categorySnapshot = await _firestore
          .collection('Category')
          .where('Name', isEqualTo: categoryName)
          .limit(1)
          .get();
      if (categorySnapshot.docs.isEmpty) return;

      final categoryId = categorySnapshot.docs.first.id;

      // Get Services by CategoryID
      final serviceSnapshot = await _firestore
          .collection('Service')
          .where('CategoryID', isEqualTo: categoryId)
          .get();

      List<Map<String, dynamic>> loadedServices = [];

      for (var doc in serviceSnapshot.docs) {
        final data = doc.data();
        final serviceId = doc.id;

        // Get address
        String? street;
        if (data['AddressID'] != null) {
          final addressDoc = await _firestore
              .collection('Address')
              .doc(data['AddressID'])
              .get();
          street = addressDoc.data()?['Street'] ?? 'Unknown Street';
        }

        // Get image
        String? imageUrl;
        final imageSnapshot = await _firestore
            .collection('Service Images')
            .where('ServiceID', isEqualTo: serviceId)
            .limit(1)
            .get();
        if (imageSnapshot.docs.isNotEmpty) {
          imageUrl = imageSnapshot.docs.first.data()['URL'];
        }

        loadedServices.add({
          'id': serviceId,
          'description': data['Description'],
          'price': data['Price'],
          'type': data['Type'],
          'availability': data['Availability'],
          'street': street,
          'imageUrl': imageUrl,
        });
      }

      setState(() {
        _services = loadedServices;
      });
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  Future<void> toggleFavorite(String serviceId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final wishlistSnapshot = await _firestore
        .collection('wishlists')
        .where('serviceId', isEqualTo: serviceId)
        .where('userId', isEqualTo: userId)
        .get();

    if (wishlistSnapshot.docs.isEmpty) {
      // Add to wishlist
      await _firestore.collection('wishlists').add({
        'serviceId': serviceId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update heart color to red
      setState(() {
        _favoriteStatus[serviceId] = true;
      });
    } else {
      // Remove from wishlist
      await wishlistSnapshot.docs.first.reference.delete();

      // Update heart color back to default
      setState(() {
        _favoriteStatus[serviceId] = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WishlistPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MessagesPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search for services...",
            suffixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _selectedCategory == category['name']
                              ? Colors.indigo
                              : Colors.grey[200],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category['name'];
                              });
                              loadServicesByCategory(category['name']);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Center(
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    color: _selectedCategory == category['name']
                                        ? Colors.white
                                        : Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.grey[300]),
              ],
            ),
          Expanded(
            child: _services.isEmpty
                ? const Center(child: Text("No services available."))
                : ListView.builder(
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final serviceId = service['id'];

                      // Check if the service is already in the wishlist
                      bool isFavorite = _favoriteStatus[serviceId] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                if (service['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: Image.network(
                                      service['imageUrl'],
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () => toggleFavorite(serviceId),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedCategory ?? "Home"} in ${service['street'] ?? "Unknown"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service['description'] ?? 'No description',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${service['price']}\$ per night',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
}
