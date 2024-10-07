import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Result extends StatelessWidget {
  final String eventName;
  Result({Key? key, required this.eventName}) : super(key: key);

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
          _buildBottomDrawer(),
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
              eventName, // Use the eventName variable here
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
        onPressed: () {
          // Add your refresh logic here
        },
        icon: const Icon(
          Icons.access_time,
          size: 20,
          color: Color(0xFF9087E5),
        ),
        label: Text(
          'Latest Updated \n Score',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: const Color(0xFFFFFFFF),
          ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('scoresheets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Map to store aggregated scores by participantId
        Map<String, Map<String, dynamic>> participantScores = {};
        Map<String, int> judgeCounts = {};

        // Loop through the Firestore data to accumulate scores for each participant
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

        // Calculate average score for each participant and cap it at 100 points
        participantScores.forEach((id, data) {
          int totalScore = data['totalScore'];
          int judgeCount = judgeCounts[id]!;
          double averageScore = totalScore / judgeCount;

          // Ensure score does not exceed 100 points
          data['totalScore'] =
              (averageScore > 100) ? 100 : averageScore.round();
        });

        // Sort participants by their average score
        var scores = participantScores.values.toList();
        scores.sort((a, b) => b['totalScore'].compareTo(a['totalScore']));

        if (scores.isEmpty) {
          return const Center(child: Text("No scores available"));
        }

        // Ensure the podium displays only the top 3 participants
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
    );
  }

  Widget _buildPodiumWinnerInfo(List<Map<String, dynamic>> topScores,
      double screenHeight, double screenWidth) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (topScores.length > 1)
          Positioned(
            bottom: screenHeight * 0.41,
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
            bottom: screenHeight * 0.47,
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

    // Define a smaller style for points, bolded
    final TextStyle pointsStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: 14, // Adjust the font size for points if needed
      color: const Color(0xFFE7E4E4), // Desired color for points
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Use ClipOval to create a circular image
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
        Text(
          points,
          textAlign: TextAlign.center,
          style: pointsStyle,
        ),
      ],
    );
  }

  Widget _buildBottomDrawer() {
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

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFEEFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                        _buildRankList(),
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
  }

  Widget _buildRankList() {
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
