import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddressFormPage extends StatefulWidget {
  final String categoryId;
  final String userId;
  final String selectedType;
  final double price;
  final String description;
  final List<File> imageFiles;

  const AddressFormPage({
    super.key,
    required this.categoryId,
    required this.userId,
    required this.selectedType,
    required this.price,
    required this.description,
    required this.imageFiles,
  });

  @override
  _AddressFormPageState createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController buildingController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  final TextEditingController modelController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController carDetailsController = TextEditingController();

  bool isLoading = false;

  Future<void> saveAddressAndCarDetails() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Create service document
      final serviceRef = FirebaseFirestore.instance.collection('Service').doc();
      final serviceId = serviceRef.id;

      await serviceRef.set({
        'Price': widget.price,
        'Description': widget.description,
        'CategoryID': widget.categoryId,
        'UserID': widget.userId,
        'AddressID': null,
        'Type': widget.selectedType,
        'Deleted': false,
      });

      // 2. Upload images
      for (int i = 0; i < widget.imageFiles.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('service_images/$serviceId/image_$i.jpg');

        await ref.putFile(widget.imageFiles[i]);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('Service Images').add({
          'URL': url,
          'ServiceID': serviceId,
        });
      }

      // 3. Save address
      final addressRef = FirebaseFirestore.instance.collection('Address').doc();
      final addressId = addressRef.id;

      await addressRef.set({
        'Street': streetController.text,
        'Building': buildingController.text,
        'Details': detailsController.text,
      });

      // 4. Save car details if type is 'Cars'
      if (widget.selectedType == 'Cars') {
        final carDescriptionRef =
            FirebaseFirestore.instance.collection('CarDescription').doc();

        await carDescriptionRef.set({
          'Model': modelController.text,
          'Color': colorController.text,
          'Details': carDetailsController.text,
          'ServiceID': serviceId,
        });
      }

      // 5. Update service with AddressID
      await FirebaseFirestore.instance
          .collection('Service')
          .doc(serviceId)
          .update({
        'AddressID': addressId,
      });

      setState(() => isLoading = false);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Address and details saved successfully")),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text('Enter Address')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: streetController,
                      decoration: const InputDecoration(labelText: "Street"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter street"
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: buildingController,
                      decoration: const InputDecoration(labelText: "Building"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter building"
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: detailsController,
                      decoration: const InputDecoration(labelText: "Details"),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter details"
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (widget.selectedType == 'Cars') ...[
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: "Model"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter model"
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: colorController,
                        decoration: const InputDecoration(labelText: "Color"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter color"
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: carDetailsController,
                        decoration:
                            const InputDecoration(labelText: "Car Details"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter car details"
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveAddressAndCarDetails,
                      child: const Text("Save Address and Details"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
