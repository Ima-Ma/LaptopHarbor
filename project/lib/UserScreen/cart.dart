import 'dart:convert';
import 'dart:math';
// import 'dart:ui' as html;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  void openStripeCheckout() {
    const stripeLink = 'https://buy.stripe.com/test_aFa8wQf4c5oLgJf0hQcQU00';
    html.window.open(stripeLink, '_blank'); // Open in new tab
  }

  //Create Controller
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String selectedPayment = '';
  bool isProfileComplete = true;

  //End Controller

  //Fetch UserProfile Func Create
  Future<void> fetchUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return;

    final userSnapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: email)
            .get();

    if (userSnapshot.docs.isNotEmpty) {
      final userId = userSnapshot.docs.first.id;

      final snapshot =
          await FirebaseFirestore.instance
              .collection("userprofile")
              .where("UserId", isEqualTo: userId)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final userProfile = snapshot.docs.first.data();
        addressController.text = userProfile['address'] ?? '';
        contactController.text = userProfile['phonenumber'] ?? '';
        setState(() {
          isProfileComplete = true;
        });
      } else {
        setState(() {
          isProfileComplete = false;
        });
      }
    }
  }

  //End Func

  //OrderModal Func Start
  void showCartOrderModal(double totalAmount) async {
    await fetchUserProfile();

    bool isInfoFilled =
        addressController.text.isNotEmpty && contactController.text.isNotEmpty;

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
                    if (!isInfoFilled) ...[
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: "Address",
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contactController,
                        decoration: InputDecoration(
                          labelText: "Contact No",
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.orange),
                          const SizedBox(width: 10),
                          Text(
                            "Total: PKR ${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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

                        Navigator.pop(context);
                        placeCartOrder(totalAmount);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Confirm Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
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

  //OrderModal Func End
  //PlaceOrder Func Start
  Future<void> placeCartOrder(double totalAmount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return;

    final userSnapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: email)
            .get();

    if (userSnapshot.docs.isEmpty) return;

    final userId = userSnapshot.docs.first.id;

    // ✅ Ensure user profile exists
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

    // ✅ Fetch All Agents and Pick Random One
    Map<String, dynamic> courierMap = {"agentName": "Unknown"};
    final agentSnapshot =
        await FirebaseFirestore.instance.collection("Agent").get();

    if (agentSnapshot.docs.isNotEmpty) {
      final randomIndex = Random().nextInt(agentSnapshot.docs.length);
      final agentDoc = agentSnapshot.docs[randomIndex];
      courierMap = {"agentName": agentDoc['AgentName'] ?? "CourierX"};
    }

    // ✅ Prepare product list
    final List<Map<String, dynamic>> products =
        cartItems.map((item) {
          final Map<String, dynamic> productData = {
            "title": item['title'],
            "productId": item['productId'],
            "image": item['image'],
            "price": item['hasDeal'] ? item['discountPrice'] : item['price'],
            "quantity": item['quantity'],
          };

          if (item['hasDeal']) {
            productData['deal'] = {
              "dealTitle": item['dealTitle'] ?? "",
              "startDate": item['startDate'] ?? "",
              "endDate": item['endDate'] ?? "",
              "discountedPrice": item['discountPrice'],
              "originalPrice": item['price'],
            };
          }

          return productData;
        }).toList();

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your cart is empty! Cannot place order."),
        ),
      );
      return;
    }

    // ✅ Add order
    await FirebaseFirestore.instance.collection("Orders").add({
      "userId": userId,
      "orderDate": Timestamp.now(),
      "orderStatus": "Pending",
      "paymentMethod": selectedPayment,
      "courier": courierMap,
      "shipping": {
        "address": addressController.text.trim(),
        "contactno": contactController.text.trim(),
      },
      "products": products,
      "totalPrice": totalAmount,
    });

    // ✅ Clear Cart
    final userProfileSnap =
        await FirebaseFirestore.instance
            .collection("userprofile")
            .where("UserId", isEqualTo: userId)
            .limit(1)
            .get();

    if (userProfileSnap.docs.isNotEmpty) {
      final userProfileId = userProfileSnap.docs.first.id;

      final cartSnap =
          await FirebaseFirestore.instance
              .collection("Cart")
              .where("userId", isEqualTo: userProfileId)
              .get();

      for (var doc in cartSnap.docs) {
        await doc.reference.delete();
      }
    }

    // ✅ Clear local cart state
    setState(() {
      cartItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order placed and cart cleared!")),
    );
  }

  //PlaceOrder Func End
  String? email;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  String userName = 'Guest';
  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFf2f2f2);

  @override
  void initState() {
    super.initState();
    loadCartData();
  }

  Future<void> loadCartData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');

    if (email != null) {
      final userSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (userSnap.docs.isNotEmpty) {
        final userDocId = userSnap.docs.first.id;
        userName = userSnap.docs.first.data()['name'] ?? 'Guest';

        final profileSnap =
            await FirebaseFirestore.instance
                .collection('userprofile')
                .where('UserId', isEqualTo: userDocId)
                .limit(1)
                .get();

        if (profileSnap.docs.isNotEmpty) {
          final userProfileDocId = profileSnap.docs.first.id;

          final cartSnap =
              await FirebaseFirestore.instance
                  .collection('Cart')
                  .where('userId', isEqualTo: userProfileDocId)
                  .get();

          List<Map<String, dynamic>> tempCart = [];

          for (var cartDoc in cartSnap.docs) {
            List<dynamic> productIds = cartDoc['productId'];

            for (var pid in productIds) {
              if (pid == null || pid.toString().isEmpty) continue;

              var productSnap =
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(pid)
                      .get();

              if (!productSnap.exists) continue;

              var productData = productSnap.data()!;
              String title = productData['title'];
              double price =
                  double.tryParse(productData['price'].toString()) ?? 0.0;
              String imageUrl =
                  (productData['images'] as List).isNotEmpty
                      ? productData['images'][0]
                      : "";

              // Deal handling
              final dealSnap =
                  await FirebaseFirestore.instance
                      .collection('deals')
                      .where('productId', isEqualTo: pid)
                      .limit(1)
                      .get();

              bool hasDeal = false;
              double discountPrice = price;
              String? dealTitle, startDate, endDate;

              if (dealSnap.docs.isNotEmpty) {
                final deal = dealSnap.docs.first.data();

                final DateTime now = DateTime.now();
                final DateTime sDate =
                    (deal['startDate'] as Timestamp).toDate();
                final DateTime eDate = (deal['endDate'] as Timestamp).toDate();

                if (now.isAfter(sDate) && now.isBefore(eDate)) {
                  hasDeal = true;

                  double discount =
                      double.tryParse(deal['discount'].toString()) ?? 0.0;
                  discountPrice = price - (price * discount / 100);

                  dealTitle = deal['dealTitle'];
                  startDate = sDate.toIso8601String();
                  endDate = eDate.toIso8601String();
                }
              }

              tempCart.add({
                'title': title,
                'price': price,
                'image': imageUrl,
                'productId': pid,
                'hasDeal': hasDeal,
                'discountPrice': discountPrice,
                'dealTitle': dealTitle,
                'startDate': startDate,
                'endDate': endDate,
                'quantity': 1,
              });
            }
          }

          setState(() {
            cartItems = tempCart;
            isLoading = false;
          });
        }
      }
    }
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (var item in cartItems) {
      double price = 0.0;

      try {
        price =
            (item['hasDeal'] == true)
                ? double.tryParse(item['discountPrice'].toString()) ?? 0.0
                : double.tryParse(item['price'].toString()) ?? 0.0;
      } catch (e) {
        price = 0.0;
      }

      subtotal += price * (item['quantity'] ?? 1);
    }
    return subtotal;
  }

  void updateQuantity(int index, int change) {
    setState(() {
      cartItems[index]['quantity'] += change;
      if (cartItems[index]['quantity'] < 1) {
        cartItems[index]['quantity'] = 1;
      }
    });
  }

  void _openRightWishlistDrawer(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('Wishlist').doc(uid).get();
    final data = snapshot.data();

    if (data == null ||
        data['productIds'] == null ||
        (data['productIds'] as List).isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              content: const Text("Your wishlist is empty 😔"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
      );
      return;
    }

    final productIds = List<String>.from(data['productIds']);
    final productSnapshots =
        await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: productIds)
            .get();

    final products = productSnapshots.docs;

    showGeneralDialog(
      context: context,
      barrierLabel: "Wishlist",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "My Wishlist",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final data =
                                  product.data() as Map<String, dynamic>;
                              final productId = product.id;
                              final imageBase64 = data['image'];
                              final title = data['title'] ?? 'No Title';

                              return ListTile(
                                leading:
                                    (imageBase64 != null && imageBase64 != "")
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.memory(
                                            base64Decode(
                                              imageBase64.replaceAll(
                                                RegExp(
                                                  r'data:image/[^;]+;base64,',
                                                ),
                                                '',
                                              ),
                                            ),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => const Icon(
                                                  Icons.broken_image,
                                                ),
                                          ),
                                        )
                                        : const Icon(Icons.image, size: 40),
                                title: Text(title),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: "Remove from wishlist",
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('Wishlist')
                                        .doc(uid)
                                        .update({
                                          'productIds': FieldValue.arrayRemove([
                                            productId,
                                          ]),
                                        });

                                    setState(() {
                                      products.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        );
      },
    );
  }

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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty 🛒"))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      
                      padding: const EdgeInsets.all(16),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final spec =
                            item['specification'] as Map<String, dynamic>? ??
                            {};
                        bool isExpanded = item['isExpanded'] ?? false;

                        return StatefulBuilder(
                          builder: (context, setInnerState) {
                            return Card(
                              color: Color.fromARGB(255, 237, 237, 237)    ,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image + Title + Price + Quantity
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          child: Image.network(
                                            item['image'],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (item['hasDeal']) ...[
                                                Text(
                                                  "PKR ${item['discountPrice'].toStringAsFixed(2)} (Deal)",
                                                  style: TextStyle(
                                                    color:
                                                        Colors.green.shade800,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "Was PKR ${item['price'].toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    decoration:
                                                        TextDecoration
                                                            .lineThrough,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ] else
                                                Text(
                                                  "PKR ${item['price'].toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed:
                                                  () =>
                                                      updateQuantity(index, 1),
                                            ),
                                            Text(
                                              item['quantity'].toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  () =>
                                                      updateQuantity(index, -1),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              tooltip: "Remove from cart",
                                              onPressed: () async {
                                                final productId =
                                                    item['productId'];

                                                // Remove from Firestore
                                                final userSnap =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .where(
                                                          'email',
                                                          isEqualTo: email,
                                                        )
                                                        .limit(1)
                                                        .get();

                                                if (userSnap.docs.isNotEmpty) {
                                                  final userId =
                                                      userSnap.docs.first.id;

                                                  final profileSnap =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                            'userprofile',
                                                          )
                                                          .where(
                                                            'UserId',
                                                            isEqualTo: userId,
                                                          )
                                                          .limit(1)
                                                          .get();

                                                  if (profileSnap
                                                      .docs
                                                      .isNotEmpty) {
                                                    final cartDoc =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('Cart')
                                                            .where(
                                                              'userId',
                                                              isEqualTo:
                                                                  profileSnap
                                                                      .docs
                                                                      .first
                                                                      .id,
                                                            )
                                                            .limit(1)
                                                            .get();

                                                    if (cartDoc
                                                        .docs
                                                        .isNotEmpty) {
                                                      final cartRef =
                                                          cartDoc
                                                              .docs
                                                              .first
                                                              .reference;
                                                      await cartRef.update({
                                                        'productId':
                                                            FieldValue.arrayRemove(
                                                              [productId],
                                                            ),
                                                      });
                                                    }
                                                  }
                                                }

                                                // Remove from local state
                                                setState(() {
                                                  cartItems.removeAt(index);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Buttons: View
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/explore',
                                              arguments: item['productId'],
                                            );
                                          },
                                          icon: const Icon(Icons.visibility),
                                          label: const Text("View Product"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Checkout Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Checkout Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal"),
                            Text(
                              "PKR ${_calculateSubtotal().toStringAsFixed(2)}",
                            ),
                          ],
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text("Shipping"), Text("200.00 PKR")],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "PKR ${(_calculateSubtotal() + 200).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              double total = _calculateSubtotal() + 200;
                              showCartOrderModal(total);
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF539b69),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Proceed to Checkout",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
