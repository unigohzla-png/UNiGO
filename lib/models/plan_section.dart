import 'package:flutter/material.dart';

class PlanSection {
  final String title;
  final String type;
  final Color indicatorColor;

  String subtitle;
  bool loading;
  bool isExpanded;

  /// Each item is a map from Firestore + extra fields:
  ///  {
  ///    'id': code,
  ///    'code': code,
  ///    'name': ...,
  ///    'credits': int,
  ///    'isCompleted': bool,
  ///    'isEnrolled': bool,
  ///    'grade': String?,        // from user.previousCourses[code].grade
  ///    'semester': String?,     // from user.previousCourses[code].semester
  ///  }
  List<Map<String, dynamic>> courses;

  PlanSection({
    required this.title,
    required this.type,
    required this.indicatorColor,
    this.subtitle = '0 of 0 Hour',
    this.loading = false,
    this.isExpanded = false,
    List<Map<String, dynamic>>? courses,
  }) : courses = courses ?? [];
}
