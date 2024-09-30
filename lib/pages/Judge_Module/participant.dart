import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart'; // Import your DatabaseHelper

class ParticipantsPage extends StatefulWidget {
  final String? templateCode;

  const ParticipantsPage({super.key, required this.templateCode});

  @override
  _ParticipantsPageState createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  List<dynamic> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplateCodeAndDetails();
  }

  void _fetchTemplateCodeAndDetails() async {
    String? templateCode;

    if (widget.templateCode != null && widget.templateCode!.isNotEmpty) {
      templateCode = widget.templateCode!;
    } else {
      templateCode = await DatabaseHelper.instance.getLastSavedTemplateCode();
    }

    if (templateCode != null) {
      await _fetchTemplateDetails(templateCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved template codes found.')),
      );
      setState(() {
        _isLoading = false; // Stop loading if no template code
      });
    }
  }

  Future<void> _fetchTemplateDetails(String templateCode) async {
    if (templateCode.isNotEmpty) {
      try {
        print('Fetching details for template code: $templateCode');
        var details =
            await DatabaseHelper.instance.getTemplateDetails(templateCode);
        print('Fetched details: $details');

        if (details != null) {
          _parseTemplateDetails(details);
          print('Parsed participants: $_participants');

          setState(() {
            _isLoading = false; // Stop loading after fetching
          });
        } else {
          print('No details found for template code: $templateCode');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No template found for this code.')),
          );
          setState(() {
            _isLoading = false; // Stop loading if no details found
          });
        }
      } catch (e) {
        print('Error fetching template details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch template details.')),
        );
        setState(() {
          _isLoading = false; // Stop loading on error
        });
      }
    }
  }

  void _parseTemplateDetails(Map<String, dynamic> details) {
    // Decode and parse participant details
    if (details['participant'] != null) {
      _participants = _decodeJson(details['participant']);
    } else {
      _participants = []; // Handle case where no participants are found
    }
  }

  dynamic _decodeJson(dynamic value) {
    return value is String ? jsonDecode(value) : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'List of Participants',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6A5AE0),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final participant = _participants[index];
                  return _buildParticipantCard(participant);
                },
              ),
            ),
    );
  }

  Widget _buildParticipantCard(dynamic participant) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const ShapeDecoration(
              shape: OvalBorder(
                side: BorderSide(
                  width: 1.50,
                  color: Color(0xFFE6E6E6),
                ),
              ),
            ),
            child: Center(
              child: Text(
                participant['Number'] ?? 'N/A',
                style: const TextStyle(
                  color: Color(0xFF7A798B),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 2.0,
                color: const Color(0xFFE6E6E6),
              ),
            ),
            child: ClipOval(
              child: Image.network(
                participant['Photo'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant['Name'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  participant['TeamName'] ?? 'N/A',
                  style: const TextStyle(
                    color: Color(0xFF7A798B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
