import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'booking_details_page.dart';

class ManageBooking extends StatefulWidget {
  @override
  _ManageBooking createState() => _ManageBooking();
}

class _ManageBooking extends State<ManageBooking> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = fetchRelevantBookings();
  }

  Future<List<Map<String, dynamic>>> fetchRelevantBookings() async {
    final now = Timestamp.now();

    // 1. Get service IDs that belong to current user
    final serviceSnapshot = await FirebaseFirestore.instance
        .collection('Service')
        .where('UserID', isEqualTo: currentUser!.uid)
        .get();
    final serviceIds = serviceSnapshot.docs.map((doc) => doc.id).toSet();

    // 2. Get all book-service relations
    final bookServiceSnapshot =
        await FirebaseFirestore.instance.collection('Book-Service').get();

    // 3. Match booking IDs related to your services
    Set<String> bookingIds = {};
    Map<String, String> bookingToService = {};

    for (var doc in bookServiceSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (serviceIds.contains(data['ServiceID'])) {
        final bookingId = data['BookingID'];
        bookingIds.add(bookingId);
        bookingToService[bookingId] = data['ServiceID'];
      }
    }

    if (bookingIds.isEmpty) return [];

    // 4. Get pending bookings whose ID is in the list
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection('Booking')
        .where(FieldPath.documentId, whereIn: bookingIds.toList())
        .get();

    List<Map<String, dynamic>> bookings = [];

    for (var bookingDoc in bookingSnapshot.docs) {
      final data = bookingDoc.data() as Map<String, dynamic>;
      final checkout = data['checkout-date'] as Timestamp?;
      final status = data['status'];
      final userId = data['userId'];

      if (status == 'pending' &&
          checkout != null &&
          checkout.toDate().isAfter(now.toDate())) {
        // Get renter info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userDoc.data() ?? {};
        final username = userData['username'] ?? 'Unknown';
        final email = userData['email'] ?? 'No email';

        // Get profile picture
        final profilePath = 'profiles/$userId.jpg';
        String profilePicUrl = '';
        try {
          profilePicUrl =
              await FirebaseStorage.instance.ref(profilePath).getDownloadURL();
        } catch (e) {
          profilePicUrl = '';
        }

        bookings.add({
          'bookingId': bookingDoc.id,
          'username': username,
          'email': email,
          'userPic': profilePicUrl,
          'userId': userId,
          'serviceId': bookingToService[bookingDoc.id],
        });
      }
    }

    return bookings;
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _bookingsFuture = fetchRelevantBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text("Pending Bookings")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text("No active pending bookings."));

          final bookings = snapshot.data!;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return ListTile(
                leading: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: booking['userPic'],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.person, size: 40),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(booking['username']),
                subtitle: Text(booking['email']),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailsPage(
                        bookingId: booking['bookingId'],
                      ),
                    ),
                  );
                  // Refresh when returning from details page
                  _refreshBookings();
                },
              );
            },
          );
        },
      ),
    );
  }
}
