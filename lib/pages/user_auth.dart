// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/data_base_helper.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth for online mode
import 'package:connectivity_plus/connectivity_plus.dart'; // To check online/offline status

class AuthenticationScreen extends StatefulWidget {
  final String role;

  const AuthenticationScreen({super.key, required this.role});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isOnline = true; // Store connectivity status
  bool _checkingConnection = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  // Function to continuously check internet connectivity
  void _checkConnectivity() async {
    setState(() {
      _checkingConnection = true;
    });
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
      _checkingConnection = false;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text;
      String password = _passwordController.text;

      if (_isOnline) {
        await _loginOnline(username, password);
      } else {
        await _loginOffline(username, password);
      }
    }
  }

  // Firebase authentication for online mode
  Future<void> _loginOnline(String username, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: username, password: password);

      if (userCredential.user != null) {
        // Navigate to dashboard on successful login
        Navigator.pushReplacementNamed(context, '/dashBoard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    }
  }

  // Custom authentication for offline mode (using local database)
  Future<void> _loginOffline(String username, String password) async {
    try {
      DatabaseHelper dbHelper = DatabaseHelper.instance;
      bool isLoggedIn = await dbHelper.loginAdmin(username, password);

      if (isLoggedIn) {
        // Navigate to dashboard on successful offline login
        Navigator.pushReplacementNamed(context, '/dashBoard');
      } else {
        _showErrorDialog('Invalid username or password (offline mode).');
      }
    } catch (e) {
      _showErrorDialog('An error occurred during offline login.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${widget.role} Login',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 24,
                      color: const Color(0xFF482970),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_checkingConnection)
                    const CircularProgressIndicator() // Show while checking connection
                  else
                    Text(
                      _isOnline ? 'You are online' : 'You are offline',
                      style: TextStyle(
                        color: _isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _usernameController,
                    label: '${widget.role} Username',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter username'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: !_passwordVisible,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter password'
                        : null,
                    toggleVisibility: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A5AE0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Login as ${widget.role}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    required FormFieldValidator<String> validator,
    VoidCallback? toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: toggleVisibility,
              )
            : null,
      ),
      style: GoogleFonts.poppins(color: Colors.black),
      validator: validator,
    );
  }
}
