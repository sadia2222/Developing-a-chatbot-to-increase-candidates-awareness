import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chat_app/chat.dart';
import 'package:chat_app/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_screen.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isDarkTheme = false; // Track the theme preference

  @override
  void initState() {
    super.initState();
    _loadTheme(); // Load saved theme preference
  }

  // Load the saved theme preference from SharedPreferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false; // Default to light theme if not saved
    });
  }

  // Validate email
  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(email);
  }

  // Validate password
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(String title, String message, VoidCallback onOkPressed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              onOkPressed(); // Navigate after closing the dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Sign-in with email and password
  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !isValidEmail(email)) {
      _showErrorDialog('Invalid Email', 'Please enter a valid email address.');
      return;
    }

    if (password.isEmpty || !isValidPassword(password)) {
      _showErrorDialog('Invalid Password', 'Password must be at least 6 characters.');
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Show success message first, then navigate to the chat screen
      _showSuccessDialog('Login Successful', 'You are successfully logged in.', () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      });
    } catch (e) {
      _showErrorDialog('Login Failed', 'An error occurred. Please try again.');
    }
  }

  // Sign-in with Google
  Future<void> _signInWithGoogle() async {
    try {
      // First, sign out the current Google user
      await _googleSignIn.signOut();

      // Then, sign in again which will prompt the user to select an account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Show success message first, then navigate to the chat screen
      _showSuccessDialog('Google Sign-In Successful', 'You are successfully logged in with Google.', () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      });
    } catch (e) {
      _showErrorDialog('Google Sign-In Failed', 'An error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 200),
                Container(
                  height: 100,
                  child: Image.asset('assets/logo.png'),
                ),
                SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: Text('Forgot Password?', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _signInWithEmail,
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFF063190),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlueAccent,
                          blurStyle: BlurStyle.outer,
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('___________  OR Sign in with  ____________'),
                SizedBox(height: 20),
                Center(
                  child: InkWell(
                    onTap: _signInWithGoogle,
                    child: Container(
                      height: 30,
                      width: 30,
                      child: Image.asset('assets/google.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Signup()),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
