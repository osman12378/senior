import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressFormPage extends StatefulWidget {
  final String serviceId;
  final String type;

  const AddressFormPage({
    super.key,
    required this.serviceId,
    required this.type,
  });

  @override
  _AddressFormPageState createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController buildingController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  // Car-related fields
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
      // Save address details in Address collection
      final addressRef = FirebaseFirestore.instance.collection('Address').doc();
      final addressId = addressRef.id;

      await addressRef.set({
        'Street': streetController.text,
        'Building': buildingController.text,
        'Details': detailsController.text,
      });

      // If the type is car, save car details in CarDescription collection
      if (widget.type == 'Cars') {
        final carDescriptionRef =
            FirebaseFirestore.instance.collection('CarDescription').doc();

        await carDescriptionRef.set({
          'Model': modelController.text,
          'Color': colorController.text,
          'Details': carDetailsController.text,
          'ServiceID': widget.serviceId, // Foreign key to Service collection
        });
      }

      // Update the Service collection with the AddressID
      await FirebaseFirestore.instance
          .collection('Service')
          .doc(widget.serviceId)
          .update({
        'AddressID': addressId,
      });

      setState(() => isLoading = false);

      // Navigate to the next page or show success
      Navigator.pop(
          context); // This pops the current page to go back to the previous screen.
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
      appBar: AppBar(title: const Text('Enter Address')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Address Fields
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

                    // Car-related Fields if the type is car
                    if (widget.type == 'Cars') ...[
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

                    // Submit Button
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
