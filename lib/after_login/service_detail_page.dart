import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final serviceDoc = await _firestore.collection('Service').doc(widget.serviceId).get();
      if (!serviceDoc.exists) return;

      final data = serviceDoc.data()!;

      final imagesSnapshot = await _firestore
          .collection('Service Images')
          .where('ServiceID', isEqualTo: widget.serviceId)
          .get();

      List<String> urls = imagesSnapshot.docs.map((doc) => doc['URL'] as String).toList();

      // Fetch category type from Category table
      final categoryDoc = await _firestore.collection('Category').doc(data['CategoryID']).get();
      final categoryType = categoryDoc.exists ? categoryDoc['Type'].toString().toLowerCase() : '';

      Map<String, dynamic>? extra;
      if (categoryType == 'cars') {
        final carDoc = await _firestore.collection('carDescription').doc(widget.serviceId).get();
        if (carDoc.exists) extra = carDoc.data();
      } else if (categoryType == 'properties') {
        final addressDoc = await _firestore.collection('Address').doc(data['AddressID']).get();
        if (addressDoc.exists) extra = addressDoc.data();
      }

      setState(() {
        serviceData = data;
        imageUrls = urls;
        extraData = extra;
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
    if (startDate != null && endDate != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Placeholder()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both start and end dates")),
      );
    }
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
      appBar: AppBar(title: const Text("Service Details", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.indigo))),
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
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text(serviceData!['Description'] ?? 'No description provided', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text("Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text("Type: ${serviceData!['Type']}", style: const TextStyle(fontSize: 16)),
            Text("Price: ${serviceData!['Price']}\$ per night", style: const TextStyle(fontSize: 16)),
            Text("Availability: ${serviceData!['Availability'] ? 'Available' : 'Unavailable'}", style: const TextStyle(fontSize: 16)),
            if (extraData != null) ...[
              
              ...extraData!.entries.map((entry) => Text("${entry.key}: ${entry.value}", style: const TextStyle(fontSize: 16))),
            ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Proceed to Payment", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
