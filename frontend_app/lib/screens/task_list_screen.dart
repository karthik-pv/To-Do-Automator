import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  // Sample data for tasks
  final List<String> tasks = ['Task 1', 'Task 2', 'Task 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task List')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index]),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/task-detail',
              ); // Implement navigation
            },
          );
        },
      ),
    );
  }
}
