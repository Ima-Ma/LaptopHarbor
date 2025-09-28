import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ManageBrandForm extends StatefulWidget {
  final VoidCallback refreshBrands;

  const ManageBrandForm({Key? key, required this.refreshBrands}) : super(key: key);

  @override
  _ManageBrandFormState createState() => _ManageBrandFormState();
}

class _ManageBrandFormState extends State<ManageBrandForm> {
  final TextEditingController brandNameController = TextEditingController();
  String? uploadedBrandImageBase64;
  String? editingBrandId;

  List<Map<String, dynamic>> brands = [];

  @override
  void initState() {
    super.initState();
    fetchBrands();
  }

  Future<void> fetchBrands() async {
    final snapshot = await FirebaseFirestore.instance.collection('brands').get();
    setState(() {
      brands = snapshot.docs.map((doc) => {
        'id': doc.id,
        'BrandName': doc['BrandName'],
        'BrandImage': doc['BrandImage'],
      }).toList();
    });
  }

  Future<void> pickBrandImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unsupported image type. Use jpg, jpeg, or png.")));
        return;
      }

      setState(() {
        uploadedBrandImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> addOrUpdateBrand() async {
    final name = brandNameController.text.trim();
    if (name.isEmpty || uploadedBrandImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter brand name and upload image.")));
      return;
    }

    if (editingBrandId != null) {
      await FirebaseFirestore.instance.collection('brands').doc(editingBrandId).update({
        'BrandName': name,
        'BrandImage': uploadedBrandImageBase64,
      });
    } else {
      await FirebaseFirestore.instance.collection('brands').add({
        'BrandName': name,
        'BrandImage': uploadedBrandImageBase64,
      });
    }

    brandNameController.clear();
    uploadedBrandImageBase64 = null;
    editingBrandId = null;
    await fetchBrands();
    widget.refreshBrands();
  }

  Future<void> deleteBrand(String brandId) async {
    await FirebaseFirestore.instance.collection('brands').doc(brandId).delete();
    await fetchBrands();
    widget.refreshBrands();
  }

  void startEditingBrand(Map<String, dynamic> brand) {
    setState(() {
      brandNameController.text = brand['BrandName'];
      uploadedBrandImageBase64 = brand['BrandImage'];
      editingBrandId = brand['id'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Text(
                    editingBrandId == null ? "Add  Laptop Brand " : "Edit Brand",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandNameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Brand Name",
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: pickBrandImage,
                  icon: Icon(Icons.image, color: Colors.white),
                  label: Text("Upload Brand Image", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  Color.fromARGB(255, 234, 30, 53),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: addOrUpdateBrand,
                    child: Text(editingBrandId == null ? "Add Brand" : "Update"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF539b69),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...brands.map((b) => Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: b['BrandImage'] != null
                    ? Image.memory(
                        base64Decode(b['BrandImage']),
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      )
                    : null,
                title: Text(b['BrandName'], style: TextStyle(color: Colors.white)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFF539b69)),
                      onPressed: () => startEditingBrand(b),
                    ),
                    IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromARGB(255, 234, 30, 53)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Deletion"),
                          content: const Text("Are you sure you want to delete this brand?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), // Cancel
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close the dialog
                                deleteBrand(b['id']);   // Delete function
                              },
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Color.fromARGB(255, 234, 30, 53)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )

                  ],
                ),
              ),
            ))
      ],
    );
  }
}