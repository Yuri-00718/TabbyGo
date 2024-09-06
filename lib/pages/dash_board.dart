import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/user_management.dart';
import 'package:tabby/pages/result_and_reports_active_events.dart';
import 'package:tabby/pages/template_menus.dart';

class DashBoard extends StatelessWidget {
  const DashBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF6A5AE0), // Background color
        child: Column(
          children: [
            // Fixed Greeting Section
            Container(
              height: 200,
              color: const Color(0xFF6A5AE0), // Same color for consistency
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 30),
                child: _buildGreeting(),
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(6, 0, 6, 29),
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCCD5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                child: SizedBox(
                                  width: 291,
                                  height: 81,
                                  child: SvgPicture.asset(
                                    'assets/vectors/mask_group_2_x2.svg',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 350,
                                height: 100,
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            0, 0, 1.2, 2),
                                        child: Opacity(
                                          opacity: 0.5,
                                          child: Text(
                                            'Active Event',
                                            style: GoogleFonts.getFont(
                                              'Rubik',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              height: 1.4,
                                              letterSpacing: 1.1,
                                              color: const Color(0xFF660012),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Military Parade 2024',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.getFont(
                                          'Poppins',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 26,
                                          height: 1.4,
                                          color: const Color(0xFF660012),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildActionContainer(
                      context,
                      'Results and Reports',
                      'assets/images/business_analytics_on_tablet_screen.png',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ResultAndReportsActiveEvents(),
                          ),
                        );
                      },
                    ),
                    _buildActionContainer(
                      context,
                      'Event Template Management',
                      'assets/images/time_management.png',
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TemplateMenus(),
                            ));
                      },
                    ),
                    _buildActionContainer(
                      context,
                      'User Account \n Management',
                      'assets/images/woman_participates_in_an_online_conference_with_colleagues.png',
                      () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserManagement(),
                            ));
                      },
                    ),
                    _buildActionContainer(
                      context,
                      'Criteria \n Management',
                      'assets/images/law_studies_with_contract_and_gavel.png',
                      () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 3.8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: SvgPicture.asset(
                      'assets/vectors/frame_x2.svg',
                    ),
                  ),
                ),
                Text(
                  'GOOD MORNING ',
                  style: GoogleFonts.getFont(
                    'Rubik',
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                    height: 1.8,
                    letterSpacing: 0.5,
                    color: const Color(0xFFFFD6DD),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Administrator',
            style: GoogleFonts.getFont(
              'Poppins',
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

  Widget _buildActionContainer(
      BuildContext context, String text, String imagePath, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF9087E5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 4),
            blurRadius: 2,
          ),
        ],
      ),
      child: SizedBox(
        width: 364,
        height: 150, // Adjusted height to accommodate larger images
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.contain,
                      image: AssetImage(imagePath),
                    ),
                  ),
                  child: const SizedBox(
                    width: 130, // Increased width
                    height: 250, // Increased height
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
