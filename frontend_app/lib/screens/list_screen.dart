import 'package:flutter/material.dart';

class ListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('karthik.pv77@gmail.com'),
        backgroundColor: Colors.black, // Match the background color
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white), // Search icon
            onPressed: () {
              // Implement search functionality if needed
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 16.0), // Padding around list
          children: [
            ListTile(
              title: Text(
                'My Day',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              tileColor: Colors.grey[800], // Background color for the tile
              onTap: () {
                // Implement navigation
              },
            ),
            ListTile(
              title: Text(
                'Planned',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              tileColor: Colors.grey[800],
              onTap: () {
                // Implement navigation
              },
            ),
            ListTile(
              title: Text(
                'All',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              tileColor: Colors.grey[800],
              onTap: () {
                // Implement navigation
              },
            ),
            ListTile(
              title: Text(
                'Tasks',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              tileColor: Colors.grey[800],
              onTap: () {
                // Implement navigation
              },
            ),
            Divider(color: Colors.white), // Divider for aesthetic separation
            ListTile(
              title: Text(
                'Getting started',
                style: TextStyle(color: Colors.white),
              ),
              tileColor: Colors.grey[850],
              onTap: () {
                // Implement navigation
              },
            ),
            ListTile(
              title: Text('Groceries', style: TextStyle(color: Colors.white)),
              tileColor: Colors.grey[850],
              onTap: () {
                // Implement navigation
              },
            ),
            ListTile(
              title: Text('Orion Notes', style: TextStyle(color: Colors.white)),
              tileColor: Colors.grey[850],
              onTap: () {
                // Implement navigation
              },
            ),
            Divider(color: Colors.white),
            ListTile(
              title: Text(
                'New list',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              onTap: () {
                // Implement navigation to create new list
              },
            ),
          ],
        ),
      ),
    );
  }
}
