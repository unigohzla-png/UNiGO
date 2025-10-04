import 'package:flutter/material.dart';

class GradesController extends ChangeNotifier {
  List<Map<String, dynamic>> grades = [
    {
      "title": "Digital Logic",
      "mid": 18,
      "project": 15,
      "total": 33,
      "expanded": false,
    },
    {
      "title": "Computer Graphics",
      "mid": 20,
      "project": 12,
      "total": 32,
      "expanded": false,
    },
    {
      "title": "Software Engineering",
      "mid": 22,
      "project": 14,
      "total": 36,
      "expanded": false,
    },
    {
      "title": "Simulation & Modeling",
      "mid": 16,
      "project": 18,
      "total": 34,
      "expanded": false,
    },
  ];

  void toggleExpand(String course) {
    final index = grades.indexWhere((c) => c["title"] == course);
    if (index != -1) {
      grades[index]["expanded"] = !grades[index]["expanded"];
      notifyListeners();
    }
  }
}
