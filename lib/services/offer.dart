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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> allServices = [];
  List<DocumentSnapshot> filteredServices = [];
  DocumentSnapshot? selectedService;

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationValueController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedUnit;
  final List<String> _durationUnits = ['hours', 'days'];
  DateTime? selectedEndDate;

  bool _isLoading = false;

  List<Map<String, String>> categories = [];
  String selectedCategoryId = "All";

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndServices();
    _searchController.addListener(filterServices);
  }

  Future<void> fetchCategoriesAndServices() async {
    final categorySnapshot = await _firestore.collection('Category').get();
    categories = [
      {'id': 'All', 'name': 'All'},
      ...categorySnapshot.docs.map((doc) => {
            'id': doc.id,
            'name': (doc['Name'] is List)
                ? (doc['Name'] as List).join(', ')
                : doc['Name'].toString(),
          }),
    ];

    await fetchUserServices();
  }

  Future<void> fetchUserServices() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final servicesQuery = await _firestore
        .collection('Service')
        .where('UserID', isEqualTo: userId)
        .get();

    final services = servicesQuery.docs.where((doc) {
      return doc.data().containsKey('Deleted') ? doc['Deleted'] == false : true;
    }).toList();

    final serviceIds = services.map((s) => s.id).toList();

    final offersQuery = await _firestore
        .collection('Offer')
        .where('serviceID',
            whereIn: serviceIds.isEmpty ? ['dummy'] : serviceIds)
        .get();

    final now = DateTime.now();
    final activeOfferServiceIds = <String>{};

    for (final offer in offersQuery.docs) {
      final endTime = (offer['endTime'] as Timestamp).toDate();
      if (endTime.isAfter(now)) {
        activeOfferServiceIds.add(offer['serviceID']);
      }
    }

    allServices = services.where((service) {
      return !activeOfferServiceIds.contains(service.id);
    }).toList();

    filterServices();
  }

  void filterServices() {
    final query = _searchController.text.toLowerCase();

    final filtered = allServices.where((service) {
      final matchesCategory = selectedCategoryId == "All" ||
          service['CategoryID'] == selectedCategoryId;
      final description =
          (service['Description'] ?? '').toString().toLowerCase();
      return matchesCategory && description.contains(query);
    }).toList();

    setState(() {
      filteredServices = filtered;
    });
  }

  Future<String?> fetchFirstImage(String serviceId) async {
    final imagesSnapshot = await _firestore
        .collection('Service Images')
        .where('ServiceID', isEqualTo: serviceId)
        .limit(1)
        .get();

    if (imagesSnapshot.docs.isNotEmpty) {
      return imagesSnapshot.docs.first['URL'] as String;
    }
    return null;
  }

  Future<void> submitOffer() async {
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
      final int? durationValue = int.tryParse(_durationValueController.text);
      if (durationValue == null || durationValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid number of hours')),
        );
        return;
      }
      endTime = now.add(Duration(hours: durationValue));
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
      double? price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid price greater than 0')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await _firestore.collection('Offer').add({
        'serviceID': selectedService!.id,
        'price': price,
        'createdAt': Timestamp.now(),
        'endTime': Timestamp.fromDate(endTime),
        'Availibility': true,
      });

      allServices.remove(selectedService);
      filterServices();
      setState(() {
        selectedService = null;
        _selectedUnit = null;
        selectedEndDate = null;
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Add offer'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Category filter
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              selectedCategoryId == category['id'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryId = category['id']!;
                                filterServices();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 4),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.indigo
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  category['name']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search Service',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Service list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedService = service;
                            });
                          },
                          child: Card(
                            color: selectedService?.id == service.id
                                ? Colors.blue.shade100
                                : null,
                            child: ListTile(
                              title: Text(service['Description'] ?? 'Unnamed'),
                              subtitle: Text('Price: \$${service['Price']}'),
                              leading: FutureBuilder<String?>(
                                future: fetchFirstImage(service.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasData) {
                                    return CachedNetworkImage(
                                      imageUrl: snapshot.data!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    );
                                  } else {
                                    return const Icon(
                                        Icons.image_not_supported);
                                  }
                                },
                              ),
                              trailing: selectedService?.id == service.id
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
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
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      hint: const Text('Select Duration Unit'),
                      items: _durationUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedUnit = val;
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
                            setState(() {
                              selectedEndDate = picked;
                            });
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
                    ElevatedButton(
                      onPressed: submitOffer,
                      child: const Text('Submit Offer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
