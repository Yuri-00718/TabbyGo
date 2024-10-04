import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Result extends StatelessWidget {
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
              'Military Parade 2024',
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

        var scores = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['participantName'] ??
                'Unknown', // Default to 'Unknown' if null
            'points': data['totalScore'] ?? 0, // Default to 0 if null
            'participantPhoto': data['participantPhoto'] ??
                '', // Default to empty string if null
            'templateCode':
                data['templateCode'] ?? '', // Default to empty string if null
          };
        }).toList();

        if (scores.isEmpty) {
          return const Center(child: Text("No scores available"));
        }

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
            _buildPodiumWinnerInfo(scores, screenHeight, screenWidth),
          ],
        );
      },
    );
  }

  Widget _buildPodiumWinnerInfo(List<Map<String, dynamic>> scores,
      double screenHeight, double screenWidth) {
    // Sort scores in descending order based on points
    scores.sort((a, b) => b['points'].compareTo(a['points']));

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (scores.isNotEmpty && scores.length > 1)
          Positioned(
            bottom: screenHeight * 0.41,
            right: screenWidth * 0.64,
            child: SizedBox(
              width: screenWidth * 0.25,
              child: Align(
                alignment: Alignment.center,
                child: _buildWinnerInfo(
                  scores[1]['name'] ??
                      'Unknown', // Default to 'Unknown' if null
                  scores[1]['participantPhoto'] ??
                      '', // Corrected to participantPhoto
                  '${scores[1]['points'] ?? 0} POINTS', // Default to 0 if null
                ),
              ),
            ),
          ),
        if (scores.isNotEmpty)
          Positioned(
            bottom: screenHeight * 0.47,
            child: SizedBox(
              width: screenWidth * 0.3,
              child: Align(
                alignment: Alignment.center,
                child: _buildWinnerInfo(
                  scores[0]['name'] ?? 'Unknown', // First place name
                  scores[0]['participantPhoto'] ??
                      '', // Corrected to participantPhoto
                  '${scores[0]['points'] ?? 0} POINTS', // First place points
                ),
              ),
            ),
          ),
        if (scores.length > 2)
          Positioned(
            bottom: screenHeight * 0.38,
            left: screenWidth * 0.63,
            child: SizedBox(
              width: screenWidth * 0.25,
              child: Align(
                alignment: Alignment.center,
                child: _buildWinnerInfo(
                  scores[2]['name'] ?? 'Unknown', // Third place name
                  scores[2]['participantPhoto'] ??
                      '', // Corrected to participantPhoto
                  '${scores[2]['points'] ?? 0} POINTS', // Third place points
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

        // Create a list of participant scores
        var participants = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['participantName'] ?? 'Unknown', // Participant's name
            'totalScore': data['totalScore'] ?? 0, // Participant's score
            'participantPhoto':
                data['participantPhoto'] ?? '', // Participant's image URL
          };
        }).toList();

        // Sort participants based on their totalScore in descending order
        participants.sort((a, b) =>
            (b['totalScore'] as int).compareTo(a['totalScore'] as int));

        if (participants.isEmpty) {
          return const Center(child: Text("No ranks available"));
        }

        // Filter out the top 3 ranks
        var additionalRanks = participants.sublist(3); // Get ranks 4 and above

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
