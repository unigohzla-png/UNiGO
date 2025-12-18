import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/plan_section.dart';

class AcademicPlanController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  final List<PlanSection> planSections = [
    PlanSection(
      title: 'University Requirements',
      type: 'University Requirements',
      indicatorColor: Colors.redAccent,
    ),
    PlanSection(
      title: 'University Electives',
      type: 'University Electives',
      indicatorColor: Colors.redAccent,
    ),
    PlanSection(
      title: 'Obligatory School Courses',
      type: 'Obligatory School Courses',
      indicatorColor: Colors.redAccent,
    ),
    PlanSection(
      title: 'Elective School Courses',
      type: 'Elective School Courses',
      indicatorColor: Colors.redAccent,
    ),
    PlanSection(
      title: 'Obligatory Speciality Courses',
      type: 'Obligatory Speciality Courses',
      indicatorColor: Colors.redAccent,
    ),
    PlanSection(
      title: 'Elective Speciality Courses',
      type: 'Elective Speciality Courses',
      indicatorColor: Colors.redAccent,
    ),
  ];

  bool loading = false;

  int totalCredits = 0;
  int completedCredits = 0;
  int inProgressCredits = 0;

  int get remainingCredits =>
      totalCredits - completedCredits - inProgressCredits;

  double get completionPercent =>
      totalCredits == 0 ? 0.0 : completedCredits / totalCredits;

  double get overallProgressPercent => totalCredits == 0
      ? 0.0
      : (completedCredits + inProgressCredits) / totalCredits;

  Future<void> loadSections() async {
    loading = true;
    totalCredits = 0;
    completedCredits = 0;
    inProgressCredits = 0;

    for (final s in planSections) {
      s.loading = true;
      s.courses = [];
      s.subtitle = '0 of 0 Hour';
      s.isExpanded = false;
    }

    notifyListeners();

    try {
      // ------------------ 1) Read user progress + facultyId ------------------
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final userSnap = await _db.collection('users').doc(uid).get();
      final userData = userSnap.data();
      if (userData == null) throw Exception('User document not found');

      final facultyId = (userData['facultyId'] ?? '').toString().trim();
      if (facultyId.isEmpty) {
        throw Exception('User facultyId is missing in users/$uid');
      }

      // ------------------ Read user progress ------------------
      final Set<String> enrolledCodes = {};
      final enrolledRaw = (userData['enrolledCourses'] as List?) ?? [];
      enrolledCodes.addAll(
        enrolledRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );

      // completed from previousCourses keys
      final Set<String> completedCodes = {};
      final Map<String, String> gradeByCode = {};
      final Map<String, String> semesterByCode = {};

      final prev = userData['previousCourses'];
      if (prev is Map) {
        prev.forEach((key, value) {
          final code = key.toString().trim(); // ✅ important
          if (code.isEmpty) return;

          // ✅ completed even if grade is missing
          completedCodes.add(code);

          if (value is Map) {
            final g = value['grade'];
            final s = value['semester'];

            final grade = (g ?? '').toString().trim();
            if (grade.isNotEmpty) gradeByCode[code] = grade;

            final semester = (s ?? '').toString().trim();
            if (semester.isNotEmpty) semesterByCode[code] = semester;
          }
        });
      }

      // OPTIONAL fallback: users/{uid}.courseGrades { "1901101": "A" }
      final cg = userData['courseGrades'];
      if (cg is Map) {
        cg.forEach((k, v) {
          final code = k.toString().trim();
          final grade = (v ?? '').toString().trim();
          if (code.isNotEmpty && grade.isNotEmpty) {
            gradeByCode[code] = grade;
            completedCodes.add(code);
          }
        });
      }

      // ------------------ 2) Load ALL courses in this faculty ------------------
      final coursesSnap = await _db
          .collection('courses')
          .where('facultyId', isEqualTo: facultyId)
          .get();

      final Map<String, PlanSection> typeToSection = {
        for (final s in planSections) _normType(s.type): s,
      };

      final Map<String, int> sectionTotalCredits = {
        for (final s in planSections) s.type: 0,
      };
      final Map<String, int> sectionCompletedCredits = {
        for (final s in planSections) s.type: 0,
      };

      for (final doc in coursesSnap.docs) {
        final data = doc.data();
        final code = doc.id.toString().trim();

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

        final bool isCompleted = completedCodes.contains(code);
        final bool isEnrolled = enrolledCodes.contains(code);

        totalCredits += credits;
        if (isCompleted) {
          completedCredits += credits;
        } else if (isEnrolled) {
          inProgressCredits += credits;
        }

        final rawType = _readCourseType(data);
        final normalized = _normType(rawType);

        final section = typeToSection[normalized];
        if (section == null) continue;

        sectionTotalCredits[section.type] =
            (sectionTotalCredits[section.type] ?? 0) + credits;

        if (isCompleted) {
          sectionCompletedCredits[section.type] =
              (sectionCompletedCredits[section.type] ?? 0) + credits;
        }

        final String? gradeRaw = gradeByCode[code];
        final String? grade = (gradeRaw == null || gradeRaw.trim().isEmpty)
            ? null
            : gradeRaw.trim();

        final String? semester = semesterByCode[code];

        section.courses.add({
          ...data,
          'id': code,
          'code': data['code'] ?? code,
          'credits': credits,
          'isCompleted': isCompleted,
          'isEnrolled': isEnrolled,
          'grade': grade,
          'semester': semester,
        });
      }

      // sort + subtitle
      for (final s in planSections) {
        s.courses.sort((a, b) {
          final ac = (a['code'] ?? a['id'] ?? '').toString();
          final bc = (b['code'] ?? b['id'] ?? '').toString();
          return ac.compareTo(bc);
        });

        final total = sectionTotalCredits[s.type] ?? 0;
        final done = sectionCompletedCredits[s.type] ?? 0;
        s.subtitle = '$done of $total Hour';
      }
    } catch (e) {
      debugPrint('AcademicPlanController.loadSections error: $e');

      for (final s in planSections) {
        s.courses = [];
        s.subtitle = '0 of 0 Hour';
      }
      totalCredits = 0;
      completedCredits = 0;
      inProgressCredits = 0;
    } finally {
      for (final s in planSections) {
        s.loading = false;
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

    // fallback: sometimes type is mistakenly stored inside the first section map
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
