import 'package:flutter/material.dart';

class CompletedCoursesController extends ChangeNotifier {
  final List<Map<String, dynamic>> semesters = [
    {
      "term": "Spring 2024",
      "expanded": false,
      "courses": [
        {"title": "Data Structures", "grade": "A"},
        {"title": "Database Systems", "grade": "B+"},
      ],
    },
    {
      "term": "Fall 2023",
      "expanded": false,
      "courses": [
        {"title": "Computer Networks", "grade": "A-"},
        {"title": "Operating Systems", "grade": "B"},
      ],
    },
    {
      "term": "Spring 2023",
      "expanded": false,
      "courses": [
        {"title": "Linear Algebra", "grade": "C"},
        {"title": "Software Design", "grade": "B"},
      ],
    },
  ];

  void toggleExpand(String term) {
    final index = semesters.indexWhere((s) => s["term"] == term);
    if (index != -1) {
      semesters[index]["expanded"] = !semesters[index]["expanded"];
      notifyListeners();
    }
  }
}
