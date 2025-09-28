import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ManageDealsForm extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function refreshProducts;

  const ManageDealsForm({
    Key? key,
    required this.products,
    required this.refreshProducts,
  }) : super(key: key);

  @override
  _ManageDealsFormState createState() => _ManageDealsFormState();
}

class _ManageDealsFormState extends State<ManageDealsForm> {
  final _dealTitleController = TextEditingController();
  final _discountController = TextEditingController();
  String? selectedProductId;
  DateTime? startDate;
  DateTime? endDate;
  String? editingDealId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    editingDealId == null ? 'Add New Laptop Discount' : 'Edit Deal',
                    style: GoogleFonts.merriweather(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color.fromARGB(195, 0, 0, 0),
                  value: selectedProductId,
                  decoration: InputDecoration(
                    labelText: 'Select Product',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.products
                      .map((p) => DropdownMenuItem<String>(
                            value: p['id'],
                            child: Text(p['title'], style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedProductId = val),
                ),
                const SizedBox(height: 12),
                buildTextField(_dealTitleController, 'Deal Title'),
                const SizedBox(height: 12),
                buildTextField(_discountController, 'Discount %', isNumber: true),
                const SizedBox(height: 12),
                buildDateRow('Start Date', startDate, () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => startDate = picked);
                }),
                buildDateRow('End Date', endDate, () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => endDate = picked);
                }),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: addOrUpdateDeal,
                    child: Text(editingDealId == null ? "Add Deal" : "Update Deal"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF539b69),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('deals').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
            final deals = snapshot.data!.docs;
            double maxDiscount = 0;
            for (var d in deals) {
              final data = d.data() as Map<String, dynamic>;
              final discount = data['discount'] ?? 0.0;
              if (discount > maxDiscount) maxDiscount = discount;
            }

            return Column(
              children: deals.map((d) {
                final deal = d.data() as Map<String, dynamic>;
                final id = d.id;
                final product = widget.products.firstWhere((p) => p['id'] == deal['productId'], orElse: () => {'title': 'Unknown', 'price': 0});
                final now = DateTime.now();
                final start = deal['startDate'].toDate();
                final end = deal['endDate'].toDate();
                String status = '';
                if (now.isBefore(start)) {
                  status = 'Upcoming';
                } else if (now.isAfter(end)) {
                  status = 'Expired';
                } else {
                  status = 'Active';
                }

                final isBestDeal = deal['discount'] == maxDiscount;

                return Card(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.2))),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(" ${deal['dealTitle']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 6),
                            if (isBestDeal) const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            Chip(
                              label: Text(status, style: const TextStyle(color: Colors.white)),
                              backgroundColor: status == 'Active'
                                  ? Color(0xFF539b69)
                                  : status == 'Upcoming'
                                      ? Colors.blueAccent
                                      : Color.fromARGB(255, 234, 30, 53),
                            ),
                          ],
                        ),
                            const SizedBox(height: 6),

                        Text("Product: ${product['title']}", style: const TextStyle(color: Colors.white)),
                        Text("Original Price: Rs. ${formatPrice(deal['originalPrice'])}", style: const TextStyle(color: Colors.white)),
                        Text("Discounted Price: Rs. ${formatPrice(deal['discountedPrice'])}", style: const TextStyle(color: Colors.white)),
                        Text("Discount: ${deal['discount']}%", style: const TextStyle(color: Colors.white)),
                        Text("Start: ${start.toString().split(' ')[0]}", style: const TextStyle(color: Colors.white)),
                        Text("End: ${end.toString().split(' ')[0]}", style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(onPressed: () => editDeal(id, deal), icon: const Icon(Icons.edit, color:Color(0xFF539b69))),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Deletion"),
                                content: const Text("Are you sure you want to delete this deal?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context), // Cancel
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close dialog
                                      deleteDeal(id); // Call your delete function
                                    },
                                    child: const Text("Delete", style: TextStyle(color: Color.fromARGB(255, 234, 30, 53))),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete, color: Color.fromARGB(255, 234, 30, 53)),
                        )

                          ],
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }

  Widget buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget buildDateRow(String label, DateTime? date, VoidCallback onPressed) {
    return Row(
      children: [
        Expanded(
          child: Text(
            date == null ? label : '$label: ${date.toLocal().toString().split(' ')[0]}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        TextButton(onPressed: onPressed, child: const Text("Pick", style: TextStyle(color: Colors.white)))
      ],
    );
  }

  void addOrUpdateDeal() async {
    if (selectedProductId == null || _dealTitleController.text.isEmpty || _discountController.text.isEmpty || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final product = widget.products.firstWhere((p) => p['id'] == selectedProductId, orElse: () => {'price': 0});
    final originalPrice = product['price'] ?? 0;
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final discountedPrice = originalPrice - (originalPrice * discount / 100);

    final dealData = {
      'productId': selectedProductId,
      'dealTitle': _dealTitleController.text.trim(),
      'discount': discount,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'startDate': Timestamp.fromDate(startDate!),
      'endDate': Timestamp.fromDate(endDate!),
      'createdAt': Timestamp.now(),
    };

    if (editingDealId != null) {
      await FirebaseFirestore.instance.collection('deals').doc(editingDealId!).update(dealData);
      editingDealId = null;
    } else {
      await FirebaseFirestore.instance.collection('deals').add(dealData);
    }

    clearForm();
  }

  void editDeal(String id, Map<String, dynamic> deal) {
    setState(() {
      editingDealId = id;
      selectedProductId = deal['productId'];
      _dealTitleController.text = deal['dealTitle'];
      _discountController.text = deal['discount'].toString();
      startDate = deal['startDate'].toDate();
      endDate = deal['endDate'].toDate();
    });
  }

  void deleteDeal(String id) async {
    await FirebaseFirestore.instance.collection('deals').doc(id).delete();
  }

  void clearForm() {
    setState(() {
      selectedProductId = null;
      _dealTitleController.clear();
      _discountController.clear();
      startDate = null;
      endDate = null;
    });
  }

  String formatPrice(dynamic value) {
    final number = value is int ? value : int.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,###').format(number);
  }
}
