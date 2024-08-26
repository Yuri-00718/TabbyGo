// ignore_for_file: library_private_types_in_public_api
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tabby/pages/data_base_helper.dart';

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

  int _currentStep = 1;
  bool _isTemplateGenerated = false;
  late String _templateCode;

  final List<Map<String, TextEditingController>> _judges = [
    {
      'name': TextEditingController(),
      'role': TextEditingController(),
      'email': TextEditingController(),
    },
  ];

  final List<Map<String, TextEditingController>> _criteria = [
    {
      'Name': TextEditingController(),
      'Description': TextEditingController(),
      'Weightage': TextEditingController(),
    },
  ];

  @override
  void initState() {
    super.initState();

    if (widget.template != null) {
      // Initialize the controllers with existing data from the template
      _eventNameController.text = widget.template!['eventName'] ?? '';
      _eventLocationController.text = widget.template!['eventLocation'] ?? '';
      _dateController.text = widget.template!['eventDate'] ?? '';

      // Retrieve the existing template code or generate a new one if it's null
      _templateCode = widget.template!['templateCode'] ?? _generateRandomCode();

      // Store the generated code back in the template if it was null
      if (widget.template!['templateCode'] == null) {
        widget.template!['templateCode'] = _templateCode;
      }

      // Clear existing lists before populating
      _judges.clear();
      _criteria.clear();

      // Populate judges if they exist in the template
      if (widget.template!['judges'] != null) {
        for (var judge in widget.template!['judges']) {
          _judges.add({
            'name': TextEditingController(text: judge['name']),
            'role': TextEditingController(text: judge['role']),
            'email': TextEditingController(text: judge['email']),
          });
        }
      } else {
        // Add a default judge if none exist
        _addJudge();
      }

      // Populate criteria if they exist in the template
      if (widget.template!['criteria'] != null) {
        for (var criterion in widget.template!['criteria']) {
          _criteria.add({
            'Name': TextEditingController(text: criterion['Name']),
            'Description':
                TextEditingController(text: criterion['Description']),
            'Weightage': TextEditingController(text: criterion['Weightage']),
          });
        }
      } else {
        // Add default criteria if none exist
        _addCriteria();
      }
    } else {
      // Generate a new template code if creating a new template
      _templateCode = _generateRandomCode();
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventLocationController.dispose();
    _dateController.dispose();

    for (var judge in _judges) {
      judge['name']?.dispose();
      judge['role']?.dispose();
      judge['email']?.dispose();
    }

    for (var criterion in _criteria) {
      criterion['Name']?.dispose();
      criterion['Description']?.dispose();
      criterion['Weightage']?.dispose();
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
      if (_currentStep < 4) {
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
      });
    });
  }

  void _addCriteria() {
    setState(() {
      _criteria.add({
        'Name': TextEditingController(),
        'Description': TextEditingController(),
        'Weightage': TextEditingController(),
      });
    });
  }

  Future<void> _saveTemplateToDatabase() async {
    String eventName = _eventNameController.text;
    String eventLocation = _eventLocationController.text;
    String eventDate = _dateController.text;

    List<Map<String, dynamic>> judges = _judges.map((judge) {
      return {
        'name': judge['name']!.text,
        'role': judge['role']!.text,
        'email': judge['email']!.text,
      };
    }).toList();

    List<Map<String, dynamic>> criteria = _criteria.map((criterion) {
      return {
        'Name': criterion['Name']!.text,
        'Description': criterion['Description']!.text,
        'Weightage': criterion['Weightage']!.text,
      };
    }).toList();

    Map<String, dynamic> data = {
      'eventName': eventName,
      'eventLocation': eventLocation,
      'eventDate': eventDate,
      'judges': judges,
      'criteria': criteria,
      'templateCode': _templateCode,
    };

    try {
      if (widget.template != null && widget.template!['id'] != null) {
        // Update existing template
        data['id'] = widget.template!['id'];
        await DatabaseHelper.instance.updateTemplate(data);
      } else {
        // Insert new template
        await DatabaseHelper.instance.insertTemplate(data);
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
            _buildProgressBar(_currentStep, 4),
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
            'Administrator',
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
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF9087E5) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC6C6C6),
                    width: 2,
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
                  _buildCriteriaForm(),
                ] else if (_currentStep == 4) ...[
                  _buildTemplateCodeDisplay(),
                ] else if (_currentStep == 5) ...[
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
          _buildTextField('Judge ${i + 1} Name', _judges[i]['name']!),
          const SizedBox(height: 16),
          _buildTextField('Judge ${i + 1} Role', _judges[i]['role']!),
          const SizedBox(height: 16),
          _buildTextField('Judge ${i + 1} Email', _judges[i]['email']!),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: _addJudge,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Add Another Judge'),
        ),
      ],
    );
  }

  Widget _buildCriteriaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _criteria.length; i++) ...[
          _buildTextField('Criteria ${i + 1} Name', _criteria[i]['Name']!),
          const SizedBox(height: 16),
          _buildTextField(
              'Criteria ${i + 1} Description', _criteria[i]['Description']!),
          const SizedBox(height: 16),
          _buildTextField(
              'Criteria ${i + 1} Weightage', _criteria[i]['Weightage']!),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: _addCriteria,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Add Another Criteria'),
        ),
      ],
    );
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
        if (_currentStep < 4) ...[
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
            onPressed: () {
              if (_currentStep == 3 && !_isTemplateGenerated) {
                setState(() {
                  _isTemplateGenerated = true;
                });
              }
              if (_currentStep < 4 || !_isTemplateGenerated) {
                _nextStep();
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
              _currentStep == 3 ? 'Generate Template' : 'Next',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ] else if (_currentStep == 4) ...[
          ElevatedButton(
            onPressed: () {
              if (_isTemplateGenerated) {
                _saveTemplateToDatabase(); // Save template details
                setState(() {
                  _currentStep = 5; // Move to the final step
                });
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

  Widget _buildTextField(String label, TextEditingController controller) {
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
          child: TextField(
            controller: controller,
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
