// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:tabby/pages/Judge_Module/scoresheet.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isCodeVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCodeInputDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCodeVerified
          ? _buildReadyToJudgePrompt()
          : const Center(child: CircularProgressIndicator()),
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

  Widget _buildReadyToJudgePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Are you ready to start judging?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScoresheetPage()),
              );
            },
            child: Text(
              'Start Judging Now',
              style: GoogleFonts.poppins(),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _showCodeInputDialog(context);
            },
            child: Text(
              'Cancel or Go Back',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }
}
