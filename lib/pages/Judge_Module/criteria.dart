import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:google_fonts/google_fonts.dart';

class CriteriaPage extends StatefulWidget {
  const CriteriaPage({super.key});

  @override
  _CriteriaPageState createState() => _CriteriaPageState();
}

class _CriteriaPageState extends State<CriteriaPage> {
  Map<String, dynamic>? _templateDetails;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchTemplateCodeAndDetails();
  }

  void _fetchTemplateCodeAndDetails() async {
    String? templateCode =
        await DatabaseHelper.instance.getLastSavedTemplateCode();

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
        print('Error fetching template details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false; // Stop loading on error
        });
      }
    }
  }

  void _parseTemplateDetails(Map<String, dynamic> details) {
    details['criteria'] = _decodeJson(details['criteria']);
  }

  dynamic _decodeJson(dynamic value) {
    return value is String ? jsonDecode(value) : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Judging Criteria')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading // Show loading indicator or criteria details
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (_templateDetails != null) ...[
                      for (var criterion in _templateDetails!['criteria'] ?? [])
                        CriterionCard(
                          description: criterion['Description'] ?? 'N/A',
                          weightage: criterion['Weightage'] ?? 'N/A',
                        ),
                      const SizedBox(height: 16), // Spacer
                      const TotalWeightageCard(totalWeightage: 100),
                    ] else ...[
                      const Text('No criteria found for this template code.',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class CriterionCard extends StatelessWidget {
  final String description;
  final dynamic weightage;

  const CriterionCard({
    Key? key,
    required this.description,
    required this.weightage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 40, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Weightage: $weightage%',
                    style: GoogleFonts.poppins(fontSize: 16.0),
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

class TotalWeightageCard extends StatelessWidget {
  final int totalWeightage;

  const TotalWeightageCard({
    super.key,
    required this.totalWeightage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment, size: 40, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Total Weightage: $totalWeightage%',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }
}
