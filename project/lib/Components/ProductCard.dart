import 'package:another_flushbar/flushbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductCardWidget extends StatefulWidget {
  final DocumentSnapshot productSnapshot;

  const ProductCardWidget({super.key, required this.productSnapshot});

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  int selectedImageIndex = 0;
  int currentPage = 0;
  final int itemsPerPage = 3;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final userId = await getUserIdFromPrefs();
    setState(() {
      isLoggedIn = userId != null;
    });
  }

  Future<String?> getUserIdFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return null;

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

  Future<void> showLoginRequiredFlushbar(BuildContext context) async {
    await Flushbar(
      title: "Login Required",
      message: "Please log in to use this feature.",
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.redAccent,
    ).show(context);
  }

  Future<void> addToWishlist(String productId) async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) {
      await showLoginRequiredFlushbar(context);
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection("Wishlist")
        .doc(userId);
    final doc = await wishlistRef.get();

    if (doc.exists) {
      final List existingProducts = doc.data()?['productIds'] ?? [];

      if (existingProducts.contains(productId)) {
        await Flushbar(
          title: "Already in Wishlist",
          message: "This product is already in your wishlist.",
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
        ).show(context);
        return;
      }

      await wishlistRef.update({
        "productIds": FieldValue.arrayUnion([productId]),
      });
    } else {
      await wishlistRef.set({
        "userId": userId,
        "productIds": [productId],
      });
    }

    await Flushbar(
      title: "Added to Wishlist",
      message: "Product added to your wishlist successfully.",
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  Future<void> addToCart(String productId) async {
    final userId = await getUserIdFromPrefs();
    if (userId == null) {
      await showLoginRequiredFlushbar(context);
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection("Cart").doc(userId);
    final doc = await cartRef.get();

    if (doc.exists) {
      final List existingProducts = doc.data()?['productId'] ?? [];

      if (existingProducts.contains(productId)) {
        await Flushbar(
          title: "Already in Cart",
          message: "This product is already in your cart.",
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
        ).show(context);
        return;
      }

      await cartRef.update({
        "productId": FieldValue.arrayUnion([productId]),
      });
    } else {
      await cartRef.set({
        "userId": userId,
        "productId": [productId],
      });
    }

    await Flushbar(
      title: "Added to Cart",
      message: "Product added to your cart successfully.",
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }
Future<double> fetchAverageRating(String productId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('reviews')
      .where('productId', isEqualTo: productId)
      .get();

  if (snapshot.docs.isEmpty) return 0;

  final ratings = snapshot.docs
      .map((doc) => doc['rating'] as num)
      .toList();

  final average = ratings.reduce((a, b) => a + b) / ratings.length;
  return average.toDouble();
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

  @override
  Widget build(BuildContext context) {
    final product = widget.productSnapshot.data() as Map<String, dynamic>;
    final productId = widget.productSnapshot.id;

    final title = product['title'] ?? 'No Title';
    final price = double.tryParse(product['price'].toString()) ?? 0.0;
    final inStock = product['inStock'] ?? true;
    final List<dynamic> images = product['images'] ?? [];

    List<dynamic> paginatedImages =
        images.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('deals')
              .where('productId', isEqualTo: productId)
              .get(),
      builder: (context, dealSnapshot) {
        final isDeal =
            dealSnapshot.hasData && dealSnapshot.data!.docs.isNotEmpty;
        final deal =
            isDeal
                ? dealSnapshot.data!.docs.first.data() as Map<String, dynamic>
                : null;

        String formattedStart = '';
        String formattedEnd = '';

        if (isDeal && deal?['startDate'] != null && deal?['endDate'] != null) {
          final startDate = (deal!['startDate'] as Timestamp).toDate();
          final endDate = (deal['endDate'] as Timestamp).toDate();
          formattedStart = DateFormat('dd MMM yyyy').format(startDate);
          formattedEnd = DateFormat('dd MMM yyyy').format(endDate);
        }

     return ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 600),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      color: const Color.fromARGB(255, 237, 237, 237),
    ),
    padding: const EdgeInsets.all(5),
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDeal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 234, 30, 53),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${deal?['dealTitle']} - ${deal?['discount']}% OFF',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 2),
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: images[selectedImageIndex],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 14),
                      onPressed: () {
                        setState(() {
                          currentPage--;
                          selectedImageIndex = currentPage * itemsPerPage;
                        });
                      },
                    ),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: paginatedImages.length,
                        itemBuilder: (context, i) {
                          int actualIndex =
                              currentPage * itemsPerPage + i;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImageIndex = actualIndex;
                              });
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedImageIndex == actualIndex
                                      ? const Color.fromARGB(255, 86, 86, 86)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: paginatedImages[i],
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if ((currentPage + 1) * itemsPerPage < images.length)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: () {
                        setState(() {
                          currentPage++;
                          selectedImageIndex = currentPage * itemsPerPage;
                        });
                      },
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
       const SizedBox(height: 4),

FutureBuilder<double>(
  future: fetchAverageRating(productId),
  builder: (context, snapshot) {
    double average = snapshot.data ?? 0;

    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < average.round()
              ? Icons.star
              : Icons.star_border,
          size: 12,
          color: index < average.round()
              ? Colors.amber
              : Colors.grey,
        );
      }),
    );
  },
),

const SizedBox(height: 4),

          isDeal
              ? Row(
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '\$${(price - (price * (deal?['discount'] ?? 0) / 100)).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 234, 30, 53),
                      ),
                    ),
                  ],
                )
              : Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
          const SizedBox(height: 4),
         Row(
  children: [
    if (!inStock)
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            color: Color.fromARGB(255, 234, 30, 53),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    const Spacer(),
IconButton(
  icon: const Icon(Icons.favorite),
  color: const Color.fromARGB(255, 234, 30, 53),
  iconSize: 22,
  onPressed: inStock
      ? () async {
          if (!isLoggedIn) {
            await showLoginRequiredFlushbar(context);
            return;
          }

          final userId = await getUserIdFromPrefs();
          if (userId == null) {
            await showLoginRequiredFlushbar(context);
            return;
          }

          final wishlistDoc = await FirebaseFirestore.instance
              .collection("Wishlist")
              .doc(userId)
              .get();

          final existingWishlistItems = wishlistDoc.exists
              ? List.from(wishlistDoc.data()?['productIds'] ?? [])
              : [];

          if (existingWishlistItems.contains(productId)) {
            await Flushbar(
              title: "Already in Wishlist",
              message: "This product is already in your wishlist.",
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
              margin: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(8),
            ).show(context);
            return;
          }

          final confirm = await showConfirmationDialog(
            context,
            'Add to Wishlist',
            'Are you sure you want to add this item to your wishlist?',
          );

          if (confirm == true) {
            await FirebaseFirestore.instance
                .collection('Wishlist')
                .doc(userId)
                .set({
              'productIds': FieldValue.arrayUnion([productId]),
            }, SetOptions(merge: true));

            await Flushbar(
              title: "Added to Wishlist",
              message: "This product has been added to your wishlist.",
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              margin: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(8),
            ).show(context);
          }
        }
      : null,

// disable if not in stock
    ),
    IconButton(
      icon: const Icon(Icons.shopping_cart),
      color: const Color.fromARGB(255, 234, 30, 53),
      iconSize: 22,
      onPressed: inStock
          ? () async {
              if (!isLoggedIn) {
                await showLoginRequiredFlushbar(context);
                return;
              }

              final confirm = await showConfirmationDialog(
                context,
                'Add to Cart',
                'Are you sure you want to add this item to your cart?',
              );
              if (confirm == true) {
                await addToCart(productId);
              }
            }
          : null, // disable if not in stock
    ),
  ],
),
      

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 83, 155, 105),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/explore', arguments: productId);
            },
            child: const Text(
              'Explore',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          if (isDeal &&
              deal?['startDate'] != null &&
              deal?['endDate'] != null)
            SizedBox(
              height: 18,
              child: Marquee(
                text: 'Deal valid from $formattedStart to $formattedEnd',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                velocity: 25,
                blankSpace: 20,
                pauseAfterRound: const Duration(seconds: 1),
                startPadding: 10,
              ),
            ),
        ],
      ),
    ),
  ),
     );
      },
    );
  }




}

