// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool _isJudgesSelected = true;
  late Future<List<Map<String, dynamic>>> _judgesFuture;

  @override
  void initState() {
    super.initState();
    _judgesFuture = _fetchJudges();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        decoration: const BoxDecoration(
          color: Color(0xFF6A5AE0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingSection(),
              const SizedBox(height: 19),
              _buildTitleSection(context),
              const SizedBox(height: 19),
              _buildEventButtons(),
              const SizedBox(height: 19),
              Expanded(
                child: _buildJudgeListSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30.4),
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 3.8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 20,
                      height: 19.8,
                      child: SvgPicture.asset(
                        'assets/vectors/frame_x2.svg',
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'GOOD MORNING',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 1.5,
                        letterSpacing: 0.5,
                        color: const Color(0xFFFFD6DD),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'ORGANIZER',
              style: GoogleFonts.rubik(
                fontWeight: FontWeight.w500,
                fontSize: 24,
                height: 1.5,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            'assets/images/Back_Arrow.png',
            width: 30,
            height: 30,
          ),
        ),
        const SizedBox(width: 15.3),
        Expanded(
          child: Text(
            'User Management',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 24,
              height: 1.5,
              color: const Color(0xFFFFFFFF),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEventButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isJudgesSelected = true;
                _judgesFuture = _fetchJudges();
              });
            },
            child: _buildButton('Judges', _isJudgesSelected),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF9087E5) : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFF9087E5),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color:
                isSelected ? const Color(0xFFFFFFFF) : const Color(0x80FFFFFF),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      if (_isJudgesSelected) {
        _judgesFuture = _fetchJudges();
      }
    });
  }

  Widget _buildJudgeListSection() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _judgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No judges found.'));
          } else {
            final judges = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: judges.length,
              itemBuilder: (context, index) {
                final judge = judges[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildUserCard(judge, 'Judge'),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String type) {
    final name = user['name'] ?? 'Unknown';
    final role = user['role'] ?? type;
    final template = user['eventName'] ?? 'No event assigned';
    final imagePath = user['image'] ?? '';

    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    imagePath.isNotEmpty ? FileImage(File(imagePath)) : null,
                child: imagePath.isEmpty && (name.isNotEmpty)
                    ? Text(name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24))
                    : const Icon(Icons.person, size: 24, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 16)),
                    Text(role,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey)),
                    Text(template,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color.fromARGB(
                                255, 82, 15, 207))), // Updated font style
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchJudges() async {
    final dbHelper = DatabaseHelper
        .instance; // Ensure you have an instance of DatabaseHelper
    try {
      // Fetch all judges with their associated template names
      final judgesWithTemplates = await dbHelper.getJudgesByTemplate();

      if (kDebugMode) {
        print('Fetched ${judgesWithTemplates.length} judges with templates.');
        print('Judges with Templates: $judgesWithTemplates');
      }

      if (judgesWithTemplates.isEmpty) {
        if (kDebugMode) {
          print('No judges with template names found in the database.');
        }
        return []; // Return an empty list if no data is found
      }

      return judgesWithTemplates; // Return the list of judges with templates
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching judges with templates: $e');
      }
      return []; // Return empty in case of error
    }
  }
}
