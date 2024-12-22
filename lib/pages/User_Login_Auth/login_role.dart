import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/Judge_Module/judge_dashboard.dart';
import 'package:tabby/pages/User_Login_Auth/user_signup_login.dart';

class LoginRoleSelection extends StatelessWidget {
  const LoginRoleSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if the screen is wide (web) or narrow (mobile)
          bool isWideScreen = constraints.maxWidth > 600;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: isWideScreen
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  mainAxisAlignment: isWideScreen
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      'Select',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w700,
                        fontSize: isWideScreen ? 40 : 32,
                        color: const Color(0xFFFFD6DD),
                      ),
                    ),
                    Text(
                      'User Type',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w700,
                        fontSize: isWideScreen ? 40 : 32,
                        color: const Color(0xFFFFD6DD),
                      ),
                    ),
                    const SizedBox(height: 30),
                    isWideScreen
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildRoleButton(
                                  context,
                                  'Judge',
                                  'assets/images/judge.jpg',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Dashboard(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildRoleButton(
                                  context,
                                  'Organizer',
                                  'assets/images/admin.jpg',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UserSignUpLoginScreen(
                                          role: 'Organizer',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildRoleButton(
                                context,
                                'Judge',
                                'assets/images/judge.jpg',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Dashboard(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildRoleButton(
                                context,
                                'Organizer',
                                'assets/images/admin.jpg',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UserSignUpLoginScreen(
                                        role: 'Organizer',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String role, String imagePath,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
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
                ' $role',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
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
