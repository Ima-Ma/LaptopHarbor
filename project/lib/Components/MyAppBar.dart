import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MyAppBar({Key? key}) : super(key: key);

  @override
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _MyAppBarState extends State<MyAppBar> {
  String userName = 'Guest';
  bool isLoggedIn = false;
  final Color primaryColor = Color(0xFF539b69);

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedin');
    String? name = prefs.getString('UserName');

    setState(() {
      isLoggedIn = loggedIn == true;
      userName = name ?? 'Guest';
    });
  }

  void _showLoginRequired(BuildContext context) {
    Flushbar(
      message: "Login required to use this feature.",
      icon: Icon(Icons.lock_outline, color: Colors.white),
      backgroundColor: Colors.redAccent,
      duration: Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  void _openRightWishlistDrawer(BuildContext context) async {
    if (!isLoggedIn) {
      _showLoginRequired(context);
      return;
    }

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
        builder: (_) => AlertDialog(
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
    final productSnapshots = await FirebaseFirestore.instance
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
                        const SizedBox(height: 4),
                        const Text(
                          "Note: This wishlist is powered by Laptop Harbor.",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
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
                              final images = data['images'] ?? [];
                              final imageUrl =
                                  (images is List && images.isNotEmpty)
                                      ? images[0]
                                      : null;
                              final title = data['title'] ?? 'No Title';

                              return ListTile(
                                leading: (imageUrl != null && imageUrl != "")
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 40),
                                title: Text(title),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.deepPurple,
                                      ),
                                      tooltip: "View Details",
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/explore',
                                          arguments: productId,
                                        );
                                      },
                                    ),
                                    IconButton(
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
                                          'productIds': FieldValue.arrayRemove(
                                              [productId]),
                                        });

                                        setState(() {
                                          products.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
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
    return AppBar(
      backgroundColor: Color.fromARGB(0, 137, 58, 72),
      elevation: 2,
      title: Image.asset('assets/images/main.png', height: 70),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: CircleAvatar(
          backgroundColor: primaryColor,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      actions: [
        if (isLoggedIn)
          IconButton(
            tooltip: 'Profile',
            icon: _buildStyledIcon(Icons.person_3_sharp, primaryColor),
            onPressed: () {
              Navigator.pushNamed(context, '/EditProfile');
            },
          ),
        PopupMenuButton<String>(
          tooltip: isLoggedIn ? 'Logout' : 'Account',
          icon: _buildStyledIcon(
            isLoggedIn ? Icons.logout : Icons.login,
            primaryColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: Offset(0, 40),
          color: Colors.white,
          onSelected: (value) async {
            if (value == 'Logout') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            } else if (value == 'Signup') {
              Navigator.pushNamed(context, '/signup');
            } else if (value == 'Login') {
              Navigator.pushNamed(context, '/login');
            }
          },
          itemBuilder: (BuildContext context) => isLoggedIn
              ? [
                  PopupMenuItem<String>(
                    value: 'Logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Text('Logout', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ]
              : [
                  PopupMenuItem<String>(
                    value: 'Signup',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1,
                            color: Colors.deepOrange, size: 20),
                        SizedBox(width: 10),
                        Text('Signup',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Login',
                    child: Row(
                      children: [
                        Icon(Icons.login, color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Text('Login',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
        ),
        IconButton(
          tooltip: 'Cart',
          icon: _buildStyledIcon(Icons.shopping_cart_rounded, primaryColor),
          onPressed: () {
            if (!isLoggedIn) {
              _showLoginRequired(context);
            } else {
              Navigator.pushNamed(context, '/Cart');
            }
          },
        ),
        IconButton(
          tooltip: 'Wishlist',
          icon: _buildStyledIcon(Icons.favorite, primaryColor),
          onPressed: () => _openRightWishlistDrawer(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

Widget _buildStyledIcon(IconData icon, Color color) {
  return Container(
    padding: EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          blurRadius: 4,
          offset: Offset(2, 2),
        ),
      ],
    ),
    child: Icon(icon, color: color, size: 24),
  );
}

