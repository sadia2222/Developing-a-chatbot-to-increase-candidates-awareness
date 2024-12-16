import 'dart:async'; //import timer class
import 'package:chat_app/chat.dart';
import 'package:chat_app/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool isDarkTheme = false; // Track the theme

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3), () {
      _checkUserLogin();
    });
  }

  // Load the saved theme preference from SharedPreferences


  // Method to check if the user is already signed in
  Future<void> _checkUserLogin() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    // If user is signed in, navigate to Home, otherwise to SignIn screen
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Signin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF063190),
      body: Center(
        child: Column(
          children: [
SizedBox(height: 100,),
            Text("Hello!", style: TextStyle(color: Colors.white60, fontSize: 40),),
            Text("I'm ComBot", style: TextStyle(color: Colors.white60, fontSize: 40),),


            SizedBox(height: 100,),
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/logo.png'),
                ),
              ),
            ),
            SizedBox(height: 100,),
            Text(
              'How may I help  ',
              style:  TextStyle(color: Colors.white60, fontSize: 40),
            ),
            Text(
              'you ?',
              style:  TextStyle(color: Colors.white60, fontSize: 40),
            ),
            SizedBox(height: 50,),
            Container(height: 50,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white,

              ),
              child: Center(child: Text('I want to know', style: TextStyle(fontSize: 17),)),
            )
          ],
        ),
      ),
    );
  }
}
