import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditServicePage extends StatefulWidget {
  final String serviceId;

  const EditServicePage({Key? key, required this.serviceId}) : super(key: key);

  @override
  _EditServicePageState createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  String _price = '';
  bool _isUploading = false;
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  List<String> _photoUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('Service')
        .doc(widget.serviceId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _price = data['Price'].toString();
        _priceController.text = _price;
      });
    }

    final images = await FirebaseFirestore.instance
        .collection('Service Images')
        .where('ServiceID', isEqualTo: widget.serviceId)
        .get();

    setState(() {
      _photoUrls = images.docs.map((doc) => doc['URL'] as String).toList();
    });
  }

  Future<void> _addPhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
    });
  }

  Future<void> _updatePrice() async {
    final newPrice = _priceController.text.trim();
    if (newPrice.isEmpty || double.tryParse(newPrice) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('Service')
        .doc(widget.serviceId)
        .update({'Price': double.parse(newPrice)});

    if (_pickedImage != null) {
      setState(() {
        _isUploading = true;
      });

      String fileName =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()) + ".jpg";

      final ref = FirebaseStorage.instance
          .ref()
          .child('service_images/${widget.serviceId}/$fileName');

      try {
        await ref.putFile(_pickedImage!);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('Service Images').add({
          'ServiceID': widget.serviceId,
          'URL': url,
        });

        setState(() {
          _photoUrls.add(url);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price and photo updated')),
        );
      } catch (e) {
        print("Error uploading photo: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading photo')),
        );
      } finally {
        setState(() {
          _isUploading = false;
          _pickedImage = null;
        });
      }
    }

    setState(() {
      _price = newPrice;
    });
  }

  Future<void> _deleteService() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('Service')
          .doc(widget.serviceId)
          .update({
        'Deleted': true,
        'deletedbyuser': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service marked as deleted')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error marking service as deleted: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete service')),
      );
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: imageUrl,
                child: Image.network(imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Service')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Display newly picked image (not yet uploaded)
              if (_pickedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _pickedImage!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _addPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Photo"),
              ),

              const SizedBox(height: 24),

              Text(
                'Price: \$$_price',
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: 200,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter New Price',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updatePrice,
                      child: const Text('Update'),
                    ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: _deleteService,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Service'),
              ),

              const SizedBox(height: 30),

              const Divider(thickness: 1),
              const Text(
                'All Uploaded Images:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 120,
                child: _photoUrls.isEmpty
                    ? const Text('No images yet.')
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photoUrls.length,
                        itemBuilder: (context, index) {
                          final imageUrl = _photoUrls[index];
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(imageUrl),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Hero(
                                  tag: imageUrl,
                                  child: Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
