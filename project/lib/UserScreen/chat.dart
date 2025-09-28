import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  static const routeName = '/chat';
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];

  final Color primaryColor = const Color(0xFF539b69);
  final Color backgroundColor = const Color(0xFFf2f2f2);

  @override
  void initState() {
    super.initState();
    // Add default greeting message
    _chatHistory.add({
      "time": DateTime.now(),
      "message": "👋 Ask me anything!",
      "isSender": false,
    });
  }

  Future<void> getAnswer() async {
    const String apiKey = 'AIzaSyBqIa-mOV0KoW-Bc4PBIVPkuUyNyKKDbCQ';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    String userMessage = '';
    for (int i = _chatHistory.length - 1; i >= 0; i--) {
      if (_chatHistory[i]["isSender"] == true) {
        userMessage = _chatHistory[i]["message"];
        break;
      }
    }

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": userMessage}
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final result = json.decode(response.body);

      final candidates = result["candidates"];
      if (candidates != null &&
          candidates.isNotEmpty &&
          candidates[0]["content"] != null &&
          candidates[0]["content"]["parts"] != null &&
          candidates[0]["content"]["parts"].isNotEmpty) {
        final String reply =
            candidates[0]["content"]["parts"][0]["text"].toString();

        setState(() {
          _chatHistory.add({
            "time": DateTime.now(),
            "message": reply,
            "isSender": false,
          });
        });
      } else {
        setState(() {
          _chatHistory.add({
            "time": DateTime.now(),
            "message": "❌ Gemini API gave no valid response.",
            "isSender": false,
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({
          "time": DateTime.now(),
          "message": "❌ Error: ${e.toString()}",
          "isSender": false,
        });
      });
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
      body: Stack(
        children: [
          // Chat Messages
          Container(
            margin: const EdgeInsets.only(bottom: 80, top: 100),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chatHistory.length,
              padding: const EdgeInsets.symmetric(vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isSender = message["isSender"];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment:
                        isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isSender
                              ? LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.2),
                                    primaryColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.2),
                                    primaryColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message["message"],
                          style: TextStyle(
                            color: isSender ? Colors.black : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Chat input
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF539b69),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(40.0),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: "Type something...",
                            hintStyle:
                                TextStyle(color: Colors.white54, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (_chatController.text.isNotEmpty) {
                        setState(() {
                          _chatHistory.add({
                            "time": DateTime.now(),
                            "message": _chatController.text,
                            "isSender": true,
                          });
                          _chatController.clear();
                        });
                        getAnswer();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 0, 0, 0),
                            Color.fromARGB(255, 0, 0, 0)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
