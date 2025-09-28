import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project/Components/MyBottomBar.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

class Explore extends StatefulWidget {


  const Explore({Key? key}) : super(key: key);

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
      void openStripeCheckout() {
    const stripeLink = 'https://buy.stripe.com/test_aFa8wQf4c5oLgJf0hQcQU00';
    html.window.open(stripeLink, '_blank'); // Open in new tab
  }
  // create Order Modal Controllers & States

  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String selectedPayment = '';
  bool isProfileComplete = true;
  //END Order Modal Controllers & States
  //Create Map userProfile
  Map<String, dynamic>? userProfile;
  //Check Login Start
  Future<String?> checkLogin() async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) {
      // Show flushbar if not logged in
      Flushbar(
        message: "Login required to perform this action.",
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ).show(context);
      return null;
    }
    return userId;
  }

  //Check login end
  Future<void> fetchUserProfile() async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection("userprofile")
            .where("UserId", isEqualTo: userId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      userProfile = snapshot.docs.first.data();
      addressController.text = userProfile?['address'] ?? '';
      contactController.text = userProfile?['phonenumber'] ?? '';

      // ✅ Profile is complete
      setState(() {
        isProfileComplete = true;
      });
    } else {
      // ❌ Profile not found
      setState(() {
        isProfileComplete = false;
      });
    }
  }

  //End Map userProfile
  late String productId;
  late Future<Map<String, dynamic>> combinedData;
  String userName = 'Guest';
  int _selectedIndex = 0;

  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFf2f2f2);
  int selectedImageIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    productId = ModalRoute.of(context)!.settings.arguments as String;
    combinedData = fetchCombinedData(productId);
  }

  Future<Map<String, dynamic>> fetchCombinedData(String productId) async {
    final productDoc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
    final product = productDoc.data();

    if (product == null) throw Exception("Product not found");

    final categoryId = product['categoryId'];
    final brandId = product['brandId'];
    final seriesId = product['seriesId'];

    final categoryDoc =
        categoryId != null
            ? await FirebaseFirestore.instance
                .collection('category')
                .doc(categoryId)
                .get()
            : null;
    final brandDoc =
        brandId != null
            ? await FirebaseFirestore.instance
                .collection('brands')
                .doc(brandId)
                .get()
            : null;
    final seriesDoc =
        seriesId != null
            ? await FirebaseFirestore.instance
                .collection('series')
                .doc(seriesId)
                .get()
            : null;

    final dealSnap =
        await FirebaseFirestore.instance
            .collection("deals")
            .where("productId", isEqualTo: productId)
            .get();

    final deal = dealSnap.docs.isNotEmpty ? dealSnap.docs.first.data() : null;

    return {
      'product': product,
      'category': categoryDoc?.data(),
      'brand': brandDoc?.data(),
      'series': seriesDoc?.data(),
      'deal': deal,
    };
  }

  Future<String?> getUserIdFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");

    if (email == null) return null;

    // Get userId from users collection
    final userSnapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: email)
            .get();

    if (userSnapshot.docs.isNotEmpty) {
      return userSnapshot.docs.first.id;
    }

    return null;
  }

  Future<void> addToWishlist(String productId) async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) return;

    final wishlistRef = FirebaseFirestore.instance
        .collection("Wishlist")
        .doc(userId);

    final doc = await wishlistRef.get();

    if (doc.exists) {
      // Update existing wishlist
      await wishlistRef.update({
        "productIds": FieldValue.arrayUnion([productId]),
      });
    } else {
      // Create new wishlist
      await wishlistRef.set({
        "userId": userId,
        "productIds": [productId],
      });
    }
  }

  Future<void> addToCart(String productId) async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) return;

    final cartRef = FirebaseFirestore.instance.collection("Cart").doc(userId);

    final doc = await cartRef.get();

    if (doc.exists) {
      await cartRef.update({
        "productId": FieldValue.arrayUnion([productId]),
      });
    } else {
      await cartRef.set({
        "userId": userId,
        "productId": [productId],
      });
    }
  }

  Future<bool?> showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  //Create Widget _buildTextField
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  //End Widget _buildTextField

  //Start Order Modal
  void showOrderModal(
    int price,
    String productId,
    Map<String, dynamic> product,
    Map<String, dynamic>? deal,
  ) async {
    await fetchUserProfile(); // Fetch user profile before opening modal

    bool isInfoFilled =
        addressController.text.isNotEmpty && contactController.text.isNotEmpty;

    // 💰 Apply discount if deal is available
    int finalPrice = price;
    if (deal != null && deal['discount'] != null) {
      final int discount = deal['discount'];
      finalPrice = price - ((price * discount) ~/ 100);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Confirm Your Order",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🏠 Show form fields only if profile is incomplete
                    if (!isInfoFilled) ...[
                      _buildTextField(addressController, "Address", Icons.home),
                      const SizedBox(height: 10),
                      _buildTextField(
                        contactController,
                        "Contact No",
                        Icons.phone,
                      ),
                      const SizedBox(height: 10),
                    ],

                    // 💳 Payment Method
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Cash on Delivery',
                          groupValue: selectedPayment,
                          onChanged:
                              (value) =>
                                  setState(() => selectedPayment = value!),
                        ),
                        const Text("Cash on Delivery"),
                      ],
                    ),
                    
Align(
  alignment: Alignment.centerLeft,
  child: ElevatedButton.icon(
    onPressed: () {
      setState(() {
        selectedPayment = 'Online Payment'; // ya '' agar khali chahte ho
      });
      openStripeCheckout();
    },
    icon: const Icon(Icons.payment),
    label: const Text("Pay with Card"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

                    const SizedBox(height: 10),

                    // 💸 Price Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_shipping, color: Colors.teal),
                              SizedBox(width: 10),
                              Text("Shipping: PKR 200"),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Total: PKR ${finalPrice + 200}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✅ Confirm Button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!isInfoFilled &&
                            (addressController.text.isEmpty ||
                                contactController.text.isEmpty)) {
                          showDialog(
                            context: context,
                            builder:
                                (_) => const AlertDialog(
                                  title: Text("Missing Info"),
                                  content: Text("Please fill all the fields."),
                                ),
                          );
                          return;
                        }

                        if (selectedPayment.isEmpty) {
                          showDialog(
                            context: context,
                            builder:
                                (_) => const AlertDialog(
                                  title: Text("Select Payment"),
                                  content: Text(
                                    "Please select a payment method.",
                                  ),
                                ),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close modal
                        placeOrder(
                          finalPrice + 200,
                          productId,
                          product,
                          deal,
                        ); // Place order with discounted price
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Confirm Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        // foregroundColor:Colors.white,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  //END Order Modal
  //Start FUNC placeOrder

  Future<void> placeOrder(
    int totalPrice,
    String productId,
    Map<String, dynamic> productData,
    Map<String, dynamic>? dealData,
  ) async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) return;

    // ✅ Fetch all agents and pick a random one
    String agentName = "Unknown";
    final agentSnap =
        await FirebaseFirestore.instance.collection("Agent").get();
    if (agentSnap.docs.isNotEmpty) {
      final randomIndex = Random().nextInt(agentSnap.docs.length);
      agentName = agentSnap.docs[randomIndex]['AgentName'] ?? "CourierX";
    }

    // ✅ Ensure user profile
    final profileSnap =
        await FirebaseFirestore.instance
            .collection("userprofile")
            .where("UserId", isEqualTo: userId)
            .get();

    if (profileSnap.docs.isEmpty) {
      await FirebaseFirestore.instance.collection("userprofile").add({
        "UserId": userId,
        "address": addressController.text.trim(),
        "phonenumber": contactController.text.trim(),
        "image": "",
        "createdAt": Timestamp.now(),
      });
    }

    final shippingData = {
      "address": addressController.text.trim(),
      "contactno": contactController.text.trim(),
    };

    final originalPrice = productData['price'] ?? 0;
    double discountedPrice = originalPrice.toDouble();
    Map<String, dynamic>? dealMap;

    if (dealData != null) {
      final discount = dealData['discount'] ?? 0;
      discountedPrice = originalPrice - (originalPrice * discount / 100);
      dealMap = {
        "dealTitle": dealData['dealTitle'],
        "discount": discount,
        "startDate": dealData['startDate'],
        "endDate": dealData['endDate'],
        "originalPrice": originalPrice,
        "discountedPrice": discountedPrice,
      };
    }

    final productItem = {
      "image":
          (productData['images'] != null && productData['images'].isNotEmpty)
              ? productData['images'][0]
              : "",
      "price": discountedPrice,
      "productId": productId,
      "quantity": 1,
      "stockQuantity": productData['stockQuantity'] ?? 0,
      "title": productData['title'],
      if (dealMap != null) "deal": dealMap,
    };

    await FirebaseFirestore.instance.collection("Orders").add({
      "courier": {"agentName": agentName}, // ✅ Random agent assigned
      "orderDate": Timestamp.now(),
      "orderStatus": "Pending",
      "paymentMethod": selectedPayment,
      "products": [productItem],
      "shipping": shippingData,
      "totalPrice": totalPrice,
      "userId": userId,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Order placed successfully!")));
  }

  //End placeOrder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/main.png', height: 60),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: combinedData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData)
            return const Center(child: Text("No data available"));

          final product = snapshot.data!['product'] as Map<String, dynamic>;
          final deal = snapshot.data!['deal'] as Map<String, dynamic>?;
          final category = snapshot.data!['category'] as Map<String, dynamic>?;
          final brand = snapshot.data!['brand'] as Map<String, dynamic>?;
          final series = snapshot.data!['series'] as Map<String, dynamic>?;

          final List<String> images = List<String>.from(
            product['images'] ?? [],
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // if (brand != null && brand['BrandImage'] != null)
                //   Center(
                //     child: CachedNetworkImage(
                //       imageUrl: brand['BrandImage'],
                //       height: 80,
                //     ),
                //   ),
                const SizedBox(height: 16),

                if (images.isNotEmpty)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: images[selectedImageIndex],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImageIndex = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        selectedImageIndex == index
                                            ? primaryColor
                                            : Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: images[index],
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                Text(
                  product['title'] ?? 'No Title',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('deals')
                          .where('productId', isEqualTo: productId)
                          .get(),
                  builder: (context, dealSnapshot) {
                    if (dealSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text(
                        '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.redAccent,
                        ),
                      );
                    }

                    if (!dealSnapshot.hasData ||
                        dealSnapshot.data!.docs.isEmpty) {
                      return Text(
                        '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.redAccent,
                        ),
                      );
                    }

                    final dealData =
                        dealSnapshot.data!.docs.first.data()
                            as Map<String, dynamic>;
                    final discount = dealData['discount'] ?? 0;
                    final dealTitle = dealData['dealTitle'] ?? '';
                    final startDate = dealData['startDate']?.toDate();
                    final endDate = dealData['endDate']?.toDate();

                    final originalPrice = product['price'] ?? 0;
                    final discountedPrice =
                        originalPrice - (originalPrice * discount / 100);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🌟 Deal Title
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dealTitle.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        // 🔻 Discount + Original + Discounted Price
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-$discount%',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '\$${originalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '\$${discountedPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        // 🕒 Start and End Dates in Marquee
                        SizedBox(
                          height: 22,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Text(
                                '🕒 Deal from ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final userId = await checkLogin();
                          if (userId == null) return; // Not logged in, exit
                          showOrderModal(
                            product['price'],
                            productId,
                            product,
                            deal,
                          );
                        },

                        icon: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Buy Now',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final userId = await checkLogin();
                        if (userId == null) return;

                        final confirm = await showConfirmationDialog(
                          context,
                          'Add to Wishlist',
                          'Are you sure you want to add this item to your wishlist?',
                        );

                        if (confirm == true) {
                          await addToWishlist(productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to Wishlist')),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final userId = await checkLogin();
                        if (userId == null) return;

                        final confirm = await showConfirmationDialog(
                          context,
                          'Add to Cart',
                          'Are you sure you want to add this item to your cart?',
                        );

                        if (confirm == true) {
                          await addToCart(productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to Cart')),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                //end
                const SizedBox(height: 10),

                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    InfoTile(
                      icon: Icons.category,
                      title: 'Category',
                      value: category?['categoryname'] ?? 'N/A',
                    ),
                    InfoTile(
                      icon: Icons.label,
                      title: 'Brand',
                      value: brand?['BrandName'] ?? 'N/A',
                    ),
                    InfoTile(
                      icon: Icons.linear_scale,
                      title: 'Series',
                      value: series?['seriesName'] ?? 'N/A',
                    ),
                    InfoTile(
                      icon: Icons.check_circle_outline,
                      title: 'In Stock',
                      value: product['inStock'] == true ? 'Yes' : 'No',
                      iconColor:
                          product['inStock'] == true
                              ? Colors.green
                              : Colors.red,
                    ),
                    InfoTile(
                      icon: Icons.star_border,
                      title: 'Rating',
                      value: product['rating']?.toString() ?? 'N/A',
                    ),
                    if (product['activated'] != null)
                      InfoTile(
                        icon:
                            product['activated']
                                ? Icons.check_box
                                : Icons.indeterminate_check_box,
                        title: 'Activated',
                        value: product['activated'] ? 'Active' : 'Inactive',
                        iconColor:
                            product['activated'] ? Colors.green : Colors.red,
                      ),
                  ],
                ),

                const Divider(height: 30),

                Text("Description", style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 6),
                Text(product['description'] ?? 'No description available'),

                const Divider(height: 30),

                if (product['specification'] != null &&
                    product['specification'] is Map<String, dynamic>) ...[
                  Text(
                    "Specifications of ${product['title'] ?? 'this product'}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Below are the key specifications of this product. Each feature has been carefully listed to help you make an informed decision.",
                    style: TextStyle(fontSize: 13),
                  ),

                  const SizedBox(height: 16),

                  // Booleans as buttons
                  Row(
                    children: [
                      BoolButton(
                        label: "Fingerprint",
                        value: product['specification']['fingerprint'],
                      ),
                      const SizedBox(width: 8),
                      BoolButton(
                        label: "HDMI",
                        value: product['specification']['hdmi'],
                      ),
                      const SizedBox(width: 8),
                      BoolButton(
                        label: "Touchscreen",
                        value: product['specification']['touchscreen'],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Other Specifications in Table Format
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                    },
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children:
                        (product['specification'] as Map<String, dynamic>)
                            .entries
                            .where(
                              (entry) =>
                                  entry.key != 'fingerprint' &&
                                  entry.key != 'hdmi' &&
                                  entry.key != 'touchscreen',
                            )
                            .map(
                              (entry) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(entry.value.toString()),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  "Reviews And Rating",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('reviews')
                          .where(
                            'productId',
                            isEqualTo: productId,
                          ) // Filter by productId
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final reviews = snapshot.data!.docs;

                    if (reviews.isEmpty) {
                      return Center(
                        child: Text(
                          'No reviews found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        final userId = review['userId'];
                        final rating = review['rating'];
                        final comment = review['comment'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('userprofile')
                              .where('UserId', isEqualTo: userId)
                              .limit(1)
                              .get()
                              .then((snap) => snap.docs.first.reference.get()),
                          builder: (context, userProfileSnapshot) {
                            if (!userProfileSnapshot.hasData) {
                              return SizedBox.shrink();
                            }

                            final userProfile = userProfileSnapshot.data!;
                            final usersUserId = userProfile['UserId'];

                            return FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(usersUserId)
                                      .get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return SizedBox.shrink();
                                }

                                final user = userSnapshot.data!;
                                final username = user['UserName'];
                                final email = user['email'];

                                return Card(
                                  color:  const Color.fromARGB(255, 237, 237, 237) ,
                                  margin: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(email),
                                        SizedBox(height: 4),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              i < rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(comment),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  "Explore More Laptops ..",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('products')
                          .where(
                            'categoryId',
                            isEqualTo: category?['categoryId'],
                          ) // or similar logic
                          .limit(5)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final products = snapshot.data!.docs;

                    if (products.isEmpty) {
                      return Center(
                        child: Text('No recommended products found'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final productId = product.id;
                        final title = product['title'];
                        final description = product['description'];
                        final price = product['price'];
                        final imageUrl =
                            (product['images'] != null &&
                                    product['images'].isNotEmpty)
                                ? product['images'][0]
                                : null;

                        return Card(
                           color:  const Color.fromARGB(255, 237, 237, 237) ,
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading:
                                imageUrl != null
                                    ? Image.network(
                                      imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                    : Icon(Icons.image_not_supported, size: 60),
                            title: Text(
                              title,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text('\$${price.toString()}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/explore',
                                  arguments: productId,
                                );
                              },
                              child: Text('Explore'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;

  const InfoTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: iconColor ?? Colors.black),
      label: Text("$title: $value", style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }
}

class BoolButton extends StatelessWidget {
  final String label;
  final dynamic value;

  const BoolButton({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isYes = value == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isYes ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: ${isYes ? 'Yes' : 'No'}",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

