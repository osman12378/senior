import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  Map<String, bool> _favoriteStatus = {};
  bool _isLoading = false; // Added flag for loading state

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() {
      _isLoading = true; // Start loading when categories are being fetched
    });

    try {
      // Get the current user
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Fetch the user's role from the 'Users' collection
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final role =
          userData?['role']; // Assuming 'role' field is in the user's document

      // Load categories from Firestore
      final snapshot = await _firestore.collection('Category').get();
      final categories = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['Name'],
          'type': doc['Type'],
        };
      }).toList();

      categories
          .insert(0, {'id': 'offers', 'name': 'Offers', 'type': 'special'});

      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first['name'];
          loadServicesByCategory(_selectedCategory!);
        }
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() {
        _isLoading = false; // End loading once the data is fetched
      });
    }
  }

  Future<void> loadServicesByCategory(String categoryName) async {
    setState(() {
      _services = [];
      _isLoading =
          true; // Set loading state true when services are being fetched
    });

    if (categoryName == 'Offers') {
      await loadOffers();
    } else {
      await loadRegularServices(categoryName);
    }
  }

  Future<void> loadOffers() async {
    try {
      final now = Timestamp.now();

      final offerSnapshot = await _firestore
          .collection('Offer')
          .where('endTime', isGreaterThan: now)
          .get();

      List<Map<String, dynamic>> loadedServices = [];

      for (var offerDoc in offerSnapshot.docs) {
        final offerData = offerDoc.data();
        final serviceId = offerData['serviceID'];

        final serviceDoc =
            await _firestore.collection('Service').doc(serviceId).get();
        if (!serviceDoc.exists) continue;

        final serviceData = serviceDoc.data()!;
        String? street;
        if (serviceData['AddressID'] != null) {
          final addressDoc = await _firestore
              .collection('Address')
              .doc(serviceData['AddressID'])
              .get();
          street = addressDoc.data()?['Street'] ?? 'Unknown Street';
        }

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
          'description': serviceData['Description'],
          'price': offerData['price'], // use price from Offer
          'type': serviceData['Type'],
          'availability': serviceData['Availability'],
          'street': street,
          'imageUrl': imageUrl,
        });
      }

      setState(() {
        _services = loadedServices;
      });
    } catch (e) {
      debugPrint('Error loading offers: $e');
    } finally {
      setState(() {
        _isLoading = false; // End loading after offers are fetched
      });
    }
  }

  Future<void> loadRegularServices(String categoryName) async {
    try {
      final categorySnapshot = await _firestore
          .collection('Category')
          .where('Name', isEqualTo: categoryName)
          .limit(1)
          .get();
      if (categorySnapshot.docs.isEmpty) return;

      final categoryId = categorySnapshot.docs.first.id;
      final serviceSnapshot = await _firestore
          .collection('Service')
          .where('CategoryID', isEqualTo: categoryId)
          .get();

      List<Map<String, dynamic>> loadedServices = [];

      for (var doc in serviceSnapshot.docs) {
        final data = doc.data();
        final serviceId = doc.id;

        String? street;
        if (data['AddressID'] != null) {
          final addressDoc = await _firestore
              .collection('Address')
              .doc(data['AddressID'])
              .get();
          street = addressDoc.data()?['Street'] ?? 'Unknown Street';
        }

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
    } finally {
      setState(() {
        _isLoading = false; // End loading after regular services are fetched
      });
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
      await _firestore.collection('wishlists').add({
        'serviceId': serviceId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _favoriteStatus[serviceId] = true;
      });
    } else {
      await wishlistSnapshot.docs.first.reference.delete();
      setState(() {
        _favoriteStatus[serviceId] = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WishlistPage()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MessagesPage()));
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                          color: Colors.transparent,
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
          if (_isLoading) // Display loading indicator when fetching data
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Please wait a moment..."),
                ],
              ),
            ),
          if (!_isLoading && _services.isEmpty)
            Center(
              child: Text(
                _selectedCategory == 'Offers'
                    ? "No offers available."
                    : "No services available.",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          Expanded(
            child: !_isLoading && _services.isNotEmpty
                ? ListView.builder(
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final serviceId = service['id'];
                      final isFavorite = _favoriteStatus[serviceId] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                if (service['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: CachedNetworkImage(
                                      imageUrl: service['imageUrl'],
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                if (_selectedCategory != 'Offers')
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
                                          color: isFavorite
                                              ? Colors.red
                                              : Colors.black,
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
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service['description'] ?? 'No description',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${service['price']}\$ per night',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Container(),
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
