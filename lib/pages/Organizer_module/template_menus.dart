// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:tabby/pages/Organizer_Module/template_creation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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
    _loadTemplates();
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

      final localTemplates = await DatabaseHelper.instance.getTemplates();
      final localTemplateIds =
          localTemplates.map((template) => template['id'].toString()).toSet();

      final firestoreTemplatesSnapshot = await firestoreCollection.get();
      final firestoreTemplateDocs = firestoreTemplatesSnapshot.docs;
      final firestoreTemplateIds =
          firestoreTemplateDocs.map((doc) => doc.id).toSet();

      final firestoreTemplatesMap = {
        for (var doc in firestoreTemplateDocs) doc.id: doc.data()
      };

      final templatesToAdd = <Map<String, dynamic>>[];
      final templatesToUpdate = <Map<String, dynamic>>[];
      final templatesToDelete = <String>{};

      final synchronizedTemplateIds =
          await DatabaseHelper.instance.getSynchronizedTemplateIds();

      for (final template in localTemplates) {
        final templateId = template['id'].toString();

        if (firestoreTemplateIds.contains(templateId)) {
          final firestoreTemplate = firestoreTemplatesMap[templateId];
          if (firestoreTemplate != null &&
              !_areTemplatesIdentical(firestoreTemplate, template)) {
            templatesToUpdate.add(template);
          }
        } else {
          if (!synchronizedTemplateIds.contains(templateId)) {
            templatesToAdd.add(template);
          }
        }
      }

      final templatesInFirestoreNotInLocal =
          firestoreTemplateIds.difference(localTemplateIds);
      templatesToDelete.addAll(templatesInFirestoreNotInLocal);

      final firestoreBatch = firestore.batch();
      for (final template in templatesToAdd) {
        final templateId = template['id'].toString();
        firestoreBatch.set(firestoreCollection.doc(templateId), template,
            SetOptions(merge: true));
      }
      for (final template in templatesToUpdate) {
        final templateId = template['id'].toString();
        firestoreBatch.set(firestoreCollection.doc(templateId), template,
            SetOptions(merge: true));
      }
      if (templatesToAdd.isNotEmpty || templatesToUpdate.isNotEmpty) {
        await firestoreBatch.commit();
      }
      for (final id in templatesToDelete) {
        await DatabaseHelper.instance.deleteTemplate(int.parse(id));
      }

      final updatedFirestoreTemplatesData = firestoreTemplateDocs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      for (final templateData in updatedFirestoreTemplatesData) {
        final templateId = templateData['id'];
        if (!synchronizedTemplateIds.contains(templateId)) {
          await DatabaseHelper.instance.insertOrUpdateTemplate(templateData);
          await DatabaseHelper.instance.markTemplateAsSynchronized(templateId);
        }
      }

      await _loadTemplates(); // Reload templates after sync
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Templates synchronized successfully!')),
      );
    } catch (e) {
      _handleError('Error syncing templates', e);
    }
  }

// Helper function to compare templates
  bool _areTemplatesIdentical(Map<String, dynamic> firestoreTemplate,
      Map<String, dynamic> localTemplate) {
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
        _loadTemplates();
      } catch (e) {
        _handleError('Error deleting template', e);
      }
    }
  }

  Future<void> _sendTemplateCodeToJudges(
      BuildContext context, String templateCode) async {
    try {
      // Retrieve judge emails from the local database
      final judgeEmails = await DatabaseHelper.instance
          .getJudgeEmailsFromTemplate(templateCode);

      if (judgeEmails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No judge emails found for the template.'),
          ),
        );
        return;
      }

      // Define the SMTP server
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        username: 'Lloydeast1@gmail.com',
        password: 'kgou urak cemu wetz',
        ssl: true,
        port: 465,
        ignoreBadCertificate: true,
      );

      // Create the message
      final message = Message()
        ..from = const Address('Lloydeast1@gmail.com', 'Tabby Go!')
        ..recipients.addAll(judgeEmails)
        ..subject = 'Template Code for Event is $templateCode'
        ..text =
            'Hello Judge!,\n\nHere is the template code you requested: $templateCode';

      // Send the email
      final sendReport = await send(message, smtpServer);

      if (kDebugMode) {
        print('Email sent: ${sendReport.toString()}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template code sent to judges successfully.'),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending email: $e'),
        ),
      );
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
                const PopupMenuItem<String>(
                  value: 'Send Code',
                  child: Text('Send Code'),
                ),
              ];
            },
            onSelected: (value) async {
              switch (value) {
                case 'Edit':
                  _editTemplate(template);
                  break;
                case 'Delete':
                  _deleteTemplate(template['id']);
                  break;
                case 'Send Code':
                  await _sendTemplateCodeToJudges(
                      context, template['templateCode']);
                  break;
              }
            },
          )
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
