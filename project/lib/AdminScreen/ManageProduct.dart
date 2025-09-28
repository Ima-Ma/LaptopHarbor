import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project/AdminScreen/AddProductForm.dart';
import 'package:project/AdminScreen/ManageAgentForm.dart';
import 'package:project/AdminScreen/ManageBrandForm.dart';
import 'package:project/AdminScreen/ManageDealsForm.dart';
import 'package:project/AdminScreen/ManageSeriesForm.dart';
import 'package:project/Components/AdminAppBar.dart';
import 'package:project/Components/AdminBottomNav.dart';

class ManageProduct extends StatefulWidget {
  const ManageProduct({Key? key}) : super(key: key);

  @override
  State<ManageProduct> createState() => _ManageProductState();
}

class _ManageProductState extends State<ManageProduct> {
  int _selectedTab = 0;

  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchBrands();
    fetchProducts();
  }

  void fetchBrands() async {
    final snapshot = await FirebaseFirestore.instance.collection('brands').get();
    setState(() {
      brands = snapshot.docs.map((doc) => {
        'id': doc.id,
        'BrandName': doc['BrandName'],
        'BrandImage': doc['BrandImage'],
      }).toList();
    });
  }

  void fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      products = snapshot.docs.map((doc) => {
        'id': doc.id,
        'title': doc['title'],
        'price': doc['price'],
      }).toList();
    });
  }

  Widget buildFilterChip(String label, IconData icon, int index) {
    return SizedBox(
      width: 150, // 🔧 Fixed width for all chips
      child: ChoiceChip(
        showCheckmark: false,
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: _selectedTab == index,
        onSelected: (_) => setState(() => _selectedTab = index),
        selectedColor: Color(0xFF539b69),
        backgroundColor: Color.fromARGB(255, 15, 20, 26),
        labelPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

 Widget buildTopChips() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildFilterChip("Manage Laptops", Icons.laptop, 0),
          SizedBox(width: 12),
          buildFilterChip("Manage Deals", Icons.local_offer, 1),
          SizedBox(width: 12),
          buildFilterChip("Manage Brands", Icons.business, 2),
          SizedBox(width: 12),
          buildFilterChip("Manage Series", Icons.category, 3),
          SizedBox(width: 12),
          buildFilterChip("Manage Agents", Icons.person, 4),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(255, 15, 20, 26),
      appBar: AdminAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            buildTopChips(),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(_selectedTab),
                  padding: EdgeInsets.all(16),
                  child: _selectedTab == 0
                      ? AddProductForm()
                      : _selectedTab == 1
                          ? ManageDealsForm(
                              products: products,
                              refreshProducts: fetchProducts,
                            )
                          : _selectedTab == 2
                              ? ManageBrandForm(refreshBrands: fetchBrands)
                              : _selectedTab == 3
                                  ? ManageSeriesForm(
                                      brands: brands,
                                      refreshBrands: fetchBrands,
                                    )
                                  : ManageAgentForm(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GlassBottomNavBar(selectedIndex: 1),
    );
  }
}
