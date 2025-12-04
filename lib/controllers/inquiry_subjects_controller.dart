import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plan_section.dart';

class InquirySubjectsController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

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

  Future<void> loadSections() async {
    loading = true;
    error = null;
    notifyListeners();

    for (final section in sections) {
      section.loading = true;
      section.courses = [];
      section.subtitle = 'Available: 0 Hour';
      notifyListeners();

      try {
        final q = await _db
            .collection('courses')
            .where('type', isEqualTo: section.type)
            .where('availableNextSemester', isEqualTo: true)
            .get();

        final List<Map<String, dynamic>> courses = [];
        int totalCredits = 0;

        for (final doc in q.docs) {
          final data = doc.data();
          final code = doc.id;

          final int credits = (data['credits'] is int)
              ? data['credits'] as int
              : (data['credits'] is num ? (data['credits'] as num).toInt() : 0);

          totalCredits += credits;

          courses.add({
            ...data,
            'id': code,
            'code': data['code'] ?? code,
            'credits': credits,
            // these flags will just default to false in the card
            'isCompleted': false,
            'isEnrolled': false,
          });
        }

        section.courses = courses;
        section.subtitle = 'Available: $totalCredits Hour';
      } catch (e) {
        section.courses = [];
        section.subtitle = 'Available: 0 Hour';
        error ??= 'Failed to load some inquiry sections.';
        debugPrint('Inquiry section ${section.type} error: $e');
      } finally {
        section.loading = false;
        notifyListeners();
      }
    }

    loading = false;
    notifyListeners();
  }
}
