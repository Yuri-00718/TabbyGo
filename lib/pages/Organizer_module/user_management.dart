// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:tabby/pages/Organizer_Module/user_admin_creation.dart';
import 'package:tabby/pages/Organizer_Module/user_judge_creation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
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
            final page = const JudgeCreation(role: 'Add Judge +', judge: {});

            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
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
                _judgesFuture = _fetchJudges();
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
              'Add Judge +',
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _syncData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Sync Data'),
            ),
          ],
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
      } else {
        _adminsFuture = _fetchAdmins();
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

  Widget _buildAdminListSection() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
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
                  child: _buildUserCard(admin, 'Admin'),
                );
              },
            );
          }
        },
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
                    if (type == 'Admin')
                      Text(
                        'Administrator',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 122, 30, 241)),
                      )
                    else
                      Text(
                        user['role'] ?? type,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey),
                      ),
                    if (type != 'Admin')
                      Text(
                        user['template'] ?? 'No event assigned',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 82, 15, 207)),
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
      barrierDismissible: false,
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
    final db = DatabaseHelper.instance;
    final List<Map<String, dynamic>> judges = await db.getJudges();
    return judges;
  }

  Future<List<Map<String, dynamic>>> _fetchAdmins() async {
    final db = DatabaseHelper.instance;
    final List<Map<String, dynamic>> admins = await db.getAdmins();
    return admins;
  }

  Future<void> _syncData() async {
    // Retrieve data from SQLite
    final db = DatabaseHelper.instance;
    final judges = await db.getJudges();
    final admins = await db.getAdmins();

    // Firestore instance
    final firestore = FirebaseFirestore.instance;

    // Sync Judges
    for (final judge in judges) {
      final judgeId = judge['id'].toString(); // Convert to String
      final existingDoc =
          await firestore.collection('judges').doc(judgeId).get();
      if (existingDoc.exists) {
        // Update Firestore
        await firestore.collection('judges').doc(judgeId).update(judge);
      } else {
        // Add new Firestore document
        await firestore.collection('judges').doc(judgeId).set(judge);
      }
    }

    // Sync Admins
    for (final admin in admins) {
      final adminId = admin['id'].toString();
      final adminWithCorrectRole = {
        ...admin,
        'role': 'Administrator',
      };

      final existingDoc =
          await firestore.collection('admins').doc(adminId).get();
      if (existingDoc.exists) {
        // Update Firestore with correct role
        await firestore
            .collection('admins')
            .doc(adminId)
            .update(adminWithCorrectRole);
      } else {
        // Add new Firestore document with correct role
        await firestore
            .collection('admins')
            .doc(adminId)
            .set(adminWithCorrectRole);
      }
    }

    // Notify user of successful sync
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data synchronized successfully!')),
    );
  }
}
