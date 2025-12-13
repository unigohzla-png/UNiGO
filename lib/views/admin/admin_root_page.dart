import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'admin_courses_page.dart';
import 'admin_calendar_manage_page.dart';
import 'super_admin_registration_page.dart';
import 'super_admin_student_window_page.dart'; // still exists if you need it internally
import 'super_admin_courses_page.dart';
import 'super_admin_roles_page.dart';
import 'super_admin_students_page.dart';
import 'super_admin_create_from_registry_page.dart';
import 'super_admin_academic_staff_page.dart';

class AdminRootPage extends StatelessWidget {
  final UserRole role;

  const AdminRootPage({super.key, required this.role});

  bool get isSuper => role == UserRole.superAdmin;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Back to AuthGate
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final title = isSuper ? 'Super Admin Dashboard' : 'Admin Dashboard';

    final tiles = <_AdminTile>[
      // ================= NORMAL ADMIN ONLY =================
      if (!isSuper) ...[
        _AdminTile(
          icon: Icons.menu_book_outlined,
          title: 'My Courses',
          subtitle: 'View and manage your own courses.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const AdminCoursesPage(role: UserRole.admin),
              ),
            );
          },
        ),
      ],

      // ================= SUPER ADMIN ONLY =================
      if (isSuper) ...[
        // 🔹 Restored: All courses panel (grades, materials, confirmations)
        _AdminTile(
          icon: Icons.menu_book_outlined,
          title: 'Courses (Grades & Content)',
          subtitle: 'View materials, announcements and grade confirmations.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) =>
                    const AdminCoursesPage(role: UserRole.superAdmin),
              ),
            );
          },
        ),
        _AdminTile(
          icon: Icons.school_outlined,
          title: 'Faculty Courses & Sections',
          subtitle: 'Manage all courses & sections in your faculty.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const SuperAdminCoursesPage()),
            );
          },
        ),
        _AdminTile(
          icon: Icons.group_outlined,
          title: 'Faculty Students Panel',
          subtitle: 'View students & grades for your faculty.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const SuperAdminStudentsPage()),
            );
          },
        ),
        _AdminTile(
          icon: Icons.badge_outlined,
          title: 'Academic Staff',
          subtitle: 'Professors, advising, and assigned courses.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const SuperAdminAcademicStaffPage(),
              ),
            );
          },
        ),
        _AdminTile(
          icon: Icons.app_registration_outlined,
          title: 'Registration Windows',
          subtitle: 'Configure global and per-student registration timing.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const SuperAdminRegistrationPage(),
              ),
            );
          },
        ),
        // ❌ Student Windows tile removed from dashboard
        _AdminTile(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Create UniGO User',
          subtitle: 'Create users from the civil registry.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const SuperAdminCreateFromRegistryPage(),
              ),
            );
          },
        ),
        _AdminTile(
          icon: Icons.manage_accounts_outlined,
          title: 'Roles & Users',
          subtitle: 'Manage user roles in your faculty.',
          onTap: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const SuperAdminRolesPage()),
            );
          },
        ),
      ],

      // ================= SHARED (ADMIN + SUPER ADMIN) =================
      _AdminTile(
        icon: Icons.event_note_outlined,
        title: 'Calendar & Deadlines',
        subtitle: isSuper
            ? 'Manage faculty events & deadlines.'
            : 'Manage deadlines for your own courses.',
        onTap: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => AdminCalendarManagePage(role: role),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final crossAxisCount = isWide ? 3 : 1;

            return GridView.builder(
              itemCount: tiles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isWide ? 3 : 2.6,
              ),
              itemBuilder: (context, index) {
                final tile = tiles[index];
                return _AdminDashboardCard(tile: tile);
              },
            );
          },
        ),
      ),
    );
  }
}

class _AdminTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext) onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _AdminDashboardCard extends StatelessWidget {
  final _AdminTile tile;

  const _AdminDashboardCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => tile.onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tile.icon, size: 32, color: Colors.black87),
              const SizedBox(height: 12),
              Text(
                tile.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    tile.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
