// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, use_build_context_synchronously

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      setState(() {
        isLoading = true; // Start loading
      });

      // Fetch all events
      final allEvents = await DatabaseHelper.instance.getTemplates();

      // Fetch scoresheets and extract template codes
      final scoresheets = await DatabaseHelper.instance.getScoresheets();
      final scoreTemplateCodes =
          scoresheets.map((score) => score['templateCode']).toSet();

      // Filter active events based on template codes
      activeEvents = allEvents.where((event) {
        final templateCode = event['templateCode'];
        return templateCode != null &&
            templateCode.isNotEmpty &&
            scoreTemplateCodes.contains(templateCode);
      }).toList();

      // Update the state with the loaded data
      setState(() {
        events = allEvents;
        isLoading = false; // Stop loading
      });
    } catch (e) {
      // Handle errors gracefully
      if (kDebugMode) {
        print('Error loading event data: $e');
      }

      setState(() {
        isLoading = false; // Stop loading even on error
      });

      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load events. Please try again.'),
          duration: Duration(seconds: 3),
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
                style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (activeEvents.isEmpty) {
      return Center(
        child: Text(
          'No active events found',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Display the list of active events
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: activeEvents.length,
      itemBuilder: (context, index) {
        final event = activeEvents[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Result(eventName: event['eventName']),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: index == 0 ? 6 : 13, // Less margin for the first event
            ),
            width: screenWidth * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7D8EEA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['eventName'] ?? 'Unnamed Event',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event['eventDate'] ?? 'Date not available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllEventGrid() {
    return events.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              // Determine the crossAxisCount based on screen width
              int crossAxisCount = 2; // Default for small screens
              if (constraints.maxWidth >= 1200) {
                crossAxisCount = 5; // Larger screens
              } else if (constraints.maxWidth >= 800) {
                crossAxisCount = 4; // Medium screens
              } else if (constraints.maxWidth >= 600) {
                crossAxisCount = 3; // Tablet screens
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the Result module with the event name
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
                            style: GoogleFonts.poppins(
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
            },
          );
  }
}
