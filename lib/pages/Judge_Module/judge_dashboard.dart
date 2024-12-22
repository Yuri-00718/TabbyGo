// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'notes.dart';
import 'profile.dart';
import 'event.dart';
import 'participant.dart';
import 'mechanics.dart';
import 'criteria.dart';
import 'history.dart';
import 'scoresheet.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool _isCodeVerified = false;

  final List<Widget> _pages = <Widget>[
    DashboardContent(),
    const NotesPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCodeInputDialog(context);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCodeVerified
          ? _pages[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: _isCodeVerified
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sticky_note_2_rounded),
                  label: 'Notes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }

  void _showCodeInputDialog(BuildContext context) {
    final List<TextEditingController> codeControllers =
        List.generate(4, (index) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 132, 96, 214),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Text(
              'Enter Template Code',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 50,
                      height: 60,
                      child: TextField(
                        controller: codeControllers[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '',
                          hintText: '0',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 3) {
                            FocusScope.of(context).nextFocus();
                          } else if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () async {
                  if (!context.mounted) return;

                  String enteredCode = codeControllers
                      .map((controller) => controller.text)
                      .join();
                  await _validateCode(context, enteredCode);
                },
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color.fromARGB(255, 132, 96, 214),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _validateCode(BuildContext context, String enteredCode) async {
    String trimmedEnteredCode = enteredCode.trim();

    try {
      String? templateCode =
          await _getTemplateCodeFromFirestore(trimmedEnteredCode);

      if (templateCode == trimmedEnteredCode) {
        // Save the validated code locally
        await DatabaseHelper.instance.saveTemplateCode(trimmedEnteredCode);

        setState(() {
          _isCodeVerified = true;
        });

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template code verified successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code! Please try again.')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error validating template code: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error validating template code.')),
      );
    }
  }

  Future<String?> _getTemplateCodeFromFirestore(String enteredCode) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('templates')
          .where('templateCode', isEqualTo: enteredCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first['templateCode'];
      }
    } catch (e) {
      debugPrint('Error fetching template code: $e');
    }
    return null; // Return null if code is not found
  }
}

class DashboardContent extends StatefulWidget {
  DashboardContent({super.key});
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String? _eventName; // To store the event name
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  // Function to fetch event details
  void _fetchEventDetails() async {
    String? templateCode =
        await DatabaseHelper.instance.getLastSavedTemplateCode();

    if (templateCode != null) {
      await _fetchTemplateDetails(templateCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved template codes found.')),
      );
      setState(() {
        _isLoading = false; // Stop loading if no template code
      });
    }
  }

  // Function to fetch template details and parse event name
  Future<void> _fetchTemplateDetails(String templateCode) async {
    if (templateCode.isNotEmpty) {
      try {
        var details =
            await DatabaseHelper.instance.getTemplateDetails(templateCode);

        if (details != null && details['eventName'] != null) {
          setState(() {
            _eventName = details['eventName']; // Set the event name dynamically
            _isLoading = false; // Stop loading after fetching
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No event name found for this template.')),
          );
          setState(() {
            _isLoading = false; // Stop loading if no event name found
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching template details: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch template details.')),
        );
        setState(() {
          _isLoading = false; // Stop loading on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoWidth = screenWidth * 0.38;
    double logoHeight = screenWidth * 0.27;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 194, 238),
      body: Stack(
        children: [
          // Logo positioned on the left side
          Positioned(
            left: 16,
            top: 30,
            child: Container(
              width: logoWidth,
              height: logoHeight,
              color: const Color.fromARGB(255, 213, 194, 238),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/text logo black.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Logout icon at the top right corner
          Positioned(
            right: 16,
            top: 60,
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => _showLogoutDialog(context),
            ),
          ),
          // Main content positioned at the bottom
          Positioned.fill(
            top: 130.0, // Adjust this to align with the logo height
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Display event name dynamically
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : EventInfo(
                              eventName:
                                  _eventName ?? 'No event name available',
                            ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Center(
                    child: _buildStartJudgingButton(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await widget._googleSignIn.signOut(); // Use widget._googleSignIn here
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/role');
    } catch (e) {
      if (kDebugMode) {
        print("Error signing out: $e");
      }
    }
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut(context);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildStartJudgingButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScoresheetPage()),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 350,
          height: 40,
          decoration: ShapeDecoration(
            color: const Color(0xFF6A0BC4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Judging',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventInfo extends StatelessWidget {
  final String eventName;

  const EventInfo({super.key, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),

        // Separate Card for Event Name
        EventNameCard(eventName: eventName),

        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'EVENT INFORMATION',
          subtitle: 'View the complete details of the event',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventPage()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'LIST OF PARTICIPANTS',
          subtitle: 'Manage participant details',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParticipantsPage(
                  templateCode: '',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'MECHANICS OR GUIDELINES',
          subtitle: 'Review event rules and procedures',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MechanicsScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'CRITERIA FOR JUDGING',
          subtitle: 'See scoring criteria and standards',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CriteriaPage()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          title: 'HISTORY',
          subtitle: 'View past judging activities',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Rubik',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate Widget for Event Name Card
class EventNameCard extends StatelessWidget {
  final String eventName;

  const EventNameCard({super.key, required this.eventName});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 216, 186, 255),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            eventName,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
