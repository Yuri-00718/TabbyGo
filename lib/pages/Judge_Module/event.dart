import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class EventPage extends StatefulWidget {
  final String? templateCode;

  const EventPage({super.key, this.templateCode});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  Map<String, dynamic>? _templateDetails;
  bool _isLoading = true; // Add loading state

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
          print('Parsed details: $_templateDetails');

          setState(() {
            _templateDetails = details;
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
        if (kDebugMode) {
          print('Error fetching template details: $e');
        }
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
    details['criteria'] = _decodeJson(details['criteria']);
    details['judges'] = _decodeJson(details['judges']);
    details['participant'] = _decodeJson(details['participant']);
    details['eventMechanics'] = _decodeJson(details['eventMechanics']);
  }

  dynamic _decodeJson(dynamic value) {
    return value is String ? jsonDecode(value) : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Information')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading // Show loading indicator or details
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (_templateDetails != null) ...[
                      InfoCard(
                        title: 'Event Name',
                        icon: Icons.event,
                        content: _templateDetails!['eventName'] ?? 'N/A',
                      ),
                      InfoCard(
                        title: 'Event Date',
                        icon: Icons.calendar_today,
                        content: _templateDetails!['eventDate'] ?? 'N/A',
                      ),
                      InfoCard(
                        title: 'Event Location',
                        icon: Icons.location_on,
                        content: _templateDetails!['eventLocation'] ?? 'N/A',
                      ),
                      InfoCard(
                        title: 'Template Code',
                        icon: Icons.code,
                        content: _templateDetails!['templateCode'] ?? 'N/A',
                      ),
                      for (var criterion in _templateDetails!['criteria'] ?? [])
                        InfoCard(
                          title: 'Criteria',
                          icon: Icons.check_circle,
                          content:
                              'Description: ${criterion['Description'] ?? 'N/A'}, Weightage: ${criterion['Weightage'] ?? 'N/A'}',
                        ),
                      for (var participant
                          in _templateDetails!['participant'] ?? [])
                        InfoCard(
                          title: 'Participants',
                          icon: Icons.person,
                          content:
                              'Name: ${participant['Name'] ?? 'N/A'}, Number: ${participant['Number'] ?? 'N/A'}, Team Name: ${participant['TeamName'] ?? 'N/A'}',
                        ),
                      for (var mechanic
                          in _templateDetails!['eventMechanics'] ?? [])
                        InfoCard(
                          title: 'Event Mechanics',
                          icon: Icons.build,
                          content:
                              '${mechanic['files']?.map((file) => Uri.parse(file).pathSegments.last).join(', ') ?? 'N/A'}',
                        ),
                    ] else ...[
                      const Text('No template found for this code.',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const InfoCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: GoogleFonts.poppins(fontSize: 14.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
