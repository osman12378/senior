import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'payment_details.dart'; // Import the PaymentDetailsPage

class ApprovedPage extends StatefulWidget {
  const ApprovedPage({super.key});

  @override
  State<ApprovedPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ApprovedPage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Pay')
              .where('Status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No approved requests"));
            }
      
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var payDoc = snapshot.data!.docs[index];
                var data = payDoc.data() as Map<String, dynamic>;
                String userId = data['UserID'];
                String paymentImageUrl = data['Payment_image'] ?? '';
                String payDocId = payDoc.id;
                String subscriptionId = data['SubscriptionID'] ?? '';
      
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
      
                    if (!userSnapshot.hasData || userSnapshot.data == null) {
                      return ListTile(title: Text("User data not found"));
                    }
      
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) {
                      return ListTile(title: Text("No user data"));
                    }
      
                    String name = userData['username'] ?? 'Unknown';
                    String email = userData['email'] ?? 'No email available';
                    String profilePicPath = 'profiles/$userId.jpg';
      
                    return FutureBuilder<String?>(
                      future: FirebaseStorage.instance
                          .ref(profilePicPath)
                          .getDownloadURL()
                          .catchError((_) => 'null'),
                      builder: (context, imageSnapshot) {
                        String profilePicUrl = imageSnapshot.data ??
                            'https://via.placeholder.com/150';
      
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Subscription')
                              .doc(subscriptionId)
                              .get(),
                          builder: (context, subscriptionSnapshot) {
                            String subscriptionName = 'Unknown Subscription';
      
                            if (subscriptionSnapshot.hasData &&
                                subscriptionSnapshot.data!.exists) {
                              var subData = subscriptionSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              subscriptionName =
                                  subData['name'] ?? 'Unknown Subscription';
                            }
      
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentDetailsPage(
                                      payDocId: payDocId,
                                      username: name,
                                      email: email,
                                      profilePicUrl: profilePicUrl,
                                      paymentImageUrl: paymentImageUrl,
                                      userId: userId,
                                      status: data['Status'],
                                      subscriptionId: subscriptionId,
                                    ),
                                  ),
                                );
                              },
                              leading: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profilePicUrl,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(name),
                              subtitle:
                                  Text('$email\nSubscription: $subscriptionName'),
                              isThreeLine: true,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
