// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/Organizer_Module/result.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tabby/pages/Backend/data_base_helper.dart';

class ResultAndReportsActiveEvents extends StatefulWidget {
  const ResultAndReportsActiveEvents({super.key});

  @override
  _ResultAndReportsActiveEventsState createState() =>
      _ResultAndReportsActiveEventsState();
}

class _ResultAndReportsActiveEventsState
    extends State<ResultAndReportsActiveEvents> {
  bool _isActiveEventSelected = true;
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> activeEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      // Fetch all templates (events) from the database
      final allEvents = await DatabaseHelper.instance.getTemplates();

      // Fetch scores from the database (you need to implement this method)
      final scoresheets = await DatabaseHelper.instance.getScoresheets();

      // Get template codes from scoresheets to filter active events
      final scoreTemplateCodes =
          scoresheets.map((score) => score['templateCode']).toSet();

      // Filter active events based on the template code and whether scores exist
      activeEvents = allEvents.where((event) {
        final templateCode = event['templateCode'];
        return templateCode != null &&
            templateCode.isNotEmpty &&
            scoreTemplateCodes.contains(templateCode);
      }).toList();

      setState(() {
        events = allEvents;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading event data: $e');
      }
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load events. Please try again.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
                  ? _buildActiveEventContainer(context)
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

  Widget _buildActiveEventContainer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = screenHeight * 0.5;

    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: bottomPadding),
      child: activeEvents.isEmpty
          ? const Center(child: Text('No active event found'))
          : GestureDetector(
              onTap: () {
                // Pass the event name to the Result module
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Result(eventName: activeEvents.first['eventName']),
                  ),
                );
              },
              child: SizedBox(
                width: screenWidth * 0.9,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7D8EEA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      activeEvents.first['eventName'] ?? 'Unnamed Event',
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
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
    return events.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
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
              final event = events[index];
              return GestureDetector(
                onTap: () {
                  // Pass the event name to the Result module
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Result(eventName: event['eventName']),
                    ),
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
                        event['eventName'] ?? 'Unnamed Event',
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
