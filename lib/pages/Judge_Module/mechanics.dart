import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({Key? key}) : super(key: key);

  @override
  _MechanicsScreenState createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  List<Map<String, String>> files = []; // To store the file details
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplateMechanicsFiles();
  }

  // Fetch the template code and load associated event mechanics
  Future<void> _fetchTemplateMechanicsFiles() async {
    try {
      // Retrieve the latest saved template code
      String? templateCode =
          await DatabaseHelper.instance.getLastSavedTemplateCode();

      if (templateCode != null) {
        print('Template code used: $templateCode');
        await _loadFilesFromFirebase(
            templateCode); // Load files for the template code
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved template codes found.')),
        );
        setState(() {
          _isLoading = false; // Stop loading if no template code
        });
      }
    } catch (e) {
      print('Error fetching template mechanics files: $e');
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  // Load files based on the template code
  Future<void> _loadFilesFromFirebase(String templateCode) async {
    try {
      // Retrieve template details from Firestore based on template code
      Map<String, dynamic>? templateDetails =
          await DatabaseHelper.instance.getTemplateDetails(templateCode);

      if (templateDetails != null &&
          templateDetails['eventMechanics'] != null) {
        List<Map<String, String>> loadedFiles = [];

        // Decode and extract event mechanics files
        List<dynamic> eventMechanics =
            _decodeJson(templateDetails['eventMechanics']);
        if (eventMechanics.isNotEmpty && eventMechanics[0]['files'] != null) {
          for (var fileUrl in eventMechanics[0]['files']) {
            loadedFiles.add({
              'name': _extractFileName(fileUrl),
              'path': fileUrl,
            });
          }
        }

        setState(() {
          files = loadedFiles; // Update the state with the loaded files
          _isLoading = false; // Stop loading
        });
      } else {
        print('No mechanics found for template code: $templateCode');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No event mechanics found for this template.')),
        );
        setState(() {
          _isLoading = false; // Stop loading if no mechanics found
        });
      }
    } catch (e) {
      print('Error loading files: $e');
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  // Decode JSON (since eventMechanics is a string in Firestore)
  dynamic _decodeJson(dynamic value) {
    return value is String ? jsonDecode(value) : value;
  }

  // Extract file name from the URL
  String _extractFileName(String url) {
    String fileName =
        url.split('/').last.split('?').first; // Extracts file name from URL
    return Uri.decodeComponent(
        fileName); // Decode the file name if it contains URL encoded characters
  }

// Open the file using OpenFilex
  Future<void> _openFile(BuildContext context, String fileUrl) async {
    try {
      // Check for permission before requesting
      if (await Permission.storage.request().isGranted) {
        // Get the external directory (Downloads folder)
        Directory? downloadsDir = await getExternalStorageDirectory();
        final fileName =
            _extractFileName(fileUrl); // Use the method to get the file name
        final filePath =
            '${downloadsDir!.path}/Download/$fileName'; // Path to Downloads folder

        print('Downloads Directory: ${downloadsDir.path}'); // Debugging path

        // Create downloads directory if it doesn't exist
        Directory downloadsFolder = Directory('${downloadsDir.path}/Download');
        if (!downloadsFolder.existsSync()) {
          downloadsFolder.createSync(recursive: true);
        }

        // Download the file to the Downloads folder
        Dio dio = Dio();
        final response = await dio.download(fileUrl, filePath);

        // Check if the file was downloaded successfully
        if (response.statusCode == 200) {
          print('File downloaded successfully to: $filePath');
        } else {
          throw Exception(
              'Failed to download file. Status Code: ${response.statusCode}');
        }

        // Check if the file exists in the directory
        File downloadedFile = File(filePath);
        if (await downloadedFile.exists()) {
          print('File exists at: $filePath'); // Confirm file existence

          // Attempt to open the file using OpenFilex
          final result = await OpenFilex.open(filePath);
          print('Open File Result: ${result.message}');

          if (result.message != 'Done' && result.message != 'File opened') {
            throw Exception('Could not open file: ${result.message}');
          }
        } else {
          throw Exception('File does not exist at path: $filePath');
        }
      } else {
        throw Exception('Storage permission not granted.');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Mechanics'),
        backgroundColor: const Color(0xFF6A5AE0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFE3E0FF), // Set the background color
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: files.isEmpty
                    ? const Center(child: Text('No files uploaded.'))
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const Icon(Icons.insert_drive_file,
                                  size: 40, color: Color(0xFF6A5AE0)),
                              title: Text(
                                files[index]['name']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Tap to open',
                                  style: TextStyle(color: Colors.grey[600])),
                              onTap: () =>
                                  _openFile(context, files[index]['path']!),
                            ),
                          );
                        },
                      ),
              ),
            ),
    );
  }
}
