// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages, non_constant_identifier_names, avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage

class TemplateCreation extends StatefulWidget {
  final Map<String, dynamic>? template;

  const TemplateCreation({super.key, this.template});

  @override
  _TemplateCreationState createState() => _TemplateCreationState();
}

class _TemplateCreationState extends State<TemplateCreation> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _maxWeightageController = TextEditingController();
  final TextEditingController _eventMechanicsController =
      TextEditingController();

  List<String?> _uploadedFiles = [];
  int _currentStep = 1;
  bool _isTemplateGenerated = false;
  late String _templateCode;
  int _totalWeightage = 0;
  final int _maxWeightage = 100;

  final List<Map<String, TextEditingController>> _judges = [
    {
      'name': TextEditingController(),
      'role': TextEditingController(),
      'email': TextEditingController(),
      'phonenumber': TextEditingController(),
    },
  ];

  final List<Map<String, TextEditingController>> _criteria = [
    {
      'Description': TextEditingController(),
      'Weightage': TextEditingController(),
    },
  ];

  final List<Map<String, dynamic>> _category = [
    {
      'Category': TextEditingController(),
      'Weightage': TextEditingController(text: '0'),
      'criteriaList': [
        {
          'Criteria': TextEditingController(),
          'Weightage': TextEditingController(text: '0'),
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _participant = [
    {
      'Name': TextEditingController(),
      'Number': TextEditingController(),
      'TeamName': TextEditingController(),
      'Photo': null,
    }
  ];

  final List<Map<String, dynamic>> _eventMechanics = [
    {
      'description': TextEditingController(),
      'files': <String>[],
    }
  ];

  @override
  void initState() {
    super.initState();
    _maxWeightageController.text = '100';
    _calculateTotalWeightage();

    if (widget.template != null) {
      _eventNameController.text = widget.template!['eventName'] ?? '';
      _eventLocationController.text = widget.template!['eventLocation'] ?? '';
      _dateController.text = widget.template!['eventDate'] ?? '';
      _templateCode =
          widget.template!['templateCode']?.toString() ?? _generateRandomCode();

      if (widget.template!['templateCode'] == null) {
        widget.template!['templateCode'] = _templateCode;
      }

      _judges.clear();
      _participant.clear();
      _criteria.clear();
      _category.clear();
      _eventMechanics.clear();

      // Load template data
      _loadTemplateData();
    } else {
      _templateCode = _generateRandomCode();
    }
  }

  void _loadTemplateData() {
    if (kDebugMode) {
      print("Loaded template data: ${widget.template}");
    }

    _loadJudges();
    _loadParticipants();
    _loadCriteria();
    _loadCategory();
    _loadEventMechanics();
    _calculateTotalWeightage();
  }

  void _loadJudges() {
    if (widget.template!['judges'] != null) {
      List<dynamic> judges = _getListFromTemplate('judges');

      for (var judge in judges) {
        _judges.add({
          'name': TextEditingController(text: judge['name']),
          'role': TextEditingController(text: judge['role']),
          'email': TextEditingController(text: judge['email']),
          'phonenumber': TextEditingController(text: judge['phonenumber']),
        });
      }
    } else {
      _addJudge();
    }
  }

  void _loadParticipants() {
    if (widget.template!['participant'] != null) {
      List<dynamic> participants = _getListFromTemplate('participant');

      for (var participant in participants) {
        _participant.add({
          'Name': TextEditingController(text: participant['Name']),
          'Number': TextEditingController(text: participant['Number']),
          'TeamName': TextEditingController(text: participant['TeamName']),
          'Photo': participant['Photo'] ?? '',
        });
      }
    } else {
      _addparticipant();
    }
  }

  void _loadCriteria() {
    if (widget.template!['criteria'] != null) {
      List<dynamic> criteria = _getListFromTemplate('criteria');

      for (var criterion in criteria) {
        _criteria.add({
          'Description': TextEditingController(text: criterion['Description']),
          'Weightage': TextEditingController(text: criterion['Weightage']),
        });
      }
    } else {
      _addCriteria();
    }

    // Calculate total weightage after loading criteria
    _calculateTotalWeightage();
  }

  void _loadCategory() {
    if (widget.template!.containsKey('categories') &&
        widget.template!['categories'] is List<dynamic> &&
        widget.template!['categories'].isNotEmpty) {
      print("Loading categories...");
      List<dynamic> categories = _getListFromTemplate('categories');
      print("Parsed categories: $categories");

      for (var category in categories) {
        Map<String, dynamic> newCategory = {
          'Category': TextEditingController(text: category['Category'] ?? ''),
          'Weightage': TextEditingController(
              text: category['Weightage']?.toString() ?? '0'),
          'criteriaList': [],
          'assignedJudge':
              category['AssignedJudge'] ?? '', // Load assigned judge
        };

        // Ensure the criteria are accessed correctly
        if (category.containsKey('Criteria') && category['Criteria'] != null) {
          print("Loading criteria for category: ${category['Category']}");
          List<dynamic> criteria = category['Criteria'];
          print("Parsed criteria: $criteria");

          for (var criterion in criteria) {
            newCategory['criteriaList'].add({
              'Criteria':
                  TextEditingController(text: criterion['Description'] ?? ''),
              'Weightage': TextEditingController(
                  text: criterion['Weightage']?.toString() ?? '0'),
            });
          }
        }

        _category.add(newCategory);
      }
      print("Loaded categories into _category list: $_category");
    } else {
      print("No categories found, adding default category.");
      _addCategory(); // Ensure this method is correctly defined
    }
  }

  void _loadEventMechanics() {
    if (widget.template!['eventMechanics'] != null) {
      List<dynamic> mechanics = _getListFromTemplate('eventMechanics');

      for (var mechanic in mechanics) {
        // Set the description
        _eventMechanicsController.text = mechanic['description'] ?? '';

        // Load uploaded files from the mechanic data
        _uploadedFiles = mechanic['files'] != null
            ? List<String>.from(mechanic['files'])
            : <String>[];

        _eventMechanics.add({
          'description':
              TextEditingController(text: mechanic['description'] ?? ''),
          'files': mechanic['files'] != null
              ? List<String>.from(mechanic['files'])
              : <String>[],
        });
      }
    } else {
      _addEventMechanic();
    }
  }

  List<dynamic> _getListFromTemplate(String key) {
    var value = widget.template![key];
    if (value is String) {
      return jsonDecode(value) as List<dynamic>;
    } else {
      return value as List<dynamic>;
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventLocationController.dispose();
    _dateController.dispose();
    _maxWeightageController.dispose();

    // Dispose controllers for judges, participants, criteria, and event mechanics
    for (var judge in _judges) {
      judge['name']?.dispose();
      judge['role']?.dispose();
      judge['email']?.dispose();
      judge['phonenumber']?.dispose();
    }

    for (var participant in _participant) {
      participant['Name']?.dispose();
      participant['Number']?.dispose();
      participant['TeamName']?.dispose();
    }

    for (var criterion in _criteria) {
      criterion['Description']?.dispose();
      criterion['Weightage']?.dispose();
    }

    for (var Category in _category) {
      Category['Category']?.dispose();
      Category['Criteria']?.dispose();
      Category['Weightage']?.dispose();
    }

    for (var mechanic in _eventMechanics) {
      mechanic['description']?.dispose();
    }

    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      setState(() {
        _dateController.text = DateFormat('MMMM d, y').format(selectedDate);
      });
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 7) {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 1) {
        _currentStep--;
      }
    });
  }

  void _addJudge() {
    setState(() {
      _judges.add({
        'name': TextEditingController(),
        'role': TextEditingController(),
        'email': TextEditingController(),
        'phonenumber': TextEditingController(),
      });
    });
  }

  void _removeJudge(int index) {
    setState(() {
      _judges.removeAt(index);
    });
  }

  void _addparticipant() {
    setState(() {
      _participant.add({
        'Name': TextEditingController(),
        'Number': TextEditingController(),
        'TeamName': TextEditingController(),
        'Photo': null, // Start with no photo
      });
    });
  }

  void _removeCriteria(int index) {
    setState(() {
      _criteria.removeAt(index);
      _calculateTotalWeightage();
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participant.removeAt(index);
    });
  }

  void _addCriteria() {
    final descriptionController = TextEditingController();
    final weightageController = TextEditingController(text: '0');

    weightageController.addListener(() {
      _calculateTotalWeightage();
    });
    setState(() {
      _criteria.add({
        'Description': descriptionController,
        'Weightage': weightageController,
      });
    });
    _calculateTotalWeightage();
  }

  void _addCategory() {
    setState(() {
      _category.add({
        'Category': TextEditingController(),
        'Criteria': TextEditingController(),
        'Weightage': TextEditingController(),
      });
    });
  }

  void _removeCategory(int index) {
    setState(() {
      _category.removeAt(index);
    });
  }

  void _addEventMechanic() {
    setState(() {
      _eventMechanics.add({
        'description': TextEditingController(),
        'files': <String>[],
      });
    });
  }

  void _calculateTotalWeightage() {
    int total = _criteria.fold<int>(
      0,
      (sum, criterion) {
        final weightage =
            int.tryParse(criterion['Weightage']?.text ?? '0') ?? 0;
        return sum + weightage;
      },
    );

    setState(() {
      _totalWeightage = total;
    });

    if (kDebugMode) {
      print('Total weightage calculated: $_totalWeightage');
    }
  }

  void _calculateTotalWeightageForCategories() {
    double totalWeightage = 0;

    for (var category in _category) {
      if (category['Weightage']?.text.isNotEmpty ?? false) {
        totalWeightage += double.tryParse(category['Weightage']!.text) ?? 0;
      }
    }

    // Do something with totalWeightage, e.g., update a state variable to display
    print("Total Weightage for Categories: $totalWeightage");
  }

// Update participant image with error handling
  Future<void> _updateParticipantImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Create a reference to the Firebase Storage location
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('participant_photos/${image.name}');

      // Upload the image to Firebase Storage
      try {
        await storageRef.putFile(File(image.path));

        // Get the download URL
        final String downloadUrl = await storageRef.getDownloadURL();

        // Update the participant's photo URL in the local list
        setState(() {
          _participant[index]['Photo'] =
              downloadUrl; // Store the URL instead of the local path
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading image: $e');
        }
      }
    }
  }

  Future<void> _saveTemplateToDatabase() async {
    _calculateTotalWeightage();

    String eventName = _eventNameController.text;
    String eventLocation = _eventLocationController.text;
    String eventDate = _dateController.text;

    // Convert judges details to list of maps
    List<Map<String, dynamic>> judges = _judges.map((judge) {
      return {
        'name': judge['name']?.text ?? '',
        'role': judge['role']?.text ?? '',
        'email': judge['email']?.text ?? '',
        'phonenumber': judge['phonenumber']?.text ?? '',
      };
    }).toList();

    // Convert participant details to list of maps
    List<Map<String, dynamic>> participants = _participant.map((participant) {
      return {
        'Name': participant['Name']?.text ?? '',
        'Number': participant['Number']?.text ?? '',
        'TeamName': participant['TeamName']?.text ?? '',
        'Photo': participant['Photo'] ?? '',
      };
    }).toList();

    // Convert criteria details to list of maps
    List<Map<String, dynamic>> criteria = _criteria.map((criterion) {
      return {
        'Description': criterion['Description']?.text ?? '',
        'Weightage': criterion['Weightage']?.text ?? '',
      };
    }).toList();

// Convert categories details to list of maps, including criteria and assigned judge
    List<Map<String, dynamic>> categoriesToSave = [];
    for (var category in _category) {
      List<Map<String, dynamic>> criteriaList = [];
      int totalWeightageForCategory =
          0; // Variable to hold total weightage for the category

      for (var criterion in category['criteriaList']) {
        try {
          int criterionWeightage = int.tryParse(criterion['Weightage'].text) ??
              0; // Convert to integer
          totalWeightageForCategory +=
              criterionWeightage; // Sum up the weightages

          criteriaList.add({
            'Description': criterion['Criteria'].text ?? '',
            'Weightage': criterionWeightage,
          });
        } catch (e) {
          // Handle potential parsing errors
          if (kDebugMode) {
            print('Error parsing criterion weightage: $e');
          }
        }
      }

      categoriesToSave.add({
        'Category': category['Category'].text ?? '',
        'Criteria': criteriaList,
        'Weightage': totalWeightageForCategory, // Store as integer
        'AssignedJudge':
            category['assignedJudge'] ?? '', // Include assigned judge
      });
    }

    // Prepare event mechanics data, including uploaded files
    List<Map<String, dynamic>> eventMechanics = [
      {
        'description': _eventMechanicsController.text,
        'files': _uploadedFiles,
      }
    ];

    // Prepare data for saving
    Map<String, dynamic> data = {
      'eventName': eventName,
      'eventLocation': eventLocation,
      'eventDate': eventDate,
      'judges': judges,
      'participant': participants,
      'criteria': criteria,
      'categories': categoriesToSave,
      'eventMechanics': eventMechanics,
      'templateCode': _templateCode,
      'totalWeightage': _totalWeightage,
    };

    try {
      if (widget.template != null && widget.template!['id'] != null) {
        data['id'] = widget.template!['id'];
        await DatabaseHelper.instance.updateTemplate(data);
      } else {
        await DatabaseHelper.instance.insertTemplate(data);
      }
      if (kDebugMode) {
        print('Template saved successfully: $data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving template: $e');
      }
    }
  }

  String _generateRandomCode() {
    final random = Random();
    return List.generate(4, (index) => random.nextInt(10)).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 44, 12, 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingSection(),
            const SizedBox(height: 24),
            _buildTitleSection(),
            const SizedBox(height: 16),
            _buildProgressBar(_currentStep, 6),
            const SizedBox(height: 16),
            _buildTemplateForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          left: -67.2,
          top: 714.3,
          child: Opacity(
            opacity: 0.1,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF6A5AE0),
                BlendMode.srcIn,
              ),
              child: SvgPicture.asset(
                'assets/vectors/oval_copy_x2.svg',
                width: 99,
                height: 80.6,
              ),
            ),
          ),
        ),
        Positioned(
          left: -102,
          top: 686,
          child: Opacity(
            opacity: 0.2,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF6A5AE0),
                BlendMode.srcIn,
              ),
              child: SvgPicture.asset(
                'assets/vectors/oval_copy_53_x2.svg',
                width: 171.3,
                height: 139.4,
              ),
            ),
          ),
        ),
        Positioned(
          right: -65,
          top: -93,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFF6A5AE0),
              BlendMode.srcIn,
            ),
            child: SvgPicture.asset(
              'assets/vectors/group_67_x2.svg',
              width: 141,
              height: 143.7,
            ),
          ),
        ),
        Positioned(
          left: 72,
          top: 72,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFF6A5AE0),
              BlendMode.srcIn,
            ),
            child: SvgPicture.asset(
              'assets/vectors/img_3_x2.svg',
              width: 159,
              height: 138,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 20,
                  height: 19.8,
                  child: SvgPicture.asset(
                    'assets/vectors/frame_x2.svg',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'GOOD MORNING ',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.5,
                  letterSpacing: 0.5,
                  color: const Color(0xFFFFD6DD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ORGANIZER',
            style: GoogleFonts.rubik(
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

  Widget _buildTitleSection() {
    return Center(
      child: Text(
        'Event Template Creation',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF7D8EEA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          bool isActive = index < currentStep;
          bool isCompleted = index < currentStep - 1;

          return Row(
            children: [
              Container(
                height: 25, // Same size for all circles
                width: 25,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF9087E5) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC6C6C6),
                    width: 1,
                  ),
                  boxShadow: isActive || isCompleted
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
                child: isCompleted
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : null,
              ),
              if (index < totalSteps - 1)
                SizedBox(
                  width: 40,
                  child: Container(
                    height: 4,
                    color: isActive ? const Color(0xFFD56DD7) : Colors.white,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTemplateForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF9087E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 1) ...[
                  _buildEventDetailsForm(),
                ] else if (_currentStep == 2) ...[
                  _buildJudgesForm(),
                ] else if (_currentStep == 3) ...[
                  _buildParticipantForm(),
                ] else if (_currentStep == 4) ...[
                  _buildEventMechanicsForm(context),
                ] else if (_currentStep == 5) ...[
                  _buildCriteriaForm(),
                ] else if (_currentStep == 6) ...[
                  _buildCategoryForm(),
                ] else if (_currentStep == 7) ...[
                  _buildTemplateCodeDisplay(),
                ] else if (_currentStep == 8) ...[
                  _buildTemplateCreatedDisplay(),
                ],
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Event Name', _eventNameController),
        const SizedBox(height: 16),
        _buildTextField('Event Location', _eventLocationController),
        const SizedBox(height: 16),
        _buildDateField('Event Date'),
      ],
    );
  }

  Widget _buildJudgesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _judges.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Judge ${i + 1} Name', _judges[i]['name']!),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Judge ${i + 1} Role',
                      _judges[i]['role']!,
                      isDropdown: true,
                      dropdownItems: const [
                        'Lead Judge',
                        'Head Judge',
                        'Technical Judge',
                        'Guest Judge'
                      ],
                      initialValue: _judges[i]['role']!.text.isNotEmpty
                          ? _judges[i]['role']!.text
                          : null,
                      onChanged: (newValue) {
                        _judges[i]['role']!.text = newValue!;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                        'Judge ${i + 1} Email', _judges[i]['email']!),
                    const SizedBox(height: 16),
                    _buildTextField('Judge ${i + 1} Phone Number',
                        _judges[i]['phonenumber']!),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
        Row(
          children: [
            // Add Button
            ElevatedButton(
              onPressed: _addJudge,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text('Add', style: GoogleFonts.poppins()),
            ),
            const SizedBox(width: 8),
            // Remove Button
            ElevatedButton(
              onPressed: () {
                if (_judges.isNotEmpty) {
                  _removeJudge(_judges.length - 1);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: Text('Remove', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _participant.length; i++) ...[
          _buildTextField(
            'Participant ${i + 1} Name',
            _participant[i]['Name']!,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Participant ${i + 1} Number',
            _participant[i]['Number']!,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Participant ${i + 1} Team Name',
            _participant[i]['TeamName']!,
          ),
          const SizedBox(height: 16),
          // Check if the photo is valid before attempting to display it
          _buildParticipantPhoto(_participant[i]['Photo']),
          ElevatedButton(
            onPressed: () => _updateParticipantImage(i),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text('Upload Photo', style: GoogleFonts.poppins()),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            // Add Button
            ElevatedButton(
              onPressed: _addparticipant,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text('Add', style: GoogleFonts.poppins()),
            ),
            const SizedBox(width: 8),
            // Remove Button
            ElevatedButton(
              onPressed: () {
                if (_participant.isNotEmpty) {
                  _removeParticipant(_participant.length - 1);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text('Remove', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ],
    );
  }

// Helper method to build the participant photo widget
  Widget _buildParticipantPhoto(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE0E0E0),
        ),
        child: const Center(
          child: Icon(
            Icons.image,
            color: Color(0xFF6A5AE0),
            size: 24,
          ),
        ),
      );
    }

    // Check if the imagePath is a URL
    if (imagePath.startsWith('http')) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imagePath), // Use NetworkImage for URLs
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Handle local image paths
      try {
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image:
                  FileImage(File(imagePath)), // Use FileImage for local files
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error loading image: $e');
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE0E0E0),
          ),
          child: const Center(
            child: Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
          ),
        );
      }
    }
  }

  Widget _buildCriteriaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _criteria.length; i++) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Criteria ${i + 1} Description',
                _criteria[i]['Description']!,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Criteria ${i + 1} Weightage',
                _criteria[i]['Weightage']!,
                isWeightage: true,
                onChanged: (value) {
                  setState(() {
                    _criteria[i]['Weightage']!.text = value!;
                    _calculateTotalWeightage();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
        Row(
          children: [
            ElevatedButton(
              onPressed: _addCriteria,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text('Add', style: GoogleFonts.poppins()),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_criteria.isNotEmpty) {
                  _removeCriteria(_criteria.length - 1);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text('Remove', style: GoogleFonts.poppins()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6A5AE0),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Weightage: $_totalWeightage',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_totalWeightage > _maxWeightage)
                const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _category.length; i++) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Category ${i + 1}',
                _category[i]['Category'] ?? TextEditingController(),
                isWeightage: false,
              ),
              const SizedBox(height: 8),
              // Enhanced dropdown for assigning a judge
              _buildTextField(
                'Assign Judge',
                TextEditingController(), // Placeholder controller
                isDropdown: true,
                dropdownItems:
                    _judges.map((judge) => judge['name']!.text).toList(),
                initialValue: _category[i]['assignedJudge'],
                onChanged: (selectedJudge) {
                  setState(() {
                    _category[i]['assignedJudge'] = selectedJudge;
                  });
                },
              ),
              const SizedBox(height: 16),
              for (int j = 0;
                  j < (_category[i]['criteriaList'] ?? []).length;
                  j++) ...[
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Criteria',
                            _category[i]['criteriaList']?[j]['Criteria'] ??
                                TextEditingController(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            'Weightage',
                            _category[i]['criteriaList']?[j]['Weightage'] ??
                                TextEditingController(text: '0'),
                            isWeightage: true,
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Color.fromARGB(255, 0, 0, 0)),
                        tooltip: 'Remove Criteria',
                        onPressed: () {
                          setState(() {
                            _category[i]['criteriaList']?.removeAt(j);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add,
                        color: Color.fromARGB(255, 0, 0, 0)),
                    tooltip: 'Add Criteria',
                    onPressed: () {
                      setState(() {
                        final criteriaController = TextEditingController();
                        final weightageController =
                            TextEditingController(text: '0');

                        weightageController.addListener(() {
                          _calculateTotalWeightageForCategories();
                        });

                        if (_category[i]['criteriaList'] == null) {
                          _category[i]['criteriaList'] = [];
                        }

                        _category[i]['criteriaList'].add({
                          'Criteria': criteriaController,
                          'Weightage': weightageController,
                        });
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                setState(() {
                  final categoryController = TextEditingController();
                  _category.add({
                    'Category': categoryController,
                    'criteriaList': [],
                    'assignedJudge': null, // Initialize assigned judge as null
                  });
                });
              },
              child: const Text('Add'),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                if (_category.isNotEmpty) {
                  _removeCategory(_category.length - 1);
                }
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventMechanicsForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Event Mechanics Description',
          _eventMechanicsController,
        ),
        const SizedBox(height: 16),
        Text(
          'Uploaded File',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        const SizedBox(height: 8),
        if (_uploadedFiles.isNotEmpty)
          Column(
            children: _uploadedFiles.map((fileUrl) {
              String fileName =
                  Uri.decodeFull(fileUrl!.split('/').last.split('?').first);
              return Container(
                margin:
                    const EdgeInsets.only(bottom: 8), // Spacing between files
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Light background for the container
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fileName, // Display only the file name
                        style: GoogleFonts.poppins(),
                        overflow:
                            TextOverflow.ellipsis, // Handle long file names
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _uploadedFiles.remove(fileUrl);
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_uploadedFiles.isEmpty)
          Text(
            'No files uploaded',
            style: GoogleFonts.poppins(),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectFile,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.white,
          ),
          child: Text('Upload Files', style: GoogleFonts.poppins()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _selectFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.paths.isNotEmpty) {
      List<String> uploadedFileUrls = [];

      for (var filePath in result.paths) {
        if (filePath != null) {
          File file = File(filePath);

          try {
            String fileName = file.path.split('/').last; // Get the file name
            UploadTask uploadTask = FirebaseStorage.instance
                .ref('event_mechanics/$fileName')
                .putFile(file);

            TaskSnapshot snapshot = await uploadTask;

            if (mounted) {
              String fileUrl = await snapshot.ref.getDownloadURL();
              uploadedFileUrls.add(fileUrl);
            }
          } catch (e) {
            if (mounted) {
              if (kDebugMode) {
                print('Error uploading file: $e');
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _uploadedFiles = uploadedFileUrls; // Update the file URLs for display
        });
      }
    }
  }

  Widget _buildTemplateCodeDisplay() {
    if (kDebugMode) {
      print('Displaying template code: $_templateCode');
    } // ensure that that the code in template creation are syncronized when it saved!

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Event Template Code',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _templateCode
                .split('')
                .map((digit) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        width: 60,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            digit,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 50,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTemplateCreatedDisplay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Template Created',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Image.asset('assets/images/Happy_Cat.png'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9087E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                  color: Color(0xFFACACAC),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep < 7) ...[
          ElevatedButton(
            onPressed: () {
              if (_currentStep > 1) {
                _previousStep();
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9087E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                  color: Color(0xFFACACAC),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              'Back',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_currentStep == 6 && !_isTemplateGenerated) {
                // Trigger the confirmation dialog when the user tries to generate the template
                bool confirm = await _showConfirmationDialog(context);
                if (confirm) {
                  setState(() {
                    _isTemplateGenerated =
                        true; // Set flag to prevent further generation
                  });
                  // Optionally, proceed with any logic to generate the template here
                }
              } else if (_currentStep < 7 || !_isTemplateGenerated) {
                _nextStep(); // Go to the next step if we're not on step 6
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9087E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                  color: Color(0xFFACACAC),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              _currentStep == 6 ? 'Generate Template' : 'Next',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ] else if (_currentStep == 7) ...[
          ElevatedButton(
            onPressed: () async {
              if (_isTemplateGenerated) {
                try {
                  await _saveTemplateToDatabase(); // Save template details
                  setState(() {
                    _currentStep = 8; // Move to the final step
                  });
                } catch (e) {
                  if (kDebugMode) {
                    print('Error in saving template: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9087E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                  color: Color(0xFFACACAC),
                  width: 2,
                ),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    String judgesData = _judges
        .map((j) => "${j['name']?.text} (${j['role']?.text})")
        .join("\n");
    String participantsData = _participant
        .map((p) => "${p['Name']?.text}, Team: ${p['TeamName']?.text}")
        .join("\n");
    String criteriaData = _criteria
        .map((c) => "${c['Description']?.text} (${c['Weightage']?.text}%)")
        .join("\n");
    String categoriesData = _category.map((cat) {
      String criteria = cat['criteriaList']
              ?.map((crit) =>
                  "${crit['Criteria']?.text} (${crit['Weightage']?.text}%)")
              .join(", ") ??
          "";
      return "${cat['Category']?.text}: $criteria";
    }).join("\n");
    String mechanicsData = _eventMechanicsController.text;

    // Event details
    String eventName = _eventNameController.text;
    String eventLocation = _eventLocationController.text;
    String eventDate = _dateController.text; // Updated this line

    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Oops! Before You Generate, Check The Details Below!",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Details Section
                _buildSectionTitle("Event Details"),
                _buildSectionContent("Event Name: $eventName"),
                _buildSectionContent("Event Location: $eventLocation"),
                _buildSectionContent("Event Date: $eventDate"),
                const SizedBox(height: 16),

                // Judges Section
                _buildSectionTitle("Judges"),
                _buildSectionContent(judgesData),
                const SizedBox(height: 8),

                // Participants Section
                _buildSectionTitle("Participants"),
                _buildSectionContent(participantsData),
                const SizedBox(height: 8),

                // Criteria Section
                _buildSectionTitle("Criteria"),
                _buildSectionContent(criteriaData),
                const SizedBox(height: 8),

                // Categories Section
                _buildSectionTitle("Categories"),
                _buildSectionContent(categoriesData),
                const SizedBox(height: 8),

                // Event Mechanics Section
                _buildSectionTitle("Event Mechanics"),
                _buildSectionContent(mechanicsData),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text("Confirm",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

// Helper widget to build each section title and content
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: const Color(0xFF9087E5),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isWeightage = false,
      bool isDropdown = false,
      List<String>? dropdownItems,
      String? initialValue,
      ValueChanged<String?>? onChanged}) {
    if (isDropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<String>(
              value: initialValue,
              onChanged: onChanged,
              items: dropdownItems!
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ))
                  .toList(),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
                size: 24,
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
              dropdownColor: Colors.white,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: isWeightage ? 100 : double.infinity,
            child: TextField(
              controller: controller,
              keyboardType:
                  isWeightage ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black,
              ),
              onChanged:
                  isWeightage ? (value) => _calculateTotalWeightage() : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _dateController,
              enabled: false,
              style: const TextStyle(
                color: Colors.black, // Always black text color
              ),
              decoration: InputDecoration(
                hintText: label,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
