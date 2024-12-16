import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'ChatBotApi.dart';
import 'chatHistory.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatBotApi api = ChatBotApi();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  String? chatId;
  bool isTyping = false;
  String typingDots = '';
  bool isDarkTheme = false;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initializeChat();
    _getUserEmail();
  }

  Future<void> _getUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
      });
    } else {
      print('No user is logged in');
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', value);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Signin()),
    );
  }

  Future<void> _initializeChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User is not authenticated");
        return;
      }

      final chatData = await api.createChat();
      final String newChatId = chatData['chat_id'];

      setState(() {
        chatId = newChatId;
      });

      final response = await api.sendQuestion(newChatId, "Hi");
      if (response['answer'] != null && response['answer'] != "") {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chats')
            .doc(newChatId)
            .set({
          'chat_id': newChatId,
          'created_at': FieldValue.serverTimestamp(),
        });

        print("Chat initialized and saved for user: ${user.uid}");
      } else {
        print("No meaningful response. Chat not saved.");
      }
    } catch (e) {
      print("Error initializing chat: $e");
    }
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty || chatId == null) return;

    setState(() {
      messages.add({"type": "user", "text": question});
      _controller.clear();
      isTyping = true;
    });

    _startTypingAnimation();

    try {
      final response = await api.sendQuestion(chatId!, question);
      if (response['answer'] != null && response['answer'] != "") {
        String responseText = response['answer'] ?? "No response";

        // Detect language of bot's response
        String responseLanguage = _detectLanguage(responseText);

        setState(() {
          isTyping = false;
          messages.add({
            "type": "bot",
            "text": responseText,
            "language": responseLanguage,  // Store language info with message
          });
        });
      } else {
        setState(() {
          isTyping = false;
        });
      }
    } catch (e) {
      print("Error sending question: $e");
      setState(() {
        isTyping = false;
      });
    }
  }

  void _startTypingAnimation() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!isTyping) {
        timer.cancel();
      } else {
        setState(() {
          typingDots = typingDots.length < 3 ? typingDots + '.' : '';
        });
      }
    });
  }



  Future<void> _launchURL(String text) async {
    final urlRegex = RegExp(
        r'\b((https?|ftp)://|www\.)[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})(/[^\s<>]*)?');

    final match = urlRegex.firstMatch(text);

    if (match != null) {
      String url = match.group(0)!.trim();

      // Handle URLs starting with "www."
      if (!url.startsWith('http')) {
        url = 'http://$url';
      }

      // Print URL for debugging
      print('Processed URL: $url');

      try {
        final Uri uri = Uri.parse(Uri.encodeFull(url));
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('Launching URL: $url');
        } else {
          print('Could not launch URL: $url');
        }
      } catch (e) {
        print('Error launching URL: $e');
      }
    } else {
      print('No valid URL found.');
    }
  }


  String _detectLanguage(String text) {
    final urduRegex = RegExp(r'[\u0600-\u06FF]');
    return urduRegex.hasMatch(text) ? 'urdu' : 'english';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFF063190),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('assets/logo.png'),
                        ),
                        SizedBox(width: 20),
                        Text(
                          'ComBot',
                          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 35),
                    Text(
                      userEmail != null ? ' $userEmail' : 'No email found',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text('Chat History'),
                trailing: Icon(Icons.history),
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => ChatHistoryScreen()));
                },
              ),
              SwitchListTile(
                title: Text('Dark Theme'),
                value: isDarkTheme,
                onChanged: (value) {
                  setState(() {
                    isDarkTheme = value;
                    _saveTheme(isDarkTheme);
                  });
                },
              ),
              ListTile(
                title: Text('Log Out'),
                trailing: Icon(Icons.logout, color: Colors.red),
                onTap: _signOut,
              ),
            ],
          ),
        ),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color(0xFF063190),
          elevation: 20,
          titleTextStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(child: Image.asset('assets/logo.png')),
              SizedBox(width: 10),
              Text(" ComBot"),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isTyping && index == 0) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Typing$typingDots",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    );
                  }

                  final message = messages[messages.length - 1 - index + (isTyping ? 1 : 0)];
                  final isUser = message['type'] == 'user';
                  final language = message['language'] ?? 'english';  // Use language info from message

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser ? Color(0xFF063190) : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: isUser ? Radius.circular(12) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : Radius.circular(12),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (message['type'] == 'bot') {
                              _launchURL(message['text']!);  // This will now work with the updated URL function
                            }
                          },
                          child: Text(
                            message['text']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontFamily: language == 'urdu' ? 'Noto Nastaliq Urdu' : null,
                            ),
                            textAlign: isUser ? TextAlign.right : TextAlign.left,
                            textDirection: language == 'urdu' ? TextDirection.rtl : TextDirection.ltr,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
