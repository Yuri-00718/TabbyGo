import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/data_base_helper.dart';
import 'package:tabby/pages/template_creation.dart';

class TemplateMenus extends StatefulWidget {
  const TemplateMenus({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TemplateMenusState createState() => _TemplateMenusState();
}

class _TemplateMenusState extends State<TemplateMenus> {
  List<Widget> contentEvents = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates(); // Load templates when the widget initializes
  }

  Future<void> _loadTemplates() async {
    try {
      List<Map<String, dynamic>> templates =
          await DatabaseHelper.instance.getTemplates();
      if (kDebugMode) {
        print('Loaded templates: $templates');
      }
      setState(() {
        contentEvents = templates.map((template) {
          return _buildContentEvents(template);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading templates: $e');
      }
    }
  }

  void _navigateToTemplateCreation({Map<String, dynamic>? template}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateCreation(
          template: template, // Pass the template data here
        ),
      ),
    );

    // Reload templates after returning from the template creation screen
    _loadTemplates();
  }

  void _editTemplate(Map<String, dynamic> template) async {
    _navigateToTemplateCreation(template: template);
  }

  void _deleteTemplate(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this template?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteTemplate(id);
        _loadTemplates(); // Reload templates after deletion
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting template: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF6A5AE0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 17, 51),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBackSection(context),
              Expanded(
                child: ListView.builder(
                  itemCount: contentEvents.length,
                  itemBuilder: (context, index) {
                    return contentEvents[index];
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 38.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset('assets/vectors/frame_x2.svg'),
                ),
                const SizedBox(width: 10),
                Text(
                  'GOOD MORNING',
                  style: GoogleFonts.getFont(
                    'Rubik',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.5,
                    letterSpacing: 0.5,
                    color: const Color(0xFFFFD6DD),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Administrator',
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
    );
  }

  Widget _buildBackSection(BuildContext context) {
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
        Text(
          'Templates',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            height: 1.5,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _buildContentEvents(Map<String, dynamic> template) {
    if (kDebugMode) {
      print('Building content for template: $template');
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 25, 0, 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEFEEFC)),
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFFFFF),
      ),
      padding: const EdgeInsets.fromLTRB(20, 13, 25, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                  child: Text(
                    template['eventName'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      height: 1.5,
                      color: const Color(0xFF0C092A),
                    ),
                  ),
                ),
                Text(
                  'Event Code Template: ${template['templateCode'] ?? 'No Code'}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.5,
                    color: const Color(0xFF858494),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: SizedBox(
              width: 35,
              height: 35,
              child: Image.asset(
                'assets/images/menu.png',
                color: const Color(0xFF6A5AE0),
                fit: BoxFit.contain,
              ),
            ),
            onSelected: (String value) {
              if (value == 'edit') {
                _editTemplate(template);
              } else if (value == 'delete') {
                _deleteTemplate(template['id']);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      backgroundColor: Colors.white,
      onPressed: () {
        _navigateToTemplateCreation();
      },
      child: const Icon(
        Icons.add,
        color: Color(0xFF6A5AE0),
      ),
    );
  }
}
