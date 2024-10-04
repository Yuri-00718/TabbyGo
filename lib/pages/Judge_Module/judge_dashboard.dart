// ignore_for_file: depend_on_referenced_packages

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
  bool _isCodeVerified = false; // To track if the correct code has been entered

  // List of pages for navigation
  final List<Widget> _pages = <Widget>[
    DashboardContent(),
    const NotesPage(), // Notes screen
    const ProfilePage(), // Profile screen
  ];

  @override
  void initState() {
    super.initState();
    // Trigger code entry dialog when dashboard loads
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
          ? _pages[_selectedIndex] // Show content only if code is verified
          : const Center(
              child: CircularProgressIndicator(), // Show loader until verified
            ),
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
          : null, // Hide navigation bar until code is verified
    );
  }

  void _showCodeInputDialog(BuildContext context) {
    // Create a list of TextEditingControllers for each input field
    final List<TextEditingController> codeControllers =
        List.generate(4, (index) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing the dialog without entering a code
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 132, 96,
              214), // Set a background color that matches your theme
          title: Text(
            'Enter Template Code',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7.0), // Add horizontal spacing
                    child: SizedBox(
                      width: 50, // Adjust the width as needed
                      height: 60, // Adjust the height to make it larger
                      child: TextField(
                        controller: codeControllers[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1, // Limit input to 1 digit
                        style: GoogleFonts.poppins(
                            color: Colors.black), // Text color for input
                        textAlign:
                            TextAlign.center, // Center text in the input box
                        decoration: InputDecoration(
                          hintText: '0', // Hint text as a placeholder
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.grey), // Hint text color
                          filled: true,
                          fillColor:
                              Colors.white, // Background color of the TextField
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Colors.black, width: 1),
                          ),
                          counterText: '',
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && index < 3) {
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
              const SizedBox(height: 16),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Check if the context is still mounted
                if (!context.mounted) return;

                String enteredCode =
                    codeControllers.map((controller) => controller.text).join();
                await _validateCode(context, enteredCode);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _validateCode(BuildContext context, String enteredCode) async {
    String trimmedEnteredCode = enteredCode.trim();

    // Fetch the template code from Firestore
    String? templateCode =
        await _getTemplateCodeFromFirestore(trimmedEnteredCode);

    if (templateCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Error retrieving template code. Please check Firestore.')),
      );
      return;
    }

    // Validate the code
    if (templateCode == trimmedEnteredCode) {
      // Save the code
      await DatabaseHelper.instance.saveTemplateCode(trimmedEnteredCode);

      setState(() {
        _isCodeVerified = true;
      });
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code! Please try again.')),
      );
    }
  }

  Future<String?> _getTemplateCodeFromFirestore(String enteredCode) async {
    try {
      // Query the 'templates' collection where 'templateCode' matches the entered code
      var querySnapshot = await FirebaseFirestore.instance
          .collection('templates')
          .where('templateCode', isEqualTo: enteredCode)
          .limit(1) // Limit to 1 result since templateCode should be unique
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var document = querySnapshot.docs.first;

        print('Firestore Document Data: ${document.data()}');

        // Check if the 'templateCode' field exists in the document
        if (document.data().containsKey('templateCode')) {
          // Cast 'templateCode' to String and return it
          return document['templateCode'] as String?;
        } else {
          print('templateCode field does not exist in the document');
          return null;
        }
      } else {
        print('No document found for the entered template code');
        return null;
      }
    } catch (e) {
      print('Error fetching template code from Firestore: $e');
      return null;
    }
  }
}

class DashboardContent extends StatelessWidget {
  DashboardContent({super.key});
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 194, 238),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 130.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: const [
                      EventInfo(),
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
          Positioned(
            left: 16,
            top: 30,
            child: Container(
              width: screenWidth * 0.38,
              height: screenWidth * 0.27,
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
          Positioned(
            right: 200,
            top: 60, // Adjust the top position as needed
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => _showLogoutDialog(context), // Show logout dialog
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
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
          // Navigate directly to ScoresheetPage
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
            color: const Color(0xFF6A5AE0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Start Judging Now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventInfo extends StatelessWidget {
  const EventInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                      )),
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
              MaterialPageRoute(builder: (context) => MechanicsScreen()),
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
              MaterialPageRoute(builder: (context) => CriteriaPage()),
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
              MaterialPageRoute(builder: (context) => HistoryPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
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
