import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'Booking_payment.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> imageUrls = [];
  Map<String, dynamic>? serviceData;
  Map<String, dynamic>? extraData;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;

  int selectedRating = 0;
  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    loadServiceDetails();
  }

  Future<void> loadServiceDetails() async {
    try {
      final serviceDoc =
          await _firestore.collection('Service').doc(widget.serviceId).get();
      if (!serviceDoc.exists) return;

      final data = serviceDoc.data()!;

      final imagesSnapshot = await _firestore
          .collection('Service Images')
          .where('ServiceID', isEqualTo: widget.serviceId)
          .get();

      List<String> urls =
          imagesSnapshot.docs.map((doc) => doc['URL'] as String).toList();

      final categoryDoc =
          await _firestore.collection('Category').doc(data['CategoryID']).get();
      final categoryType = categoryDoc.exists
          ? categoryDoc['Type'].toString().toLowerCase()
          : '';

      Map<String, dynamic> combinedExtra = {};

      if (categoryType == 'cars') {
        final carSnapshot = await _firestore
            .collection('CarDescription')
            .where('ServiceID', isEqualTo: widget.serviceId)
            .limit(1)
            .get();

        final addressDoc =
            await _firestore.collection('Address').doc(data['AddressID']).get();

        if (carSnapshot.docs.isNotEmpty) {
          final carData =
              Map<String, dynamic>.from(carSnapshot.docs.first.data());
          carData.remove('ServiceID');
          combinedExtra.addAll(carData);
        }
        if (addressDoc.exists) {
          combinedExtra.addAll(addressDoc.data()!);
        }
      } else if (categoryType == 'properties') {
        final addressDoc =
            await _firestore.collection('Address').doc(data['AddressID']).get();
        if (addressDoc.exists) combinedExtra.addAll(addressDoc.data()!);
      }

      final ratingsSnapshot = await _firestore
          .collection('Review')
          .where('ServiceID', isEqualTo: widget.serviceId)
          .get();

      double avgRating = 0.0;
      int userRating = 0;

      if (ratingsSnapshot.docs.isNotEmpty) {
        final ratings = ratingsSnapshot.docs
            .map((doc) => (doc['Rating'] as num).toDouble())
            .toList();
        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

        // Check if user has rated
        final user = _auth.currentUser;
        if (user != null) {
          try {
            final userRatingDoc = ratingsSnapshot.docs.firstWhere(
              (doc) => doc['UserID'] == user.uid,
            );
            userRating = (userRatingDoc['Rating'] as num).toInt();
          } catch (e) {
            // No rating found for this user, so leave userRating as 0 or default
          }
        }
      }

      setState(() {
        serviceData = data;
        imageUrls = urls;
        extraData = combinedExtra;
        averageRating = avgRating;
        selectedRating = userRating;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading service: $e');
    }
  }

  Future<void> submitRating(int rating) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to submit rating"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final ratingsQuery = await _firestore
          .collection('Review')
          .where('ServiceID', isEqualTo: widget.serviceId)
          .where('UserID', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (ratingsQuery.docs.isNotEmpty) {
        // Update existing rating
        await _firestore
            .collection('Review')
            .doc(ratingsQuery.docs.first.id)
            .update({'Rating': rating, 'Timestamp': DateTime.now()});
      } else {
        // Add new rating
        await _firestore.collection('Review').add({
          'ServiceID': widget.serviceId,
          'UserID': user.uid,
          'Rating': rating,
          'Timestamp': DateTime.now(),
        });
      }

      setState(() {
        selectedRating = rating;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rating submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the average rating
      loadServiceDetails();
    } catch (e) {
      debugPrint("Error submitting rating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit rating"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildRatingStars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            int starNumber = index + 1;
            return IconButton(
              icon: Icon(
                selectedRating >= starNumber ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () async {
                setState(() {
                  selectedRating = starNumber;
                });
                await submitRating(starNumber);
              },
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              "Average: ${averageRating.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> selectDate({required bool isStart}) async {
    DateTime initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void goToPaymentPage() {
    final user = _auth.currentUser;
    if (user == null) return;

    final pricePerDay = (serviceData!['Price'] as num).toDouble();
    if (startDate == null || endDate == null) return;

    final totalDays = endDate!.difference(startDate!).inDays + 1;
    final fullPrice = totalDays * pricePerDay;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPaymentPage(
          serviceId: widget.serviceId,
          userId: user.uid,
          pricePerDay: pricePerDay,
          fullPrice: fullPrice,
          startDate: startDate!,
          endDate: endDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (serviceData == null) {
      return const Scaffold(body: Center(child: Text("Service not found")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Details",
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.indigo)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (imageUrls.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // ⭐ Rating
            const Text("Rate this Service",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 8),
            buildRatingStars(),
            const Divider(),

            // 📝 Description
            const SizedBox(height: 16),
            const Text("Description",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 8),
            Text(serviceData!['Description'] ?? 'No description provided',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 📄 Details
            const Text("Details",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 8),
            Text("Type: ${serviceData!['Type']}",
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text("Price: ${serviceData!['Price']}\$ per day",
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

            if (extraData != null)
              ...extraData!.entries.map((entry) => Text(
                    "${entry.key}: ${entry.value}",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  )),

            // 📅 Date Pickers
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => selectDate(isStart: true),
                    child: Text(startDate == null
                        ? "Start Date"
                        : "Start: ${startDate!.toLocal().toString().split(' ')[0]}"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => selectDate(isStart: false),
                    child: Text(endDate == null
                        ? "End Date"
                        : "End: ${endDate!.toLocal().toString().split(' ')[0]}"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: goToPaymentPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Proceed to Payment",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
