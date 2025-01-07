// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, prefer_final_fields, avoid_print, prefer_const_constructors, avoid_types_as_parameter_names, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io'; // For file operations
import 'package:csv/csv.dart'; // For CSV conversion
import 'package:path_provider/path_provider.dart'; // For accessing device storage
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class TabulationModule extends StatefulWidget {
  final String eventName;

  const TabulationModule({super.key, required this.eventName});

  @override
  _TabulationModuleState createState() => _TabulationModuleState();
}

class _TabulationModuleState extends State<TabulationModule> {
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _participantScores = {};
  Map<String, List<Map<String, dynamic>>> _categoryScores = {};
  String _selectedView = "menu";

  @override
  void initState() {
    super.initState();
    _fetchScores();
    _fetchCategoryScores();
  }

  Future<void> _fetchScores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('scoresheets')
          .where('eventName', isEqualTo: widget.eventName)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String participantId = data['participantId'].toString();
        String name = data['participantName'] ?? 'Unknown';
        String photoUrl = data['participantPhoto'] ?? '';
        double totalScore = (data['totalScore'] ?? 0).toDouble();
        List<String> criteriaDescriptions =
            List<String>.from(data['criteriaDescriptions'] ?? []);
        List<int> scores = List<int>.from(data['scores'] ?? []);

        // Initialize participant data if not present
        if (!_participantScores.containsKey(participantId)) {
          _participantScores[participantId] = {
            'name': name,
            'totalScore': 0.0,
            'participantPhoto': photoUrl,
            'criteriaDescriptions': criteriaDescriptions,
            'scores': List<int>.filled(criteriaDescriptions.length, 0),
            'judgeCount': 0,
          };
        }

        _participantScores[participantId]!['judgeCount'] += 1;
        _participantScores[participantId]!['totalScore'] += totalScore;

        // Update individual scores (for each criterion)
        List<int> currentScores =
            _participantScores[participantId]!['scores'] as List<int>;
        for (int i = 0; i < scores.length; i++) {
          currentScores[i] += scores[i];
        }
      }

      // Finalize averaging scores for each participant
      _participantScores.forEach((participantId, scoreData) {
        int judgeCount = scoreData['judgeCount'] ?? 1;
        scoreData['totalScore'] =
            (scoreData['totalScore'] as double) / judgeCount;
        scoreData['totalScore'] = (scoreData['totalScore'] as double)
            .clamp(0, 100); // Corrected method name

        // Average the scores for each criterion
        List<int> currentScores = scoreData['scores'] as List<int>;
        for (int i = 0; i < currentScores.length; i++) {
          currentScores[i] = (currentScores[i] / judgeCount).round();
        }

        // Debug log for verification
        print('Final Criteria and Scores:');
        List<String> criteriaDescriptions =
            scoreData['criteriaDescriptions'] as List<String>;
        for (int i = 0; i < criteriaDescriptions.length; i++) {
          print(
              'Criteria: ${criteriaDescriptions[i]}, Score: ${currentScores[i]}');
        }
      });

      // Debug log for verification
      print("Fetched scores: $_participantScores");
    } catch (e) {
      print("Failed to fetch scores: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCategoryScores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch data from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('categoryScores')
          .where('eventName', isEqualTo: widget.eventName)
          .get();

      // Process each document in the collection
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String participantName = data['participantName'] ?? 'Unknown';
        String category = data['categoryName'] ?? 'Unknown';
        double score = (data['totalCategoryScore'] ?? 0).toDouble();
        List<String> criterionNames =
            List<String>.from(data['criterionNames'] ?? []);
        List<int> categoryScores = List<int>.from(data['categoryScores'] ?? []);

        // Add scores to the respective participant's category data
        if (!_categoryScores.containsKey(participantName)) {
          _categoryScores[participantName] = [];
        }

        _categoryScores[participantName]!.add({
          'category': category,
          'score': score,
          'criterionNames': criterionNames,
          'categoryScores': categoryScores,
        });
      }

      // Debug log for verification
      print("Fetched category scores: $_categoryScores");
    } catch (e) {
      print("Failed to fetch category scores: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCsv() async {
    try {
      List<List<dynamic>> rows = [
        [
          "Participant ID",
          "Name",
          "Total Score",
          "Criteria",
          "Scores",
          "Category",
          "Category Scores"
        ]
      ];

      // Add Overall Scores
      _participantScores.forEach((participantId, data) {
        String name = data['name'] ?? 'Unknown';
        double totalScore = data['totalScore'] ?? 0.0;
        List<String> criteriaDescriptions =
            List<String>.from(data['criteriaDescriptions']);
        List<int> scores = List<int>.from(data['scores']);

        rows.add([
          participantId,
          name,
          totalScore.toStringAsFixed(2),
          criteriaDescriptions.join(", "),
          scores.join(", "),
          "Overall",
          ""
        ]);
      });

      // Add Category Scores
      _categoryScores.forEach((participantName, categories) {
        for (var category in categories) {
          rows.add([
            "",
            participantName,
            category['score'] ?? 0.0,
            category['criterionNames'].join(", "),
            category['categoryScores'].join(", "),
            category['category'],
            category['categoryScores'].join(", ")
          ]);
        }
      });

      // Convert to CSV
      String csvData = const ListToCsvConverter(eol: '\r\n').convert(rows);
      String csvWithBom = "\uFEFF$csvData";

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/event_results.csv";
      final file = File(filePath);

      await file.writeAsString(csvWithBom,
          mode: FileMode.write, encoding: utf8);

      print("CSV file saved at: $filePath");

      // Success Dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Export Successful"),
              content: Text(
                  "The results have been exported to $filePath. Please check it. :)"),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _openExportedFile(filePath);
                  },
                  child: const Text("Check File"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error exporting to CSV: $e");
    }
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      // Permission granted
    } else {
      print("Storage permission denied.");
    }
  }

  Future<void> _openExportedFile(String filePath) async {
    try {
      // Log the file path to verify correctness
      print("Attempting to open file at: $filePath");

      // Check if the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        print("Error: File does not exist at path: $filePath");
        return;
      }

      // Open the file using open_filex
      final result = await OpenFilex.open(filePath);

      // Log the result of the operation
      switch (result.type) {
        case ResultType.done:
          print("File opened successfully.");
          break;
        case ResultType.fileNotFound:
          print("Error: File not found. Ensure the file path is correct.");
          break;
        case ResultType.permissionDenied:
          print("Error: Permission denied. Check file permissions.");
          break;
        case ResultType.error:
          print("Error: An unknown error occurred: ${result.message}");
          break;
        default:
          print("Unhandled result type: ${result.type}");
      }
    } catch (e) {
      // Log any unexpected exceptions
      print("Unexpected error opening file: $e");
    }
  }

  Widget _buildGreetingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
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
          const SizedBox(height: 20),
          if (_selectedView != "overallScores" &&
              _selectedView != "categoryScores")
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.asset(
                      'assets/images/Back_Arrow.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      height: 1.5,
                      letterSpacing: 0.5,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Menu Title
          Text(
            "Tabulation Menu",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),

          // Overall Scores Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedView = "overallScores";
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
            icon: const Icon(Icons.bar_chart, size: 24),
            label: Text(
              "View Overall Scores",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category Scores Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedView = "categoryScores";
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
            icon: const Icon(Icons.category, size: 24),
            label: Text(
              "View Category Scores",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              await _exportToCsv(); // Pass context explicitly
            },
            child: Text(
              "Export Results",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedView = "menu";
            });
          },
          child: Image.asset(
            'assets/images/Back_Arrow.png',
            width: 30,
            height: 30,
          ),
        ),
        const SizedBox(width: 15.3),
        Text(
          'Tabulation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            height: 1.5,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScores() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _participantScores.isEmpty
            ? const Center(
                child: Text(
                  "No scores found for this event.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _participantScores.length,
                itemBuilder: (context, index) {
                  String participantId =
                      _participantScores.keys.elementAt(index);
                  final data = _participantScores[participantId]!;

                  final participantPhoto = data['participantPhoto'] ?? '';
                  final participantName = data['name'] ?? 'No Name';
                  final totalScore = data['totalScore'] ?? 0.0;
                  final criteriaDescriptions =
                      data['criteriaDescriptions'] as List<String>? ?? [];
                  final scores = data['scores'] as List<int>? ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipOval(
                            child: participantPhoto.isNotEmpty
                                ? Image.network(
                                    participantPhoto,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person, size: 50);
                                    },
                                  )
                                : const Icon(Icons.person, size: 50),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          participantName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Score: ${totalScore.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        GestureDetector(
                          onTap: () {
                            // Build score details
                            final scoreDetails = List<Widget>.generate(
                              criteriaDescriptions.length,
                              (index) {
                                final score =
                                    index < scores.length ? scores[index] : 0;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      criteriaDescriptions[index],
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '$score',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            // Calculate TOTAL score
                            final totalScore = scores.fold<int>(
                                0, (sum, score) => sum + score);

                            // Show dialog with details
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  title: const Text(
                                    'Criteria Details',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (scoreDetails.isNotEmpty)
                                          ...scoreDetails
                                        else
                                          const Text(
                                            'No criterion data available.',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        const Divider(
                                          height: 20,
                                          thickness: 1,
                                          color: Colors.grey,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'TOTAL',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              '$totalScore',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: SfCartesianChart(
                            title: ChartTitle(
                              text: 'Total Scores for $participantName',
                              textStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            legend: const Legend(isVisible: true),
                            primaryXAxis: CategoryAxis(
                              title: AxisTitle(
                                textStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              arrangeByIndex: true,
                            ),
                            primaryYAxis: NumericAxis(
                              title: AxisTitle(
                                text: 'Scores',
                                textStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              minimum: 0,
                              maximum: 100,
                              interval: 10,
                              axisLine: const AxisLine(width: 2),
                              majorTickLines: const MajorTickLines(
                                size: 4,
                                color: Colors.black,
                              ),
                              minorTickLines: const MinorTickLines(
                                size: 2,
                                color: Colors.black,
                              ),
                            ),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries>[
                              BarSeries<Map<String, dynamic>, String>(
                                dataSource: scores
                                    .asMap()
                                    .entries
                                    .map((entry) => {
                                          'criterion':
                                              criteriaDescriptions[entry.key],
                                          'score': entry.value
                                        })
                                    .toList(),
                                xValueMapper: (data, _) =>
                                    data['criterion'] as String,
                                yValueMapper: (data, _) => data['score'] as int,
                                name: 'Scores',
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  Widget _buildCategoryScores(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _categoryScores.isEmpty
            ? const Center(
                child: Text(
                  "No category scores found for this event.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _categoryScores.length,
                itemBuilder: (context, index) {
                  // Get participant name and category data
                  String participantName =
                      _categoryScores.keys.elementAt(index);
                  final categoryData = _categoryScores[participantName]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participantName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Display category scores in a chart
                        SfCartesianChart(
                          title: ChartTitle(
                            text: 'Category Scores for $participantName',
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          legend: const Legend(isVisible: true),
                          primaryXAxis: CategoryAxis(
                            title: AxisTitle(
                              text: 'Categories',
                              textStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            arrangeByIndex: true,
                          ),
                          primaryYAxis: NumericAxis(
                            title: AxisTitle(
                              text: 'Scores',
                              textStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            minimum: 0,
                            maximum: 100,
                            interval: 10,
                            axisLine: const AxisLine(width: 2),
                            majorTickLines: const MajorTickLines(
                              size: 4,
                              color: Colors.black,
                            ),
                            minorTickLines: const MinorTickLines(
                              size: 2,
                              color: Colors.black,
                            ),
                          ),
                          tooltipBehavior: TooltipBehavior(enable: true),
                          series: <CartesianSeries>[
                            ColumnSeries<Map<String, dynamic>, String>(
                              dataSource: categoryData,
                              xValueMapper: (data, _) =>
                                  data['category'] as String,
                              yValueMapper: (data, _) =>
                                  data['score'] as double,
                              name: 'Scores',
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                textStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              onPointTap: (ChartPointDetails details) {
                                // Get tapped category data
                                final tappedCategory =
                                    categoryData[details.pointIndex!];

                                // Safely retrieve the criterionNames and categoryScores fields
                                final criterionNames =
                                    tappedCategory['criterionNames']
                                            as List<String>? ??
                                        [];
                                final categoryScores =
                                    tappedCategory['categoryScores']
                                            as List<int>? ??
                                        [];

                                // Build the content for the dialog
                                final scoreDetails = List<Widget>.generate(
                                  criterionNames.length,
                                  (index) {
                                    final score = index < categoryScores.length
                                        ? categoryScores[index]
                                        : 0;
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          criterionNames[index],
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          '$score',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                // Show dialog with criterion details
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      title: const Text(
                                        'Category Details',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ...scoreDetails.isNotEmpty
                                                ? scoreDetails
                                                : [
                                                    const Text(
                                                      'No criterion data available.',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                            const Divider(
                                              height: 20,
                                              thickness: 1,
                                              color: Colors.grey,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'TOTAL',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                Text(
                                                  '${tappedCategory['score'] ?? 0}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      actionsAlignment:
                                          MainAxisAlignment.center,
                                      actions: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Close',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5144B6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingSection(context),
            const SizedBox(height: 10),
            if (_selectedView == "menu")
              Expanded(child: _buildMenuSection(context))
            else if (_selectedView == "overallScores") ...[
              _buildResultsSection(context),
              const SizedBox(height: 20),
              Expanded(child: _buildOverallScores()),
            ] else if (_selectedView == "categoryScores") ...[
              _buildResultsSection(context),
              const SizedBox(height: 20),
              Expanded(child: _buildCategoryScores(context)),
            ] else
              Expanded(
                child: Center(
                  child: Text(
                    "Coming soon.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
