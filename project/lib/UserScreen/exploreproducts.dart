import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/Components/MyAppBar.dart';
import 'package:project/Components/MyBottomBar.dart';

class ExploreProductsPage extends StatefulWidget {
  const ExploreProductsPage({Key? key}) : super(key: key);

  @override
  State<ExploreProductsPage> createState() => _ExploreProductsPageState();
}

class _ExploreProductsPageState extends State<ExploreProductsPage> {
  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFF2F2F2);

  String? selectedBrand;
  String? selectedCategory;
  String? selectedLaptopType;

  Future<Map<String, String>> _loadMap(String collection, String fieldName) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    return {for (var doc in snapshot.docs) doc.id: doc[fieldName]};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _loadMap('brands', 'BrandName'),
        _loadMap('category', 'categoryname'),
        _loadMap('LaptopType', 'TypeName'),
      ]),
      builder: (context, AsyncSnapshot<List<Map<String, String>>> snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final brandMap = snap.data![0];
        final categoryMap = snap.data![1];
        final typeMap = snap.data![2];

        return Scaffold(
          backgroundColor: backgroundColor,
                        floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.pushNamed(context, '/chat');
  },
  backgroundColor:backgroundColor,
  
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
  bottomNavigationBar: MyBottomBar(currentIndex: 4),
         appBar: MyAppBar(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Use the filters above to narrow down your product search. "
                        "You can browse by brand, category, or laptop type. "
                        "Combining filters will give you the most relevant results based on your preferences.",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10,),
      buildBrandCategoryScroll(context),


              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterDropdown('Brand', brandMap, selectedBrand,
                        (v) => setState(() => selectedBrand = v)),
                    const SizedBox(width: 8),
                    _buildFilterDropdown('Category', categoryMap, selectedCategory,
                        (v) => setState(() => selectedCategory = v)),
                    const SizedBox(width: 8),
                    _buildFilterDropdown('Laptop Type', typeMap, selectedLaptopType,
                        (v) => setState(() => selectedLaptopType = v)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .whereIf(selectedBrand != null && selectedBrand!.isNotEmpty,
                          'brandId', isEqualTo: selectedBrand)
                      .whereIf(selectedCategory != null && selectedCategory!.isNotEmpty,
                          'categoryId', isEqualTo: selectedCategory)
                      .whereIf(selectedLaptopType != null && selectedLaptopType!.isNotEmpty,
                          'laptopTypeId', isEqualTo: selectedLaptopType)
                      .snapshots(),
                  builder: (context, prodSnap) {
                    if (prodSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!prodSnap.hasData || prodSnap.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No product of selected filter.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
                    }

                    final docs = prodSnap.data!.docs;

                    return GridView.builder(
                      padding: const EdgeInsets.all(6),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final images = List<String>.from(data['images'] ?? []);
                        final price = data['price'];
                        final inStock = data['inStock'] ?? false;

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color:  Color.fromARGB(255, 237, 237, 237)   ,
                           
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(3),
                                    child: Icon(Icons.devices, size: 20, color: Colors.black54),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 120,
                                child: PageView.builder(
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: images[index],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['title'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('PKR ${price.toString()}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor)),
                                    const SizedBox(height: 2),
                                    if (!inStock)
                                      Text('Out of stock',
                                          style: TextStyle(
                                              color: Colors.red.shade700)),
                                    const SizedBox(height: 2),
                                    if (inStock)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, '/explore',
                                                arguments: docs[i].id);
                                          },
                                          child: const Text('Explore',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(
    String label,
    Map<String, String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    final updatedOptions = {
      '': 'All $label', // Default option with empty key
      ...options,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color(0xFF539b69),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected ?? '',
          items: updatedOptions.entries
              .map((entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ))
              .toList(),
               style: const TextStyle(color: Colors.white),
          onChanged: (value) => onChanged(value == '' ? null : value),
          dropdownColor: Colors.black,
          iconEnabledColor: Colors.white,
        ),
      ),
    );
  }
}

// Extension for conditional filtering
extension QueryExtensions on Query {
  Query whereIf(bool condition, String field, {required dynamic isEqualTo}) {
    return condition ? where(field, isEqualTo: isEqualTo) : this;
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
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Column(
                    children: [
                Container(
  width: 70,
  height: 70,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
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

