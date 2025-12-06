import 'package:flutter/material.dart';

import 'admin_courses_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Admin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Here you can add more admin actions later (students, windows, etc.)
            ElevatedButton.icon(
              onPressed: () {
                // Open the admin courses screen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminCoursesPage()),
                );
              },
              icon: const Icon(Icons.book),
              label: const Text('Manage My Courses'),
            ),
          ],
        ),
      ),
    );
  }
}
