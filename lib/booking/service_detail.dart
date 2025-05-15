import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ServiceDetail extends StatefulWidget {
  final String bookingId;

  const ServiceDetail({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<ServiceDetail> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends State<ServiceDetail> {
  Map<String, dynamic>? serviceData;
  String? bookingStatus;
  String? serviceImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookingDetails();
  }

  Future<void> fetchBookingDetails() async {
    try {
      final bookServiceSnapshot = await FirebaseFirestore.instance
          .collection("Book-Service")
          .where("BookingID", isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (bookServiceSnapshot.docs.isEmpty) return;

      String serviceId = bookServiceSnapshot.docs.first.get("ServiceID");

      final serviceDoc = await FirebaseFirestore.instance
          .collection("Service")
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) return;

      final bookingDoc = await FirebaseFirestore.instance
          .collection("Booking")
          .doc(widget.bookingId)
          .get();

      final imageSnapshot = await FirebaseFirestore.instance
          .collection("Service Images")
          .where("ServiceID", isEqualTo: serviceId)
          .limit(1)
          .get();

      setState(() {
        serviceData = serviceDoc.data();
        bookingStatus = bookingDoc.get("status");
        serviceImageUrl = imageSnapshot.docs.isNotEmpty
            ? imageSnapshot.docs.first.get("URL")
            : null;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching details: $e");
    }
  }

  Future<void> confirmCancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Cancellation"),
        content: Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cancelBooking();
    }
  }

  Future<void> cancelBooking() async {
    await FirebaseFirestore.instance
        .collection("Booking")
        .doc(widget.bookingId)
        .update({"status": "Canceled"});

    setState(() {
      bookingStatus = "Canceled";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking canceled")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Service Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : serviceData == null
              ? Center(child: Text("Service not found."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        serviceImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: serviceImageUrl!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              )
                            : Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                ),
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 100,
                                  color: Colors.grey[600],
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceData!["Description"] ??
                                    "No description available.",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text("Price: \$${serviceData!["Price"] ?? 0}"),
                              Text(
                                  "Type: ${serviceData!["Type"] ?? "Unknown"}"),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Status: $bookingStatus",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: bookingStatus == "Canceled"
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: bookingStatus == "Canceled"
                                        ? null
                                        : confirmCancelBooking,
                                    icon: Icon(Icons.cancel, color: Colors.red),
                                    tooltip: "Cancel Booking",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
