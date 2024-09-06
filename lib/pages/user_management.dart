import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tabby/pages/data_base_helper.dart';
import 'package:tabby/pages/user_admin_creation.dart'; // Ensure you have this page
import 'package:tabby/pages/user_judge_creation.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool _isJudgesSelected = true;
  late Future<List<Map<String, dynamic>>> _judgesFuture;
  late Future<List<Map<String, dynamic>>> _adminsFuture;

  @override
  void initState() {
    super.initState();
    _judgesFuture = _fetchJudges();
    _adminsFuture = _fetchAdmins();
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
                child: _isJudgesSelected
                    ? _buildJudgeListSection()
                    : _buildAdminListSection(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 150,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 165, 164, 164),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(25),
          color: const Color(0xFF6A5AE0),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final page = _isJudgesSelected
                ? const JudgeCreation(role: 'Add Judge +', judge: {})
                : const AdminCreation(role: 'Add Admin +', admin: {});

            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false, // Prevent dismiss by tapping outside
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );

            // ignore: use_build_context_synchronously
            Navigator.pop(context); // Dismiss the loading dialog

            if (result != null) {
              setState(() {
                if (_isJudgesSelected) {
                  _judgesFuture = _fetchJudges();
                } else {
                  _adminsFuture = _fetchAdmins();
                }
              });
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              _isJudgesSelected ? 'Add Judge +' : 'Add Admin +',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              'Administrator',
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
                _judgesFuture = _fetchJudges(); // Refresh judges list
              });
            },
            child: _buildButton('Judges', _isJudgesSelected),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isJudgesSelected = false;
                _adminsFuture = _fetchAdmins(); // Refresh admins list
              });
            },
            child: _buildButton('Admin', !_isJudgesSelected),
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
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color:
                isSelected ? const Color(0xFFFFFFFF) : const Color(0x80FFFFFF),
          ),
        ),
      ),
    );
  }

  Widget _buildJudgeListSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
    );
  }

  Widget _buildAdminListSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _adminsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No admins found.'));
        } else {
          final admins = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildAdminCard(admin),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
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
                    admin['image'] != null && admin['image'].isNotEmpty
                        ? FileImage(File(admin['image']))
                        : null,
                child: admin['image'] == null || admin['image'].isEmpty
                    ? Text(admin['name'][0].toUpperCase(),
                        style: const TextStyle(fontSize: 24))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin['name'] ?? 'N/A',
                        style: GoogleFonts.poppins(fontSize: 16)),
                    Text(admin['username'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Edit') {
                    _editAdmin(admin);
                  } else if (value == 'Delete') {
                    _deleteAdmin(admin['id'] as int);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String type) {
    // Determine the image path, if available
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
              // Display the image if available, otherwise use a default icon
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    imagePath.isNotEmpty ? FileImage(File(imagePath)) : null,
                child: imagePath.isEmpty
                    ? Text(user['name'][0].toUpperCase(),
                        style: const TextStyle(fontSize: 24))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? 'N/A',
                        style: GoogleFonts.poppins(fontSize: 16)),
                    Text(
                        user['role'] ??
                            type, // Default to type if role is missing
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey)),
                    Text(
                      user['template'] ??
                          'No event assigned', // Default to 'No event assigned'
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Edit') {
                    if (type == 'Judge') {
                      _editJudge(user);
                    } else {
                      _editAdmin(user);
                    }
                  } else if (value == 'Delete') {
                    if (type == 'Judge') {
                      _deleteJudge(user['id'] as int);
                    } else {
                      _deleteAdmin(user['id'] as int);
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'Edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'Delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editJudge(Map<String, dynamic> judge) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JudgeCreation(
          role: 'Edit Judge',
          judge: judge,
        ),
      ),
    );

    // ignore: use_build_context_synchronously
    Navigator.pop(context); // Dismiss the loading dialog

    if (result != null) {
      setState(() {
        _judgesFuture = _fetchJudges();
      });
    }
  }

  Future<void> _deleteJudge(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteJudge(id);

    setState(() {
      _judgesFuture = _fetchJudges();
    });
  }

  Future<void> _editAdmin(Map<String, dynamic> admin) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCreation(
          role: 'Edit Admin',
          admin: admin,
        ),
      ),
    );

    // ignore: use_build_context_synchronously
    Navigator.pop(context); // Dismiss the loading dialog

    if (result != null) {
      setState(() {
        _adminsFuture = _fetchAdmins();
      });
    }
  }

  Future<void> _deleteAdmin(int id) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deleteAdmin(id);

    setState(() {
      _adminsFuture = _fetchAdmins();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchJudges() async {
    final dbHelper = DatabaseHelper.instance;
    final result = await dbHelper.getJudges();
    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchAdmins() async {
    final dbHelper = DatabaseHelper.instance;
    final result = await dbHelper.getAdmins();
    return result;
  }
}
