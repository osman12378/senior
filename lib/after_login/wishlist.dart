import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senior/chat/messages.dart';
import 'package:senior/after_login/Explore.dart';
import 'package:senior/profile/profile.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _wishlist = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

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
        final serviceSnapshot =
            await _firestore.collection('Service').doc(serviceId).get();

        if (serviceSnapshot.exists) {
          final serviceData = serviceSnapshot.data()!;
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
            'imageUrl': imageUrl,
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
        _loadWishlist();
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => ExplorePage()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => MessagesPage()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: _wishlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.heart_broken_rounded, size: 80, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Your wishlist is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlist.length,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemBuilder: (context, index) {
                final service = _wishlist[index];
                return Card(
                  color: Colors.white,
                  shadowColor: Colors.indigo.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: service['imageUrl'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: Colors.white,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.error)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () =>
                                    _removeFromWishlist(service['id']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['description'] ?? 'No description',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${service['price']} per day',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 1,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        iconSize: 28,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
