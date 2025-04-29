import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service.dart'; // <-- Ensure this import is correct

class Select extends StatefulWidget {
  const Select({super.key});

  @override
  State<Select> createState() => _SelectState();
}

class _SelectState extends State<Select> {
  String? selectedType;
  String? selectedName;
  String? selectedCategoryId;

  List<String> types = [];
  List<String> names = [];
  Map<String, String> nameToCategoryId = {}; // Name -> CategoryID

  @override
  void initState() {
    super.initState();
    fetchTypes();
  }

  Future<void> fetchTypes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Category').get();

    final allTypes =
        snapshot.docs.map((doc) => doc['Type'] as String).toSet().toList();

    setState(() {
      types = allTypes;
    });
  }

  Future<void> fetchNamesByType(String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Category')
        .where('Type', isEqualTo: type)
        .get();

    setState(() {
      names = snapshot.docs.map((doc) => doc['Name'] as String).toList();
      nameToCategoryId = {for (var doc in snapshot.docs) doc['Name']: doc.id};
      selectedName = null;
      selectedCategoryId = null;
    });
  }

  void navigateToServicePage() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (selectedCategoryId != null && selectedType != null && userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceFormPage(
            categoryId: selectedCategoryId!,
            userId: userId,
            selectedType: selectedType!, // Pass selectedType here
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedType,
              hint: const Text("Select Type"),
              isExpanded: true,
              items: types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.toUpperCase(),
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                });
                if (value != null) {
                  fetchNamesByType(value);
                }
              },
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedName,
              hint: const Text("Select Name"),
              isExpanded: true,
              items: names.map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedName = value;
                  selectedCategoryId = nameToCategoryId[value];
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: selectedCategoryId != null && selectedType != null
                  ? navigateToServicePage
                  : null, // Ensure selectedType and selectedCategoryId are not null
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
