import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senior/after_login/wishlist.dart';
import 'package:senior/after_login/Explore.dart';
import 'package:senior/chat/messages.dart';
import 'package:senior/profile/manage_offers.dart';
import 'package:senior/profile/manage_services.dart';
import 'package:senior/screens/login.dart';
import 'package:senior/profile/change_password.dart';
import 'package:senior/profile/edit_profile.dart';
import 'package:senior/subscription/subscription.dart';
import 'package:senior/services/offer.dart';
import 'package:senior/services/select.dart';
import 'package:senior/booking/manage.dart';
import 'package:senior/booking/track.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<Map<String, dynamic>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = getUserData();
    checkAndUpdateSubscription();
  }

  Future<void> checkAndUpdateSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = Timestamp.now();

    final payQuery = await FirebaseFirestore.instance
        .collection('Pay')
        .where('UserID', isEqualTo: user.uid)
        .where('Status', isEqualTo: 'approved')
        .get();

    bool hasActiveSubscription = false;

    for (var doc in payQuery.docs) {
      final endDate = doc['EndDate'] as Timestamp;

      if (now.compareTo(endDate) <= 0) {
        hasActiveSubscription = true;
        break;
      }
    }

    if (!hasActiveSubscription) {
      // No valid subscription — downgrade user and mark services as deleted
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'role': 'renter'});

      final serviceQuery = await FirebaseFirestore.instance
          .collection('Service')
          .where('UserID', isEqualTo: user.uid)
          .get();

      for (var serviceDoc in serviceQuery.docs) {
        await serviceDoc.reference.update({'Deleted': true});
      }
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String username = userDoc["username"] ?? "User Name";
      String role = userDoc["role"] ?? "renter";
      String storagePath = "profiles/${user.uid}.jpg";
      String imageUrl = "";

      try {
        imageUrl =
            await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
      } catch (e) {
        imageUrl = "https://via.placeholder.com/150";
      }

      return {"name": username, "image": imageUrl, "role": role};
    }
    return {
      "name": "Guest",
      "image": "https://via.placeholder.com/150",
      "role": "renter"
    };
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ExplorePage()));
    } else if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => WishlistPage()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => MessagesPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }
          final userData = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              CachedNetworkImageProvider(userData["image"]),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userData["name"],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                      
                      ],
                    ),
                  ),
              
                  const SizedBox(height: 5),
                    ListTile(
                    title: const Text("Edit profile"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfile()),
                      );
                    },
                  ),
                                const Divider(indent: 15, endIndent: 15, color: Colors.black),
              
                
                  ListTile(
                    title: const Text("Track bookings"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrackMyBookingsPage()),
                      );
                    },
                  ),
                  const Divider(indent: 15, endIndent: 15, color: Colors.black),
              
                  // Role-based UI section
                  // Role-based UI section
                  if (userData["role"] == "renter") ...[
                    ListTile(
                      title: const Text("Become a host"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubscriptionPage()),
                        );
                      },
                    ),
                    const Divider(indent: 15, endIndent: 15, color: Colors.black),
                  ] else if (userData["role"] == "Host" ||
                      userData["role"] == "Premium Host") ...[
                    ListTile(
                      title: const Text("Manage bookings"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ManageBooking()),
                        ).then((_) {
                          // This runs when you come back from ServicePage
                          setState(() {
                            _userData = getUserData(); // refresh user data
                          });
                        });
                      },
                    ),
                    const Divider(indent: 15, endIndent: 15, color: Colors.black),
                    ListTile(
                      title: const Text("RentX a service"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => Select()),
                        ).then((_) {
                          // This runs when you come back from ServicePage
                          setState(() {
                            _userData = getUserData(); // refresh user data
                          });
                        });
                      },
                    ),
                    const Divider(indent: 15, endIndent: 15, color: Colors.black),
                    ListTile(
                      title: const Text("Manage Service"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ManageServicesPage()),
                        ).then((_) {
                          // This runs when you come back from ServicePage
                          setState(() {
                            _userData = getUserData(); // refresh user data
                          });
                        });
                      },
                    ),
                    const Divider(indent: 15, endIndent: 15, color: Colors.black),
                    if (userData["role"] == "Premium Host") ...[
                      ListTile(
                        title: const Text("RentX an offer"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OfferPage()),
                          ).then((_) {
                            // This runs when you come back from ServicePage
                            setState(() {
                              _userData = getUserData(); // refresh user data
                            });
                          });
                        },
                      ),
                      const Divider(indent: 15, endIndent: 15, color: Colors.black),
                      ListTile(
                        title: const Text("Manage Offer"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ManageOffers()),
                          ).then((_) {
                            // This runs when you come back from ServicePage
                            setState(() {
                              _userData = getUserData(); // refresh user data
                            });
                          });
                        },
                      ),
                      const Divider(indent: 15, endIndent: 15, color: Colors.black),
                    ],
                  ],
              
                  ListTile(
                    title: const Text("Login & security"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                      ).then((_) {
                        // This runs when you come back from ServicePage
                        setState(() {
                          _userData = getUserData(); // refresh user data
                        });
                      });
                    },
                  ),
                  const Divider(indent: 15, endIndent: 15, color: Colors.black),
                  const SizedBox(height: 40),
                  Center(
                    child: const Text(
                      "from",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Center(
                    child: const Text(
                      "LIU Students",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () async {
                      await _auth.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Log out",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 3,
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
