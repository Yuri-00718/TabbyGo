import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tabby/pages/user_management.dart';
import 'package:tabby/pages/result_and_reports_active_events.dart';
import 'package:tabby/pages/template_menus.dart';
// ignore: depend_on_referenced_packages
import 'package:connectivity_plus/connectivity_plus.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashBoardState createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  bool _isOffline = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _isOffline = result == ConnectivityResult.none;
        });
      }
      if (!_isOffline) {
        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isOffline = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF6A5AE0),
        child: Column(
          children: [
            // Banner for connectivity status
            if (_isOffline || (_bannerTimer != null && _bannerTimer!.isActive))
              Container(
                width: double.infinity,
                color: _isOffline ? Colors.redAccent : Colors.greenAccent,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _isOffline
                      ? "Tabby is currently in Offline Mode."
                      : "Tabby’s Got Internet!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            // Fixed Greeting Section
            Container(
              height: 200,
              color: const Color(0xFF6A5AE0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: _buildGreeting(context),
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildActionContainer(
                      context,
                      'Results and Reports',
                      'assets/images/business_analytics_on_tablet_screen.png',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ResultAndReportsActiveEvents(),
                          ),
                        );
                      },
                    ),
                    _buildActionContainer(
                      context,
                      'Event Template Management',
                      'assets/images/time_management.png',
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TemplateMenus(),
                            ));
                      },
                    ),
                    _buildActionContainer(
                      context,
                      'User Account \n Management',
                      'assets/images/woman_participates_in_an_online_conference_with_colleagues.png',
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserManagement(),
                            ));
                      },
                    ),
                    _buildActionContainer(
                      context,
                      'Criteria \n Management',
                      'assets/images/law_studies_with_contract_and_gavel.png',
                      () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0), // Adjust padding as needed
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: SvgPicture.asset('assets/vectors/frame_x2.svg'),
                  ),
                ),
                Expanded(
                  child: Text(
                    'GOOD MORNING',
                    style: GoogleFonts.getFont(
                      'Rubik',
                      fontWeight: FontWeight.w500,
                      fontSize: 24,
                      height: 1.8,
                      letterSpacing: 0.5,
                      color: const Color(0xFFFFD6DD),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Adjust spacing between rows
            Row(
              children: [
                Text(
                  'Administrator',
                  style: GoogleFonts.getFont(
                    'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                    height: 1.5,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(width: 8), // Space between text and icon
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/role');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionContainer(
      BuildContext context, String text, String imagePath, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF9087E5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 2,
          ),
        ],
      ),
      child: SizedBox(
        width: 364,
        height: 150,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.contain,
                      image: AssetImage(imagePath),
                    ),
                  ),
                  child: const SizedBox(
                    width: 130,
                    height:
                        150, // Ensure this height matches the container's height
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
