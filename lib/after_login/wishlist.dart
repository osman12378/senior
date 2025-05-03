import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:senior/chat/messages.dart';
import 'package:senior/after_login/Explore.dart';
import 'package:senior/profile/profile.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<WishlistPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _wishlist = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  // Load the wishlist for the current user
  Future<void> _loadWishlist() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> wishlistItems = [];
      for (var doc in snapshot.docs) {
        final serviceId = doc['serviceId'];

        // Fetch the service details based on the serviceId
        final serviceSnapshot =
            await _firestore.collection('Service').doc(serviceId).get();

        if (serviceSnapshot.exists) {
          final serviceData = serviceSnapshot.data()!;

          // Fetch service images
          String? imageUrl;
          final imageSnapshot = await _firestore
              .collection('Service Images')
              .where('ServiceID', isEqualTo: serviceId)
              .limit(1)
              .get();
          if (imageSnapshot.docs.isNotEmpty) {
            imageUrl = imageSnapshot.docs.first['URL'];
          }

          wishlistItems.add({
            'id': serviceId,
            'description': serviceData['Description'],
            'price': serviceData['Price'],
            'availability': serviceData['Availability'],
            'imageUrl': imageUrl, // Fetch image URL from Service Images
          });
        }
      }

      setState(() {
        _wishlist = wishlistItems;
      });
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  // Remove service from wishlist
  Future<void> _removeFromWishlist(String serviceId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .where('serviceId', isEqualTo: serviceId)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
        _loadWishlist(); // Reload wishlist after removing
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  // Navigate between tabs
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ExplorePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MessagesPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Wishlist',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _wishlist.isEmpty
          ? const Center(child: Text('No items in your wishlist.'))
          : ListView.builder(
              itemCount: _wishlist.length,
              itemBuilder: (context, index) {
                final service = _wishlist[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            service['imageUrl']!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['description'] ?? 'No description',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${service['price']} USD',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Availability: ${service['availability']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _removeFromWishlist(service['id']),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Wishlist tab selected
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
