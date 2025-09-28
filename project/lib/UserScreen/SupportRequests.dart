import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:project/Components/MyAppBar.dart';
import 'package:project/Components/MyBottomBar.dart';

class SupportRequests extends StatefulWidget {
  const SupportRequests({Key? key}) : super(key: key);

  @override
  State<SupportRequests> createState() => _SupportRequestsState();
}

class _SupportRequestsState extends State<SupportRequests> {
  final List<String> issueTypes = [
    'Login Problem',
    'App Crash / Bug',
    'Payment Issue',
    'Order Not Showing',
    'Laptop Specification Confusion',
    'General Help',
    'Other',
  ];

  String selectedIssueType = 'Login Problem';
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;
  bool showForm = false;
  String? userName = 'Guest';

  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFF8F8F8);
  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitSupportRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (descriptionController.text.trim().isEmpty) {
      Flushbar(
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.warning, color: Colors.black),
        titleText: const Text("Error", style: TextStyle(color: Colors.black)),
        messageText: const Text("Please enter a description.",
            style: TextStyle(color: Colors.black)),
      ).show(context);
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance.collection('supportReq').add({
      'userid': user.uid,
      'category': selectedIssueType,
      'description': descriptionController.text.trim(),
      'status': 'Pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() {
      descriptionController.clear();
      selectedIssueType = issueTypes.first;
      isLoading = false;
      showForm = false;
    });

    Flushbar(
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.green.shade600,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(Icons.check_circle, color: Colors.black),
      titleText: const Text("Success",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      messageText: const Text("Support request submitted successfully!",
          style: TextStyle(color: Colors.black)),
    ).show(context);
  }
 
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
       bottomNavigationBar: MyBottomBar(currentIndex: 3),

         backgroundColor: backgroundColor,
      appBar: MyAppBar(),
     
     
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 💬 Info Card
                      Container(
  padding: const EdgeInsets.all(5),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left side: Support content
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              " Support Help Guide",
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _infoBullet("Choose the issue category that fits best."),
            _infoBullet("Write your concern in detail."),
            _infoBullet("We'll respond in 24–48 hours."),
          ],
        ),
      ),
      const SizedBox(width: 16),

      // Right side: Support image
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/support.png',
          width: 100, // Adjust as needed
          height: 100,
          fit: BoxFit.cover,
        ),
      ),
    ],
  ),
),

                        const SizedBox(height: 24),

                        // 📤 Ask Button or Form
                        if (!showForm)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text("Ask Your Question?"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:Color(0xFF539b69),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() => showForm = true);
                              },
                            ),
                          ),

                        // 📋 Support Request Form
                        if (showForm)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text("Issue Type:",
                                  style: GoogleFonts.merriweather(
                                      fontSize: 16, color: Colors.black)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                dropdownColor: const Color.fromARGB(255, 226, 226, 226),
                                value: selectedIssueType,
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black12,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: issueTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => selectedIssueType = val!),
                              ),
                              const SizedBox(height: 16),

                              Text("Description:",
                                  style: GoogleFonts.merriweather(
                                      fontSize: 16, color: Colors.black)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: descriptionController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black12,
                                  hintText: selectedIssueType == "Other"
                                      ? "e.g. I have a suggestion or facing issue while uploading..."
                                      : "Describe your issue...",
                                  hintStyle: const TextStyle(color: Colors.black54),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 24),

                              Center(
                                child: ElevatedButton(
                                  onPressed: submitSupportRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF539b69),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 20),
                                  ),
                                  child: const Text("Submit Request"),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // 💬 Top Header with ❌
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(" Need Help? We're Here!",
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ],
                    ),
                  ),
                ],
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

  Widget _infoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text("• ", style: TextStyle(color: Colors.orange)),
          Expanded(
              child: Text(text, style: const TextStyle(color: Colors.black))),
        ],
      ),
    );
  }
}
