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
  String? _facultyId;
  List<String> _assignedCourseCodes = [];

  bool _loadingUser = true;

  bool get isSuper => widget.role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _loadInstructorInfo();
  }

  Future<void> _loadInstructorInfo() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _loadingUser = false;
        });
        return;
      }

      // 1) Load user basic info (name + facultyId)
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final name = (userData['name'] ??
              userData['fullName'] ??
              userData['instructorName'])
          ?.toString();

      final facultyId = userData['facultyId']?.toString();

      List<String> assignedCodes = [];

      // 2) For normal admins (professors), load assignedCourseCodes
      if (!isSuper && facultyId != null && facultyId.trim().isNotEmpty) {
        final profSnap = await _db
            .collection('faculties')
            .doc(facultyId.trim())
            .collection('professors')
            .doc(uid)
            .get();

        final profData = profSnap.data();
        if (profData != null) {
          final raw = profData['assignedCourseCodes'];
          if (raw is List) {
            assignedCodes = raw.map((e) => e.toString()).toList();
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _instructorName = name;
        _facultyId = facultyId?.trim();
        _assignedCourseCodes = assignedCodes;
        _loadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      _loadingUser = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isSuper ? 'All Courses' : 'My Courses'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Base query = courses for this faculty (if we know it)
    Query<Map<String, dynamic>> query = _db.collection('courses');

    if (_facultyId != null && _facultyId!.isNotEmpty) {
      query = query.where('facultyId', isEqualTo: _facultyId);
    }

    // Always order by code (index already created for facultyId+code)
    query = query.orderBy('code');

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

          var docs = snap.data?.docs ?? [];

          if (!isSuper) {
            // Normal admin: only see assigned courses
            if (_assignedCourseCodes.isEmpty) {
              return Center(
                child: Text(
                  _instructorName == null
                      ? 'No courses assigned to this account yet.\nPlease contact your super admin.'
                      : 'No courses assigned to $_instructorName.\nPlease contact your super admin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }

            docs = docs.where((doc) {
              final data = doc.data();
              final code = data['code']?.toString() ?? doc.id;
              return _assignedCourseCodes.contains(code);
            }).toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Text(
                isSuper
                    ? 'No courses found for this faculty.'
                    : 'No assigned courses found in this faculty.',
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
              final name =
                  (data['name'] ?? 'Untitled course').toString();
              final credits = data['credits'];
              final instructor =
                  data['instructorName']?.toString() ?? '';

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
                      if (instructor.isNotEmpty)
                        'Instructor: $instructor',
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
