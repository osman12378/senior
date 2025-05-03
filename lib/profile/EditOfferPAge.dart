import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class EditOfferPage extends StatefulWidget {
  final String offerId;
  final double currentPrice;
  final DateTime currentEndDate;
  final String serviceId;

  const EditOfferPage({
    super.key,
    required this.offerId,
    required this.currentPrice,
    required this.currentEndDate,
    required this.serviceId,
  });

  @override
  State<EditOfferPage> createState() => _EditOfferPageState();
}

class _EditOfferPageState extends State<EditOfferPage> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationValueController =
      TextEditingController();

  String? _selectedUnit;
  final List<String> _durationUnits = ['hours', 'days'];
  DateTime? _selectedEndDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.currentPrice.toString();

    final duration = widget.currentEndDate.difference(DateTime.now());

    if (duration.inHours <= 24) {
      _selectedUnit = 'hours';
      _durationValueController.text = duration.inHours.toString();
    } else {
      _selectedUnit = 'days';
      _selectedEndDate = widget.currentEndDate;
    }
  }

  Future<void> _updateOffer() async {
    if (_priceController.text.isEmpty ||
        _selectedUnit == null ||
        (_selectedUnit == 'hours' && _durationValueController.text.isEmpty) ||
        (_selectedUnit == 'days' && _selectedEndDate == null)) {
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
      final days = _selectedEndDate!.difference(now).inDays + 1;
      if (days <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a valid end date')),
        );
        return;
      }
      endTime = DateTime(
        _selectedEndDate!.year,
        _selectedEndDate!.month,
        _selectedEndDate!.day,
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

      await FirebaseFirestore.instance
          .collection('Offer')
          .doc(widget.offerId)
          .update({
        'price': price,
        'endTime': Timestamp.fromDate(endTime),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
      appBar: AppBar(title: const Text('Edit Offer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Enter New Price',
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
                          _selectedEndDate = null;
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
                            initialDate: _selectedEndDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedEndDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick End Date'),
                      ),
                      if (_selectedEndDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'End Date: ${DateFormat.yMMMd().format(_selectedEndDate!)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateOffer,
                      child: const Text('Update Offer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
