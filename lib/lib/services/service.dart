import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class ServiceFormPage extends StatefulWidget {
  final String categoryId;
  final String userId;
  final String selectedType; // Add selectedType to the constructor

  const ServiceFormPage({
    super.key,
    required this.categoryId,
    required this.userId,
    required this.selectedType, // Initialize selectedType here
  });

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isAvailable = true;
  List<File> imageFiles = [];

  bool isLoading = false;

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        imageFiles = picked.map((img) => File(img.path)).toList();
      });
    }
  }

  Future<void> uploadService() async {
    if (!_formKey.currentState!.validate() || imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please fill all fields and select at least 1 image")),
      );
      return;
    }

    setState(() => isLoading = true); // Show the loading indicator

    try {
      final serviceRef = FirebaseFirestore.instance.collection('Service').doc();
      final serviceId = serviceRef.id;

      // Store service details
      await serviceRef.set({
        'Price': double.parse(priceController.text),
        'Availability': isAvailable,
        'Description': descriptionController.text,
        'CategoryID': widget.categoryId,
        'UserID': widget.userId,
        'AddressID': null,
        'Type': widget.selectedType, // Store selectedType
      });

      // Upload images to Firebase Storage & save URLs
      for (int i = 0; i < imageFiles.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('service_images/$serviceId/image_$i.jpg');

        await ref.putFile(imageFiles[i]);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('Service Images').add({
          'URL': url,
          'ServiceID': serviceId,
        });
      }

      // Now set isLoading to false before navigation
      setState(() => isLoading = false);

      // Navigate to AddressFormPage directly
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddressFormPage(
            serviceId: serviceId,
            type: widget.selectedType, // Pass selectedType to the next screen
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter price per night" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter description"
                          : null,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: isAvailable,
                      onChanged: (val) => setState(() => isAvailable = val),
                      title: const Text("Available?"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Select Images"),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: imageFiles
                          .map((file) => Image.file(file,
                              width: 100, height: 100, fit: BoxFit.cover))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: uploadService,
                      child: const Text("Continue to Address"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
