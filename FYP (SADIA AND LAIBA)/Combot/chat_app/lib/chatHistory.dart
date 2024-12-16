import 'package:cloud_firestore/cloud_firestore.dart'; //Firestore for database operations.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'chat_details.dart';

class ChatHistoryScreen extends StatefulWidget {
  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId;
  bool isLoading = true; // To track loading state
  bool hasChats = false;
  bool isDarkTheme = false;
  List<Map<String, dynamic>> chatHistories = [];

  // Load theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkTheme = prefs.getBool('isDarkTheme') ?? false; // Get saved theme preference
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTheme(); // Load theme preference when the screen is initialized
    _fetchChatHistories();
  }

  // Fetch all chat_id's for the authenticated user and their chat history
  Future<void> _fetchChatHistories() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;

      try {
        // Fetch chat_id's for this user
        QuerySnapshot chatSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('chats')
            .orderBy('created_at', descending: true) // Sort chats by creation time
            .get();

        if (chatSnapshot.docs.isEmpty) {
          setState(() {
            isLoading = false;
            hasChats = false; // No chats available
          });
        } else {
          for (var doc in chatSnapshot.docs) {
            var chatId = doc.id;
            var chatData = doc.data() as Map<String, dynamic>; // Get chat data directly
            var createdAt = chatData['created_at'] as Timestamp?; // Fetch 'created_at'

            setState(() {
              chatHistories.add({
                'chat_id': chatId,
                'messages': chatData['messages'] ?? [],
                'created_at': createdAt?.toDate() ?? DateTime.now(), // Convert Timestamp to DateTime
              });
            });
          }
          setState(() {
            isLoading = false;
            hasChats = true; // Chats are available
          });
        }
      } catch (e) {
        print("Error fetching chat histories: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Delete a specific chat by its ID
  Future<void> _deleteChat(String chatId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .delete();

      setState(() {
        chatHistories.removeWhere((chat) => chat['chat_id'] == chatId);
      });
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  // Delete all chats
  Future<void> _deleteAllChats() async {
    try {
      for (var chat in chatHistories) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('chats')
            .doc(chat['chat_id'])
            .delete();
      }

      setState(() {
        chatHistories.clear();
      });
    } catch (e) {
      print("Error deleting all chats: $e");
    }
  }

  // Show confirmation dialog before deleting all chats
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('This will delete all chats permanently.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteAllChats(); // Proceed with deletion
              },
              child: Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Choose theme based on the `isDarkTheme` value
    return MaterialApp(
      theme: isDarkTheme
          ? ThemeData.dark()
          : ThemeData.light(), // Apply dark or light theme
      home: Scaffold(
        appBar: AppBar(
          title: Text('Chat History'),
        ),
        body: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator
                  : (hasChats
                  ? ListView.builder(
                itemCount: chatHistories.length,
                itemBuilder: (context, index) {
                  var chat = chatHistories[index];
                  var chatId = chat['chat_id'];
                  var createdAt = chat['created_at'];

                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Image.asset('assets/logo.png'),
                      ),
                      title: Text(
                        DateFormat('dd-MM-yyyy    HH:mm').format(createdAt), // Format 'created_at'
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('bot :'), // Show 'bot :' in subtitle
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteChat(chatId); // Delete this chat
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatDetailScreen(chatId: chatId),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
                  : Center(child: Text("No chats in history"))),
            ),
            if (hasChats)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  child: InkWell(
                    onTap: _showDeleteConfirmation, // Show confirmation before deleting
                    child: Card(
                      elevation: 3,
                      color: Colors.redAccent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Delete all chats',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 36,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
