import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/plan_section.dart';

class InquirySubjectsController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Same structure as Academic Plan
  final List<PlanSection> sections = [
    PlanSection(
      title: 'University Requirements',
      subtitle: 'Available: 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'University Requirements',
    ),
    PlanSection(
      title: 'University Electives',
      subtitle: 'Available: 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'University Electives',
    ),
    PlanSection(
      title: 'Obligatory School Courses',
      subtitle: 'Available: 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Obligatory School Courses',
    ),
    PlanSection(
      title: 'Elective School Courses',
      subtitle: 'Available: 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Elective School Courses',
    ),
    PlanSection(
      title: 'Obligatory Speciality Courses',
      subtitle: 'Available: 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Obligatory Speciality Courses',
    ),
    PlanSection(
      title: 'Elective Speciality Courses',
      subtitle: 'Available: 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Elective Speciality Courses',
    ),
  ];

  bool loading = false;
  String? error;

  int get totalAvailableCourses =>
      sections.fold<int>(0, (sum, s) => sum + s.courses.length);

  int get totalAvailableHours {
    int total = 0;
    for (final section in sections) {
      for (final course in section.courses) {
        final v = course['credits'];
        if (v is int) total += v;
        if (v is num) total += v.toInt();
      }
    }
    return total;
  }

  /// Loads only courses that:
  /// - belong to the SAME faculty as the student (users/{uid}.facultyId)
  /// - have availableNextSemester == true
  ///
  /// Then groups them by course type.
  Future<void> loadSections() async {
    loading = true;
    error = null;

    // reset sections
    for (final section in sections) {
      section.loading = true;
      section.courses = [];
      section.subtitle = 'Available: 0 Hour';
      section.isExpanded = false;
    }
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final userSnap = await _db.collection('users').doc(uid).get();
      final userData = userSnap.data();
      if (userData == null) throw Exception('User document not found');

      final facultyId = (userData['facultyId'] ?? '').toString().trim();
      if (facultyId.isEmpty) {
        throw Exception('User facultyId is missing in users/$uid');
      }

      // Query by faculty only (no composite index issues),
      // then filter availableNextSemester in memory.
      final snap = await _db
          .collection('courses')
          .where('facultyId', isEqualTo: facultyId)
          .get();

      final Map<String, PlanSection> typeToSection = {
        for (final s in sections) _normType(s.type): s,
      };

      final Map<String, int> creditsByType = {
        for (final s in sections) s.type: 0,
      };

      for (final doc in snap.docs) {
        final data = doc.data();

        final bool available = data['availableNextSemester'] == true;
        if (!available) continue;

        final String code = doc.id.toString().trim();

        // credits
        final crRaw = data['credits'];
        int credits = 0;
        if (crRaw is int) {
          credits = crRaw;
        } else if (crRaw is num) {
          credits = crRaw.toInt();
        } else if (crRaw != null) {
          credits = int.tryParse(crRaw.toString()) ?? 0;
        }

        final rawType = _readCourseType(data);
        final normalized = _normType(rawType);

        final section = typeToSection[normalized];
        if (section == null) continue;

        creditsByType[section.type] =
            (creditsByType[section.type] ?? 0) + credits;

        section.courses.add({
          ...data,
          'id': code,
          'code': (data['code'] ?? code).toString().trim(),
          'credits': credits,
          // Inquiry is not progress-based
          'isCompleted': false,
          'isEnrolled': false,
          'grade': null,
          'semester': null,
        });
      }

      // sort + subtitles
      for (final s in sections) {
        s.courses.sort((a, b) {
          final ac = (a['code'] ?? a['id'] ?? '').toString();
          final bc = (b['code'] ?? b['id'] ?? '').toString();
          return ac.compareTo(bc);
        });

        final totalCredits = creditsByType[s.type] ?? 0;
        s.subtitle = 'Available: $totalCredits Hour';
      }
    } catch (e) {
      error = e.toString();
      debugPrint('InquirySubjectsController.loadSections error: $e');

      for (final s in sections) {
        s.courses = [];
        s.subtitle = 'Available: 0 Hour';
      }
    } finally {
      for (final section in sections) {
        section.loading = false;
      }
      loading = false;
      notifyListeners();
    }
  }

  String _readCourseType(Map<String, dynamic> data) {
    final t = data['type'];
    if (t != null && t.toString().trim().isNotEmpty) {
      return t.toString().trim();
    }

    // fallback: type stored inside first section map
    final secs = data['sections'];
    if (secs is List && secs.isNotEmpty && secs.first is Map) {
      final first = Map<String, dynamic>.from(secs.first as Map);
      final st = first['type'];
      if (st != null && st.toString().trim().isNotEmpty) {
        return st.toString().trim();
      }
    }

    return '';
  }

  String _normType(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (t == 'Obligatory Specialty Courses') {
      return 'Obligatory Speciality Courses';
    }
    if (t == 'Elective Specialty Courses') return 'Elective Speciality Courses';
    return t;
  }
}
