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

  void _checkForUpdates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('scoresheets')
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

//animation of loading
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
        _showDrawer = true;
      });
    });
  }

  final TextStyle goodMorningStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.5,
    color: const Color(0xFFFFD6DD),
  );

  final TextStyle adminStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.5,
    color: const Color(0xFFFFFFFF),
  );

  final TextStyle resultsStyle = GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.5,
    color: const Color(0xFFFFFFFF),
  );

  final TextStyle exportStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.5,
    color: const Color(0xFFE6E6E6),
  );

  final TextStyle eventStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.5,
    color: const Color(0xFFFFFFFF),
  );

  final TextStyle allEventStyle = GoogleFonts.rubik(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    color: const Color(0xFFB9B4E4),
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
      padding: const EdgeInsets.only(bottom: 38.4),
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
                    builder: (context) => TabulationModule(
                        eventName:
                            widget.eventName), // Ensure eventName is passed
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
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    Set<String> categoryNames = {'Main Criteria'};
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      var categoryName = data['categoryName'] as String?;
                      if (categoryName != null) {
                        categoryNames.add(categoryName);
                      }
                    }

                    var uniqueCategoryList = categoryNames.toList()..sort();

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
                .collection('scoresheets')
                .where('eventName', isEqualTo: widget.eventName)
                .snapshots(),
            builder: (context, overallSnapshot) {
              if (overallSnapshot.connectionState == ConnectionState.waiting &&
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

              if (overallSnapshot.hasError) {
                return Center(
                  child: Text("Error fetching data: ${overallSnapshot.error}"),
                );
              }

              if (!overallSnapshot.hasData ||
                  overallSnapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("No overall scores found for the event"));
              }

              // Collecting participant scores from scoresheets
              Map<String, Map<String, dynamic>> participantScores = {};
              for (var doc in overallSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String participantId = data['participantId'].toString();
                String name = data['participantName'] ?? 'Unknown';
                String photoUrl = data['participantPhoto'] ?? '';
                int totalScore = data['totalScore'] ?? 0;

                // Initialize participant data if not already present
                if (!participantScores.containsKey(participantId)) {
                  participantScores[participantId] = {
                    'name': name,
                    'totalScore': 0,
                    'participantPhoto': photoUrl,
                    'judgeCount': 0, // Initialize judge count
                  };
                }

                // Accumulate scores and increment judge count
                participantScores[participantId]!['totalScore'] += totalScore;
                participantScores[participantId]!['judgeCount'] +=
                    1; // Count the judges
              }

              // Average scores based on the number of judges
              participantScores.forEach((participantId, scoreData) {
                int judgeCount =
                    scoreData['judgeCount'] ?? 1; // Avoid division by zero
                scoreData['totalScore'] =
                    (scoreData['totalScore'] ~/ judgeCount).clamp(
                        0, 100); // Average score as an integer and cap at 100
              });

              // Check if a category is selected
              if (_selectedCategory != null) {
                // Fetch category scores only when a specific category is selected
                if (_selectedCategory != 'Main Criteria') {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categoryScores')
                        .where('categoryName', isEqualTo: _selectedCategory)
                        .snapshots(),
                    builder: (context, categorySnapshot) {
                      if (categorySnapshot.connectionState ==
                          ConnectionState.waiting) {
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

                      // Collecting participant scores from categoryScores
                      for (var doc in categorySnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        String participantId = data['participantId'].toString();
                        String name = data['participantName'] ?? 'Unknown';
                        String photoUrl = data['participantPhoto'] ?? '';
                        int totalCategoryScore =
                            data['totalCategoryScore'] ?? 0;

                        // Update participant scores for the selected category
                        if (participantScores.containsKey(participantId)) {
                          participantScores[participantId]!['totalScore'] =
                              totalCategoryScore; // Update to category score
                          participantScores[participantId]!['source'] =
                              'categoryScores';
                        } else {
                          participantScores[participantId] = {
                            'name': name,
                            'totalScore': totalCategoryScore,
                            'participantPhoto': photoUrl,
                            'source': 'categoryScores',
                          };
                        }
                      }

                      // Prepare scores for category display
                      var filteredScores = participantScores.values.toList();
                      filteredScores.sort(
                          (a, b) => b['totalScore'].compareTo(a['totalScore']));

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
                  );
                } else {
                  // Overall Scores Display
                  var filteredScores = participantScores.values.toList();

                  // Sort by the total score
                  filteredScores.sort(
                      (a, b) => b['totalScore'].compareTo(a['totalScore']));

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
                }
              }
              return const SizedBox(); // Fallback in case of issues
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
                  .collection('scoresheets')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                bool hasRanks = snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['eventName'] == eventName;
                });
                if (!hasRanks) {
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
                            // Remove Spacer to bring the text closer to the bottom
                            const SizedBox(
                                height: 1), // Optional: Small spacing above
                            Text(
                              'Additional Ranks',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(
                                height:
                                    1), // Reduce this size to move it even closer to the ranks
                            _buildRankList(eventName,
                                selectedCategory), // Pass the selected category
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
      stream: FirebaseFirestore.instance.collection('scoresheets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, Map<String, dynamic>> participantScores = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['eventName'] == eventName) {
            String participantId = data['participantId'].toString();
            String name = data['participantName'] ?? 'Unknown';
            String photoUrl = data['participantPhoto'] ?? '';
            int totalScore = data['totalScore'] ?? 0;

            // Initialize participant scores
            if (!participantScores.containsKey(participantId)) {
              participantScores[participantId] = {
                'name': name,
                'totalScore': 0.0, // Initialize total score for main criteria
                'participantPhoto': photoUrl,
                'judgeCount': 0,
                'categoryScores': {},
              };
            }

            // Increment judge count and sum the scores for main criteria
            participantScores[participantId]!['judgeCount'] += 1;
            participantScores[participantId]!['totalScore'] += totalScore;

            // Update category scores if applicable
            if (data['categoryScores'] != null) {
              data['categoryScores'].forEach((category, score) {
                participantScores[participantId]!['categoryScores'].update(
                    category, (value) => value + score,
                    ifAbsent: () => score);
              });
            }
          }
        }

        // Average the total scores based on the number of judges
        participantScores.forEach((participantId, scoreData) {
          int judgeCount =
              scoreData['judgeCount'] ?? 1; // Avoid division by zero
          scoreData['totalScore'] /= judgeCount; // Average score
          scoreData['totalScore'] =
              scoreData['totalScore'].clamp(0, 100); // Cap the score at 100
        });

        // Handle category filtering
        if (selectedCategory != null && selectedCategory != 'Main Criteria') {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categoryScores')
                .where('categoryName', isEqualTo: selectedCategory)
                .snapshots(),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Update scores based on category selection
              for (var doc in categorySnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String participantId = data['participantId'].toString();
                int totalCategoryScore = data['totalCategoryScore'] ?? 0;

                // If the participant exists, update their score for the category view
                if (participantScores.containsKey(participantId)) {
                  participantScores[participantId]!['totalScore'] =
                      totalCategoryScore; // Only for category view
                } else {
                  participantScores[participantId] = {
                    'name': data['participantName'] ?? 'Unknown',
                    'totalScore': totalCategoryScore,
                    'participantPhoto': data['participantPhoto'] ?? '',
                    'judgeCount': 0,
                    'categoryScores': {},
                  };
                }
              }

              var sortedScores = _getSortedScores(participantScores);
              return _buildRankListView(sortedScores);
            },
          );
        }

        var sortedScores = _getSortedScores(participantScores);
        return _buildRankListView(sortedScores);
      },
    );
  }

  List _getSortedScores(Map<String, Map<String, dynamic>> participantScores) {
    // Create a new list to store capped total scores
    var cappedScores = [];

    // Iterate through each participant's scores
    participantScores.forEach((participantId, scoreData) {
      // Get totalScore as double and convert it to int if necessary
      double totalScoreDouble = scoreData['totalScore']?.toDouble() ?? 0.0;

      // Cap the score at 100 and convert to int
      int totalScore = totalScoreDouble.clamp(0, 100).toInt();

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

    // Return only participants ranked 4th or below
    return cappedScores.skip(3).toList(); // Skip the top 3 participants
  }

  Widget _buildRankListView(List<dynamic> sortedScores) {
    if (sortedScores.isEmpty) {
      return const Center(child: Text("No ranks available"));
    }

    return SizedBox(
      height: 400,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: sortedScores.length,
        itemBuilder: (context, index) {
          var participant = sortedScores[index];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Display the rank
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9087E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 4}th',
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
                      // Display category scores if available
                      ...participant['categoryScores']
                          .entries
                          .map((categoryEntry) {
                        return Text(
                          '${categoryEntry.key}: ${categoryEntry.value} POINTS',
                          style: GoogleFonts.rubik(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        );
                      }).toList(),
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
