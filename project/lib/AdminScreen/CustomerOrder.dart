// Same imports
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emailjs/emailjs.dart' as EmailJS;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project/Components/AdminAppBar.dart';
import 'package:project/Components/AdminBottomNav.dart';
import 'package:project/Components/generateInvoice.dart';

class CustomerOrder extends StatefulWidget {
  const CustomerOrder({Key? key}) : super(key: key);

  @override
  _CustomerOrderState createState() => _CustomerOrderState();
}

class _CustomerOrderState extends State<CustomerOrder> {
  final orders = FirebaseFirestore.instance.collection('Orders');
  final users = FirebaseFirestore.instance.collection('users');
  String selectedStatus = 'All';

  Future<Map<String, String>> getUserInfo(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final userName = data['UserName'] ?? 'No Name';
        final email = data['email'] ?? 'No Email';
        return {'UserName': userName, 'email': email};
      } else {
        return {'UserName': 'Unknown User', 'email': 'Unknown Email'};
      }
    } catch (e) {
      return {'UserName': 'Unknown User', 'email': 'Unknown Email'};
    }
  }

Future<void> sendEmail(String userEmail, String userName, String messageText) async {
  const serviceId = 'service_sqqbo27';
  const templateId = 'template_qykt9uu'; // Same template
  const publicKey = 'PyM--VQkH272v8PFI';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'name': userName,
        'email': userEmail,
        'message': messageText,
        'time': DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now()),
        'year': DateTime.now().year.toString(),
          'headerTitle': messageText == 'Your order has been shipped!' 
      ? '📦 Your Order is on the Way!' 
      : '✅ Your Order Has Been Delivered!',
  'headerSubtext': 'From LaptopHarbor',
      },
    }),
  );

  if (response.statusCode == 200) {
    debugPrint('✅ Email sent to $userEmail');
  } else {
    debugPrint('❌ Failed to send email: ${response.body}');
  }
}

void updateStatus(String orderId, String newStatus, String userEmail, String userName) async {
  await orders.doc(orderId).update({'orderStatus': newStatus});

  if (newStatus == "Shipped") {
    await sendEmail(userEmail, userName, 'Your order has been shipped!');
    showSuccessDialog(context);
  } else if (newStatus == "Delivered") {
    await sendEmail(userEmail, userName, 'Your order has been delivered!');
    showSuccessDialog(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Order status updated to $newStatus'),
      backgroundColor: Colors.green,
    ));
  }
}


  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            height: 250,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, size: 35, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text("Success", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Order Status Has Been Sent!", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Okay", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        );
      },
    );
  }
//Confirmation dialog box deliverd
Future<void> showDeliveryConfirmationDialog({
  required BuildContext context,
  required String orderId,
  required String userEmail,
  required String userName,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        backgroundColor: const Color.fromARGB(255, 15, 20, 26),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all, size: 60, color: Color(0xFF539b69)),
              const SizedBox(height: 15),
              const Text(
                "Mark as Delivered?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to mark this order as 'Delivered' and notify the customer via email?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF539b69),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop(); // Close dialog
                      updateStatus(orderId, "Delivered", userEmail, userName); // Update status
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text("Confirm", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

//end
  // ✅ Added confirmation dialog here

Future<void> showConfirmationDialog({
  required BuildContext context,
  required String orderId,
  required String userEmail,
  required String userName,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        backgroundColor: Color.fromARGB(255, 15, 20, 26),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.85,
           decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(2),
      
      ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping_rounded, size: 60, color: Color(0xFF539b69)),
              const SizedBox(height: 15),
              const Text(
                "Mark as Shipped?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to mark this order as 'Shipped' and send a confirmation email to the customer?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text("Cancel", style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF539b69),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop(); // Close dialog
                      updateStatus(orderId, "Shipped", userEmail, userName); // Update order
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text("Confirm", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  List<DocumentSnapshot> filterOrders(List<DocumentSnapshot> orders) {
    if (selectedStatus == 'All') return orders;
    return orders.where((doc) => doc['orderStatus'] == selectedStatus).toList();
  }
Widget buildFilterChip(String label, IconData icon) {
  final isSelected = selectedStatus == label;

  return Padding(
    padding: const EdgeInsets.all(0),
    child: SizedBox(
      width: 130, // 👈 Adjust width as needed
      child: ChoiceChip(
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        label: Text(
          label,
          style: GoogleFonts.merriweather(
            textStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => selectedStatus = label),
        selectedColor: const Color(0xFF539b69),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF539b69) : Colors.grey.shade300,
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        visualDensity: VisualDensity.compact,
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    extendBody: true,
    extendBodyBehindAppBar: true, // Transparent AppBar effect
    backgroundColor: const Color.fromARGB(255, 15, 20, 26),

    appBar: AdminAppBar(), // Custom Admin AppBar

    bottomNavigationBar: GlassBottomNavBar(selectedIndex: 2), // Bottom Glass Navbar

    body: Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 20, 26), // Background color
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: orders.orderBy('orderDate', descending: true).snapshots(), // Listen to order collection
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading orders', style: TextStyle(color: Colors.white)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final orderDocs = filterOrders(snapshot.data!.docs); // Filtered orders by selected status

            return Column(
              children: [
                // Horizontal scroll filter chips (All, Pending, etc.)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      buildFilterChip("All", Icons.list_alt),
                      buildFilterChip("Pending", Icons.pending_actions),
                      buildFilterChip("Shipped", Icons.local_shipping),
                      buildFilterChip("Delivered", Icons.verified),
                    ],
                  ),
                ),

                // Show message if no orders found
                if (orderDocs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No orders found for this filter",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                else
               Expanded(
  child: ListView.builder(
    padding: const EdgeInsets.only(bottom: 90, top: 8),
    itemCount: orderDocs.length,
    itemBuilder: (context, index) {
      final order = orderDocs[index];
      final orderId = order.id;
      final userId = order['userId'];
      final totalPrice = order['totalPrice'];
      final orderDate = order['orderDate'];
      final formattedOrderDate = DateFormat('dd-MMM-yyyy hh:mm a').format(orderDate.toDate());
      final orderStatus = order['orderStatus'];
      final paymentMethod = order['paymentMethod'];
      final courier = order['courier'];
      final shipping = order['shipping'];
      final products = List.from(order['products'] ?? []);

      return FutureBuilder<Map<String, String>>(
        future: getUserInfo(userId),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data ?? {
            'UserName': 'Loading...',
            'email': 'Loading...',
          };

         return Padding(
  padding: const EdgeInsets.all(8.0),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ---------- First Row ----------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Order + Courier + Shipping Info)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order Summary",
                      style: GoogleFonts.merriweather(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.person, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("Customer: ${userData['UserName']}",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                  Row(children: [
                    const Icon(Icons.email_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("Email: ${userData['email']}",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                  Row(children: [
                    const Icon(Icons.monetization_on_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("Total: Rs. $totalPrice",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("Date: $formattedOrderDate",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                  Row(children: [
                    const Icon(Icons.verified_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("Status: $orderStatus",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                  Row(children: [
                    const Icon(Icons.credit_card, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text("Payment: $paymentMethod",
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.local_shipping_outlined,
                        color: Color(0xFF539b69), size: 16),
                    const SizedBox(width: 4),
                    Text("Courier Info",
                        style: GoogleFonts.merriweather(fontSize: 18, color: Colors.white)),
                  ]),
                  const SizedBox(height: 4),
                  Text("Agent Name: ${courier['agentName']}",
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.home_outlined, color:  Color(0xFF539b69), size: 16),
                    const SizedBox(width: 4),
                    Text("Shipping Info",
                        style: GoogleFonts.merriweather(fontSize: 18, color: Colors.white)),
                  ]),
                  const SizedBox(height: 4),
                  Text("Address: ${shipping['address']}",
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  Text("Contact: ${shipping['contactno']}",
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Right Column (Buttons)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pending_actions, color: Colors.white),
                    label: const Text("Pending", style: TextStyle(color: Colors.white)),
                    onPressed: (orderStatus == "Pending" || orderStatus == "Shipped" || orderStatus == "Delivered")
                        ? null
                        : () => updateStatus(orderId, "Pending", userData['email']!, userData['UserName']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 234, 30, 53),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.local_shipping, color: Colors.white),
                    label: const Text("Shipped", style: TextStyle(color: Colors.white)),
                onPressed: orderStatus == "Pending"
    ? () => showConfirmationDialog(
        context: context,
        orderId: orderId,
        userEmail: userData['email']!,
        userName: userData['UserName']!,
      )
    : null,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(156, 83, 155, 105),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    label: const Text("Delivered", style: TextStyle(color: Colors.white)),
onPressed: orderStatus == "Shipped"
  ? () => showDeliveryConfirmationDialog(
      context: context,
      orderId: orderId,
      userEmail: userData['email']!,
      userName: userData['UserName']!,
    )
  : null,


                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF539b69),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(height: 24, color: Colors.white24),

        /// ---------- Second Row ----------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Products List (80%)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text("Products",
                        style: GoogleFonts.merriweather(fontSize: 18, color: Colors.white)),
                  ]),
                  const SizedBox(height: 8),
                  ...products.map<Widget>((product) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.laptop) ,
                      title: Text(product['title'],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "Qty: ${product['quantity']} | PKR ${product['price']}",
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Invoice Button (20%)
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.topRight,
                child: ElevatedButton.icon(
                 onPressed: () {
                    generateInvoice(
                      context: context,
                      userData: userData,
                      products: products,
                      courier: courier,
                      shipping: shipping,
                      totalPrice: totalPrice,
                      orderStatus: orderStatus,
                      paymentMethod: paymentMethod,
                      formattedOrderDate: formattedOrderDate,
                    );
                  },

                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                  label: const Text("Invoice", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 234, 30, 53),
                    minimumSize: const Size(double.infinity, 40),
                  ),
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
)

              ],
            );
          },
        ),
      ),
    ),
  );
}

}
