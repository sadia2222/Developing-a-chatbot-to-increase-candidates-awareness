import 'dart:convert'; // for jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  // Constructor that accepts the chat_id
  ChatDetailScreen({required this.chatId});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Map<String, String>> chatHistory = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isDarkTheme = false; // Track the theme

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchChatDetails();
  }

  // Load the saved theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false; // Get the saved dark theme preference
    });
  }

  // Fetch chat details (questions and answers) from the API
  Future<void> _fetchChatDetails() async {
    final String url = "https://Sadiaa-Comsats-Bot.hf.space/get_chat/${widget.chatId}";

    try {
      // Make a GET request to fetch the chat history
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Decode UTF-8 response body
        var data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['history'] != null) {
          setState(() {
            chatHistory = List<Map<String, String>>.from(
              data['history'].map((message) {
                return {
                  'question': message['question'].toString(),
                  'answer': message['answer'].toString(),
                };
              }),
            );
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load chat history';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }
  // Helper function to detect Urdu text
  bool isUrdu(String text) {
    final urduRegex = RegExp(r'[\u0600-\u06FF]');
    return urduRegex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : ListView.builder(
        itemCount: chatHistory.length,
        itemBuilder: (context, index) {
          var message = chatHistory[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: isUrdu(message['question']!)
                        ? TextDirection.rtl // If Urdu, use RTL
                        : TextDirection.ltr, // If English, use LTR
                    child: Text(
                      'Question: ${message['question']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoNaskhArabic', // Font for Urdu
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Directionality(
                    textDirection: isUrdu(message['answer']!)
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Text(
                      'Answer: ${message['answer']}',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic', // Font for Urdu
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
