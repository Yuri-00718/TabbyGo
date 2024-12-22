// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously, avoid_print
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
      final judgesCollection = firestore.collection('judges');

      // Fetch local templates
      final localTemplates = await DatabaseHelper.instance.getTemplates();
      final localTemplateIds =
          localTemplates.map((template) => template['id'].toString()).toSet();

      // Fetch Firestore templates
      final firestoreTemplatesSnapshot = await firestoreCollection.get();
      final firestoreTemplateDocs = firestoreTemplatesSnapshot.docs;
      final firestoreTemplateIds =
          firestoreTemplateDocs.map((doc) => doc.id).toSet();

      final firestoreTemplatesMap = {
        for (var doc in firestoreTemplateDocs) doc.id: doc.data()
      };

      // Templates to sync
      final templatesToAddOrUpdateLocally = <Map<String, dynamic>>[];
      final templatesToAddToFirestore = <Map<String, dynamic>>[];
      final templatesToUpdateInFirestore = <Map<String, dynamic>>[];
      final templatesToDeleteLocally = <String>{};

      final synchronizedTemplateIds =
          await DatabaseHelper.instance.getSynchronizedTemplateIds();

      // Restore missing templates locally
      for (final firestoreTemplateId in firestoreTemplateIds) {
        if (!localTemplateIds.contains(firestoreTemplateId)) {
          final missingTemplate = firestoreTemplatesMap[firestoreTemplateId];
          if (missingTemplate != null) {
            templatesToAddOrUpdateLocally.add({
              ...missingTemplate,
              'id': firestoreTemplateId,
            });
          }
        }
      }

      // Process local templates
      for (final localTemplate in localTemplates) {
        final templateId = localTemplate['id'].toString();

        if (firestoreTemplateIds.contains(templateId)) {
          // Check if the template is identical
          final firestoreTemplate = firestoreTemplatesMap[templateId];
          if (firestoreTemplate != null &&
              !_areTemplatesIdentical(firestoreTemplate, localTemplate)) {
            templatesToUpdateInFirestore.add(localTemplate);
          }
        } else {
          // Add locally missing templates to Firestore
          if (!synchronizedTemplateIds.contains(templateId)) {
            templatesToAddToFirestore.add(localTemplate);
          }
        }
      }

      // Identify templates to delete locally
      templatesToDeleteLocally
          .addAll(localTemplateIds.difference(firestoreTemplateIds));

      // Firestore batch operations
      final firestoreBatch = firestore.batch();

      // Add or update templates in Firestore
      for (final template in templatesToAddToFirestore) {
        final templateId = template['id'].toString();
        firestoreBatch.set(
          firestoreCollection.doc(templateId),
          template,
          SetOptions(merge: true),
        );

        // Add unique judges for the template
        if (template['judges'] != null) {
          final existingJudgeEmails =
              await _getExistingJudgeEmails(judgesCollection, templateId);
          for (final judge in template['judges']) {
            if (!existingJudgeEmails.contains(judge['email'])) {
              firestoreBatch.set(
                judgesCollection.doc(),
                {
                  'templateId': templateId,
                  'eventName': template['eventName'],
                  'templateCode': template['templateCode'],
                  'email': judge['email'],
                  'name': judge['name'],
                  'role': judge['role'],
                  'phonenumber': judge['phonenumber'],
                },
                SetOptions(merge: true),
              );
            }
          }
        }
      }

      for (final template in templatesToUpdateInFirestore) {
        final templateId = template['id'].toString();
        firestoreBatch.set(
          firestoreCollection.doc(templateId),
          template,
          SetOptions(merge: true),
        );

        // Update judges for the template
        if (template['judges'] != null) {
          final existingJudgeEmails =
              await _getExistingJudgeEmails(judgesCollection, templateId);
          for (final judge in template['judges']) {
            if (!existingJudgeEmails.contains(judge['email'])) {
              firestoreBatch.set(
                judgesCollection.doc(),
                {
                  'templateId': templateId,
                  'eventName': template['eventName'],
                  'templateCode': template['templateCode'],
                  'email': judge['email'],
                  'name': judge['name'],
                  'role': judge['role'],
                  'phonenumber': judge['phonenumber'],
                },
                SetOptions(merge: true),
              );
            }
          }
        }
      }

      if (templatesToAddToFirestore.isNotEmpty ||
          templatesToUpdateInFirestore.isNotEmpty) {
        await firestoreBatch.commit();
      }

      // Update local database with missing templates
      for (final template in templatesToAddOrUpdateLocally) {
        await DatabaseHelper.instance.insertOrUpdateTemplate(template);
        await DatabaseHelper.instance
            .markTemplateAsSynchronized(template['id'].toString());
      }

      // Delete locally missing templates
      for (final id in templatesToDeleteLocally) {
        await DatabaseHelper.instance.deleteTemplate(int.parse(id));
      }

      // Reload templates after sync
      await _loadTemplates();

      // Notification for successful sync
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Templates synced successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing templates: $e');
      }

      // Notification for sync failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error syncing templates. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// Helper method to get existing judge emails from the judges collection
  Future<Set<String>> _getExistingJudgeEmails(
      CollectionReference judgesCollection, String templateId) async {
    final judgeQuerySnapshot =
        await judgesCollection.where('templateId', isEqualTo: templateId).get();
    return judgeQuerySnapshot.docs
        .map((doc) => doc['email'].toString())
        .toSet();
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
        const SizedBox(width: 30),
        ElevatedButton(
          onPressed: () async {
            try {
              // Fetch templates from the database
              List<Map<String, dynamic>> templates =
                  await DatabaseHelper.instance.getTemplates();

              if (templates.isNotEmpty) {
                // Show the modal to choose a template for cloning
                Map<String, dynamic>? selectedTemplate =
                    await _showTemplateSelectionDialog(context, templates);

                if (selectedTemplate != null) {
                  print("Selected Template: ${selectedTemplate['eventName']}");

                  // Navigate to TemplateCreation with the selected template
                  _navigateToTemplateCreation(template: selectedTemplate);
                } else {
                  print("No template selected for cloning");
                }
              } else {
                // Show a message if no templates are available
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No templates available to choose from.')),
                );
              }
            } catch (e) {
              print("Error fetching templates: $e");
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5144B6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/Template.png',
                width: 20,
                height: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                'Choose Template',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// choose template modal
  Future<Map<String, dynamic>?> _showTemplateSelectionDialog(
      BuildContext context, List<Map<String, dynamic>> templates) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Choose a Template",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: templates.isNotEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: templates.map((template) {
                      String templateTitle =
                          template['eventName'] ?? 'Untitled Template';
                      List<dynamic> criteriaList = template['criteria'] ?? [];
                      List<dynamic> categoriesList =
                          template['categories'] ?? [];

                      // Format criteria as a bulleted list
                      String criteriaDetails = criteriaList.isNotEmpty
                          ? criteriaList
                              .map((c) =>
                                  "• ${c['Description']} (${c['Weightage']}%)")
                              .join("\n")
                          : "No criteria available.";

                      // Format categories and their criteria as a nested list
                      String categoriesDetails = categoriesList.isNotEmpty
                          ? categoriesList.map((category) {
                              String categoryName = category['Category'] ?? '';
                              List<dynamic> categoryCriteria =
                                  category['Criteria'] ?? [];

                              String formattedCriteria = categoryCriteria
                                      .isNotEmpty
                                  ? categoryCriteria
                                      .map((c) =>
                                          "   - ${c['Description']} (${c['Weightage']}%)")
                                      .join("\n")
                                  : "   No criteria.";

                              return "• $categoryName\n$formattedCriteria";
                            }).join("\n\n")
                          : "No categories available.";

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          title: Text(
                            templateTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Criteria:",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    criteriaDetails,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Categories:",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    categoriesDetails,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            // Clone the template data
                            Map<String, dynamic> clonedTemplate = {
                              'criteria': template['criteria'] ?? [],
                              'categories': template['categories'] ?? [],
                            };

                            // Close the dialog and return the cloned template
                            Navigator.of(context).pop(clonedTemplate);
                          },
                        ),
                      );
                    }).toList(),
                  )
                : Center(
                    child: Text(
                      "No templates available.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5144B6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Widget> _buildContentEvents(Map<String, dynamic> template) async {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if the screen width is for web
        final isWebView = constraints.maxWidth > 600;

        return Container(
          margin: const EdgeInsets.fromLTRB(0, 25, 0, 16),
          padding: const EdgeInsets.fromLTRB(20, 13, 25, 13),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEFEEFC)),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFFFFFF),
          ),
          constraints: isWebView
              ? const BoxConstraints(maxWidth: 800) // Limit max width on web
              : null,
          child: Center(
            child: Row(
              mainAxisAlignment: isWebView
                  ? MainAxisAlignment.spaceBetween // Spread content in web view
                  : MainAxisAlignment.start, // Stack content in mobile view
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
                            fontSize: isWebView ? 18 : 20, // Adjust font size
                            height: 1.5,
                            color: const Color(0xFF0C092A),
                          ),
                        ),
                      ),
                      Text(
                        'Event Code Template: ${template['templateCode'] ?? 'No Code'}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: isWebView ? 14 : 16, // Adjust font size
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
                ),
              ],
            ),
          ),
        );
      },
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
