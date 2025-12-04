import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_section.dart';

class AcademicPlanController extends ChangeNotifier {
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

  Future<void> loadSections() async {
    for (final section in planSections) {
      section.loading = true;
      notifyListeners();
      try {
        final q = await FirebaseFirestore.instance
            .collection('courses')
            .where('type', isEqualTo: section.type)
            .get();
        section.courses = q.docs.map((d) => d.data()..['id'] = d.id).toList();
      } catch (_) {
        section.courses = [];
      } finally {
        section.loading = false;
        notifyListeners();
      }
    }
  }
}
