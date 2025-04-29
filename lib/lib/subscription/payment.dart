import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:senior/after_login/Explore.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _selectedImage;
  String _paymentMethod = 'OMT';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _handleSubmit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Upload image to Firebase Storage
      String fileName = 'payments/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Get current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // TODO: Pass this SubscriptionID from previous page
      String subscriptionId =
          ModalRoute.of(context)!.settings.arguments as String;

      // Add to Firestore
      await FirebaseFirestore.instance.collection('Pay').add({
        'StartDate': Timestamp.now(),
        'EndDate': Timestamp.now().toDate().add(Duration(days: 30)),
        'Payment_image': imageUrl,
        'UserID': userId,
        'SubscriptionID': subscriptionId,
        'Status': 'pending',
        'PaymentMethod': _paymentMethod,
      });

      Navigator.of(context).pop(); // Remove loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request was successfully sent')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ExplorePage()),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 👈 This pops the page (goes back)
          },
        ),
        title: Text(
          "Your Payment method",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("No image selected",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'OMT',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                Text('OMT', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 16),
                Radio<String>(
                  value: 'Whish',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                Text('Whish', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3A3A7E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 14),
              ),
              child: Text("Submit",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
