import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/user_auth.dart';

class LoginRoleSelection extends StatelessWidget {
  const LoginRoleSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Padding(
        padding: const EdgeInsets.only(
            top: 90, left: 15, right: 15), // Added space from the top
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select',
              style: GoogleFonts.rubik(
                fontWeight: FontWeight.w700,
                fontSize: 32,
                color: const Color(0xFFFFD6DD),
              ),
            ),
            Text(
              'User Type',
              style: GoogleFonts.rubik(
                fontWeight: FontWeight.w700,
                fontSize: 32,
                color: const Color(0xFFFFD6DD),
              ),
            ),
            const SizedBox(height: 30), // Adjust space after the title
            _buildRoleButton(
              context,
              'Judge',
              'assets/images/judge.jpg',
              onTap: () {
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
            _buildRoleButton(
              context,
              'Admin',
              'assets/images/admin.jpg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AuthenticationScreen(role: 'Admin'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildRoleButton(
              context,
              'Organizer',
              'assets/images/Organizer.jpg',
              onTap: () {
                // Handle Organizer login
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String role, String imagePath,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              cacheWidth: 100,
              cacheHeight: 100,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Login as $role',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: const Color.fromARGB(255, 136, 78, 243),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
