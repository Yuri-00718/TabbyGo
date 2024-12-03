import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
// Organizer Module Imports
import 'package:tabby/pages/Organizer_Module/dash_board.dart';
import 'package:tabby/pages/Organizer_Module/user_management.dart';
import 'package:tabby/pages/Organizer_Module/result.dart';
import 'package:tabby/pages/Organizer_Module/result_and_reports_active_events.dart';
import 'package:tabby/pages/Organizer_Module/template_creation.dart';
import 'package:tabby/pages/Organizer_Module/template_menus.dart';

// User Authentication and Role Selection Imports
import 'package:tabby/pages/User_Login_Auth/login_role.dart';

// Judge Module Imports
import 'package:tabby/pages/Judge_Module/criteria.dart';
import 'package:tabby/pages/Judge_Module/event.dart';
import 'package:tabby/pages/Judge_Module/history.dart';
import 'package:tabby/pages/Judge_Module/judge_dashboard.dart';
import 'package:tabby/pages/Judge_Module/mechanics.dart';
import 'package:tabby/pages/Judge_Module/notes.dart';
import 'package:tabby/pages/Judge_Module/profile.dart';
import 'package:tabby/pages/Judge_Module/scoresheet.dart';

// Main function with Firebase initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/role',
      routes: {
        // Organizer Routes
        '/role': (context) => const LoginRoleSelection(),
        '/dashBoard': (context) => const DashBoard(),
        '/Result': (context) => const Result(
              eventName: '',
            ),
        '/resultAndReportsActiveEvents': (context) =>
            const ResultAndReportsActiveEvents(),
        '/templateCreation': (context) => const TemplateCreation(),
        '/templateMenus': (context) => const TemplateMenus(),
        '/JudgeManagement': (context) => const UserManagement(),

        // Judge Module Routes
        '/criteria': (context) => const CriteriaPage(),
        '/event': (context) => const EventPage(),
        '/history': (context) => const HistoryPage(),
        '/judge_dashboard': (context) => const Dashboard(),
        '/mechanics': (context) => const MechanicsScreen(),
        '/notes': (context) => const NotesPage(),
        '/profile': (context) => const ProfilePage(),
        '/scoresheet': (context) => const ScoresheetPage(),
      },
    );
  }
}
