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

  double get overallProgressPercent =>
      totalCredits == 0
          ? 0.0
          : (completedCredits + inProgressCredits) / totalCredits;

  Future<void> loadSections() async {
    loading = true;
    totalCredits = 0;
    completedCredits = 0;
    inProgressCredits = 0;
    notifyListeners();

    // ------------------ 1) Read user progress ------------------
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final Set<String> completedCodes = {};
    final Set<String> enrolledCodes = {};
    final Map<String, String> courseGrades = {};
    final Map<String, String> courseSemester = {};

    if (uid != null) {
      final userSnap = await _db.collection('users').doc(uid).get();
      final userData = userSnap.data();

      if (userData != null) {
        // enrolledCourses: simple array of codes
        final enrolledRaw = (userData['enrolledCourses'] as List?) ?? [];
        enrolledCodes.addAll(enrolledRaw.map((e) => e.toString()));

        // previousCourses: MAP keyed by course code
        final prev = userData['previousCourses'];
        if (prev is Map) {
          prev.forEach((key, value) {
            final code = key.toString();
            completedCodes.add(code);

            if (value is Map) {
              final g = value['grade'];
              final s = value['semester'];
              if (g != null) courseGrades[code] = g.toString();
              if (s != null) courseSemester[code] = s.toString();
            }
          });
        }
      }
    }

    // --------------- 2) Load each section / compute -------------
    for (final section in planSections) {
      section.loading = true;
      section.courses = [];
      section.subtitle = '0 of 0 Hour';
      notifyListeners();

      try {
        final q = await _db
            .collection('courses')
            .where('type', isEqualTo: section.type)
            .get();

        final List<Map<String, dynamic>> courses = [];
        int sectionTotal = 0;
        int sectionCompleted = 0;

        for (final doc in q.docs) {
          final data = doc.data();
          final code = doc.id;

          // credits parsing
          final crRaw = data['credits'];
          int credits = 0;
          if (crRaw is int) {
            credits = crRaw;
          } else if (crRaw is num) {
            credits = crRaw.toInt();
          } else if (crRaw != null) {
            credits = int.tryParse(crRaw.toString()) ?? 0;
          }

          sectionTotal += credits;
          totalCredits += credits;

          final bool isCompleted = completedCodes.contains(code);
          final bool isEnrolled = enrolledCodes.contains(code);

          if (isCompleted) {
            sectionCompleted += credits;
            completedCredits += credits;
          } else if (isEnrolled) {
            inProgressCredits += credits;
          }

          final String? grade = courseGrades[code];
          final String? semester = courseSemester[code];

          courses.add({
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

        section.courses = courses;
        section.subtitle = '$sectionCompleted of $sectionTotal Hour';
      } catch (e) {
        section.courses = [];
        section.subtitle = '0 of 0 Hour';
        debugPrint('AcademicPlanController.loadSections error: $e');
      } finally {
        section.loading = false;
        notifyListeners();
      }
    }

    loading = false;
    notifyListeners();
  }
}
