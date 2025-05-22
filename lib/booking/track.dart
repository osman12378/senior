import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senior/profile/profile.dart';
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
    List<Map<String, dynamic>> bookingsList = [];

    final bookingSnapshot = await FirebaseFirestore.instance
        .collection("Booking")
        .where("userId", isEqualTo: currentUser!.uid)
        .get();

    for (var bookingDoc in bookingSnapshot.docs) {
      var bookingData = bookingDoc.data();
      String bookingId = bookingDoc.id;

      Timestamp endTimestamp = bookingData["checkout-date"];
      DateTime endDate = endTimestamp.toDate();
      String status = bookingData["status"]?.toLowerCase() ?? "pending";

      if (_selectedDateRange != null) {
        if (endDate.isBefore(_selectedDateRange!.start) ||
            endDate.isAfter(_selectedDateRange!.end)) {
          continue;
        }
      }

      final bookServiceSnapshot = await FirebaseFirestore.instance
          .collection("Book-Service")
          .where("BookingID", isEqualTo: bookingId)
          .limit(1)
          .get();

      if (bookServiceSnapshot.docs.isEmpty) continue;

      String serviceId = bookServiceSnapshot.docs.first.get("ServiceID");

      final serviceDoc = await FirebaseFirestore.instance
          .collection("Service")
          .doc(serviceId)
          .get();

      if (!serviceDoc.exists) continue;

      var serviceData = serviceDoc.data()!;
      String description = serviceData["Description"] ?? "No Description";
      num price = serviceData["Price"] ?? 0;
      String type = serviceData["Type"] ?? "Unknown";

      bookingsList.add({
        "bookingId": bookingId,
        "description": description,
        "price": price,
        "type": type,
        "status": status,
      });
    }

    return bookingsList;
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
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
                            builder: (_) =>
                                ServiceDetail(bookingId: booking["bookingId"]),
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
