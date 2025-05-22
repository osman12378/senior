import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class OfferPage extends StatefulWidget {
  const OfferPage({super.key});

  @override
  State<OfferPage> createState() => _OfferPageState();
}

class _OfferPageState extends State<OfferPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _allServices = [];
  List<DocumentSnapshot> _filteredServices = [];
  List<DocumentSnapshot> _categories = [];
  DocumentSnapshot? selectedService;
  String? _selectedCategoryId;

  final _priceController = TextEditingController();
  final _durationValueController = TextEditingController();
  String? _selectedUnit;
  final _durationUnits = ['hours', 'days'];
  DateTime? selectedEndDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadServices();
  }

  Future<void> _loadCategories() async {
    final catSnap = await _firestore.collection('Category').get();
    setState(() {
      _categories = catSnap.docs;
    });
  }

  Future<void> _loadServices() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final svcSnap = await _firestore
        .collection('Service')
        .where('UserID', isEqualTo: userId)
        .get();

    // filter out deleted
    final svcs = svcSnap.docs
        .where(
            (d) => !(d.data().containsKey('Deleted') && d['Deleted'] == true))
        .toList();

    // filter out those with active offers
    final ids = svcs.map((d) => d.id).toList();
    final offerSnap = await _firestore
        .collection('Offer')
        .where('serviceID', whereIn: ids.isEmpty ? ['none'] : ids)
        .get();
    final now = DateTime.now();
    final activeIds = <String>{};
    for (var o in offerSnap.docs) {
      final end = (o['endTime'] as Timestamp).toDate();
      if (end.isAfter(now)) activeIds.add(o['serviceID']);
    }

    setState(() {
      _allServices = svcs.where((d) => !activeIds.contains(d.id)).toList();
      _applyCategoryFilter();
    });
  }

  void _applyCategoryFilter() {
    if (_selectedCategoryId == null) {
      _filteredServices = List.from(_allServices);
    } else {
      _filteredServices = _allServices
          .where((d) => d['CategoryID'] == _selectedCategoryId)
          .toList();
    }
  }

  Future<String?> _fetchFirstImage(String id) async {
    final imgSnap = await _firestore
        .collection('Service Images')
        .where('ServiceID', isEqualTo: id)
        .limit(1)
        .get();
    if (imgSnap.docs.isNotEmpty) return imgSnap.docs.first['URL'];
    return null;
  }

  Future<void> _submitOffer() async {
    if (selectedService == null ||
        _priceController.text.isEmpty ||
        _selectedUnit == null ||
        (_selectedUnit == 'hours' && _durationValueController.text.isEmpty) ||
        (_selectedUnit == 'days' && selectedEndDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    DateTime endTime;
    final now = DateTime.now();
    if (_selectedUnit == 'hours') {
      final h = int.tryParse(_durationValueController.text) ?? 0;
      if (h <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid number of hours')),
        );
        return;
      }
      endTime = now.add(Duration(hours: h));
    } else {
      final days = selectedEndDate!.difference(now).inDays + 1;
      if (days <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a valid end date')),
        );
        return;
      }
      endTime = DateTime(
        selectedEndDate!.year,
        selectedEndDate!.month,
        selectedEndDate!.day,
        23,
        59,
        59,
      );
    }

    setState(() => _isLoading = true);
    try {
      final price = double.tryParse(_priceController.text) ?? 0;
      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid price greater than 0')),
        );
        return;
      }

      await _firestore.collection('Offer').add({
        'serviceID': selectedService!.id,
        'price': price,
        'createdAt': Timestamp.now(),
        'endTime': Timestamp.fromDate(endTime),
        'Availibility': true,
      });

      setState(() {
        _allServices.remove(selectedService);
        selectedService = null;
        _selectedUnit = null;
        selectedEndDate = null;
        _applyCategoryFilter();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer submitted successfully')),
      );
      _priceController.clear();
      _durationValueController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good-Luck with your offer'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Category Chips ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // "All" chip
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                  _applyCategoryFilter();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: _selectedCategoryId == null
                                      ? Colors.deepPurple
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "All",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // category chips
                            ..._categories.map((cat) {
                              final cid = cat.id;
                              final name = cat['Name'];
                              final isSel = cid == _selectedCategoryId;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = cid;
                                    _applyCategoryFilter();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 16),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? Colors.deepPurple
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color:
                                          isSel ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Service List ──────────────────────────────────
                    _filteredServices.isEmpty
                        ? const Center(child: Text("No services found"))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredServices.length,
                            itemBuilder: (ctx, i) {
                              final svc = _filteredServices[i];
                              final isSel = svc.id == selectedService?.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedService = svc;
                                  });
                                },
                                child: Card(
                                  color: isSel ? Colors.blue.shade100 : null,
                                  child: ListTile(
                                    leading: FutureBuilder<String?>(
                                      future: _fetchFirstImage(svc.id),
                                      builder: (c, snap) {
                                        if (snap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const SizedBox(
                                            width: 50,
                                            height: 50,
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (snap.hasData) {
                                          return CachedNetworkImage(
                                            imageUrl: snap.data!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Icon(
                                            Icons.image_not_supported);
                                      },
                                    ),
                                    title: Text(
                                      svc['Description'] ?? 'Unnamed',
                                    ),
                                    subtitle: Text('Price: \$${svc['Price']}'),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 16),

                    // ── Price Input ───────────────────────────────────
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Enter the new Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Duration Unit ─────────────────────────────────
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      hint: const Text('Select Duration Unit'),
                      items: _durationUnits
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedUnit = v;
                          _durationValueController.clear();
                          selectedEndDate = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_selectedUnit == 'hours')
                      TextFormField(
                        controller: _durationValueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Number of Hours',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else if (_selectedUnit == 'days') ...[
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => selectedEndDate = picked);
                          }
                        },
                        child: const Text('Pick End Date'),
                      ),
                      if (selectedEndDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'End Date: ${selectedEndDate!.toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),

                    // ── Submit Button ────────────────────────────────
                    ElevatedButton(
                      onPressed: _submitOffer,
                      child: const Text('Submit Offer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
