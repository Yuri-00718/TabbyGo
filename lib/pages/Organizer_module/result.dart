// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: use_key_in_widget_constructors
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
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 36, 7.3, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildResultsSection(context),
                _buildEventContainer(context),
                _buildSynchronizedButton(context), // Add button here
                Expanded(
                  child: _buildPodiumStack(context),
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
      padding: const EdgeInsets.fromLTRB(
          22, 0, 22, 10), // Adjust bottom padding to fit with the podium
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
          Icons.access_time, // Clock icon
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
          backgroundColor: const Color(0xFF5144B6), // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildPodiumStack(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 100, // Position at the bottom
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
        Positioned(
          bottom: screenHeight * 0.47,
          child: SizedBox(
            width: screenWidth,
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildWinnerInfo(
                  'ADNU', 'assets/images/Winner.png', '94 POINTS'),
            ),
          ),
        ),
        Positioned(
          bottom: screenHeight * 0.42,
          child: SizedBox(
            width: screenWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(left: screenWidth * 0.14),
                child: _buildWinnerInfo(
                    'ADD', 'assets/images/Winner.png', '93 POINTS'),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: screenHeight * 0.39,
          child: SizedBox(
            width: screenWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.only(right: screenWidth * 0.14),
                child: _buildWinnerInfo(
                    'ADMU', 'assets/images/Winner.png', '92 POINTS'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerInfo(String name, String avatarPath, String points) {
    return Column(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(avatarPath),
          radius: 26, // Adjust radius for visibility
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w500,
            fontSize: 16, // Adjust font size for visibility
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          points,
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w400,
            fontSize: 14, // Adjust font size for visibility
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDrawer() {
    return DraggableScrollableSheet(
      initialChildSize: 0.2, // Adjust to control initial visibility
      minChildSize: 0.2, // Minimum height of the drawer
      maxChildSize: 0.8, // Maximum height of the drawer
      builder: (BuildContext context, ScrollController scrollController) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool isExpanded = scrollController.hasClients &&
                scrollController.offset >
                    (scrollController.position.maxScrollExtent * 0.5);

            scrollController.addListener(() {
              // Update the state based on scroll position
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
                      // Trigger scrolling to expand or collapse
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
                        angle: isExpanded ? 3.14 : 0, // Rotate when expanded
                        child: Image.asset(
                          'assets/images/Arrow_Up.png', // Replace with your image path
                          width: 24,
                          height: 24,
                          color:
                              const Color(0xFF9087E5), // Set color for the icon
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
    List<Map<String, String>> ranks = [
      {'rank': '4th', 'name': 'Contestant 4', 'points': '85 POINTS'},
      {'rank': '5th', 'name': 'Contestant 5', 'points': '80 POINTS'},
      {'rank': '6th', 'name': 'Contestant 6', 'points': '75 POINTS'},
    ];

    return Column(
      children: ranks.map((rank) {
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
                  rank['rank']!,
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                backgroundImage: AssetImage(
                    'assets/images/Winner.png'), // Replace with the contestant's image
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
                    rank['points']!,
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
  }
}
