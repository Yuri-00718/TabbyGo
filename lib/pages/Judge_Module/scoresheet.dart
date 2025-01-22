// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, avoid_print, avoid_function_literals_in_foreach_calls, avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tabby/pages/Judge_Module/Judge_Chat_Module.dart';
//import 'package:tabby/pages/Judge_Module/Judge_Chat_Module.dart';

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
  List<Map<String, dynamic>> _penalty = [];
  List<List<int>> scores = [];
  List<Map<String, dynamic>> _categories = [];
  List<List<int>> categoryScores = [];
  bool _isLoading = true;
  String? templateCode;
  List<TextEditingController> _scoreControllers = [];
  List<TextEditingController> _categoryScoreControllers = [];

  String? judgeEmail;
  String? judgeName;
  String? selectedRole;

  bool isCriteriaEvaluated = false;
  bool isInCategoryEvaluation = false;
  bool isPenaltyRoleSelected = false;

  @override
  void initState() {
    super.initState();
    _fetchTemplateDetails();
    _fetchJudgeDetails();
  }

  bool _areAllFieldsValid() {
    for (var controller in _scoreControllers) {
      if (controller.text.isEmpty || double.tryParse(controller.text) == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _fetchJudgeDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      judgeEmail = user.email;
      judgeName = user.displayName;
    }
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
            (_) => List.filled(_penalty.length, 0),
          );
          _initializeScoreControllers();

          setState(() {
            _isLoading = false;
          });

          // Show role selection modal
          _showRoleSelectionModal(details);
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
    // Parse participants
    _participants = details['participant'] != null
        ? List<Map<String, dynamic>>.from(details['participant'])
            .map((participant) {
            participant['id'] = participant['Number']; // Assign unique ID
            return participant;
          }).toList()
        : [];

    // Parse penalty
    _penalty = details['penalty'] != null
        ? List<Map<String, dynamic>>.from(details['penalty'])
        : [];

    // Parse categories
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
              'AssignedJudge': categoryData['AssignedJudge'],
            };
          }).toList()
        : [];
  }

  void _showRoleSelectionModal(Map<String, dynamic> details) {
    List<String> roles = [
      ..._categories
          .map((category) => category['AssignedJudge'] as String)
          .toSet(),
      ..._penalty.map((penalty) => penalty['AssignedJudge'] as String).toSet(),
    ].toList();

    String? temporaryRole;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 132, 96, 214),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Center(
                child: Text(
                  'Select Your Role',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: DropdownButtonFormField<String>(
                  value: temporaryRole,
                  hint: Text(
                    'Select Role',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      temporaryRole = newValue;
                      // Set isPenaltyRoleSelected based on the selected role
                      isPenaltyRoleSelected = _penalty.any(
                          (penalty) => penalty['AssignedJudge'] == newValue);
                    });
                  },
                  dropdownColor: const Color.fromARGB(255, 132, 96, 214),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: roles.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    if (temporaryRole == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select your Role before proceeding.',
                            style: GoogleFonts.poppins(),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      setState(() {
                        selectedRole = temporaryRole;
                      });
                      _filterCategoriesByRole();
                      _filterPenaltiesByRole();
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 132, 96, 214),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

  // Filter categories based on the selected role
  void _filterCategoriesByRole() {
    if (selectedRole != null && selectedRole!.isNotEmpty) {
      print('Filtering categories for role: $selectedRole');

      // Filter categories based on the selected role
      List<Map<String, dynamic>> filteredCategories = _categories
          .where((category) =>
              category['AssignedJudge']?.trim().toLowerCase() ==
              selectedRole!.trim().toLowerCase())
          .toList();

      print('Filtered Categories: $filteredCategories');

      if (filteredCategories.isNotEmpty) {
        // Update categories if valid ones are available
        setState(() {
          _categories = filteredCategories;
          currentCategoryIndex = 0; // Start from the first filtered category
          isCriteriaEvaluated =
              false; // Only evaluate criteria when categories are available
        });
      } else {
        setState(() {
          _categories = [];
          currentCategoryIndex = -1; // No valid categories
        });
      }
    } else {
      print('No selected role, categories cannot be filtered.');
      setState(() {
        _categories = [];
        currentCategoryIndex = -1;
        isCriteriaEvaluated = true; // No categories to evaluate
      });
    }

    print('After filtering categories:');
    print('Categories: $_categories');
    print('isCriteriaEvaluated: $isCriteriaEvaluated');
    print('Current Category Index: $currentCategoryIndex');
  }

// Filter penalties based on the selected role
  void _filterPenaltiesByRole() {
    print('Filtering penalties for role: $selectedRole');

    // Filter penalties based on the selected role
    List<Map<String, dynamic>> filteredPenalties = _penalty
        .where((penalty) =>
            penalty['AssignedJudge']?.trim().toLowerCase() ==
            selectedRole!.trim().toLowerCase())
        .toList();

    print('Filtered Penalties: $filteredPenalties');

    if (filteredPenalties.isNotEmpty) {
      setState(() {
        _penalty = filteredPenalties;
        isCriteriaEvaluated =
            true; // Once penalties are available, mark as evaluated
      });
    } else {
      setState(() {
        _penalty = [];
        isCriteriaEvaluated = true; // No penalties to display, still evaluated
      });
    }

    print('After filtering penalties:');
    print('Penalties: $_penalty');
    print('isCriteriaEvaluated: $isCriteriaEvaluated');
  }

  void _saveSheets() async {
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

    if (scores.length <= currentParticipantIndex ||
        scores[currentParticipantIndex].isEmpty) {
      _showErrorSnackBar('No scores available for the current participant.');
      return;
    }

    List<int> currentScores = scores[currentParticipantIndex];

    if (currentScores.any((score) => score < 0)) {
      _showErrorSnackBar('Scores cannot be negative.');
      return;
    }

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
      List currentCriteriaDescriptions = _penalty
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

      await FirebaseFirestore.instance.collection('Penalties').add(scoreData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penalty scores saved successfully!')),
        );
      }
    } catch (error) {
      _showErrorSnackBar('Error saving penalty scores: $error');
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

    // Fetch template details to get the eventName
    try {
      var templateDetails =
          await DatabaseHelper.instance.getTemplateDetails(templateCode!);
      if (templateDetails == null) {
        _showErrorSnackBar('Template details not found.');
        return;
      }
      String? eventName = templateDetails['eventName'];

      Map<String, dynamic> categoryData = {
        'participantName': participantName,
        'participantPhoto': participantPhoto,
        'templateCode': templateCode,
        'categoryName': categoryName,
        'categoryIndex': categoryIndex,
        'categoryScores': categoryScores,
        'criterionNames': criterionNames, // Added criterionNames field
        'totalCategoryScore': totalCategoryScore,
        'judgeEmail': judgeEmail,
        'judgeId': judgeId,
        'participantId': participantId,
        'eventName': eventName, // Added eventName
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
    } catch (error) {
      _showErrorSnackBar('Error saving category scores: $error');
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
        _penalty.length,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFEAE6FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.15),
        child: SizedBox(
          width: screenWidth,
          height: screenHeight * 0.15,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: screenWidth,
                  height: screenHeight * 0.15,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF5B4EC3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: screenHeight * 0.02,
                top: screenHeight * 0.04,
                child: Container(
                  width: screenWidth * 0.40,
                  height: screenHeight * 0.09,
                  decoration: const ShapeDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/new-tabby.png"),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12.0,
                top: screenHeight * 0.04,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to Judge_Chat_Module when the icon is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(
                            chatId: 'chat_id_between_admin_and_judge',
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.chat_bubble_outline,
                        color: Colors.black),
                  ),
                ),
              ),
              Positioned(
                right: 12.0,
                top: screenHeight * 0.12, // Adjusted position to avoid overlap
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                ),
              ),
            ],
          ),
        ),
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
                    _buildCriteriaContainer(), // Always call this to check both categories and penalties
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      padding: EdgeInsets.all(screenWidth * 0.04),
      width: screenWidth * 0.9,
      height: screenHeight * 0.12,
      decoration: ShapeDecoration(
        color: const Color(0xFFCDC1FF),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: const ShapeDecoration(
              shape: OvalBorder(
                side: BorderSide(width: 1.50, color: Color(0xFFE6E6E6)),
              ),
            ),
            child: Center(
              child: Text(
                participant['Number'] ?? 'N/A',
                style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: screenWidth * 0.03),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Container(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
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
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  participant['Name'] ?? 'N/A',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  participant['TeamName'] ?? 'N/A',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: screenWidth * 0.03),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to build the criteria container with categories and penalties
  Widget _buildCriteriaContainer() {
    print('Building Criteria Container...');
    print('isCriteriaEvaluated: $isCriteriaEvaluated');
    print('Categories: $_categories');
    print('Current Index: $currentCategoryIndex');

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 362,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Display category fields if categories are available
                  if (_categories.isNotEmpty)
                    _buildCategoryFields(), // Show categories after filtering

                  // Only display penalties when there are filtered penalties
                  if (_penalty.isNotEmpty && isCriteriaEvaluated)
                    _buildPenaltyFields(), // Show penalties if available

                  // Show total score if criteria is evaluated
                  if (isCriteriaEvaluated) _buildTotalScoreField(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _buildPenaltyFields() {
    List<Widget> penaltyWidgets = [];

    // Add title row for penalties
    penaltyWidgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Penalty', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Weightage', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    penaltyWidgets.add(const SizedBox(height: 10));

    // Loop through penalties and filter by selected role
    for (var index = 0; index < _penalty.length; index++) {
      var penalty = _penalty[index];
      String description = penalty['Description'] ?? 'N/A';
      String weightage = penalty['Weightage']?.toString() ?? '0';

      // Display penalty fields only if the role matches
      if (penalty['AssignedJudge'] == selectedRole) {
        penaltyWidgets.add(_buildPenaltyField(description, weightage, index));
        penaltyWidgets.add(const SizedBox(height: 10));
      }
    }

    return Column(children: penaltyWidgets);
  }

  Widget _buildPenaltyField(String description, String weightage, int index) {
    // Ensure there is a TextEditingController for each penalty field
    if (_scoreControllers.length <= index) {
      _scoreControllers.add(TextEditingController());
    }

    // Ensure scores list is initialized for the current participant
    if (scores.length <= currentParticipantIndex) {
      scores.add(List.filled(_penalty.length, 0));
    }

    return GestureDetector(
      onTap: () {
        // Handle tap event to view penalty details
        _viewPenaltyDetails(description, weightage);
      },
      child: Container(
        width: 330,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                description,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            // Adding a TextField for inputting score
            SizedBox(
              width: 60,
              height: 40,
              child: TextField(
                controller: _scoreControllers[index],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  hintText: 'Score',
                  hintStyle: TextStyle(color: Color(0xFFB8B8B8)),
                  errorStyle: TextStyle(color: Colors.red),
                ),
                onChanged: (value) {
                  int inputScore = int.tryParse(value) ?? 0;

                  // Optional: Validate if the score doesn't exceed the weightage
                  int maxScore = int.tryParse(weightage) ?? 100;
                  if (inputScore > maxScore) {
                    _showScoreLimitSnackbar(maxScore);
                    inputScore = maxScore;
                    _scoreControllers[index].text = maxScore.toString();
                  }

                  // Update the scores list
                  scores[currentParticipantIndex][index] = inputScore;

                  setState(() {}); // Update UI
                },
              ),
            ),
            const SizedBox(
                width:
                    20), // Space between the score box and the weightage text
            Text('/ $weightage', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _viewPenaltyDetails(String description, String weightage) {
    // Show penalty details in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Penalty Details'),
          content: Text('Penalty: $description\nWeightage: $weightage'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showScoreLimitSnackbar(int maxScore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Score cannot exceed $maxScore for this criterion'),
      ),
    );
  }

// Function to build category fields
  Widget _buildCategoryFields() {
    if (_categories.isEmpty) {
      print('No categories available!');
      return const Text("No categories available.");
    }

    // Debugging currentCategoryIndex
    if (currentCategoryIndex < 0 ||
        currentCategoryIndex >= _categories.length) {
      print('Invalid category index, resetting to 0');
      currentCategoryIndex = 0; // Reset to the first category
    }

    var currentCategory = _categories[currentCategoryIndex];
    String categoryName = currentCategory['Category'] ?? 'N/A';
    String categoryWeightage = currentCategory['Weightage']?.toString() ?? '0';
    List criteria = currentCategory['Criteria'] ?? [];
    String assignedRole = currentCategory['AssignedRole'] ?? '';

    // Debugging category rendering
    print('Rendering Category: $categoryName');
    print('Assigned Role: $assignedRole');
    print('Selected Role: $selectedRole');

    // Modify the role comparison logic to handle empty or null assignedRole
    if (assignedRole.isEmpty || assignedRole == selectedRole) {
      print(
          'Role matched or empty, proceeding with score controller initialization');
      _clearCategoryScoreControllers();
      _initializeCategoryScoreControllers(criteria.length);

      return _buildCategoryField(
        categoryName,
        categoryWeightage,
        criteria,
        currentCategoryIndex,
      );
    }

    // Return a placeholder if the role does not match
    print('Role did not match, returning SizedBox');
    return const SizedBox.shrink();
  }

  Widget _buildCategoryField(
    String categoryName,
    String categoryWeightage,
    List criteria,
    int categoryIndex,
  ) {
    List<Widget> criteriaWidgets = [];

    // Ensure categoryScores is initialized for currentParticipantIndex
    if (currentParticipantIndex < categoryScores.length) {
      if (categoryScores[currentParticipantIndex].length < criteria.length) {
        categoryScores[currentParticipantIndex] = List.from(
            categoryScores[currentParticipantIndex])
          ..addAll(List.generate(
              criteria.length - categoryScores[currentParticipantIndex].length,
              (_) => 0));
      }
    } else {
      categoryScores.add(List.generate(criteria.length, (_) => 0));
    }

    for (var criterionIndex = 0;
        criterionIndex < criteria.length;
        criterionIndex++) {
      var criterion = criteria[criterionIndex];
      String description = criterion['Description'] ?? 'N/A';
      String criterionWeightage = criterion['Weightage']?.toString() ?? '0';

      final maxScore = int.tryParse(criterionWeightage) ?? 100;

      // Use the current score from categoryScores
      int score = (currentParticipantIndex < categoryScores.length &&
              criterionIndex < categoryScores[currentParticipantIndex].length)
          ? categoryScores[currentParticipantIndex][criterionIndex]
          : 0;

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
        GestureDetector(
          onTap: () {
            _viewPenaltyDetails(description, criterionWeightage);
          },
          child: Container(
            width: 330,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: ShapeDecoration(
              color: const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                side:
                    BorderSide(width: 1, color: Colors.black.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 40,
                  child: TextField(
                    controller: _categoryScoreControllers[criterionIndex],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      hintText: 'Score',
                      hintStyle: TextStyle(color: Color(0xFFB8B8B8)),
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    onChanged: (value) {
                      int inputScore = int.tryParse(value) ?? 0;
                      if (inputScore > maxScore) {
                        _showScoreLimitSnackbar(maxScore);
                        inputScore = maxScore;
                        _categoryScoreControllers[criterionIndex].text =
                            maxScore.toString();
                      }

                      // Update the categoryScores list
                      categoryScores[currentParticipantIndex][criterionIndex] =
                          inputScore;
                      setState(() {});
                    },
                  ),
                ),
                Text('/ $criterionWeightage',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...criteriaWidgets,
      ],
    );
  }

  Widget _buildTotalScoreField() {
    // Check if the current participant index is valid
    if (categoryScores.isEmpty ||
        currentParticipantIndex >= categoryScores.length) {
      return Container(
        width: 330,
        height: 50,
        decoration: const ShapeDecoration(
          color: Color(0xFFD9EAFD),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Color(0xB20078FF)),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Score:',
                  style: TextStyle(color: Colors.black, fontSize: 16)),
              Text('0', style: TextStyle(color: Colors.black, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Calculate the total score for the current participant
    int totalScore = 0;

    // Sum up scores from both categories and penalty fields
    totalScore +=
        scores[currentParticipantIndex].fold(0, (sum, score) => sum + score);
    if (categoryScores.length > currentParticipantIndex) {
      totalScore += categoryScores[currentParticipantIndex]
          .fold(0, (sum, score) => sum + score);
    }

    return Container(
      width: 330,
      height: 50,
      decoration: const ShapeDecoration(
        color: Color(0xFFD9EAFD),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Color(0xB20078FF)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Score:',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            Text('$totalScore',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return Container(
      width: 336,
      height: 90,
      decoration: const ShapeDecoration(
        color: Color(0xFFBCCCDC),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Color(0xFF9AA6B2)),
        ),
      ),
      child: const TextField(
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Add a comment...',
          border: InputBorder.none,
          filled: true,
          fillColor:
              Colors.transparent, // Make the TextField background transparent
          contentPadding:
              EdgeInsets.all(10), // Add padding inside the TextField
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentParticipantIndex > 0)
          GestureDetector(
            onTap: () {
              setState(() {
                currentParticipantIndex--;
                isCriteriaEvaluated = false;
                _clearScoreControllers();
                _clearCategoryScoreControllers();
                debugPrint(
                    "Navigated to Participant $currentParticipantIndex, cleared all scores.");
              });
            },
            child: SizedBox(
              width: 120,
              height: 40,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 40,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFBAB5DF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: SizedBox(
                      width: 100,
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(255, 80, 80, 88),
                          fontSize: 16,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        GestureDetector(
          onTap: () async {
            debugPrint(
                "Next button tapped. Current participant index: $currentParticipantIndex");

            // Show confirmation dialog only when the "Next" button is tapped
            await _showConfirmationDialog(() async {
              debugPrint(
                  "Criteria evaluated, saving scores for participant $currentParticipantIndex.");

              // Handle saving scores for penalty or categories
              if (isPenaltyRoleSelected) {
                // Save penalty scores
                debugPrint("Penalty role detected. Saving penalty scores.");
                _saveSheets(); // Call method to save penalty scores
              } else if (_categories.isNotEmpty) {
                // Save category scores
                debugPrint("Saving category scores.");
                await _saveCategoryScores();
              } else {
                debugPrint(
                    "Categories are empty. Skipping category scores saving.");
              }

              // After saving scores, navigate to the next participant or category
              _navigateToNextCategoryOrParticipant();
            });
          },
          child: SizedBox(
            width: 120,
            height: 40,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 120,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF6A5AE0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 10,
                  top: 10,
                  child: SizedBox(
                    width: 100,
                    child: Text(
                      'Next',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> _navigateToNextCategoryOrParticipant() async {
    if (!_areAllFieldsValid()) {
      _showSnackBar('Please fill all score fields with valid numbers.');
      return;
    }

    // Don't show dialog here; show only after the "Next" button is confirmed
    if (currentCategoryIndex < _categories.length - 1) {
      _navigateToNextCategory();
    } else if (currentParticipantIndex < _participants.length - 1) {
      currentParticipantIndex++;
      _clearCategoryScoreControllers();
      debugPrint(
          "Switching to Participant $currentParticipantIndex. Cleared category scores.");
    } else {
      debugPrint("All categories and participants evaluated. Navigating back.");
      _showSnackBar('Evaluation completed.');
      Navigator.pop(context); // Exit or navigate back
    }
  }

  Future<void> _navigateToNextCategory() async {
    if (!_areAllFieldsValid()) {
      _showSnackBar('Please fill all score fields with valid numbers.');
      return;
    }

    // Only show dialog after pressing the "Next" button
    await _showConfirmationDialog(() {
      setState(() {
        if (currentCategoryIndex < _categories.length - 1) {
          currentCategoryIndex++;
          currentParticipantIndex = 0; // Reset to the first participant
          _clearCategoryScoreControllers();
          debugPrint(
              "Moved to Category $currentCategoryIndex, reset to Participant 0.");
        } else {
          debugPrint("No more categories available for navigation.");
          _showSnackBar('No more categories available.');
        }
      });
    });
  }

  Future<void> _showConfirmationDialog(VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to submit the score?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
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
