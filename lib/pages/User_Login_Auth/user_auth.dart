// ignore_for_file: depend_on_referenced_packages, use_super_parameters, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationScreen extends StatefulWidget {
  final String role;
  final bool isSignUp;

  const AuthenticationScreen({
    Key? key,
    required this.role,
    required this.isSignUp,
  }) : super(key: key);

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isOnline = true;
  bool _checkingConnection = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    setState(() {
      _checkingConnection = true;
    });
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi;
      _checkingConnection = false;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      if (widget.isSignUp) {
        await _signUp(username, password);
      } else {
        if (_isOnline) {
          await _loginOnline(username, password);
        } else {
          await _loginOffline(username, password);
        }
      }
    }
  }

  Future<void> _signUp(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        _showErrorDialog('Username and password cannot be empty.');
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: username, password: password);

      if (userCredential.user != null) {
        // Save role to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': username,
          'role': widget.role,
        });

        // Fetch role from Firestore to ensure consistency
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        String role = userDoc['role'] ?? widget.role;
        print('Sign-up successful. Role: $role');

        // Redirect based on role
        _navigateToDashboard(role);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.code == 'email-already-in-use'
          ? 'The email address is already in use.'
          : 'An error occurred during sign-up. Please try again.';
      _showErrorDialog(errorMessage);
    }
  }

  void _navigateToDashboard(String role) {
    if (role == 'Organizer') {
      // Ensure that the context is valid
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/dashBoard');
      }
    } else if (role == 'Judge') {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/judge_dashboard');
      }
    } else {
      _showErrorDialog('No valid role found for this user.');
    }
  }

  Future<void> _loginOnline(String username, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: username, password: password);

      if (userCredential.user != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role'] ?? '';
          _navigateToDashboard(role);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.code == 'user-not-found'
          ? 'No user found for that email.'
          : e.code == 'wrong-password'
              ? 'Wrong password provided.'
              : 'An error occurred. Please try again.';
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> _loginOffline(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        _showErrorDialog('Username and password cannot be empty.');
        return;
      }

      bool isAdmin =
          await DatabaseHelper.instance.loginAdmin(username, password);
      bool isJudge =
          await DatabaseHelper.instance.loginJudge(username, password);

      if (isAdmin) {
        _navigateToDashboard('Organizer');
      } else if (isJudge) {
        _navigateToDashboard('Judge');
      } else {
        _showErrorDialog('Invalid username or password (offline mode).');
      }
    } catch (e) {
      _showErrorDialog('An error occurred during offline login: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      print("Starting Google Sign-In process...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Google Sign-In failed: User canceled the sign-in.");
        _showErrorDialog('Google Sign-In was unsuccessful. Please try again.');
        return;
      }

      print("Google Sign-In successful, retrieving authentication...");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Signing in with Firebase using credentials...");
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final String? uid = userCredential.user?.uid;
      final String email = userCredential.user?.email ?? '';

      print('Logged in user email: $email'); // Debugging line

      if (uid != null) {
        print("Fetching user document from Firestore for UID: $uid");
        // Fetch the user's role from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          print("User document found, checking role...");
          // If the document exists, retrieve the role field
          String role = userDoc.get('role') ?? '';
          print('User role from Firestore: $role'); // Debugging line

          // Navigate based on role
          _navigateToDashboard(role);
        } else {
          print("User document not found, creating new user...");
          // Create a new user in Firestore with a default role (Organizer for new users)
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'email': email,
            'role': 'Organizer', // Default role for new users
          });

          print("New user created, redirecting to Organizer Dashboard...");
          // Automatically navigate for new user
          _navigateToDashboard('Organizer');
        }
      } else {
        print("Failed to sign in with Google, UID is null.");
        _showErrorDialog('Failed to sign in with Google. Please try again.');
      }
    } catch (e) {
      print("Error during Google Sign-In: ${e.toString()}"); // Debugging line
      _showErrorDialog(
          'An error occurred during Google Sign-In: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
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
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Define breakpoints for responsiveness
            double contentWidth = constraints.maxWidth > 1200
                ? 800
                : constraints.maxWidth > 800
                    ? 600
                    : constraints.maxWidth * 1;

            return Column(
              children: [
                Center(
                  child: Container(
                    width: contentWidth,
                    padding: const EdgeInsets.all(20.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF6A5AE0),
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  'assets/images/Back_Arrow.png',
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Welcome ${widget.role}!',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6A5AE0),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Please log in to access your account.',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 50),
                        if (_checkingConnection)
                          const Center(child: CircularProgressIndicator())
                        else
                          Text(
                            _isOnline
                                ? 'Connected to the Internet'
                                : 'You are using Tabby Offline Mode',
                            style: TextStyle(
                              color: _isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                '${widget.role} Username or Email',
                                icon: Icons.person_outline,
                                controller: _usernameController,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                'Password',
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                isPassword: true,
                              ),
                              const SizedBox(height: 40),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                        255, 121, 100, 216),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 15),
                                  ),
                                  child: Text(
                                    widget.isSignUp ? 'Sign Up' : 'Log In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Column(
                                  children: [
                                    const Divider(
                                      color: Color(0xFF6A5AE0),
                                      thickness: 1,
                                      indent: 50,
                                      endIndent: 50,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Or Login Using',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF6A5AE0),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: _signInWithGoogle,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 5,
                                              blurRadius: 7,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/images/Google_Icon.png',
                                              height: 30,
                                              width: 30,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Google',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller,
      IconData? icon,
      bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_passwordVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
