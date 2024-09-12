import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/user_auth.dart';
import 'package:tabby/pages/regis_user.dart';

class LoginRoleSelection extends StatelessWidget {
  const LoginRoleSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0), // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login As',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 32,
                color: const Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 40),
            _buildLoginButton(
              context,
              'Judge',
              onTap: () {
                // Navigate to Authentication Module for Judge login
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AuthenticationScreen(role: 'Judge'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildLoginButton(
              context,
              'Admin',
              onTap: () {
                // Navigate to Authentication Module for Admin login
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AuthenticationScreen(role: 'Admin'),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                // Navigate to Registration Module
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Register',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, String role,
      {required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFCCD5), // Button background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
      child: Text(
        'Login as $role',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: const Color(0xFF660012), // Text color
        ),
      ),
    );
  }
}
