import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'address.dart';

class ServiceFormPage extends StatefulWidget {
  final String categoryId;
  final String userId;
  final String selectedType;

  const ServiceFormPage({
    super.key,
    required this.categoryId,
    required this.userId,
    required this.selectedType,
  });

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

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

  void goToNextPage() {
    if (!_formKey.currentState!.validate() || imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please fill all fields and select at least 1 image")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressFormPage(
          categoryId: widget.categoryId,
          userId: widget.userId,
          selectedType: widget.selectedType,
          price: double.parse(priceController.text),
          description: descriptionController.text,
          imageFiles: imageFiles,
        ),
      ),
    );
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter price per night";
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return "Enter a valid positive price";
                        }
                        return null;
                      },
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
                      onPressed: goToNextPage,
                      child: const Text("Continue to Address"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
