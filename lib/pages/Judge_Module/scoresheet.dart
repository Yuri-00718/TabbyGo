// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tabby/pages/Judge_Module/Judge_Chat_Module.dart';

class ScoresheetPage extends StatefulWidget {
  const ScoresheetPage({super.key});

  @override
  _ScoresheetPageState createState() => _ScoresheetPageState();
}

class _ScoresheetPageState extends State<ScoresheetPage> {
  int currentParticipantIndex = 0;
  List<dynamic> _participants = [];
  List<dynamic> _criteria = [];
  List<List<int>> scores = [];
  bool _isLoading = true;
  String? templateCode;
  List<TextEditingController> _scoreControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchTemplateDetails();
  }

  Future<void> _fetchTemplateDetails() async {
    templateCode = await DatabaseHelper.instance
        .getLatestTemplateCode(); // Fetching the template code

    if (templateCode != null && templateCode!.isNotEmpty) {
      try {
        var details =
            await DatabaseHelper.instance.getTemplateDetails(templateCode!);
        if (details != null) {
          _parseTemplateDetails(details);
          scores = List.generate(
              _participants.length, (_) => List.filled(_criteria.length, 0));
          _initializeScoreControllers();

          setState(() {
            _isLoading = false;
          });
        } else {
          _showErrorSnackBar(
              'No details found for template code: $templateCode');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to fetch template details.');
      }
    } else {
      _showErrorSnackBar('Template code is invalid or empty.');
    }
  }

  void _parseTemplateDetails(Map<String, dynamic> details) {
    _participants = details['participant'] != null
        ? _decodeJson(details['participant'])
        : [];
    _criteria =
        details['criteria'] != null ? _decodeJson(details['criteria']) : [];

    // Assign a sequential ID starting from 1 if the participant ID is null
    for (int i = 0; i < _participants.length; i++) {
      if (_participants[i]['id'] == null) {
        _participants[i]['id'] = i + 1; // Start IDs from 1
      }
    }
  }

  dynamic _decodeJson(dynamic value) {
    return value is String ? jsonDecode(value) : value;
  }

//participant getter natin idol
  Map<String, dynamic> get currentParticipant =>
      _participants.isNotEmpty ? _participants[currentParticipantIndex] : {};

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _isLoading = false;
    });
  }

  void _saveSheets() async {
    final participantId = currentParticipant['id'];
    final judgeEmail = FirebaseAuth.instance.currentUser?.email;
    final judgeId = FirebaseAuth.instance.currentUser?.uid;
    final participantPhoto = currentParticipant['Photo'];
    final participantName = currentParticipant['Name'];

    if (participantId == null || participantId <= 0) {
      _showErrorSnackBar('Invalid participant ID. Cannot save scores.');
      return;
    }

    // Ensure the scores are being captured correctly
    List<int> currentScores = scores[currentParticipantIndex];
    print('Current Scores for Participant: $currentScores'); // Debugging line

    // Calculate total score
    int totalScore = currentScores.fold(0, (sum, score) => sum + score);
    print('Calculated Total Score: $totalScore'); // Debugging line

    if (currentScores.any((score) => score < 0)) {
      _showErrorSnackBar('Scores cannot be negative.');
      return;
    }

    try {
      // Retrieve template details to get event name
      var templateDetails =
          await DatabaseHelper.instance.getTemplateDetails(templateCode!);

      // Check if templateDetails is null and handle it
      if (templateDetails == null) {
        _showErrorSnackBar('Template details not found.');
        return;
      }

      String? eventName = templateDetails[
          'eventName']; // Ensure this matches your Firestore field name

      await FirebaseFirestore.instance.collection('scoresheets').add({
        'participantId': participantId,
        'participantName': participantName,
        'participantPhoto': participantPhoto,
        'scores': currentScores, // Save the current scores here
        'totalScore': totalScore,
        'judgeEmail': judgeEmail,
        'judgeId': judgeId,
        'templateCode': templateCode,
        'eventName': eventName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores saved successfully!')));
    } catch (error) {
      _showErrorSnackBar('Error saving scores: $error');
    }
  }

  void _initializeScoreControllers() {
    _scoreControllers = List.generate(
        _criteria.length, (index) => TextEditingController(text: '0'));
  }

  void _clearScoreControllers() {
    for (var controller in _scoreControllers) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAE6FA),
        elevation: 0,
        title: const Text('Tabby Go', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to Judge_Chat_Module when the icon is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatScreen(
                            chatId: 'chat_id_between_admin_and_judge',
                          )),
                );
              },
              child: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.timer, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_participants.isNotEmpty)
                      _buildParticipantCard(currentParticipant),
                    const SizedBox(height: 20),
                    if (_criteria.isNotEmpty) ...[
                      const Text('Criteria',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildCriteriaContainer(),
                    ] else
                      const Text('No criteria available'),
                    const SizedBox(height: 20),
                    _buildCommentField(),
                    const SizedBox(height: 20),
                    _buildNavigationButtons(),
                  ],
                ),
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
              color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const ShapeDecoration(
              shape: OvalBorder(
                  side: BorderSide(width: 1.50, color: Color(0xFFE6E6E6))),
            ),
            child: Center(
              child: Text(participant['Number'] ?? 'N/A',
                  style:
                      const TextStyle(color: Color(0xFF7A798B), fontSize: 12)),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2.0, color: const Color(0xFFE6E6E6)),
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
                Text(participant['Name'] ?? 'N/A',
                    style: const TextStyle(color: Colors.black, fontSize: 18)),
                const SizedBox(height: 4),
                Text(participant['TeamName'] ?? 'N/A',
                    style: const TextStyle(
                        color: Color(0xFF7A798B), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaContainer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildCriteriaFields(),
          const SizedBox(height: 20),
          _buildTotalScoreField(), // Move total score display here
        ],
      ),
    );
  }

  Widget _buildCriteriaFields() {
    List<Widget> criteriaWidgets = [];

    for (var index = 0; index < _criteria.length; index++) {
      var criterion = _criteria[index];
      String description = criterion['Description'] ?? 'N/A';
      String weightage = criterion['Weightage'] ?? '0';

      criteriaWidgets.add(_buildCriteriaField(description, weightage, index));
      criteriaWidgets.add(const SizedBox(height: 10));
    }

    return Column(children: criteriaWidgets);
  }

  Widget _buildCriteriaField(String criteria, String weightage, int index) {
    if (_scoreControllers.length != _criteria.length) {
      _initializeScoreControllers();
    }

    // Convert weightage to an integer for validation
    final maxScore =
        int.tryParse(weightage) ?? 100; // Default to 100 if parsing fails
    int score =
        int.tryParse(_scoreControllers[index].text) ?? 0; // Current score

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(criteria, style: const TextStyle(fontSize: 16))),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _scoreControllers[index],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Score',
              hintStyle: TextStyle(color: Color(0xFFB8B8B8)),
              // Change text color if score exceeds maxScore
              errorStyle: TextStyle(color: Colors.red),
            ),
            style: TextStyle(
              color: score > maxScore ? Colors.red : Colors.black,
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                int score = int.tryParse(value) ?? 0;

                // Ensure score doesn't exceed maxScore (weightage)
                if (score > maxScore) {
                  setState(() {
                    _scoreControllers[index].text =
                        maxScore.toString(); // Reset to maxScore
                    scores[currentParticipantIndex][index] = maxScore;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Score cannot exceed $maxScore for this criterion'),
                    ),
                  );
                } else {
                  scores[currentParticipantIndex][index] = score;
                }
              }
              setState(() {}); // Update UI to reflect score changes
            },
          ),
        ),
        Text(weightage, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildTotalScoreField() {
    int totalScore =
        scores[currentParticipantIndex].fold(0, (sum, score) => sum + score);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Score:',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Text(totalScore.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return const TextField(
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Add a comment...',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentParticipantIndex > 0)
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentParticipantIndex--;
                _clearScoreControllers();
              });
            },
            child: const Text('Previous'),
          ),
        if (currentParticipantIndex < _participants.length - 1)
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirmation'),
                    content: const Text(
                        'Do you want to save scores for this participant?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _saveSheets();
                          setState(() {
                            currentParticipantIndex++;
                            _clearScoreControllers();
                          });
                        },
                        child: const Text('Yes'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('No'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Next'),
          ),
        if (currentParticipantIndex == _participants.length - 1)
          ElevatedButton(
            onPressed: () {
              _saveSheets();
              // Navigate back to Dashboard or another page after submission
              Navigator.of(context).pop();
            },
            child: const Text('Submit'),
          ),
      ],
    );
  }
}
