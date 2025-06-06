import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service_detail.dart';

class TrackMyBookingsPage extends StatefulWidget {
  @override
  _TrackMyBookingsPageState createState() => _TrackMyBookingsPageState();
}

class _TrackMyBookingsPageState extends State<TrackMyBookingsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  DateTimeRange? _selectedDateRange;
  String _selectedStatus = "pending";

  final List<String> _statuses = [
    "pending",
    "approved",
    "rejected",
    "canceled"
  ];

  @override
  void initState() {
    super.initState();
    _bookingsFuture = fetchBookings();
  }

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection("Booking")
        .where("userId", isEqualTo: currentUser!.uid)
        .get();

    final bookings = bookingSnapshot.docs;

    final futures = bookings.map((bookingDoc) async {
      final bookingData = bookingDoc.data();
      final bookingId = bookingDoc.id;

      final endTimestamp = bookingData["checkout-date"];
      final endDate = (endTimestamp as Timestamp).toDate();
      final status = bookingData["status"]?.toLowerCase() ?? "pending";

      if (_selectedDateRange != null) {
        if (endDate.isBefore(_selectedDateRange!.start) ||
            endDate.isAfter(_selectedDateRange!.end)) {
          return null;
        }
      }

      final bookServiceSnapshot = await FirebaseFirestore.instance
          .collection("Book-Service")
          .where("BookingID", isEqualTo: bookingId)
          .limit(1)
          .get();

      if (bookServiceSnapshot.docs.isEmpty) return null;

      final serviceId = bookServiceSnapshot.docs.first.get("ServiceID");

      final serviceDoc = await FirebaseFirestore.instance
          .collection("Service")
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) return null;

      final serviceData = serviceDoc.data()!;
      final description = serviceData["Description"] ?? "No Description";
      final price = bookingData["full-price"] ?? 0;
      final type = serviceData["Type"] ?? "Unknown";

      return {
        "bookingId": bookingId,
        "description": description,
        "price": price,
        "type": type,
        "status": status,
      };
    });

    final results = await Future.wait(futures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _bookingsFuture = fetchBookings();
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
      _bookingsFuture = fetchBookings();
    });
  }

  void _onStatusSelected(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
      case "canceled":
        return Colors.red;
      case "pending":
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text("My Bookings"),
        actions: [
          if (_selectedDateRange != null)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearDateRange,
              tooltip: "Clear date filter",
            ),
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: "Filter by date range",
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _statuses.map((status) {
                bool isSelected = _selectedStatus == status;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _onStatusSelected(status);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getStatusColor(status)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return Center(child: Text("No bookings found."));

                final filtered = snapshot.data!
                    .where((booking) => booking["status"] == _selectedStatus)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(child: Text("No ${_selectedStatus} bookings."));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    return ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      title: Text(
                        booking["description"],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                          "Price: \$${booking["price"]} • Type: ${booking["type"]}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetail(
                              bookingId: booking["bookingId"],
                              price: booking["price"],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
