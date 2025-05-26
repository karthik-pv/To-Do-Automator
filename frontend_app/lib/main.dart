import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/list_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_detail_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/lists': (context) => ListScreen(),
        '/task-list': (context) => TaskListScreen(),
        '/task-detail': (context) => TaskDetailScreen(),
      },
    );
  }
}
