import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core package
import 'package:tabby/pages/Organizer_Module/dash_board.dart';
import 'package:tabby/pages/Organizer_Module/user_management.dart';
import 'package:tabby/pages/Organizer_Module/result.dart';
import 'package:tabby/pages/Organizer_Module/result_and_reports_active_events.dart';
import 'package:tabby/pages/Organizer_Module/template_creation.dart';
import 'package:tabby/pages/Organizer_Module/template_menus.dart';
import 'package:tabby/pages/User_Login_Auth/login_role.dart';

// Main function with Firebase initialization
// Main function with Firebase initialization
void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Firebase is initialized before running the app
  await Firebase.initializeApp(); // Initialize Firebase
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
        '/role': (context) => const LoginRoleSelection(),
        '/dashBoard': (context) => const DashBoard(),
        '/Result': (context) => Result(),
        '/resultAndReportsActiveEvents': (context) =>
            const ResultAndReportsActiveEvents(),
        '/templateCreation': (context) => const TemplateCreation(),
        '/templateMenus': (context) => const TemplateMenus(),
        '/JudgeManagement': (context) => const UserManagement(),
      },
    );
  }
}
