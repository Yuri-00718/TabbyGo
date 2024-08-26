import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/result.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';

class ResultAndReportsActiveEvents extends StatefulWidget {
  const ResultAndReportsActiveEvents({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ResultAndReportsActiveEventsState createState() =>
      _ResultAndReportsActiveEventsState();
}

class _ResultAndReportsActiveEventsState
    extends State<ResultAndReportsActiveEvents> {
  bool _isActiveEventSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingSection(),
            const SizedBox(height: 19),
            _buildResultsSection(context),
            const SizedBox(height: 49),
            _buildEventButtons(),
            const SizedBox(height: 29),
            Expanded(
              child: _isActiveEventSelected
                  ? _buildEventContainer(context)
                  : _buildAllEventGrid(),
            ),
          ],
        ),
      ),
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
              // Added SVG Container
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

  Widget _buildResultsSection(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            'assets/images/Back_Arrow.png',
            width: 30,
            height: 30,
          ),
        ),
        const SizedBox(width: 15.3),
        Text(
          'Results',
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

  Widget _buildEventButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isActiveEventSelected = true;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: _isActiveEventSelected
                    ? const Color(0xFF9087E5)
                    : Colors.transparent,
                border: Border.all(
                  color: _isActiveEventSelected
                      ? Colors.transparent
                      : const Color(0xFF9087E5),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Active Event',
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: _isActiveEventSelected
                        ? const Color(0xFFFFFFFF)
                        : const Color(0x80FFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isActiveEventSelected = false;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: !_isActiveEventSelected
                    ? const Color(0xFF9087E5)
                    : Colors.transparent,
                border: Border.all(
                  color: !_isActiveEventSelected
                      ? Colors.transparent
                      : const Color(0xFF9087E5),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'All Event',
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: !_isActiveEventSelected
                        ? const Color(0xFFFFFFFF)
                        : const Color(0x80FFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventContainer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust padding based on screen height to ensure the container doesn't go off-screen
    final bottomPadding = screenHeight * 0.5; // Adjust percentage as needed

    return Padding(
      padding: EdgeInsets.only(
          top: 16, bottom: bottomPadding), // Adjust top and bottom padding
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Result()),
          );
        },
        child: SizedBox(
          width: screenWidth * 0.9,
          height: 50, // Adjusted height for better visibility
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF7D8EEA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Military Parade 2024',
                style: GoogleFonts.rubik(
                  fontWeight: FontWeight.w500,
                  fontSize: 20, // Adjusted font size
                  color: const Color(0xFFFFFFFF),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllEventGrid() {
    final events = [
      'BSP Parade 2024',
      'Org Booth 2024',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Result()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF7D8EEA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  events[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
