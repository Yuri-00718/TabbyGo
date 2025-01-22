// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, use_super_parameters
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tabby/pages/Organizer_Module/tabulation_module.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class Result extends StatefulWidget {
  final String eventName;

  const Result({Key? key, required this.eventName}) : super(key: key);

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  bool _isLoading = true;
  bool _showDrawer = false;
  String? _selectedCategory;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _simulateLoading() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
          _showDrawer = true;
        });
      }
    });
  }

  void _checkForUpdates() async {
    if (!_isDisposed) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Penalties')
          .where('eventName', isEqualTo: widget.eventName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (kDebugMode) {
          print("Scores updated successfully!");
        }
      } else {
        if (kDebugMode) {
          print("No updates found for the scores.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to fetch updates: $e");
      }
    }

    await Future.delayed(const Duration(seconds: 3));
    if (!_isDisposed) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final TextStyle goodMorningStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.5,
    color: const Color(0xFFFFD6DD),
  ).copyWith(
    fontFamilyFallback: ['Rubik', 'Arial', 'sans-serif'],
  );

  final TextStyle adminStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.5,
    color: const Color(0xFFFFFFFF),
  ).copyWith(
    fontFamilyFallback: ['Rubik', 'Arial', 'sans-serif'],
  );

  final TextStyle resultsStyle = GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.5,
    color: const Color(0xFFFFFFFF),
  ).copyWith(
    fontFamilyFallback: ['Poppins', 'Arial', 'sans-serif'],
  );

  final TextStyle exportStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.5,
    color: const Color(0xFFE6E6E6),
  ).copyWith(
    fontFamilyFallback: ['Rubik', 'Arial', 'sans-serif'],
  );

  final TextStyle eventStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.5,
    color: const Color(0xFFFFFFFF),
  ).copyWith(
    fontFamilyFallback: ['Rubik', 'Arial', 'sans-serif'],
  );

  final TextStyle allEventStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: const Color(0xFFB9B4E4),
  ).copyWith(
    fontFamilyFallback: ['Rubik', 'Arial', 'sans-serif'],
  );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(13, screenHeight * 0.05, 7.3, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildResultsSection(context),
                _buildEventContainer(context),
                Expanded(
                  child: _buildPodiumStack(context, screenHeight, screenWidth),
                ),
              ],
            ),
          ),
          if (_showDrawer)
            _buildBottomDrawer(widget.eventName, _selectedCategory),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 19.8,
                  child: SvgPicture.asset('assets/vectors/frame_x2.svg'),
                ),
                const SizedBox(width: 10),
                Text('GOOD MORNING', style: goodMorningStyle),
              ],
            ),
          ),
          Text('ORGANIZER', style: adminStyle),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset('assets/images/Back_Arrow.png'),
                ),
                const SizedBox(width: 15.3),
                Text('Results', style: resultsStyle),
              ],
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _checkForUpdates();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5144B6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(9),
                ),
                child: Image.asset(
                  'assets/images/refresh_result.png',
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TabulationModule(eventName: widget.eventName),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5144B6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20.7,
                          height: 20,
                          child: SvgPicture.asset(
                              'assets/vectors/vector_1_x2.svg'),
                        ),
                        const SizedBox(width: 4.1),
                        Text('Tabulation', style: exportStyle),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventContainer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 1),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF9087E5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.eventName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    height: 1.2,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categoryScores')
                      .where('eventName', isEqualTo: widget.eventName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    Set<String> categoryNames = {}; // Initialize an empty set
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      var categoryName = data['categoryName'] as String?;
                      if (categoryName != null) {
                        categoryNames.add(categoryName);
                      }
                    }

                    var uniqueCategoryList = categoryNames.toList()..sort();

                    // If there are categories, include "Overall" option
                    if (uniqueCategoryList.isNotEmpty) {
                      uniqueCategoryList.insert(0, "Overall");
                    }

                    return Container(
                      alignment: Alignment.center,
                      child: DropdownButton<String>(
                        hint: const Text("Select a Category"),
                        value: _selectedCategory,
                        items: uniqueCategoryList.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Center(child: Text(category)),
                          );
                        }).toList(),
                        onChanged: (String? selectedCategory) {
                          setState(() {
                            _selectedCategory = selectedCategory;
                          });
                          // Notify the drawer to refresh ranks
                          _refreshDrawerRanks();
                        },
                        isExpanded: true,
                        dropdownColor: const Color(0xFF9087E5),
                        icon: Image.asset(
                          'assets/images/Filter.png',
                          height: 24,
                          width: 24,
                          color: Colors.white,
                        ),
                        iconEnabledColor: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Add a method to notify the drawer to refresh ranks
  void _refreshDrawerRanks() {
    setState(() {});
  }

  Widget _buildPodiumStack(
      BuildContext context, double screenHeight, double screenWidth) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isLoading)
          Center(
            child: Lottie.asset(
              'assets/JSON/LOADING.json',
              width: 350,
              height: 250,
              fit: BoxFit.fill,
            ),
          )
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categoryScores')
                .where('eventName',
                    isEqualTo: widget.eventName) // Filter by eventName
                .where('categoryName',
                    isEqualTo:
                        _selectedCategory ?? '') // Filter by selected category
                .snapshots(),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting &&
                  !_isLoading) {
                return Center(
                  child: Lottie.asset(
                    'assets/JSON/LOADING.json',
                    width: 350,
                    height: 250,
                    fit: BoxFit.fill,
                  ),
                );
              }

              if (categorySnapshot.hasError) {
                return Center(
                  child: Text(
                      "Error fetching category scores: ${categorySnapshot.error}"),
                );
              }

              // Check if no category scores found
              if (!categorySnapshot.hasData ||
                  categorySnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/JSON/Catsu.json',
                        width: 380,
                        height: 380,
                        fit: BoxFit.fill,
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Oops!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: '\nNo Category Scores Found',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Collecting participant scores from categoryScores
              Map<String, Map<String, dynamic>> participantScores = {};
              Map<String, int> categoryCount =
                  {}; // To track how many categories each participant has

              for (var doc in categorySnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String participantId = data['participantId'].toString();
                String name = data['participantName'] ?? 'Unknown';
                String photoUrl = data['participantPhoto'] ?? '';
                int totalCategoryScore = data['totalCategoryScore'] ?? 0;
                String categoryName = data['categoryName'] ?? 'Unknown';

                // Initialize participant data if not already present
                if (!participantScores.containsKey(participantId)) {
                  participantScores[participantId] = {
                    'name': name,
                    'totalScore': 0, // Will be updated with category score
                    'participantPhoto': photoUrl,
                    'categoryScores': {},
                    'totalCategories': 0, // To track the number of categories
                  };
                }

                // Update category scores and participant's total score
                participantScores[participantId]!['categoryScores']
                    [categoryName] = totalCategoryScore;
                participantScores[participantId]!['totalScore'] +=
                    totalCategoryScore;
                participantScores[participantId]!['totalCategories']++;

                // Track how many categories each participant is part of
                categoryCount[participantId] =
                    (categoryCount[participantId] ?? 0) + 1;
              }

              // Calculate the average score per participant across all categories
              participantScores.forEach((participantId, scoreData) {
                int totalScore = scoreData['totalScore'] ?? 0;
                int totalCategories = scoreData['totalCategories'] ?? 0;

                if (totalCategories > 0) {
                  // Calculate the average score across all categories for each participant
                  participantScores[participantId]!['averageScore'] =
                      totalScore / totalCategories;
                }
              });

              // Prepare scores for category display
              var filteredScores = participantScores.values.toList();
              filteredScores.sort(
                  (a, b) => b['averageScore'].compareTo(a['averageScore']));

              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 100,
                    child: SizedBox(
                      width: screenWidth,
                      height: screenHeight * 0.40,
                      child: Image.asset(
                        'assets/images/POLE.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  _buildPodiumWinnerInfo(
                    filteredScores.take(3).toList(),
                    screenHeight,
                    screenWidth,
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildPodiumWinnerInfo(List<Map<String, dynamic>> topScores,
      double screenHeight, double screenWidth) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (topScores.length > 1)
          Positioned(
            bottom: screenHeight * 0.42,
            right: screenWidth * 0.64,
            child: SizedBox(
              width: screenWidth * 0.25,
              child: Align(
                alignment: Alignment.center,
                child: _buildWinnerInfo(
                  topScores[1]['name'],
                  topScores[1]['participantPhoto'],
                  '${topScores[1]['totalScore']} POINTS',
                ),
              ),
            ),
          ),
        if (topScores.isNotEmpty)
          Positioned(
            bottom: screenHeight * 0.46,
            child: SizedBox(
              width: screenWidth * 0.3,
              child: Align(
                alignment: Alignment.center,
                child: _buildWinnerInfo(
                  topScores[0]['name'],
                  topScores[0]['participantPhoto'],
                  '${topScores[0]['totalScore']} POINTS',
                ),
              ),
            ),
          ),
        if (topScores.length > 2)
          Positioned(
            bottom: screenHeight * 0.38,
            left: screenWidth * 0.63,
            child: SizedBox(
              width: screenWidth * 0.25,
              child: Align(
                alignment: Alignment.center,
                child: _buildWinnerInfo(
                  topScores[2]['name'],
                  topScores[2]['participantPhoto'],
                  '${topScores[2]['totalScore']} POINTS',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWinnerInfo(String name, String photoUrl, String points) {
    // Define the text style for participant names
    final TextStyle resultsStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w500,
      fontSize: 15,
      height: 1.5,
      color: const Color(0xFFFFFFFF),
    );

    final TextStyle pointsStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: const Color(0xFFE7E4E4),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.network(
            photoUrl,
            height: 70,
            width: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 50);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: resultsStyle,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF9087E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            points,
            textAlign: TextAlign.center,
            style: pointsStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDrawer(String eventName, String? selectedCategory) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool isExpanded = scrollController.hasClients &&
                scrollController.offset >
                    (scrollController.position.maxScrollExtent * 0.5);

            scrollController.addListener(() {
              bool newIsExpanded = scrollController.offset >
                  (scrollController.position.maxScrollExtent * 0.5);
              if (newIsExpanded != isExpanded) {
                setState(() {
                  isExpanded = newIsExpanded;
                });
              }
            });

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categoryScores') // Only stream category scores
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Check if there are any category scores for the event
                bool hasCategoryScores = snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['eventName'] == eventName;
                });

                if (!hasCategoryScores) {
                  return Container();
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFEEFC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (scrollController.hasClients) {
                            double targetSize = isExpanded ? 0.2 : 0.8;
                            scrollController.animateTo(
                              scrollController.position.maxScrollExtent *
                                  targetSize,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Transform.rotate(
                            angle: isExpanded ? 3.14 : 0,
                            child: Image.asset(
                              'assets/images/Arrow_Up.png',
                              width: 24,
                              height: 24,
                              color: const Color(0xFF9087E5),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 1),
                            Text(
                              'Additional Ranks',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 1),
                            _buildRankList(eventName, selectedCategory),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRankList(String eventName, String? selectedCategory) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categoryScores')
          .where('eventName', isEqualTo: eventName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, Map<String, dynamic>> participantScores = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Filter by category if a category is selected
          String categoryName = data['categoryName'] ?? 'Unknown';
          if (selectedCategory != null && selectedCategory != categoryName) {
            continue;
          }

          String participantId = data['participantId'].toString();
          String name = data['participantName'] ?? 'Unknown';
          String photoUrl = data['participantPhoto'] ?? '';
          int totalCategoryScore = data['totalCategoryScore'] ?? 0;

          // Initialize participant scores if they don't exist
          if (!participantScores.containsKey(participantId)) {
            participantScores[participantId] = {
              'name': name,
              'totalScore': 0, // Initialize total score for category
              'participantPhoto': photoUrl,
              'judgeCount': 0,
              'categoryScores': {},
              'overallScore': 0, // Store the overall score
              'categoryCount':
                  0, // Count how many categories the participant is involved in
            };
          }

          // Increment judge count and sum the category score
          participantScores[participantId]!['judgeCount'] += 1;
          participantScores[participantId]!['totalScore'] += totalCategoryScore;

          // Update category scores
          participantScores[participantId]!['categoryScores'][categoryName] =
              totalCategoryScore;
        }

        // Calculate the average score for each participant per category
        participantScores.forEach((participantId, scoreData) {
          // Calculate the average score for each category
          int totalCategoryScore = scoreData['totalScore'] ?? 0;
          int judgeCount = scoreData['judgeCount'] ?? 0;

          // Calculate the average score per category if there are any judges
          if (judgeCount > 0) {
            double avgCategoryScore = totalCategoryScore / judgeCount;
            participantScores[participantId]!['overallScore'] +=
                avgCategoryScore;
            participantScores[participantId]!['categoryCount'] += 1;
          }
        });

        // Now, calculate the overall average score for each participant
        participantScores.forEach((participantId, scoreData) {
          int categoryCount = scoreData['categoryCount'] ?? 0;
          double overallScore = scoreData['overallScore'] ?? 0;

          // Calculate the final overall average score for each participant
          if (categoryCount > 0) {
            double finalOverallScore = overallScore / categoryCount;
            participantScores[participantId]!['overallScore'] =
                finalOverallScore;
          }
        });

        // Sort the participants based on overall score
        var sortedScores = _getSortedScores(participantScores);

        return _buildRankListView(sortedScores);
      },
    );
  }

  List _getSortedScores(Map<String, Map<String, dynamic>> participantScores) {
    // Create a list to store capped total scores
    var cappedScores = [];

    // Iterate through each participant's scores
    participantScores.forEach((participantId, scoreData) {
      // Get totalScore as int (already clamped in the logic above)
      int totalScore = scoreData['totalScore'] ?? 0;

      // Prepare score entry
      cappedScores.add({
        'participantId': participantId,
        'name': scoreData['name'],
        'totalScore': totalScore,
        'participantPhoto': scoreData['participantPhoto'],
        'judgeCount': scoreData['judgeCount'],
        'categoryScores': scoreData['categoryScores'],
      });
    });

    // Sort the scores in descending order
    cappedScores.sort((a, b) => b['totalScore'].compareTo(a['totalScore']));

    return cappedScores;
  }

  Widget _buildRankListView(List<dynamic> sortedScores) {
    if (sortedScores.isEmpty) {
      return const Center(child: Text("No ranks available"));
    }

    // Start from index 3 to skip top 3 ranks
    var startIndex = 3;
    var filteredScores =
        sortedScores.sublist(startIndex); // Only show ranks from 4th onwards

    return SizedBox(
      height: 400,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredScores.length,
        itemBuilder: (context, index) {
          var participant = filteredScores[index];

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Display the rank, starting from 4th
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9087E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${startIndex + index + 1}th', // Adjust the rank based on the startIndex
                    style: GoogleFonts.rubik(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ClipOval(
                  child: Image.network(
                    participant['participantPhoto'],
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 50);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant['name'],
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${participant['totalScore']} Points',
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
