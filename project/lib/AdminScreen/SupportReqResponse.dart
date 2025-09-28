import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:project/Components/AdminAppBar.dart';
import 'package:project/Components/AdminBottomNav.dart';

class SupportReqResponse extends StatefulWidget {
  const SupportReqResponse({Key? key}) : super(key: key);

  @override
  _SupportReqResponseState createState() => _SupportReqResponseState();
}

class _SupportReqResponseState extends State<SupportReqResponse> {
  final supportRef = FirebaseFirestore.instance.collection('supportReq');
  String selectedFilter = 'All';

  Future<Map<String, String>> getUserInfo(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = userDoc.data() ?? {};
      return {
        'UserName': data['UserName'] ?? 'No Name',
        'email': data['email'] ?? 'No Email',
      };
    } catch (e) {
      return {'UserName': 'Error', 'email': 'Error'};
    }
  }

  Future<void> sendEmailSupportStatus({
    required String name,
    required String email,
    required String status,
    required String message,
  }) async {
    const serviceId = 'service_sqqbo27';
    const templateId = 'template_qykt9uu';
    const publicKey = 'PyM--VQkH272v8PFI';

    final payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'UserName': name,
        'status': status,
        'message': message,
        'company': 'LaptopHarbor',
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

    if (response.statusCode == 200) {
      Flushbar(
        message: "Response sent Successfully! ✔",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } else {
      Flushbar(
        message: "❌ Failed to send email",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  void updateStatusAndEmail(
    String docId,
    String status,
    String message,
    Map<String, String> user,
  ) async {
    await supportRef.doc(docId).update({
      'status': status,
      'response_message': message,
    });
    await sendEmailSupportStatus(
      name: user['UserName'] ?? 'User',
      email: user['email'] ?? 'default@domain.com',
      status: status,
      message: message,
    );
    setState(() {});
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    extendBody: true,
    extendBodyBehindAppBar: true, // Transparent AppBar effect
    backgroundColor: const Color.fromARGB(255, 15, 20, 26),
    appBar: AdminAppBar(),
    bottomNavigationBar: GlassBottomNavBar(selectedIndex: 3),

   body: SafeArea(
  child: Column(
    children: [
      const SizedBox(height: 10),
      _buildFilterButtons(),
      const SizedBox(height: 10),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: supportRef
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            final filteredDocs = selectedFilter == 'All'
                ? docs
                : docs.where((doc) {
                    return (doc['status'] ?? '').toLowerCase() ==
                        selectedFilter.toLowerCase();
                  }).toList();

            if (filteredDocs.isEmpty) {
              return const Center(
                child: Text(
                  "No support requests found",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

          
          
            return ListView.builder(
  itemCount: filteredDocs.length,
  itemBuilder: (context, index) {
    final doc = filteredDocs[index];
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userid'];
    final status = data['status'];
    final category = data['category'] ?? 'Unknown';
    final description = data['description'] ?? '';
    final timestamp = (data['created_at'] as Timestamp?)?.toDate();
    final formattedTime = timestamp != null
        ? DateFormat('dd MMM yyyy hh:mm a').format(timestamp)
        : 'Unknown Time';

    return FutureBuilder<Map<String, String>>(
      future: getUserInfo(userId),
      builder: (context, snapshot) {
        final user = snapshot.data ??
            {'UserName': 'Loading...', 'email': ''};

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
                    " Customer Information",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white30),

                // Responsive customer info using Wrap
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
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
                            softWrap: true,
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
                            softWrap: true,
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
                    "Support Request",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Category: $category",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Description: $description",
                        style: const TextStyle(color: Colors.white),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.white30),

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_turned_in,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Status: $status",
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showModal(context, doc.id, user),
                      icon: const Icon(Icons.send),
                      label: const Text("Respond"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF539b69),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Color.fromARGB(139, 208, 208, 208),
                        disabledForegroundColor: Colors.white70,
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
      ),
    ],
  ),
),

 
  );
}
  Widget _buildFilterButtons() {
    final filters = {
      'All': Icons.list,
      'Pending': Icons.hourglass_empty,
      'Approved': Icons.check_circle,
      'Rejected': Icons.cancel,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final isSelected = selectedFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedFilter = entry.key;
                });
              },
              icon: Icon(entry.value, size: 16),
              label: Text(entry.key),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Color(0xFF539b69) :Color.fromARGB(255, 15, 20, 26),
                foregroundColor: Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  

  void _showModal(
    BuildContext context,
    String docId,
    Map<String, String> user,
  ) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Respond to Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Write message for the customer:"),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter response message",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              final msg = messageController.text.trim();
              if (msg.isEmpty) return;
              updateStatusAndEmail(docId, 'Approved', msg, user);
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.check),
            label: const Text("Approve"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final msg = messageController.text.trim();
              if (msg.isEmpty) return;
              updateStatusAndEmail(docId, 'Rejected', msg, user);
              Navigator.pop(ctx);
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
}
