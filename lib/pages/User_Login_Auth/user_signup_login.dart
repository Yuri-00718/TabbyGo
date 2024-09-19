import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/User_Login_Auth/user_auth.dart'; // Import AuthenticationScreen
import 'package:tabby/pages/User_Login_Auth/regis_user.dart'; // Import RegistrationScreen

class UserSignUpLoginScreen extends StatelessWidget {
  final String role;

  const UserSignUpLoginScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Container(
            color: const Color(0xFF6A5AE0), // Background color
            height: MediaQuery.of(context).size.height,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height *
                  0.9, // Adjust height as needed
              decoration: const BoxDecoration(
                color: Colors.white, // Container color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF6A5AE0), // Arrow color
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
                        Text(
                          'Welcome $role!',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF6A5AE0),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please login or create a new account.',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6A5AE0),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Image.asset(
                        'assets/images/Happy_Cat.png',
                        width: 300,
                        height: 300,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthenticationScreen(
                                role: role,
                                isSignUp: false,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF6A5AE0), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        child: Text(
                          'Login as $role',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationScreen(
                                role: role,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6A5AE0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        child: Text(
                          'Register as $role',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6A5AE0),
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
                            'Or Connect Using',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6A5AE0),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              // Handle Google login logic
                            },
                            child: Image.asset(
                              'assets/images/Google_Icon.png', // Replace with your Google icon path
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
