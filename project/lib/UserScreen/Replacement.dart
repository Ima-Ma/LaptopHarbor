import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:project/Components/MyAppBar.dart';
import 'package:project/Components/MyBottomBar.dart';

class Replacement extends StatefulWidget {
  const Replacement({Key? key}) : super(key: key);

  @override
  State<Replacement> createState() => _ReplacementState();
}

class _ReplacementState extends State<Replacement> {
  List<Map<String, dynamic>> purchasedProducts = [];
  TextEditingController messageController = TextEditingController();
  XFile? selectedImage;
  bool isLoading = false;
  String? userName = 'Guest';

  final List<String> issueTypes = [
    'Damaged Product',
    'Return Request',
    'Late Delivery',
    'Wrong Product Received',
    'Missing Item',
    'Payment Issue',
    'Other',
  ];
  String selectedIssueType = 'Damaged Product';


  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFF8F8F8);
  @override
  void initState() {
    super.initState();
    fetchPurchasedProducts();
    fetchOrdersByUserId();
  }

  Future<void> fetchPurchasedProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('Orders')
        .where('userId', isEqualTo: user.uid).where('orderStatus' , isEqualTo: 'Delivered')
        .get();

    final List<Map<String, dynamic>> allProducts = [];

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final products = data['products'] as List<dynamic>;
      final orderDate = data['orderDate'];

      for (var product in products) {
        allProducts.add({
          'title': product['title'],
          'price': product['price'],
          'quantity': product['quantity'],
          'productImage': product['image'] ?? '',
          'orderDate': orderDate,
          'isSelected': false,
        });
      }
    }

    setState(() {
      purchasedProducts = allProducts;
      isLoading = false;
    });
  }

  Future<void> fetchOrdersByUserId() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    userName = userDoc.exists ? userDoc['UserName'] : 'Unknown';

    setState(() => isLoading = false);
  }

  String getDaysLeft(DateTime orderDate) {
    final now = DateTime.now();
    final endTime = orderDate.add(const Duration(days: 7));
    final diff = endTime.difference(now);

    if (diff.isNegative) return "0 Days Left";
    return "${diff.inDays + 1} Days Left";
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = image);
    }
  }

  Future<void> submitReplacementRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    String? imageBase64;
    if (selectedImage != null) {
      final bytes = await selectedImage!.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    final selectedProducts =
        purchasedProducts.where((p) => p['isSelected'] == true).toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one product.")),
      );
      setState(() => isLoading = false);
      return;
    }

    for (var product in selectedProducts) {
      DateTime orderDate = product['orderDate'].toDate();
      if (DateTime.now().difference(orderDate).inDays > 7) continue;

      await FirebaseFirestore.instance.collection('replacement').add({
        'userId': user.uid,
        'productTitle': product['title'],
        'issueType': selectedIssueType,
        'message': messageController.text.trim(),
        'timestamp': Timestamp.now(),
        'status': 'pending',
        'image': imageBase64 ?? '',
      });
    }

    setState(() {
      selectedImage = null;
      messageController.clear();
      for (var p in purchasedProducts) {
        p['isSelected'] = false;
      }
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message Sent Successfully!")),
    );

    Navigator.pop(context);
  }

  Widget _policyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text("• ", style: TextStyle(color: Colors.orange)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     bottomNavigationBar: MyBottomBar(currentIndex: 2),

         backgroundColor: backgroundColor,
     appBar: MyAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Policy Section
                      Container(
  padding: const EdgeInsets.all(5),
  margin: const EdgeInsets.only(bottom: 2),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left side: Image

      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/return.png',
            width: 120, // adjust as needed
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(width: 2),

      // Right side: Policy content
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "7 Days Replacement Policy",
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _policyBullet("We offer a 7-day replacement on eligible products."),
            _policyBullet("Request must be made within 7 days."),
            const Divider(color: Colors.black),
            _policyBullet("❌ Not valid for misuse or no packaging."),
            _policyBullet("❌ Custom or perishable items not accepted."),
          ],
        ),
      ),
    ],
  ),
),


                        // ✅ Product Cards
                        ...purchasedProducts.map((product) {
                          final orderDate = product['orderDate'].toDate() as DateTime;
                          final isExpired = DateTime.now().isAfter(orderDate.add(const Duration(days: 7)));

                          return Card(
                            color: Colors.black.withOpacity(0.05),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product['title'],
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                        Text("Order Date: ${orderDate.toLocal().toString().split(' ')[0]}",
                                            style: const TextStyle(color: Colors.black)),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: product['isSelected'],
                                                  onChanged: (value) {
                                                    if (isExpired) {
                                                      Flushbar(
                                                        message: "Replacement Policy Expired for this product.",
                                                        duration: const Duration(seconds: 3),
                                                        backgroundColor: Colors.redAccent,
                                                        flushbarPosition: FlushbarPosition.TOP,
                                                      ).show(context);
                                                    } else {
                                                      setState(() {
                                                        product['isSelected'] = value!;
                                                      });
                                                    }
                                                  },
                                                ),
                                                Text(
                                                  isExpired ? "Policy Expired" : "Eligible",
                                                  style: TextStyle(
                                                    color: isExpired ? Colors.red : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text("Only: ${getDaysLeft(orderDate)}",
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 16),

                        // ✅ Issue Type Dropdown
                        Text("Issue Type:",
                            style: GoogleFonts.merriweather(fontSize: 16, color: Colors.black)),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          dropdownColor: const Color.fromARGB(180, 255, 255, 255),
                          value: selectedIssueType,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.black),
                          items: issueTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedIssueType = val!);
                          },
                        ),
                        const SizedBox(height: 12),

                        // ✅ Message Field
                        Text("Message:",
                            style: GoogleFonts.merriweather(fontSize: 16, color: Colors.black)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.black12,
                            hintText: "Describe your issue...",
                            hintStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),

                        const SizedBox(height: 16),

                        // ✅ Image Picker
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Image"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (selectedImage != null)
                              const Icon(Icons.check_circle, color: Colors.white),
                            if (selectedImage != null)
                              const Text(" Image Selected",
                                  style: TextStyle(color: Colors.white)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ✅ Submit Button
                        Center(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitReplacementRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                  )
                                : const Text("Submit Request",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
              floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.pushNamed(context, '/chat');
  },
  backgroundColor: const Color.fromARGB(202, 208, 208, 208),
  
  label: const Text(
    'We’re Here for You',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  ),
  icon: Image.asset(
    'assets/images/gemini.png',
    height: 40,
    width: 40,
  ),
),
    );
  }
}