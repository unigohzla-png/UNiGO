import 'package:flutter/material.dart';
import 'package:flutter_ui/models/user_role.dart';        // 👈 ADD THIS
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

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminCoursesPage(
                      role: UserRole.admin,   // 👈 HARD-CODED ADMIN ROLE
                    ),
                  ),
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
