import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PaymentDetailsPage extends StatelessWidget {
  final String payDocId;
  final String username;
  final String email;
  final String profilePicUrl;
  final String paymentImageUrl;
  final String userId;
  final String status;
  final String subscriptionId;
  final String adminId;

  const PaymentDetailsPage({
    Key? key,
    required this.payDocId,
    required this.username,
    required this.email,
    required this.profilePicUrl,
    required this.paymentImageUrl,
    required this.userId,
    required this.status,
    required this.subscriptionId,
    required this.adminId,
  }) : super(key: key);

  void updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('Pay').doc(payDocId).update({
        'Status': newStatus,
        'AdminID': adminId,
      });

      if (newStatus == 'approved') {
        DocumentSnapshot paymentDoc = await FirebaseFirestore.instance
            .collection('Pay')
            .doc(payDocId)
            .get();

        var paymentData = paymentDoc.data() as Map<String, dynamic>;
        String subscriptionId = paymentData['SubscriptionID'];
        String newRole = '';

        if (subscriptionId == 'subscription2') {
          newRole = 'Host';
        } else if (subscriptionId == 'subscription3') {
          newRole = 'Premium Host';
        }

        if (newRole.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'role': newRole});
        }

        QuerySnapshot userServices = await FirebaseFirestore.instance
            .collection('Service')
            .where('UserID', isEqualTo: userId)
            .get();

        for (var doc in userServices.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['deletedbyuser'] == true || data.containsKey('adminId')) {
            continue;
          }

          await doc.reference.update({'Deleted': false});
        }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: Colors.green,),
      );
    } catch (e) {
      print("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status')),
      );
    }
  }

  void approvePayment(BuildContext context) {
    updateStatus(context, 'approved');
  }

  void rejectPayment(BuildContext context) {
    updateStatus(context, 'rejected');
  }

  @override
  Widget build(BuildContext context) {
    final String finalProfileUrl = profilePicUrl.isNotEmpty
        ? profilePicUrl
        : 'https://via.placeholder.com/150';

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text("Payment Review"),
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('Pay').doc(payDocId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text("Payment data not found"));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final Timestamp? startTimestamp = data['StartDate'];
            final Timestamp? endTimestamp = data['EndDate'];

            final String startDate = startTimestamp != null
                ? DateFormat('yyyy-MM-dd').format(startTimestamp.toDate())
                : 'N/A';
            final String endDate = endTimestamp != null
                ? DateFormat('yyyy-MM-dd').format(endTimestamp.toDate())
                : 'N/A';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: finalProfileUrl.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: finalProfileUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Image.asset('assests/default_avatar.jpg'),
                            )
                          : Image.asset(
                              'assests/default_avatar.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(username, style: TextStyle(fontSize: 18)),
                  Text(email, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 20),
                  Text("Payment Image",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FullScreenImage(imageUrl: paymentImageUrl),
                        ),
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: paymentImageUrl,
                      height: 200,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                  SizedBox(height: 20),

                  // 👇 Display Subscription Dates
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Subscription Period",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.date_range,
                                size: 20, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text(
                              "Start Date: $startDate",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.date_range_outlined,
                                size: 20, color: Colors.indigo),
                            SizedBox(width: 16),
                            Text(
                              "End Date: $endDate",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // 👇 Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (status == 'pending')
                        ElevatedButton(
                          onPressed: () => approvePayment(context),
                          child: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      if (status == 'pending') SizedBox(width: 10),
                      if (status == 'pending')
                        ElevatedButton(
                          onPressed: () => rejectPayment(context),
                          child: Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
                Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
