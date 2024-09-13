import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/data_base_helper.dart';
import 'package:tabby/pages/template_creation.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateMenus extends StatefulWidget {
  const TemplateMenus({super.key});

  @override
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

  Future<void> _syncTemplates() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final firestoreCollection = firestore.collection('templates');

      // Retrieve local templates from SQLite
      final localTemplates = await DatabaseHelper.instance.getTemplates();
      final localTemplateIds =
          localTemplates.map((template) => template['id'].toString()).toSet();
      print('Local templates: $localTemplates');

      // Retrieve templates from Firestore
      final firestoreTemplatesSnapshot = await firestoreCollection.get();
      final firestoreTemplateDocs = firestoreTemplatesSnapshot.docs;
      final firestoreTemplateIds =
          firestoreTemplateDocs.map((doc) => doc.id).toSet();
      print('Firestore templates IDs: $firestoreTemplateIds');

      // Create a map for easy access to Firestore templates
      final firestoreTemplatesMap = {
        for (var doc in firestoreTemplateDocs) doc.id: doc.data()
      };

      // Prepare lists for templates to add, update, and delete
      final templatesToAdd = <Map<String, dynamic>>[];
      final templatesToUpdate = <Map<String, dynamic>>[];
      final templatesToDelete = <String>{};

      // Track which templates have been synchronized to avoid duplication
      final synchronizedTemplateIds =
          await DatabaseHelper.instance.getSynchronizedTemplateIds();

      // Determine which templates to add, update, or delete
      for (final template in localTemplates) {
        final templateId = template['id'].toString();
        print('Processing local template ID: $templateId');

        if (firestoreTemplateIds.contains(templateId)) {
          // Template exists in Firestore, check if it needs to be updated
          final firestoreTemplate = firestoreTemplatesMap[templateId];
          if (firestoreTemplate != null &&
              !_areTemplatesIdentical(firestoreTemplate, template)) {
            templatesToUpdate.add(template);
          }
        } else {
          // Template doesn't exist in Firestore, prepare to add
          if (!synchronizedTemplateIds.contains(templateId)) {
            templatesToAdd.add(template);
          }
        }
      }

      // Determine which templates to delete
      final templatesInFirestoreNotInLocal =
          firestoreTemplateIds.difference(localTemplateIds);
      templatesToDelete.addAll(templatesInFirestoreNotInLocal);

      // Perform batch operations for Firestore
      final firestoreBatch = firestore.batch();
      for (final template in templatesToAdd) {
        final templateId = template['id'].toString();
        firestoreBatch.set(firestoreCollection.doc(templateId), template,
            SetOptions(merge: true));
        print('Queueing addition of template ID: $templateId');
      }
      for (final template in templatesToUpdate) {
        final templateId = template['id'].toString();
        firestoreBatch.set(firestoreCollection.doc(templateId), template,
            SetOptions(merge: true));
        print('Queueing update of template ID: $templateId');
      }
      if (templatesToAdd.isNotEmpty || templatesToUpdate.isNotEmpty) {
        await firestoreBatch.commit();
        print('Batch operation committed to Firestore');
      }

      // Delete templates from local database
      for (final id in templatesToDelete) {
        await DatabaseHelper.instance.deleteTemplate(int.parse(id));
        print('Deleted local template ID: $id');
      }

      // Insert or update Firestore templates in local SQLite
      final updatedFirestoreTemplatesData = firestoreTemplateDocs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure the Firestore document ID is stored
        return data;
      }).toList();
      print('Updated Firestore templates data: $updatedFirestoreTemplatesData');

      for (final templateData in updatedFirestoreTemplatesData) {
        final templateId = templateData['id'];
        if (!synchronizedTemplateIds.contains(templateId)) {
          await DatabaseHelper.instance.insertOrUpdateTemplate(templateData);
          print('Template synchronized from Firestore: $templateId');
          await DatabaseHelper.instance.markTemplateAsSynchronized(templateId);
        }
      }

      // Reload templates from local SQLite database
      await _loadTemplates();

      // Notify user of successful sync
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Templates synchronized successfully!')),
      );
    } catch (e) {
      _handleError('Error syncing templates', e);
      print('Sync error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing template: $e')),
      );
    }
  }

// Helper function to compare templates
  bool _areTemplatesIdentical(Map<String, dynamic> firestoreTemplate,
      Map<String, dynamic> localTemplate) {
    // Compare relevant fields between the templates
    return firestoreTemplate['eventName'] == localTemplate['eventName'] &&
        firestoreTemplate['templateCode'] == localTemplate['templateCode'];
  }

  void _navigateToTemplateCreation({Map<String, dynamic>? template}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateCreation(template: template),
      ),
    );
    _loadTemplates();
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
        ElevatedButton(
          onPressed: _syncTemplates,
          child: const Text('Sync Templates'),
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
