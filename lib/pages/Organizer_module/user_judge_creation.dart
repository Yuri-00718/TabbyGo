import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:image_picker/image_picker.dart';

class JudgeCreation extends StatefulWidget {
  final String role;
  final Map<String, dynamic> judge;

  const JudgeCreation({
    super.key,
    required this.role,
    required this.judge,
  });

  @override
  // ignore: library_private_types_in_public_api
  _JudgeCreationState createState() => _JudgeCreationState();
}

class _JudgeCreationState extends State<JudgeCreation> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _selectedTemplate;
  List<String> _templates = [];
  XFile? _imageFile;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _initializeForm();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await DatabaseHelper.instance.getTemplates();
      setState(() {
        _templates = templates
            .map((template) => template['eventName'].toString())
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading templates: $e');
      }
    }
  }

  void _initializeForm() {
    final judge = widget.judge;
    _nameController.text = judge['name'] ?? '';
    _usernameController.text = judge['username'] ?? '';
    _passwordController.text = judge['password'] ?? '';
    _confirmPasswordController.text = judge['password'] ?? '';
    _selectedRole = judge['role'];

    // Set default template if not available in the list
    _selectedTemplate = _templates.contains(judge['template'])
        ? judge['template']
        : (_templates.isNotEmpty ? _templates.first : null);

    // Load image from path if available
    if (judge['image'] != null) {
      _imageFile = XFile(judge['image']);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text;
      final username = _usernameController.text;
      final password = _passwordController.text;
      final role = _selectedRole;
      final template = _selectedTemplate;

      final imagePath = _imageFile?.path;

      final judgeData = {
        'name': name,
        'username': username,
        'password': password,
        'role': role,
        'template': template,
        'image': imagePath,
      };

      try {
        final dbHelper = DatabaseHelper.instance;

        // Save judge data locally
        if (widget.judge.isEmpty) {
          await dbHelper.insertJudge(judgeData);
        } else {
          await dbHelper.updateJudge(widget.judge['id'], judgeData);
        }

        if (!mounted) return; // Check if widget is still in the tree

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.judge.isEmpty
                ? 'Judge created successfully'
                : 'Judge updated successfully'),
          ),
        );

        // Navigate back
        Navigator.pop(context);

        // After navigation, clear the form
        _formKey.currentState?.reset();
        setState(() {
          _imageFile = null;
          _selectedTemplate = null;
          _selectedRole = null;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error saving judge: $e');
        }

        if (!mounted) return; // Check if widget is still in the tree

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving judge')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          color: const Color(0xFF6A5AE0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(),
                const SizedBox(height: 19),
                _buildFormCreationSection(context),
                const SizedBox(height: 19),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildForm(),
                  ),
                ),
              ],
            ),
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
                      'GOOD MORNING ',
                      style: GoogleFonts.getFont(
                        'Rubik',
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
              style: GoogleFonts.getFont(
                'Rubik',
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

  Widget _buildFormCreationSection(BuildContext context) {
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
            widget.judge.isEmpty
                ? 'Create Judge Account'
                : 'Edit Judge Account',
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

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(File(_imageFile!.path))
                        : null,
                    child: _imageFile == null
                        ? const Icon(Icons.camera_alt,
                            color: Colors.white, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Judge Name',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter judge name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTemplate,
              decoration: InputDecoration(
                labelText: 'Select Template',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _templates
                  .map((template) => DropdownMenuItem<String>(
                        value: template,
                        child: Text(template),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTemplate = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a template';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Select Role',
                labelStyle: GoogleFonts.poppins(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                'Lead Judge',
                'Head Judge',
                'Technical Judge',
                'Guest Judge',
              ]
                  .map((role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a role';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(
                  widget.judge.isEmpty ? 'Create Judge' : 'Update Judge',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
