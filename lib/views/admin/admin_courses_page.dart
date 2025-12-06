import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_course_content_page.dart';

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _instructorName;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadInstructorName();
  }

  Future<void> _loadInstructorName() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      // try a few common fields
      final name =
          (data['name'] ?? data['fullName'] ?? data['instructorName'])
              as String?;
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
      return const Center(child: CircularProgressIndicator());
    }

    // Base query = all courses
    Query<Map<String, dynamic>> query = _db
        .collection('courses')
        .orderBy('code');

    // If we know instructorName, filter on it
    if (_instructorName != null && _instructorName!.trim().isNotEmpty) {
      query = query.where('instructorName', isEqualTo: _instructorName);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
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
                _instructorName == null
                    ? 'No courses found.'
                    : 'No courses assigned to $_instructorName.',
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
