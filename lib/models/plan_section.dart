import 'package:flutter/material.dart';

class PlanSection {
  final String title;
  String subtitle;
  final Color indicatorColor;
  final String type;

  // state
  bool loading;
  bool isExpanded;
  List<Map<String, dynamic>> courses;

  // credits info
  int completedHours;
  int totalHours;

  PlanSection({
    required this.title,
    required this.subtitle,
    required this.indicatorColor,
    required this.type,
    this.loading = false,
    this.isExpanded = false,
    this.courses = const [],
    this.completedHours = 0,
    this.totalHours = 0,
  });
}
