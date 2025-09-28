import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageSeriesForm extends StatefulWidget {
  final List<Map<String, dynamic>> brands;
  final VoidCallback refreshBrands;

  const ManageSeriesForm({
    Key? key,
    required this.brands,
    required this.refreshBrands,
  }) : super(key: key);

  @override
  State<ManageSeriesForm> createState() => _ManageSeriesFormState();
}

class _ManageSeriesFormState extends State<ManageSeriesForm> {
  final TextEditingController seriesNameController = TextEditingController();
  String? selectedBrandId;
  List<Map<String, dynamic>> seriesList = [];

  @override
  void initState() {
    super.initState();
    selectedBrandId = null; // Show all series by default
    fetchSeries();
  }

  void fetchSeries() async {
    Query query = FirebaseFirestore.instance.collection('series');

    if (selectedBrandId != null) {
      query = query.where('brandId', isEqualTo: selectedBrandId);
    }

    final snapshot = await query.get();

    setState(() {
      seriesList = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'seriesName': doc['seriesName'],
                'brandId': doc['brandId'],
              })
          .toList();
    });
  }

  Future<void> addSeries() async {
    if (seriesNameController.text.isEmpty || selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('series').add({
      'seriesName': seriesNameController.text.trim(),
      'brandId': selectedBrandId,
    });

    seriesNameController.clear();
    fetchSeries();
  }

  Future<void> deleteSeries(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this series?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('series').doc(id).delete();
      fetchSeries();
    }
  }

  Future<void> editSeries(String id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Series"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('series')
                    .doc(id)
                    .update({'seriesName': newName});
                Navigator.pop(context);
                fetchSeries();
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  String getBrandName(String brandId) {
    final brand = widget.brands.firstWhere(
      (b) => b['id'] == brandId,
      orElse: () => {'BrandName': 'Unknown'},
    );
    return brand['BrandName'];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text("Add Laptop Series",
                      style: GoogleFonts.merriweather(
                          fontSize: 20, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedBrandId,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text("All Brands", style: TextStyle(color: Colors.white)),
                    ),
                    ...widget.brands.map(
                      (b) => DropdownMenuItem<String>(
                        value: b['id'],
                        child: Text(b['BrandName']),
                      ),
                    )
                  ],
                  onChanged: (val) {
                    setState(() => selectedBrandId = val);
                    fetchSeries();
                  },
                  dropdownColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: "Select Brand",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: seriesNameController,
                  decoration: const InputDecoration(
                    labelText: "Series Name",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: addSeries,
                    child: const Text("Add Series"),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF539b69),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (seriesList.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Existing Series:",
                    style: GoogleFonts.merriweather(
                        fontSize: 18, color: Colors.white)),
                const SizedBox(height: 10),
                ...seriesList.map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['seriesName'],
                                style: const TextStyle(color: Colors.white)),
                            Text("Brand: ${getBrandName(s['brandId'])}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF539b69)),
                              onPressed: () =>
                                  editSeries(s['id'], s['seriesName']),
                            ),
                           IconButton(
                              icon: const Icon(Icons.delete, color:Color.fromARGB(255, 234, 30, 53)), // your theme red
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Color.fromARGB(255, 15, 20, 26),
                                    title: const Text("Delete Series?", style: TextStyle(color: Colors.white)),
                                    content: const Text("Are you sure you want to delete this series?",
                                        style: TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: const Text("Delete", style: TextStyle(color:Color.fromARGB(255, 234, 30, 53))),
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  deleteSeries(s['id']);
                                }
                              },
                            ),

                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}
