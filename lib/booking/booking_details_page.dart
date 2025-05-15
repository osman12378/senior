import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  String? paymentImageUrl;
  String? paymentMethod;
  String? serviceDescription;
  String? serviceImageUrl;
  DateTime? checkinDate;
  DateTime? checkoutDate;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPaymentDetails();
  }

  Future<void> fetchPaymentDetails() async {
    final bookingDoc = await FirebaseFirestore.instance
        .collection('Booking')
        .doc(widget.bookingId)
        .get();

    if (!bookingDoc.exists) {
      setState(() => loading = false);
      return;
    }

    final bookingData = bookingDoc.data()!;
    checkinDate = (bookingData['checkin-date'] as Timestamp).toDate();
    checkoutDate = (bookingData['checkout-date'] as Timestamp).toDate();

    // Fetch Book-Service to get ServiceID
    final bookServiceSnapshot = await FirebaseFirestore.instance
        .collection('Book-Service')
        .where('BookingID', isEqualTo: widget.bookingId)
        .limit(1)
        .get();

    String? serviceId;

    if (bookServiceSnapshot.docs.isNotEmpty) {
      serviceId = bookServiceSnapshot.docs.first['ServiceID'];

      // Fetch Service
      final serviceDoc = await FirebaseFirestore.instance
          .collection('Service')
          .doc(serviceId)
          .get();

      if (serviceDoc.exists) {
        serviceDescription = serviceDoc['Description'];
      }

      // Fetch Service Image
      final serviceImageSnapshot = await FirebaseFirestore.instance
          .collection('Service Images')
          .where('ServiceID', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (serviceImageSnapshot.docs.isNotEmpty) {
        serviceImageUrl = serviceImageSnapshot.docs.first['URL'];
      }
    }

    // Fetch Booking_Payment
    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('Booking_Payment')
        .where('BookingID', isEqualTo: widget.bookingId)
        .limit(1)
        .get();

    if (paymentSnapshot.docs.isNotEmpty) {
      final data = paymentSnapshot.docs.first.data();
      paymentImageUrl = data['Payment_image'];
      paymentMethod = data['PaymentMethod'];
    }

    setState(() => loading = false);
  }

  Future<void> updateBookingStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('Booking')
        .doc(widget.bookingId)
        .update({'status': status});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Booking $status.'),
      backgroundColor: status == 'approved' ? Colors.green : Colors.red,
    ));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Booking Payment")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : paymentImageUrl == null
              ? Center(child: Text("No payment submitted."))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /// --- Service Info Card ---
                        if (serviceDescription != null &&
                            checkinDate != null &&
                            checkoutDate != null)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (serviceImageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: serviceImageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    ),
                                  SizedBox(height: 16),
                                  Text("Service Details",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 10),
                                  Text("Description: $serviceDescription"),
                                  SizedBox(height: 5),
                                  Text(
                                    "Check-in: ${checkinDate!.toLocal().toString().split(' ')[0]}",
                                  ),
                                  Text(
                                    "Check-out: ${checkoutDate!.toLocal().toString().split(' ')[0]}",
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: 10),

                        /// --- Payment Info Card ---
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Payment Method: $paymentMethod",
                                  style: TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenImagePage(
                                          imageUrl: paymentImageUrl!,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: paymentImageUrl!,
                                      height: 250,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 30),

                        /// --- Action Buttons ---
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    updateBookingStatus('approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Approve"),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    updateBookingStatus('rejected'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text("Reject"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({Key? key, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) =>
                CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) =>
                Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
