import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senior/after_login/wishlist.dart';
import 'package:senior/chat/messages.dart';
import 'package:senior/profile/profile.dart';
import 'package:senior/after_login/service_detail_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchText = '';
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  List<Map<String, dynamic>> _services = [];
  Map<String, bool> _favoriteStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore.collection('Category').get();
      final categories = snapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['Name'], 'type': doc['Type']};
      }).toList();
      // Add 'Offers' category at the beginning
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadServicesByCategory(String categoryName) async {
    setState(() {
      _services = [];
      _isLoading = true;
    });

    if (categoryName == 'Offers') {
      await loadOffers();
    } else {
      await loadRegularServices(categoryName);
    }
  }

  Future<void> loadOffers() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final offerSnapshot = await _firestore
          .collection('Offer')
          .where('endTime', isGreaterThan: now)
          .where('Availibility', isEqualTo: true)
          .orderBy('endTime', descending: true)
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

        // Check if the service is not deleted (deleted == false)
        if (serviceData['Deleted'] == true) {
          continue; // Skip the service if it is deleted
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
          'price': offerData['price'],
          'type': serviceData['Type'],
          'deleted': serviceData['Deleted'],
          'street': street,
          'imageUrl': imageUrl,
        });
      }

      setState(() => _services = loadedServices);
    } catch (e) {
      debugPrint('Error loading offers: $e');
    } finally {
      setState(() => _isLoading = false);
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

      List<Future<Map<String, dynamic>?>> serviceFutures =
          serviceSnapshot.docs.map((doc) async {
        final data = doc.data();
        final serviceId = doc.id;

        final addressFuture = data['AddressID'] != null
            ? _firestore.collection('Address').doc(data['AddressID']).get()
            : Future.value(null);

        final imageFuture = _firestore
            .collection('Service Images')
            .where('ServiceID', isEqualTo: serviceId)
            .limit(1)
            .get();

        final results = await Future.wait([addressFuture, imageFuture]);

        final addressDoc = results[0] as DocumentSnapshot?;
        final imageSnapshot = results[1] as QuerySnapshot;

        String? street = addressDoc?.data() != null
            ? (addressDoc!.data() as Map<String, dynamic>)['Street']
            : 'Unknown Street';

        String? imageUrl = imageSnapshot.docs.isNotEmpty
            ? (imageSnapshot.docs.first.data() as Map<String, dynamic>)['URL']
            : null;

        // Check if the service is not deleted (deleted == false)
        if (data['Deleted'] == true) {
          return null; // Skip services that are deleted
        }

        return {
          'id': serviceId,
          'description': data['Description'],
          'price': data['Price'],
          'type': data['Type'],
          'deleted': data['Deleted'],
          'street': street,
          'imageUrl': imageUrl,
        };
      }).toList();

      // Filter out null results (deleted services)
      final loadedServices = (await Future.wait(serviceFutures))
          .where((service) => service != null)
          .map((service) => service as Map<String, dynamic>)
          .toList(); // Cast the result to List<Map<String, dynamic>>

      setState(() => _services = loadedServices);
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      setState(() => _isLoading = false);
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
      // No existing entry, create a new one
      await _firestore.collection('wishlists').add({
        'serviceId': serviceId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      setState(() => _favoriteStatus[serviceId] = true);
    } else {
      final doc = wishlistSnapshot.docs.first;
      final currentStatus = doc['status'];

      if (currentStatus == 'active') {
        // Deactivate if currently active
        await doc.reference.update({
          'status': 'deactivated',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() => _favoriteStatus[serviceId] = false);
      } else {
        // Reactivate if currently deactivated
        await doc.reference.update({
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() => _favoriteStatus[serviceId] = true);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WishlistPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MessagesPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ProfilePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Rent',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 35,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              TextSpan(
                text: 'X',
                style: TextStyle(
                  color: Colors.orange, // Set the color for 'X' to orange
                  fontSize: 35,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_categories.isNotEmpty)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _selectedCategory == category['name']
                          ? Colors.indigo
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
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
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Please wait a moment..."),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            fillColor: Colors.grey[100],
                            hintText: "Start your search",
                            suffixIcon:
                                const Icon(Icons.search, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchText = value.trim();
                            });
                          },
                        ),
                      ),
                      if (_services.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _selectedCategory == 'Offers'
                                  ? "No offers available."
                                  : "No services available.",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ..._services
                          .where((service) => service['description']
                              .toLowerCase()
                              .contains(searchText.toLowerCase()))
                          .map((service) {
                        final serviceId = service['id'];
                        final isFavorite = _favoriteStatus[serviceId] ?? false;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServiceDetailPage(serviceId: service['id']),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
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
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                        child: CachedNetworkImage(
                                          imageUrl: service['imageUrl'],
                                          height: 200,
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
                                          onTap: () =>
                                              toggleFavorite(serviceId),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_selectedCategory ?? "Home"} in ${service['street'] ?? "Unknown"}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        service['description'] ??
                                            'No description',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${service['price']}\$ per day',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
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
