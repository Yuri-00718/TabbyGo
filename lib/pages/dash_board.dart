import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabby/pages/result_and_reports_active_events.dart';
import 'package:tabby/pages/template_menus.dart';

class DashBoard extends StatelessWidget {
  const DashBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF6A5AE0),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 111),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildGreeting(),
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
                                width: 291,
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
                                              fontSize: 14,
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
                                          'Rubik',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 20,
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
                      'Participants \n Management',
                      'assets/images/woman_participates_in_an_online_conference_with_colleagues.png',
                      () {},
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      margin: const EdgeInsets.only(bottom: 31.4),
      child: Align(
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
                      width: 20,
                      height: 19.8,
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
                      fontSize: 12,
                      height: 1.5,
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
                'Rubik',
                fontWeight: FontWeight.w500,
                fontSize: 24,
                height: 1.5,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ],
        ),
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
        width: 264,
        height: 100, // Adjusted height to prevent overflow
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
                    width: 89,
                    height: 74,
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
                    fontSize: 15,
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
