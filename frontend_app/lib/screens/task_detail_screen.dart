import 'package:flutter/material.dart';

class TaskDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample task details
    final String taskTitle = 'Sample Task';
    final String taskDescription =
        'This is a detailed description of the task.';

    return Scaffold(
      appBar: AppBar(title: Text('Task Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskTitle,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(taskDescription),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement task completion logic
              },
              child: Text('Mark as Complete'),
            ),
          ],
        ),
      ),
    );
  }
}
