import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

      if (serviceIds.isEmpty) {
        setState(() {
          offers = [];
          isLoading = false;
        });
        return;
      }

      QuerySnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('Offer')
          .where('serviceID', whereIn: serviceIds)
          .where('Availibility', isEqualTo: true) // Use correct field name
          .get();

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
          'Availibility': offerDoc['Availibility'], // Correct field
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
    return Scaffold(
      appBar: AppBar(title: Text('Manage Offers')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : offers.isEmpty
              ? Center(child: Text('No offers found.'))
              : ListView.builder(
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final isExpired = offer['endTime'].isBefore(DateTime.now());

                    return ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: offer['imageUrl'],
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(offer['serviceDescription']),
                      subtitle: Text('Price: \$${offer['price']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isExpired)
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
                                              .pop(); // Close the dialog
                                          deleteOffer(offer[
                                              'offerId']); // Proceed with deletion
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          Text(
                            isExpired ? 'Expired' : 'Active',
                            style: TextStyle(
                              color: isExpired ? Colors.red : Colors.green,
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
    );
  }
}
