import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:senior/after_login/Explore.dart';

class BookingPaymentPage extends StatefulWidget {
  final String userId;
  final String serviceId;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerDay;
  final double fullPrice;

  BookingPaymentPage({
    required this.userId,
    required this.serviceId,
    required this.startDate,
    required this.endDate,
    required this.pricePerDay,
    required this.fullPrice,
  });

  @override
  _BookingPaymentPage createState() => _BookingPaymentPage();
}

class _BookingPaymentPage extends State<BookingPaymentPage> {
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
        SnackBar(content: Text('Please select an image'), backgroundColor: Colors.red,),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      // Upload payment image
      String fileName =
          'Booking_payments/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // Create booking
      final bookingRef =
          await FirebaseFirestore.instance.collection('Booking').add({
        'userId': widget.userId,
        'checkin-date': widget.startDate,
        'checkout-date': widget.endDate,
        'status': 'pending',
        'full-price': widget.fullPrice,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add booking-service reference
      await FirebaseFirestore.instance.collection('Book-Service').add({
        'BookingID': bookingRef.id,
        'ServiceID': widget.serviceId,
        'Price_Per_Day': widget.pricePerDay,
      });

      // Save payment record
      await FirebaseFirestore.instance.collection('Booking_Payment').add({
        'Date': Timestamp.now(),
        'Payment_image': imageUrl,
        'PaymentMethod': _paymentMethod,
        'BookingID': bookingRef.id,
      });

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking submitted successfully'),backgroundColor: Colors.green,),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please rate the service'),backgroundColor: Colors.green,),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ExplorePage()),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
        title: Text("Your Payment method"),
        leading: BackButton(),
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
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("No image selected",
                                style: TextStyle(fontWeight: FontWeight.bold)),
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
                Text('OMT'),
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
                Text('Whish'),
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
