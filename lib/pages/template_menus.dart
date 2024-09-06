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

      // Perform asynchronous operations before calling setState
      List<Widget> loadedContentEvents = await Future.wait(
        templates.map((template) => _buildContentEvents(template)).toList(),
      );

      // Update the state with the loaded results
      setState(() {
        contentEvents = loadedContentEvents;
      });
    } catch (e) {
      _handleError('Error loading templates', e);
    }
  }

  void _navigateToTemplateCreation({Map<String, dynamic>? template}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateCreation(template: template),
      ),
    );
    _loadTemplates(); // Reload templates after returning from the template creation screen
  }

  Future<void> _editTemplate(Map<String, dynamic> template) async {
    _navigateToTemplateCreation(template: template);
  }

  Future<void> _deleteTemplate(int id) async {
    bool? confirm = await _showConfirmationDialog(
      title: 'Confirm Delete',
      content: 'Are you sure you want to delete this template?',
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteTemplate(id);
        _loadTemplates(); // Reload templates after deletion
      } catch (e) {
        _handleError('Error deleting template', e);
      }
    }
  }

  Future<void> _resetDatabaseSchema() async {
    bool? confirm = await _showConfirmationDialog(
      title: 'Confirm Reset',
      content: 'Are you sure you want to reset the database schema?',
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.resetDatabase(); // Reset the schema
        _loadTemplates(); // Optionally reload templates or handle UI updates
      } catch (e) {
        _handleError('Error resetting database schema', e);
      }
    }
  }

  Future<bool?> _showConfirmationDialog(
      {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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
  }

  void _handleError(String message, Object error) {
    if (kDebugMode) {
      print('$message: $error');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message. Please try again.')),
    );
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: _resetDatabaseSchema,
          child: const Text('Delete All Templates'),
        ),
      ],
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

  Future<Widget> _buildContentEvents(Map<String, dynamic> template) async {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 25, 0, 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEFEEFC)),
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFFFFF),
      ),
      padding: const EdgeInsets.fromLTRB(20, 13, 25, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
              ),
            ),
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'Delete',
                  child: Text('Delete'),
                ),
              ];
            },
            onSelected: (value) {
              switch (value) {
                case 'Edit':
                  _editTemplate(template);
                  break;
                case 'Delete':
                  _deleteTemplate(template['id']);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      onPressed: () => _navigateToTemplateCreation(),
      child: const Icon(Icons.add),
    );
  }
}
