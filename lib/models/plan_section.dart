import 'package:flutter/material.dart';

class PlanSection {
  final String title;
  final String subtitle;
  final Color indicatorColor;
  final String type; // Firestore 'type' value to query by

  bool loading = false;
  List<Map<String, dynamic>> courses = [];

  PlanSection({
    required this.title,
    required this.subtitle,
    required this.indicatorColor,
    required this.type,
  });
}
