import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/Components/MyAppBar.dart';
import 'package:project/Components/MyBottomBar.dart';

class TrackingOrder extends StatefulWidget {
  const TrackingOrder({Key? key}) : super(key: key);

  @override
  _TrackingOrderState createState() => _TrackingOrderState();
}

class _TrackingOrderState extends State<TrackingOrder> {
  bool isLoading = false;
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  int selectedFilterIndex = 1;
  String? userName = 'Guest';

  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFF8F8F8);

  final List<String> filters = ['All', 'Pending', 'Delivered'];

  @override
  void initState() {
    super.initState();
    fetchOrdersByUserId();
  }

  Future<void> fetchOrdersByUserId() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('Orders')
        .where('userId', isEqualTo: user.uid)
        .get();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    allOrders = ordersSnapshot.docs.map((doc) => doc.data()).toList();
    userName = userDoc.exists ? userDoc['UserName'] : 'Unknown';


    applyFilter();
    setState(() => isLoading = false);
  }

  void applyFilter() {
    setState(() {
      if (selectedFilterIndex == 0) {
        filteredOrders = allOrders;
      } else if (selectedFilterIndex == 1) {
        filteredOrders = allOrders.where((order) {
          final status = order['orderStatus']?.toLowerCase();
          return status == 'pending' || status == 'shipped';
        }).toList();
      } else if (selectedFilterIndex == 2) {
        filteredOrders = allOrders.where((order) =>
            order['orderStatus']?.toLowerCase() == 'delivered').toList();
      }
    });
  }

  Widget buildStatusBar(String status) {
    const stages = ['Pending', 'Shipped', 'Delivered'];
    int activeIndex = stages.indexWhere((s) => s.toLowerCase() == status.toLowerCase());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(stages.length, (index) {
        final isActive = index <= activeIndex;
        return Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isActive ? primaryColor : Colors.grey[300],
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              stages[index],
              style: TextStyle(
                fontSize: 12,
                color: isActive ? primaryColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget buildFilterChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(filters.length, (index) {
        final isSelected = selectedFilterIndex == index;
        return ChoiceChip(
          label: Text(filters[index]),
          selected: isSelected,
          selectedColor: primaryColor,
          backgroundColor: Colors.grey[300],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          onSelected: (_) {
            selectedFilterIndex = index;
            applyFilter();
          },
        );
      }),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: backgroundColor,
    appBar: MyAppBar(),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ✅ FULL-WIDTH BANNER (hero.gif)
              Padding(
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      'assets/images/track.gif',
                      fit: BoxFit.contain, // or cover/fill based on preference
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              buildFilterChips(),
              const SizedBox(height: 12),

              /// ✅ ORDER LIST
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(child: Text("No orders found."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final Timestamp? orderTimestamp = order['orderDate'];
                          final formattedOrderDate = orderTimestamp != null
                              ? DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(orderTimestamp.toDate())
                              : 'Unknown';

                          final products = List.from(order['products'] ?? []);
                          final shipping = order['shipping'];
                          final courier = order['courier'];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order #${index + 1}",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Date: $formattedOrderDate"),
                                  Text("Status: ${order['orderStatus']}",
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 16),
                                  buildStatusBar(order['orderStatus']),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const Text("Shipping Info",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text("📍 ${shipping['address']}"),
                                  Text("📞 ${shipping['contactno']}"),
                                  const SizedBox(height: 10),
                                  const Text("Courier",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "🏢 Agent: ${courier['agentName'] ?? 'N/A'}"),
                                  const SizedBox(height: 10),
                                  const Text("Items",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  ...products.map((p) {
                                    final image = (p['images'] ?? []).isNotEmpty
                                        ? p['images'][0]
                                        : null;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: image != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                image,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.image,
                                              color: Colors.grey),
                                      title:
                                          Text(p['title'] ?? 'Product Name'),
                                      subtitle: Text(
                                          "Qty: ${p['quantity']} | PKR ${p['price']}"),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 8),
                                  Text("💳 Payment: ${order['paymentMethod']}"),
                                  Text(
                                    "💰 Total: PKR ${order['totalPrice']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              /// ✅ Bottom Note
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  "Your orders will be delivered minimum 7 days after order date.\nThanks for order — Laptop Harbor.",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
    bottomNavigationBar: MyBottomBar(currentIndex: 1),

    /// ✅ Chat FAB
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


