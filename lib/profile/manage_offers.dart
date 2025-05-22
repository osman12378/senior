import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditOfferPAge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageOffers extends StatefulWidget {
  const ManageOffers({super.key});

  @override
  State<ManageOffers> createState() => _ManageOffersState();
}

class _ManageOffersState extends State<ManageOffers> {
  List<Map<String, dynamic>> offers = [];
  bool isLoading = true;
  String selectedFilter = 'Active'; // Active, Expired, Deleted

  @override
  void initState() {
    super.initState();
    fetchUserOffers();
  }

  Future<void> fetchUserOffers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('Service')
          .where('UserID', isEqualTo: userId)
          .get();

      List<String> serviceIds =
          serviceSnapshot.docs.map((doc) => doc.id).toList();

      print("Fetched services: ${serviceSnapshot.docs.length}");
      print("Service IDs: $serviceIds");

      if (serviceIds.isEmpty) {
        print('No services found for user: $userId');
        setState(() {
          offers = [];
          isLoading = false;
        });
        return;
      }

      QuerySnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('Offer')
          .where('serviceID', whereIn: serviceIds)
          .get();

      print("Fetched offers: ${offerSnapshot.docs.length}");

      List<Map<String, dynamic>> fetchedOffers = [];

      for (var offerDoc in offerSnapshot.docs) {
        final serviceId = offerDoc['serviceID'];

        QuerySnapshot serviceImagesSnapshot = await FirebaseFirestore.instance
            .collection('Service Images')
            .where('ServiceID', isEqualTo: serviceId)
            .limit(1)
            .get();

        String imageUrl = serviceImagesSnapshot.docs.isNotEmpty
            ? serviceImagesSnapshot.docs.first['URL']
            : 'assets/default_avatar.jpg';

        final serviceDoc =
            serviceSnapshot.docs.firstWhere((s) => s.id == serviceId);

        fetchedOffers.add({
          'offerId': offerDoc.id,
          'serviceDescription': serviceDoc['Description'],
          'price': offerDoc['price'],
          'endTime': (offerDoc['endTime'] as Timestamp).toDate(),
          'imageUrl': imageUrl,
          'serviceId': serviceId,
          'Availibility': offerDoc['Availibility'],
        });
      }

      setState(() {
        offers = fetchedOffers;
      });
    } catch (e) {
      print('Error fetching offers: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      await FirebaseFirestore.instance.collection('Offer').doc(offerId).update({
        'Availibility': false,
      });
      fetchUserOffers(); // Refresh list after deletion
    } catch (e) {
      print('Error deleting offer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredOffers = offers.where((offer) {
      final isExpired = offer['endTime'].isBefore(DateTime.now());
      final isAvailable = offer['Availibility'] == true;

      if (selectedFilter == 'Active') {
        return isAvailable && !isExpired;
      } else if (selectedFilter == 'Expired') {
        return isAvailable && isExpired;
      } else if (selectedFilter == 'Deleted') {
        return !isAvailable;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Manage Offers')),
      body: Column(
        children: [
          SizedBox(height: 8),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Active', 'Expired', 'Deleted'].map((category) {
                final isSelected = selectedFilter == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredOffers.isEmpty
                    ? Center(child: Text('No offers found.'))
                    : ListView.builder(
                        itemCount: filteredOffers.length,
                        itemBuilder: (context, index) {
                          final offer = filteredOffers[index];
                          final isExpired =
                              offer['endTime'].isBefore(DateTime.now());

                          return ListTile(
                            leading: CachedNetworkImage(
                              imageUrl: offer['imageUrl'],
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                            title: Text(offer['serviceDescription']),
                            subtitle: Text('Price: \$${offer['price']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedFilter == 'Active')
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Confirm Deletion'),
                                          content: Text(
                                              'Are you sure you want to delete this offer?'),
                                          actions: [
                                            TextButton(
                                              child: Text('Cancel'),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              child: Text('Yes'),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Close dialog
                                                deleteOffer(
                                                    offer['offerId']); // Delete
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                Text(
                                  isExpired
                                      ? 'Expired'
                                      : (offer['Availibility'] == true
                                          ? 'Active'
                                          : 'Deleted'),
                                  style: TextStyle(
                                    color: isExpired
                                        ? Colors.red
                                        : (offer['Availibility'] == true
                                            ? Colors.green
                                            : Colors.red),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditOfferPage(
                                    offerId: offer['offerId'],
                                    currentPrice: offer['price'],
                                    currentEndDate: offer['endTime'],
                                    serviceId: offer['serviceId'],
                                  ),
                                ),
                              ).then((_) => fetchUserOffers());
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
