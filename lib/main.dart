import 'package:flutter/material.dart';
import 'package:tabby/pages/dash_board.dart';
import 'package:tabby/pages/user_management.dart';
import 'package:tabby/pages/result.dart';
import 'package:tabby/pages/result_and_reports_active_events.dart';
import 'package:tabby/pages/template_creation.dart';
import 'package:tabby/pages/template_menus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/dashBoard',
      routes: {
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
