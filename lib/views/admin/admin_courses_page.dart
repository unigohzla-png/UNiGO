import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'admin_course_content_page.dart';

class AdminCoursesPage extends StatefulWidget {
  final UserRole role;

  const AdminCoursesPage({
    super.key,
    required this.role,
  });

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _instructorName;
  bool _loadingUser = true;

  bool get isSuper => widget.role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _loadInstructorName();
  }

  Future<void> _loadInstructorName() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loadingUser = false);
        return;
      }

      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      final name =
          (data['name'] ?? data['fullName'] ?? data['instructorName']) as String?;

      if (!mounted) return;
      setState(() {
        _instructorName = name;
        _loadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Base query = all courses
    Query<Map<String, dynamic>> query =
        _db.collection('courses').orderBy('code');

    // Normal admin → filter by instructorName
    if (!isSuper &&
        _instructorName != null &&
        _instructorName!.trim().isNotEmpty) {
      query = query.where('instructorName', isEqualTo: _instructorName);
    }
    // Super admin → see ALL courses (no extra filter)

    return Scaffold(
      appBar: AppBar(
        title: Text(isSuper ? 'All Courses' : 'My Courses'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                'Error loading courses:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                isSuper
                    ? 'No courses found.'
                    : (_instructorName == null
                        ? 'No courses found.'
                        : 'No courses assigned to $_instructorName.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final code = data['code']?.toString() ?? doc.id;
              final name = (data['name'] ?? 'Untitled course') as String;
              final credits = data['credits'];
              final instructor = data['instructorName']?.toString() ?? '';

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 1,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    '$code – $name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (credits != null) 'Credits: $credits',
                      if (instructor.isNotEmpty) 'Instructor: $instructor',
                    ].join(' • '),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminCourseContentPage(
                          role: widget.role,
                          courseCode: code,
                          courseName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
