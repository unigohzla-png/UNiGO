import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'admin_courses_page.dart';
import 'admin_students_page.dart';
import 'super_admin_registration_page.dart';
import 'super_admin_courses_page.dart';

class AdminRootPage extends StatelessWidget {
  final UserRole role;

  const AdminRootPage({super.key, required this.role});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuper = role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSuper ? 'Super Admin Dashboard' : 'Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _dashCard(
              context,
              title: 'My Courses',
              subtitle: 'View and manage students in courses',
              icon: Icons.book_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminCoursesPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _dashCard(
              context,
              title: 'Students',
              subtitle: 'Search and inspect student records',
              icon: Icons.people_alt_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminStudentsPage(isSuper: isSuper),
                  ),
                );
              },
            ),

            // ---- Super admin extras ----
            if (isSuper) ...[
              const SizedBox(height: 12),
              _dashCard(
                context,
                title: 'Courses & sections',
                subtitle: 'Create new courses and manage their sections',
                icon: Icons.menu_book_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SuperAdminCoursesPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _dashCard(
                context,
                title: 'Registration Control',
                subtitle:
                    'Open/close registration & set global registration window',
                icon: Icons.schedule_send_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SuperAdminRegistrationPage(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dashCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
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
}
