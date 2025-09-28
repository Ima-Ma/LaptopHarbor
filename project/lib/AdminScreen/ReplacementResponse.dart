import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:project/Components/AdminAppBar.dart';
import 'package:project/Components/AdminBottomNav.dart';

class ReplacementResponse extends StatefulWidget {
  const ReplacementResponse({Key? key}) : super(key: key);

  @override
  _ReplacementResponseState createState() => _ReplacementResponseState();
}

class _ReplacementResponseState extends State<ReplacementResponse> {
  final replacementRef = FirebaseFirestore.instance.collection('replacement');
  String selectedFilter = 'All';

  Future<Map<String, String>> getUserInfo(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final profileDoc = await FirebaseFirestore.instance
          .collection('userprofile')
          .doc(userId)
          .get();

      final userData = userDoc.data() ?? {};
      final profileData = profileDoc.data() ?? {};

      return {
        'UserName': userData['UserName'] ?? 'No Name',
        'email': userData['email'] ?? 'No Email',
        'phonenumber': profileData['phonenumber'] ?? 'No Phone',
        'address': profileData['address'] ?? 'No Address',
      };
    } catch (e) {
      return {
        'UserName': 'Error',
        'email': 'Error',
        'phonenumber': 'Error',
        'address': 'Error',
      };
    }
  }

  Future<void> sendEmailReplacementStatus({
    required String name,
    required String email,
    required String status,
  }) async {
    const serviceId = 'service_x4pu6bs';
    const templateId = 'template_qbpmple';
    const publicKey = 'PyM--VQkH272v8PFI';

    final isApproved = status == "Approved";
    final safeEmail = (email.isEmpty || email == "No Email" || email == "Error")
        ? "default@domain.com"
        : email;

    final message = isApproved
        ? "Your request has been approved. We’ll contact you within 2 days."
        : "Your request has been rejected. For details, contact support.";

    final payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'UserName': name,
        'status': status,
        'message': message,
      },
    };

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    // if (response.statusCode == 200) {
    //   Flushbar(
    //     message: "✅ Email sent successfully",
    //     duration: const Duration(seconds: 3),
    //     backgroundColor: Colors.green,
    //     flushbarPosition: FlushbarPosition.TOP,
    //   ).show(context);
    // } else {
    //   Flushbar(
    //     message: "❌ Failed to send email",
    //     duration: const Duration(seconds: 3),
    //     backgroundColor: Colors.red,
    //     flushbarPosition: FlushbarPosition.TOP,
    //   ).show(context);
    // }
  }

  void showResponseModal(
    BuildContext context,
    String docId,
    Map<String, String> userData,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.send, color: Colors.teal),
            SizedBox(width: 8),
            Text("Send Response"),
          ],
        ),
        content: const Text("Choose action for this replacement request."),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await replacementRef.doc(docId).update({'status': 'Approved'});
              await sendEmailReplacementStatus(
                name: userData['UserName'] ?? 'User',
                email: userData['email'] ?? 'default@domain.com',
                status: 'Approved',
              );
              Navigator.of(ctx).pop();
              setState(() {});
            },
            icon: const Icon(Icons.check),
            label: const Text("Approve"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await replacementRef.doc(docId).update({'status': 'Rejected'});
              await sendEmailReplacementStatus(
                name: userData['UserName'] ?? 'User',
                email: userData['email'] ?? 'default@domain.com',
                status: 'Rejected',
              );
              Navigator.of(ctx).pop();
              setState(() {});
            },
            icon: const Icon(Icons.close),
            label: const Text("Reject"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true, // 👈 Important for transparent AppBar
      backgroundColor: const Color.fromARGB(255, 15, 20, 26),
      appBar: AdminAppBar(),
      bottomNavigationBar: GlassBottomNavBar(selectedIndex: 4),

      body: Container(
        decoration: const BoxDecoration(
          color: const Color.fromARGB(255, 15, 20, 26),
        ),
        child: SafeArea(
          child: Column(
            children: [
             Padding(
  padding: const EdgeInsets.all(10),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _buildFilterChip('All', Icons.filter_list),
        SizedBox(width: 10),
        _buildFilterChip('Approved', Icons.check_circle),
        SizedBox(width: 10),
        _buildFilterChip('Rejected', Icons.cancel),
        SizedBox(width: 10),
        _buildFilterChip('Pending', Icons.hourglass_empty),
      ],
    ),
  ),
),

             Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: replacementRef.orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Text(
            'Error loading data',
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      final docs = snapshot.data!.docs.where((doc) {
        final status = (doc['status'] ?? '').toString().toLowerCase();
        return selectedFilter == 'All' || status == selectedFilter.toLowerCase();
      }).toList();

      if (docs.isEmpty) {
        return const Center(
          child: Text(
            "No requests found",
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'];
          final status = data['status'];
          final message = data['message'] ?? '';
          final title = data['productTitle'] ?? '';
          final issue = data['issueType'] ?? '';
          final image = data['image'];
          final time = (data['timestamp'] as Timestamp).toDate();
          final formattedTime = DateFormat('dd MMM yyyy hh:mm a').format(time);

          return FutureBuilder<Map<String, String>>(
            future: getUserInfo(userId),
            builder: (context, snapshot) {
              final user = snapshot.data ?? {
                'UserName': 'Loading',
                'email': '',
                'phonenumber': '',
                'address': '',
              };

              return Card(
                color: Colors.white.withOpacity(0.07),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Customer Information",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white30),

                      // Name & Email Row
                      Wrap(
                        runSpacing: 8,
                        spacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, color: Colors.white70, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Customer: ${user['UserName']}",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email, color: Colors.white70, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Email: ${user['email']}",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Phone & Address Row
                      Wrap(
                        runSpacing: 8,
                        spacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, color: Colors.white70, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "Ph: ${user['phonenumber']}",
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 18),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Address: ${user['address']}",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white30),

                      const Center(
                        child: Text(
                          "Laptop Information",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Date: $formattedTime",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_bag, color: Colors.white70, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "$title",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.report_problem, color: Colors.white70, size: 18),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Issue: $issue",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                if (message.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.message, color: Colors.white70, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Message: $message",
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Image
                          if (image != null && image.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(image.contains(',') ? image.split(',').last : image),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(color: Colors.white30),

                      // Status and Button
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_turned_in, color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Status: $status",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: (status == 'Approved' || status == 'Rejected')
                                ? null
                                : () => showResponseModal(context, doc.id, user),
                            icon: const Icon(Icons.send),
                            label: const Text("Send Response"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF539b69),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color.fromARGB(139, 208, 208, 208),
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
      );
    },
  ),
)

            
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      avatar: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: isSelected ? Color(0xFF539b69) :Color.fromARGB(255, 15, 20, 26),
      onSelected: (_) => setState(() => selectedFilter = label),
    );
  }
}

