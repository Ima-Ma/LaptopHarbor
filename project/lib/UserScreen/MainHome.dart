import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/Components/MyAppBar.dart';
import 'package:project/Components/MyBottomBar.dart';
import 'package:marquee/marquee.dart';
import 'package:project/Components/ProductCard.dart';
class MainHome extends StatefulWidget {
  const MainHome({Key? key}) : super(key: key);

  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
   String userName = 'Guest'; 
  int _selectedIndex = 0;

  final Color primaryColor = const Color(0xFF012A2D);
  final Color backgroundColor =Color.fromARGB(255, 255, 255, 255);
List<DocumentSnapshot> products = [];
bool isLoading = true;


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add your navigation or page logic here if needed
  }

@override
void initState() {
  super.initState();
  fetchProducts();
}

Future<void> fetchProducts() async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  setState(() {
    products = snapshot.docs;
    isLoading = false;
  });
}
  Widget build(BuildContext context) {
    return Scaffold(

appBar: MyAppBar(),


      backgroundColor: backgroundColor,
     bottomNavigationBar: MyBottomBar(currentIndex: 0),
     
      body: SafeArea(
        child: SingleChildScrollView(
         child: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

     Padding(
  padding: EdgeInsets.symmetric(horizontal: 2),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: AspectRatio(
      aspectRatio: 16 / 9, // adjust based on your image shape
      child: Image.asset(
        'assets/images/hero.gif',
        fit: BoxFit.contain,
      ),
    ),
  ),
),

      const SizedBox(height: 16),

      /// ✅ HORIZONTAL CARD SCROLLER
      SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...[
              {'image': 'assets/images/two.jpeg', 'text': 'Explore', 'route': '/exploreproduct'},
              {'image': 'assets/images/third.jpeg', 'text': 'Deals', 'route': '/deals'},
              {'image': 'assets/images/forth.jpeg', 'text': 'Customer Support', 'route': '/SupportRequests'},
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, item['route']!);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              item['image']!,
                              width: 160,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Color.fromARGB(75, 254, 236, 208),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item['text']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),

      const SizedBox(height: 16),

      /// ✅ DEAL + SHIPPING SECTION
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'View Latest Deals!',
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/deals');
                      },
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/deal.gif",
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF539b69),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Shipping Services",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Cash on Delivery & Online Payment",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/icon.png',
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

      /// ✅ PRODUCT GRID
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) {
          return ProductCardWidget(productSnapshot: products[index]);
        },
      ),
    ],
  ),
),

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

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
Widget buildBrandCategoryScroll(BuildContext context) {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance.collection('brands').get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No brands available.'));
      }

      final brands = snapshot.data!.docs;

      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: brands.length,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          itemBuilder: (context, index) {
            final doc = brands[index];
            final brandName = doc['BrandName'];
            final base64Image = doc['BrandImage'];
            final imageBytes = base64Decode(base64Image);

            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/userbrands',
                    arguments: doc.id,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                Container(
  width: 70,
  height: 70,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: Color.fromARGB(255, 0, 0, 0), // Border color
      width: 1, // Border thickness
    ),
  ),
  child: CircleAvatar(
    radius: 30,
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    child: ClipOval(
      child: Image.memory(
        imageBytes,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      ),
    ),
  ),
),

                      const SizedBox(height: 6),
                      Text(
                        brandName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
