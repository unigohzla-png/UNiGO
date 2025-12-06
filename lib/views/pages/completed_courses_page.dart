// lib/views/pages/completed_courses_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompletedCoursesPage extends StatefulWidget {
  const CompletedCoursesPage({super.key});

  @override
  State<CompletedCoursesPage> createState() => _CompletedCoursesPageState();
}

class _CompletedCoursesPageState extends State<CompletedCoursesPage> {
  bool _loading = true;
  String? _error;

  /// semester → list of courses in that semester
  Map<String, List<_CompletedCourseRow>> _bySemester = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw 'Not logged in.';
      }

      final db = FirebaseFirestore.instance;
      final userSnap = await db.collection('users').doc(uid).get();
      final userData = userSnap.data() ?? {};

      final prevRaw = userData['previousCourses'];
      if (prevRaw == null || prevRaw is! Map<String, dynamic>) {
        // no completed courses
        setState(() {
          _bySemester = {};
          _loading = false;
        });
        return;
      }

      // 1) Collect all course codes
      final courseCodes = prevRaw.keys.map((e) => e.toString()).toList();

      // 2) Fetch course docs so we can show names/credits
      final Map<String, Map<String, dynamic>> courseDocs = {};
      for (final code in courseCodes) {
        final doc = await db.collection('courses').doc(code).get();
        if (doc.exists) {
          courseDocs[code] = doc.data()!;
        }
      }

      // 3) Build map semester → list of courses
      final Map<String, List<_CompletedCourseRow>> bySem = {};

      prevRaw.forEach((code, raw) {
        final info = (raw as Map<String, dynamic>);
        final semester = info['semester']?.toString() ?? 'Other';
        final grade = info['grade']?.toString();

        final courseData = courseDocs[code] ?? {};
        final name = courseData['name']?.toString() ?? code.toString();
        final creditsDynamic = courseData['credits'];
        final credits = (creditsDynamic is num) ? creditsDynamic.toInt() : null;

        bySem.putIfAbsent(semester, () => []).add(
          _CompletedCourseRow(
            code: code.toString(),
            name: name,
            grade: grade,
            credits: credits,
          ),
        );
      });

      // 4) Sort semesters (newest first) and courses inside each semester
      final entries = bySem.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)); // simple string sort

      final sortedMap = <String, List<_CompletedCourseRow>>{};
      for (final e in entries) {
        e.value.sort((a, b) => a.code.compareTo(b.code));
        sortedMap[e.key] = e.value;
      }

      if (!mounted) return;
      setState(() {
        _bySemester = sortedMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Courses'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load completed courses:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
      );
    }

    if (_bySemester.isEmpty) {
      return const Center(
        child: Text(
          'You have no completed courses yet.',
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    final semesters = _bySemester.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: semesters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sem = semesters[index];
        final list = _bySemester[sem] ?? [];

        return _semesterCard(context, sem, list);
      },
    );
  }

  Widget _semesterCard(
    BuildContext context,
    String semester,
    List<_CompletedCourseRow> courses,
  ) {
    // Just to mimic the soft rounded grey cards from your screenshot
    final radius = BorderRadius.circular(24);

    // remove dividers inside ExpansionTile
    final theme = Theme.of(context).copyWith(
      dividerColor: Colors.transparent,
    );

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: theme,
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: radius),
            collapsedShape: RoundedRectangleBorder(borderRadius: radius),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            childrenPadding:
                const EdgeInsets.fromLTRB(20, 8, 20, 16),
            title: Text(
              semester,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              if (courses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No courses in this term.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < courses.length; i++) ...[
                      _courseRow(courses[i]),
                      if (i != courses.length - 1)
                        const Divider(height: 16),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _courseRow(_CompletedCourseRow c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: code + name + credits
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${c.code} – ${c.name}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              if (c.credits != null)
                Text(
                  '${c.credits} credits',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right: grade chip
        if (c.grade != null && c.grade!.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              c.grade!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
      ],
    );
  }
}

class _CompletedCourseRow {
  final String code;
  final String name;
  final String? grade;
  final int? credits;

  _CompletedCourseRow({
    required this.code,
    required this.name,
    this.grade,
    this.credits,
  });
}
