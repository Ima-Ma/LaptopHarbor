import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Userbrands extends StatefulWidget {
  const Userbrands({Key? key}) : super(key: key);

  @override
  _UserbrandsState createState() => _UserbrandsState();
}

class _UserbrandsState extends State<Userbrands> {
  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFf2f2f2);

  late String brandId;
  String brandName = "";
  String brandImageBase64 = "";
  bool isBrandLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg != null && arg is String) {
      brandId = arg;
      _getBrandDetails();
    }
  }

  Future<void> _getBrandDetails() async {
    final doc = await FirebaseFirestore.instance.collection('brands').doc(brandId).get();
    if (doc.exists) {
      setState(() {
        brandName = doc['BrandName'] ?? 'This Brand';
        brandImageBase64 = doc['BrandImage'] ?? '';
        isBrandLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/main.png',
          height: 60,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
   body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBrandLoaded)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: brandImageBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(brandImageBase64),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 80),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brandName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Laptop Harbor is your trusted destination for premium tech gear. '
                      'Explore our exclusive collection of laptops and accessories, '
                      'featuring brands known for innovation, quality, and performance.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // ✅ Product List - Now scrolls properly
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('brandId', isEqualTo: brandId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No products found.'));
            }

            final products = snapshot.data!.docs;

            return GridView.builder(
              itemCount: products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: MediaQuery.of(context).size.width > 400 ? 0.75 : 0.68,
),

           itemBuilder: (context, index) {
  final product = products[index];
  final title = product['title'] ?? 'No title';
  final price = product['price']?.toString() ?? '0';
  final imageList = product['images'] as List<dynamic>? ?? [];
  final imageUrl = imageList.isNotEmpty ? imageList[0] : '';

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported, size: 100),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "Rs $price",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/explore',
                  arguments: product.id,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Explore", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}

            );
          },
        ),

        const SizedBox(height: 24),

        // ✅ Bottom Info Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Text(
            'Explore More from "$brandName" – Discover Top Picks & Unique Finds!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
),


    );
  }
}
