import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/plan_section.dart';

class AcademicPlanController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  final List<PlanSection> planSections = [
    PlanSection(
      title: 'University Requirements',
      subtitle: '0 of 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'University Requirements',
    ),
    PlanSection(
      title: 'University Electives',
      subtitle: '0 of 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'University Electives',
    ),
    PlanSection(
      title: 'Obligatory School Courses',
      subtitle: '0 of 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Obligatory School Courses',
    ),
    PlanSection(
      title: 'Elective School Courses',
      subtitle: '0 of 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Elective School Courses',
    ),
    PlanSection(
      title: 'Obligatory Speciality Courses',
      subtitle: '0 of 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Obligatory Speciality Courses',
    ),
    PlanSection(
      title: 'Elective Speciality Courses',
      subtitle: '0 of 0 Hour',
      indicatorColor: Colors.redAccent,
      type: 'Elective Speciality Courses',
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
    notifyListeners();

    // -------- 1) User progress (completed + enrolled) --------
    final uid = FirebaseAuth.instance.currentUser?.uid;

    Set<String> completedCodes = {};
    Set<String> enrolledCodes = {};

    Map<String, String> courseGrades = {};

    if (uid != null) {
      final userSnap = await _db.collection('users').doc(uid).get();
      final data = userSnap.data();

      if (data != null) {
        final previous = (data['previousCourses'] as List?) ?? [];
        final enrolled = (data['enrolledCourses'] as List?) ?? [];

        completedCodes = previous.map((e) => e.toString()).toSet();
        enrolledCodes = enrolled.map((e) => e.toString()).toSet();

        final gradesMap = data['courseGrades'];
        if (gradesMap is Map) {
          gradesMap.forEach((key, value) {
            if (key != null && value != null) {
              courseGrades[key.toString()] = value.toString();
            }
          });
        }
      }
    }

    // -------- 2) Load each section + compute credits --------
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

          final int credits = (data['credits'] is int)
              ? data['credits'] as int
              : (data['credits'] is num ? (data['credits'] as num).toInt() : 0);

          sectionTotal += credits;
          totalCredits += credits;

          final bool isCompleted = completedCodes.contains(code);
          final bool isEnrolled = enrolledCodes.contains(code);
          final String? grade = courseGrades[code];

          if (isCompleted) {
            sectionCompleted += credits;
            completedCredits += credits;
          } else if (isEnrolled) {
            inProgressCredits += credits;
          }

          courses.add({
            ...data,
            'id': code,
            'code': data['code'] ?? code,
            'credits': credits,
            'isCompleted': isCompleted,
            'isEnrolled': isEnrolled,
            'grade': grade,
          });
        }

        section.courses = courses;
        section.subtitle = '$sectionCompleted of $sectionTotal Hour';
      } catch (e) {
        section.courses = [];
        section.subtitle = '0 of 0 Hour';
        debugPrint('Error loading section ${section.type}: $e');
      } finally {
        section.loading = false;
        notifyListeners();
      }
    }

    loading = false;
    notifyListeners();
  }
}
