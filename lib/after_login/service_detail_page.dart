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

      setState(() {
        serviceData = data;
        imageUrls = urls;
        extraData = combinedExtra;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading service: $e');
    }
  }

  Future<void> selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
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
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select both start and end dates"),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("End date must be after start date"),
            backgroundColor: Colors.red),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User not logged in"), backgroundColor: Colors.red),
      );
      return;
    }

    final days = endDate!.difference(startDate!).inDays;
    final double pricePerDay = (serviceData!['Price'] as num).toDouble();
    final double fullPrice = days * pricePerDay;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPaymentPage(
          userId: user.uid,
          serviceId: widget.serviceId,
          startDate: startDate!,
          endDate: endDate!,
          pricePerDay: pricePerDay,
          fullPrice: fullPrice,
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
                      fontSize: 17, fontWeight: FontWeight.bold))),
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
