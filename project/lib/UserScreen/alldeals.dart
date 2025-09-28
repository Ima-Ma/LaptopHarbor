import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Alldeals extends StatefulWidget {
  const Alldeals({Key? key}) : super(key: key);

  @override
  _AlldealsState createState() => _AlldealsState();
}

class _AlldealsState extends State<Alldeals> {
  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFf2f2f2);

  Future<List<Map<String, dynamic>>> fetchDealsWithProducts() async {
    final dealsSnapshot = await FirebaseFirestore.instance.collection('deals').get();
    List<Map<String, dynamic>> combinedList = [];

    for (var dealDoc in dealsSnapshot.docs) {
      final dealData = dealDoc.data();
      final productId = dealData['productId'];
      final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();

      if (productSnapshot.exists) {
        final productData = productSnapshot.data();
        if (productData != null) {
          combinedList.add({
            'deal': dealData,
            'product': productData,
            'productId': productSnapshot.id,
          });
        }
      }
    }

    return combinedList;
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/deals.gif',
                width: double.infinity,
                fit: BoxFit.cover,
                height: 180,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchDealsWithProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No deals found"));
                  }

                  final dealsWithProducts = snapshot.data!;

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: dealsWithProducts.length,
                    itemBuilder: (context, index) {
                      final deal = dealsWithProducts[index]['deal'];
                      final product = dealsWithProducts[index]['product'];
                      final productDocId = dealsWithProducts[index]['productId'];
                      final discount = deal['discount'] ?? 0;
                      final originalPrice = product['price'] ?? 0.0;
                      final discountedPrice = originalPrice - (originalPrice * discount / 100);

                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image.network(
                                product['images'][0],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deal['dealTitle'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          "\₨${originalPrice.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "\₨${discountedPrice.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Discount: $discount%",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const Spacer(),
                                    Center(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: primaryColor,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/explore',
                                            arguments: productDocId,
                                          );
                                        },
                                        child: const Text("Explore", style: TextStyle(fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
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
      ),
    );
  }
}
