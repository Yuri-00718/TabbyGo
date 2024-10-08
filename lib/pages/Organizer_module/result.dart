import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class Result extends StatefulWidget {
  final String eventName;

  Result({Key? key, required this.eventName}) : super(key: key);

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  bool _isLoading = true;
  bool _showDrawer = false;
  bool _isButtonDisabled = false;
  final ValueNotifier<int> _remainingTime = ValueNotifier<int>(180);
  Timer? _timer;

  void _checkForUpdates() async {
    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
    });
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('scoresheets')
          .where('eventName', isEqualTo: widget.eventName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print("Scores updated successfully!");
      } else {
        print("No updates found for the scores.");
      }
    } catch (e) {
      print("Failed to fetch updates: $e");
    }
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isLoading = false;
    });
    _startCooldown();
  }

  void _startCooldown() {
    _remainingTime.value = 180;
    _isButtonDisabled = true;
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.value <= 1) {
        _remainingTime.value = 0;
        _isButtonDisabled = false;
        timer.cancel();
        setState(() {});
      } else {
        _remainingTime.value--;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingTime.dispose();
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
                _buildSynchronizedButton(context),
                Expanded(
                  child: _buildPodiumStack(context, screenHeight, screenWidth),
                ),
              ],
            ),
          ),
          if (_showDrawer) _buildBottomDrawer(widget.eventName),
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
          Text('Administrator', style: adminStyle),
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF5144B6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20.7,
                    height: 19,
                    child: SvgPicture.asset('assets/vectors/vector_1_x2.svg'),
                  ),
                  const SizedBox(width: 4.1),
                  Text('EXPORT', style: exportStyle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContainer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF9087E5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              widget.eventName, // Use the eventName variable here
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 20,
                height: 1.4,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSynchronizedButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _isButtonDisabled
            ? null
            : () {
                setState(() {
                  _isLoading = true; // Start loading animation
                });
                _checkForUpdates(); // Call the update check
              },
        icon: const Icon(
          Icons.access_time,
          size: 20,
          color: Color(0xFF9087E5),
        ),
        label: ValueListenableBuilder<int>(
          valueListenable: _remainingTime,
          builder: (context, remainingTime, _) {
            return Text(
              _isButtonDisabled
                  ? 'Try again in ${remainingTime.toString().padLeft(2, '0')} sec'
                  : 'Latest Updated \n Score',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: const Color(0xFFFFFFFF),
              ),
            );
          },
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5144B6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildPodiumStack(
      BuildContext context, double screenHeight, double screenWidth) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Show loading animation when loading
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
            builder: (context, snapshot) {
              // Show loading animation if data is still loading
              if (snapshot.connectionState == ConnectionState.waiting &&
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

              // Check if there was an error while fetching data
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error fetching data: ${snapshot.error}"),
                );
              }

              // Check if there is no data available
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("The event has not started yet"));
              }

              Map<String, Map<String, dynamic>> participantScores = {};
              Map<String, int> judgeCounts = {};

              // Process the fetched documents
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String participantId = data['participantId'].toString();
                String name = data['participantName'] ?? 'Unknown';
                String photoUrl = data['participantPhoto'] ?? '';
                int totalScore = data['totalScore'] ?? 0;

                // Initialize or update participant score data
                if (participantScores.containsKey(participantId)) {
                  participantScores[participantId]!['totalScore'] += totalScore;
                  judgeCounts[participantId] = judgeCounts[participantId]! + 1;
                } else {
                  participantScores[participantId] = {
                    'name': name,
                    'totalScore': totalScore,
                    'participantPhoto': photoUrl,
                  };
                  judgeCounts[participantId] = 1;
                }
              }

              // Calculate average scores
              participantScores.forEach((id, data) {
                int totalScore = data['totalScore'];
                int judgeCount = judgeCounts[id]!;
                double averageScore = totalScore / judgeCount;
                data['totalScore'] =
                    (averageScore > 100) ? 100 : averageScore.round();
              });

              // Prepare the scores for display
              var scores = participantScores.values.toList();
              scores.sort((a, b) => b['totalScore'].compareTo(a['totalScore']));

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
                      scores.take(3).toList(), screenHeight, screenWidth),
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

  Widget _buildBottomDrawer(String eventName) {
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

                // Check if there are ranks for the current event
                bool hasRanks = snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['eventName'] ==
                      eventName; // Check for the current event
                });

                // If there are no ranks, return an empty container to hide the drawer
                if (!hasRanks) {
                  return Container(); // Hide the drawer
                }

                // Proceed to build the drawer with ranks
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
                            Text(
                              'Additional Ranks',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildRankList(
                                eventName), // Pass the current event name
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

  Widget _buildRankList(String eventName) {
    // Add eventName parameter
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('scoresheets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Map to store aggregated scores by participantId
        Map<String, Map<String, dynamic>> participantScores = {};

        // Loop through the Firestore data to accumulate scores for each participant
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if the event matches the current event
          if (data['eventName'] == eventName) {
            // Filter by event name
            String participantId = data['participantId'].toString();
            String name = data['participantName'] ?? 'Unknown';
            String photoUrl = data['participantPhoto'] ?? '';
            int totalScore = data['totalScore'] ?? 0;

            // Initialize or update participant score data
            if (participantScores.containsKey(participantId)) {
              participantScores[participantId]!['totalScore'] += totalScore;
              participantScores[participantId]!['judgeCount'] += 1;
            } else {
              participantScores[participantId] = {
                'name': name,
                'totalScore': totalScore,
                'participantPhoto': photoUrl,
                'judgeCount': 1,
              };
            }
          }
        }

        // Convert map to list and calculate average scores
        var participants = participantScores.entries.map((entry) {
          var data = entry.value;
          double averageScore = data['totalScore'] / data['judgeCount'];

          // Ensure score does not exceed 100 points
          int finalScore = (averageScore > 100) ? 100 : averageScore.round();

          return {
            'name': data['name'],
            'totalScore': finalScore,
            'participantPhoto': data['participantPhoto'],
          };
        }).toList();

        // Sort participants based on their totalScore in descending order
        participants.sort((a, b) =>
            (b['totalScore'] as int).compareTo(a['totalScore'] as int));

        if (participants.isEmpty) {
          return const Center(child: Text("No ranks available"));
        }

        // Filter out the top 3 ranks
        var additionalRanks = participants.length > 3
            ? participants.sublist(3) // Get ranks 4 and above
            : [];

        return Column(
          children: additionalRanks.asMap().entries.map((entry) {
            int index = entry.key;
            var rank = entry.value;

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9087E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 4}th', // Calculate the rank starting from 4th
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      rank[
                          'participantPhoto'], // Use the participant's image URL
                    ),
                    radius: 26,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank['name']!,
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${rank['totalScore']} POINTS',
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
