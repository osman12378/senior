import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDetailsPage extends StatelessWidget {
  final String payDocId;
  final String username;
  final String email;
  final String profilePicUrl;
  final String paymentImageUrl;
  final String userId;

  const PaymentDetailsPage({
    Key? key,
    required this.payDocId,
    required this.username,
    required this.email,
    required this.profilePicUrl,
    required this.paymentImageUrl,
    required this.userId,
  }) : super(key: key);

  void updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Pay')
          .doc(payDocId)
          .update({'Status': newStatus});

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
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      print("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String finalProfileUrl = profilePicUrl.isNotEmpty
        ? profilePicUrl
        : 'https://via.placeholder.com/150';

    return Scaffold(
      appBar: AppBar(title: Text("Payment Review")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              backgroundImage: null,
              child: ClipOval(
                child:
                    profilePicUrl.isNotEmpty && profilePicUrl.startsWith('http')
                        ? Image.network(
                            profilePicUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assests/default_avatar.jpg',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              );
                            },
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
            Image.network(paymentImageUrl, height: 200),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => updateStatus(context, 'approved'),
                  child: Text("Approve", style: TextStyle(color: Colors.black)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton(
                  onPressed: () => updateStatus(context, 'rejected'),
                  child: Text("Reject", style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
