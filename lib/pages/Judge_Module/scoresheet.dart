// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
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
  int currentCriteriaIndex = 0;
  int currentCategoryIndex = 0;
  int currentParticipantIndex = 0;

  List<dynamic> _participants = [];
  List<dynamic> _criteria = [];
  List<List<int>> scores = [];
  List<Map<String, dynamic>> _categories = [];
  List<List<int>> categoryScores = [];
  bool _isLoading = true;
  String? templateCode;
  List<TextEditingController> _scoreControllers = [];
  List<TextEditingController> _categoryScoreControllers = [];

  bool isCriteriaEvaluated = false;
  bool isInCategoryEvaluation = false;

  @override
  void initState() {
    super.initState();
    _fetchTemplateDetails();
  }

  Future<void> _fetchTemplateDetails() async {
    templateCode = await DatabaseHelper.instance.getLatestTemplateCode();

    if (templateCode != null && templateCode!.isNotEmpty) {
      try {
        var details =
            await DatabaseHelper.instance.getTemplateDetails(templateCode!);
        if (details != null) {
          _parseTemplateDetails(details);
          scores = List.generate(
            _participants.length,
            (_) => List.filled(_criteria.length, 0),
          );
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
    // Print the fetched details for debugging
    print('Fetched template details: $details');

    _participants = details['participant'] != null
        ? List<Map<String, dynamic>>.from(details['participant'])
            .map((participant) {
            // Assuming you want to set an ID field
            participant['id'] = participant['Number']; // or any unique field
            return participant;
          }).toList()
        : [];

    // Print participants to ensure IDs are present
    print('Participants: $_participants');
    _participants.forEach((participant) {
      print(
          'Participant ID: ${participant['id']}'); // Should now print correctly
    });

    _criteria = details['criteria'] != null
        ? List<Map<String, dynamic>>.from(details['criteria'])
        : [];

    _categories = details['categories'] != null
        ? (details['categories'] as List<dynamic>).map((categoryData) {
            return {
              'Category': categoryData['Category'],
              'Weightage': categoryData['Weightage'],
              'Criteria':
                  (categoryData['Criteria'] as List<dynamic>).map((criterion) {
                return {
                  'Description': criterion['Description'],
                  'Weightage': criterion['Weightage'],
                };
              }).toList(),
            };
          }).toList()
        : [];
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
    // Participant-related data
    final participantId = currentParticipant['id'];
    final judgeEmail = FirebaseAuth.instance.currentUser?.email;
    final judgeId = FirebaseAuth.instance.currentUser?.uid;
    final participantPhoto = currentParticipant['Photo'];
    final participantName = currentParticipant['Name'];

    int? parsedParticipantId = int.tryParse(participantId.toString());
    if (parsedParticipantId == null || parsedParticipantId <= 0) {
      _showErrorSnackBar('Invalid participant ID. Cannot save scores.');
      return;
    }

    // Check if scores for the current participant exist
    if (scores.length <= currentParticipantIndex ||
        scores[currentParticipantIndex].isEmpty) {
      _showErrorSnackBar('No scores available for the current participant.');
      return;
    }

    // Collect participant scores
    List<int> currentScores = scores[currentParticipantIndex];

    // Check for any negative scores
    if (currentScores.any((score) => score < 0)) {
      _showErrorSnackBar('Scores cannot be negative.');
      return;
    }

    // Ensure currentScores is not empty
    if (currentScores.isEmpty) {
      _showErrorSnackBar('No scores to save.');
      return;
    }

    int totalScore = currentScores.fold(0, (sum, score) => sum + score);

    try {
      var templateDetails =
          await DatabaseHelper.instance.getTemplateDetails(templateCode!);
      if (templateDetails == null) {
        _showErrorSnackBar('Template details not found.');
        return;
      }

      String? eventName = templateDetails['eventName'];
      List currentCriteriaDescriptions = _criteria
          .map((criterion) => criterion['Description'] ?? 'N/A')
          .toList();

      Map<String, dynamic> scoreData = {
        'participantId': parsedParticipantId,
        'participantName': participantName,
        'participantPhoto': participantPhoto,
        'scores': currentScores,
        'totalScore': totalScore,
        'judgeEmail': judgeEmail,
        'judgeId': judgeId,
        'criteriaDescriptions': currentCriteriaDescriptions,
        'templateCode': templateCode,
        'eventName': eventName,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save participant scores only
      await FirebaseFirestore.instance.collection('scoresheets').add(scoreData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores saved successfully!')),
        );
      }
    } catch (error) {
      _showErrorSnackBar('Error saving scores: $error');
    }
  }

  Future<void> _saveCategoryScores() async {
    if (_categories.isEmpty) {
      _showErrorSnackBar('No categories available to save scores.');
      return;
    }

    final participantPhoto = currentParticipant['Photo'];
    final participantName = currentParticipant['Name'];
    final participantId = currentParticipant['id'];
    final judgeEmail = FirebaseAuth.instance.currentUser?.email;
    final judgeId = FirebaseAuth.instance.currentUser?.uid;

    List<int> categoryScores = [];
    int totalCategoryScore = 0;
    int categoryIndex = currentCategoryIndex;
    String categoryName = _categories[categoryIndex]['Category'];

    for (int criterionIndex = 0;
        criterionIndex < _categories[categoryIndex]['Criteria'].length;
        criterionIndex++) {
      String scoreText = _categoryScoreControllers[criterionIndex].text;
      int score = int.tryParse(scoreText) ?? 0;
      categoryScores.add(score);
      totalCategoryScore += score;
    }

    if (categoryScores.isEmpty) {
      _showErrorSnackBar(
          'No category scores to save for category $categoryName.');
      return;
    }

    List<String> criterionNames = _categories[categoryIndex]['Criteria']
        .map<String>((criterion) =>
            (criterion as Map<String, dynamic>)['Description'] as String)
        .toList();

    Map<String, dynamic> categoryData = {
      'participantName': participantName,
      'participantPhoto': participantPhoto,
      'templateCode': templateCode,
      'categoryName': categoryName,
      'categoryIndex': categoryIndex,
      'categoryScores': categoryScores,
      'criterionNames': criterionNames,
      'totalCategoryScore': totalCategoryScore,
      'judgeEmail': judgeEmail,
      'judgeId': judgeId,
      'participantId': participantId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('categoryScores')
        .add(categoryData);

    _clearCategoryScoreControllers();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category scores saved successfully!')),
      );
    }
  }

  void _initializeCategoryScoreControllers(int length,
      {String defaultValue = '0'}) {
    if (_categoryScoreControllers.isEmpty) {
      _categoryScoreControllers = List.generate(
        _categories.length,
        (index) => TextEditingController(text: defaultValue),
      );
    }
  }

  void _initializeScoreControllers({String defaultValue = '0'}) {
    // Initialize score controllers if they haven't been set yet
    if (_scoreControllers.isEmpty) {
      _scoreControllers = List.generate(
        _criteria.length,
        (index) => TextEditingController(text: defaultValue),
      );
    }
  }

  void _clearScoreControllers() {
    // Clear all score controllers
    for (var controller in _scoreControllers) {
      controller.clear();
    }
  }

  void _clearCategoryScoreControllers() {
    for (var controller in _categoryScoreControllers) {
      controller.clear(); // Clear each controller
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
                      const Text('Score Sheets',
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
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isCriteriaEvaluated)
            _buildCriteriaFields(), // Show criteria fields if not evaluated
          if (isCriteriaEvaluated)
            _buildCategoryFields(), // Show category fields if evaluated
          const SizedBox(height: 20),

          // Show Total Score Field only when not in category evaluation
          if (!isCriteriaEvaluated) _buildTotalScoreField(),

          const SizedBox(height: 10), // Optional spacing

          // Show Category Total Score Field if categories are present
          if (isCriteriaEvaluated && _categories.isNotEmpty)
            _buildCategoryTotalScoreField(),
        ],
      ),
    );
  }

  Widget _buildCriteriaFields() {
    List<Widget> criteriaWidgets = [];

    for (var index = 0; index < _criteria.length; index++) {
      var criterion = _criteria[index];
      String description = criterion['Description'] ?? 'N/A';
      String weightage = criterion['Weightage']?.toString() ?? '0';

      criteriaWidgets.add(_buildCriteriaField(description, weightage, index));
      criteriaWidgets.add(const SizedBox(height: 10));
    }

    return Column(children: criteriaWidgets);
  }

  Widget _buildCriteriaField(String criteria, String weightage, int index) {
    if (_scoreControllers.length != _criteria.length) {
      _initializeScoreControllers();
    }

    final maxScore = int.tryParse(weightage) ?? 100; // Default to 100

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
              errorStyle: TextStyle(color: Colors.red),
            ),
            onChanged: (value) {
              int inputScore = int.tryParse(value) ?? 0;
              if (inputScore > maxScore) {
                _showScoreLimitSnackbar(maxScore);
                inputScore = maxScore; // Limit score to maxScore
                _scoreControllers[index].text =
                    maxScore.toString(); // Update the controller
                _scoreControllers[index].selection = TextSelection.fromPosition(
                  TextPosition(offset: _scoreControllers[index].text.length),
                );
              }
              scores[currentParticipantIndex][index] =
                  inputScore; // Update score
              setState(() {}); // Refresh UI
            },
          ),
        ),
        Text(weightage, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _showScoreLimitSnackbar(int maxScore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Score cannot exceed $maxScore for this criterion'),
      ),
    );
  }

  Widget _buildCategoryFields() {
    if (_categories.isEmpty) {
      return const Text("No categories available.");
    }

    // Get the current category based on currentCategoryIndex
    var currentCategory = _categories[currentCategoryIndex];
    String categoryName = currentCategory['Category'] ?? 'N/A';
    String categoryWeightage = currentCategory['Weightage']?.toString() ?? '0';
    List criteria = currentCategory['Criteria'] ?? [];

    // Clear category score controllers when switching categories
    _clearCategoryScoreControllers(); // Ensure input fields are cleared for the new category

    // Initialize controllers for category scores based on the number of criteria
    _initializeCategoryScoreControllers(criteria.length);

    return _buildCategoryField(
      categoryName,
      categoryWeightage,
      criteria,
      currentCategoryIndex, // Use the current category index
    );
  }

  Widget _buildCategoryField(
    String categoryName,
    String categoryWeightage,
    List criteria,
    int categoryIndex,
  ) {
    List<Widget> criteriaWidgets = [];
    int totalCategoryScore = 0; // Initialize total category score

    // Ensure categoryScores is initialized for currentParticipantIndex
    if (currentParticipantIndex < categoryScores.length) {
      // Ensure we have a score list for the current participant
      if (categoryScores[currentParticipantIndex].length < criteria.length) {
        // Initialize the scores if necessary
        categoryScores[currentParticipantIndex].addAll(List.filled(
            criteria.length - categoryScores[currentParticipantIndex].length,
            0));
      }
    } else {
      // Initialize a new list if the participant is not present
      categoryScores.add(List.filled(criteria.length, 0));
    }

    for (var criterionIndex = 0;
        criterionIndex < criteria.length;
        criterionIndex++) {
      var criterion = criteria[criterionIndex];
      String description = criterion['Description'] ?? 'N/A';
      String criterionWeightage = criterion['Weightage']?.toString() ?? '0';

      // Get the max score allowed for this criterion
      final maxScore = int.tryParse(criterionWeightage) ?? 100;

      // Use the current score from categoryScores
      int score = (currentParticipantIndex < categoryScores.length &&
              criterionIndex < categoryScores[currentParticipantIndex].length)
          ? categoryScores[currentParticipantIndex][criterionIndex]
          : 0;

      // Initialize the controller text
      if (_categoryScoreControllers.length <= criterionIndex) {
        _categoryScoreControllers.add(
            TextEditingController(text: score > 0 ? score.toString() : ''));
      } else {
        if (_categoryScoreControllers[criterionIndex].text.isEmpty) {
          _categoryScoreControllers[criterionIndex].text =
              score > 0 ? score.toString() : '';
        }
      }

      criteriaWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(description, style: const TextStyle(fontSize: 16)),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _categoryScoreControllers[criterionIndex],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Score',
                  hintStyle: TextStyle(color: Color(0xFFB8B8B8)),
                ),
                onChanged: (value) {
                  int inputScore = int.tryParse(value) ?? 0;

                  // Validate the input score against maxScore
                  if (inputScore > maxScore) {
                    _showScoreLimitSnackbar(maxScore);
                    inputScore = maxScore; // Limit score to maxScore
                    // Update the controller text to maxScore
                    _categoryScoreControllers[criterionIndex].text =
                        maxScore.toString();
                    _categoryScoreControllers[criterionIndex].selection =
                        TextSelection.fromPosition(
                      TextPosition(
                          offset: _categoryScoreControllers[criterionIndex]
                              .text
                              .length),
                    );
                  }

                  // Update categoryScores for the current participant
                  if (currentParticipantIndex < categoryScores.length) {
                    categoryScores[currentParticipantIndex][criterionIndex] =
                        inputScore;
                  }

                  // Update the total category score
                  totalCategoryScore = categoryScores[currentParticipantIndex]
                      .fold(0, (sum, score) => sum + score);

                  setState(() {}); // Update UI
                },
              ),
            ),
            Text(criterionWeightage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
      criteriaWidgets
          .add(const SizedBox(height: 10)); // Spacing between criteria
    }

    // Update the total score display
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10), // Spacing after category title
        Column(children: criteriaWidgets),
        const SizedBox(height: 10), // Spacing before total score
        Text(
          'Total Score: $totalCategoryScore', // Display total category score
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTotalScoreField() {
    // Check if the current participant index is valid
    if (scores.isEmpty || currentParticipantIndex >= scores.length) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Score:',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('0', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }
    // Calculate the total score for the current participant
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

  Widget _buildCategoryTotalScoreField() {
    // Check if the current participant index is valid
    if (currentParticipantIndex >= categoryScores.length) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Category Score:',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('0', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }

    // Calculate total score for the current participant
    int totalScore = categoryScores[currentParticipantIndex].fold(
      0,
      (sum, score) => sum + score,
    );

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Category Score:',
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
        // Button to navigate to the previous participant
        if (currentParticipantIndex > 0)
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentParticipantIndex--;
                isCriteriaEvaluated = false; // Reset evaluation state
                _clearScoreControllers(); // Clear criteria scores
                _clearCategoryScoreControllers(); // Clear category scores
                debugPrint(
                    "Navigated to Participant $currentParticipantIndex, cleared all scores.");
              });
            },
            child: const Text('Previous'),
          ),
        // Button to save scores and navigate
        ElevatedButton(
          onPressed: () async {
            if (!isCriteriaEvaluated) {
              // Check if all criteria are evaluated for the current participant
              bool allCriteriaEvaluated =
                  scores[currentParticipantIndex].every((score) => score > 0);
              debugPrint(
                  "All criteria evaluated for participant $currentParticipantIndex: $allCriteriaEvaluated");

              if (allCriteriaEvaluated) {
                _saveSheets(); // Save scores for the current participant
                debugPrint(
                    "Sheets saved for participant $currentParticipantIndex.");
                _navigateToNextParticipant(); // Move to the next participant
              } else {
                _showSnackBar(
                    'Please evaluate all criteria before proceeding.'); // Show error message
              }
            } else {
              // Save category scores when criteria evaluation is complete
              await _saveCategoryScores();
              _showSnackBar('Category scores saved successfully!');
              debugPrint(
                  "Category scores saved for participant $currentParticipantIndex.");
              _navigateToNextCategoryOrParticipant(); // Move to the next category or participant
            }
          },
          child: Text(isCriteriaEvaluated
              ? 'Save Category Scores'
              : 'Save Criteria Score'),
        ),
      ],
    );
  }

  void _navigateToNextParticipant() {
    setState(() {
      if (currentParticipantIndex < _participants.length - 1) {
        // Switch to the next participant
        currentParticipantIndex++;
        _clearScoreControllers(); // Clear criteria scores
        _clearCategoryScoreControllers(); // Clear category scores
        debugPrint(
            "Moving to Participant $currentParticipantIndex. Cleared all scores.");
      } else {
        // All participants evaluated, reset to the first participant
        isCriteriaEvaluated = true;
        currentParticipantIndex = 0; // Reset to the first participant
        _clearScoreControllers(); // Clear criteria scores
        _clearCategoryScoreControllers(); // Clear category scores
        debugPrint("All participants evaluated. Resetting to Participant 0.");
      }
    });
  }

  void _navigateToNextCategoryOrParticipant() {
    setState(() {
      if (currentParticipantIndex < _participants.length - 1) {
        // Switch to the next participant
        currentParticipantIndex++;
        _clearCategoryScoreControllers(); // Clear category scores when switching participants
        debugPrint(
            "Switching to Participant $currentParticipantIndex. Cleared category scores.");
      } else if (currentCategoryIndex < _categories.length - 1) {
        // Switch to the next category
        switchCategory(
            currentCategoryIndex + 1); // Use the _switchCategory method
        currentParticipantIndex = 0; // Reset for the new category
        debugPrint(
            "Moving to Category $currentCategoryIndex, resetting to Participant 0. Cleared all scores.");
      } else {
        // All evaluations completed, navigate back
        Navigator.pop(context); // Return to the previous screen
        debugPrint(
            "All categories and participants evaluated. Navigating back.");
      }
    });
  }

  void switchCategory(int newCategoryIndex) {
    // Clear scores for the current category and participant
    _clearCategoryScoreControllers();
    if (currentParticipantIndex < categoryScores.length) {
      categoryScores[currentParticipantIndex] = List.filled(
        _categories[currentCategoryIndex]['Criteria'].length,
        0,
      );
    }

    // Update the current category index
    currentCategoryIndex = newCategoryIndex;

    // Rebuild the category fields
    setState(() {
      // Trigger UI update
    });
  }

// Show a SnackBar with a given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
