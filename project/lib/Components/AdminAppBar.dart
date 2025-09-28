import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AdminAppBar({Key? key}) : super(key: key);

  @override
  _AdminAppBarState createState() => _AdminAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _AdminAppBarState extends State<AdminAppBar> {
  int userCount = 0;
  int productCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      final userSnap =
          await FirebaseFirestore.instance.collection('userprofile').get();
      final productSnap =
          await FirebaseFirestore.instance.collection('products').get();

      setState(() {
        userCount = userSnap.docs.length;
        productCount = productSnap.docs.length;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: Menu + Logo
              Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'logout') {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    color: Colors.white,
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Logout',
                                style: TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Image.asset('assets/images/logo.png', height: 60),
                ],
              ),

              // RIGHT: Circle counts
              Row(
                children: [
                  _buildCountCircle(Icons.people, userCount),
                  const SizedBox(width: 12),
                  _buildCountCircle(Icons.shopping_bag, productCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountCircle(IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF539b69),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
