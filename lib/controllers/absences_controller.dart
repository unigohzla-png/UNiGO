import 'package:flutter/material.dart';

class AbsencesController extends ChangeNotifier {
  List<Map<String, dynamic>> absences = [
    {
      "title": "Digital Logic",
      "days": ["Sun", "Tue", "Thu"],
      "value": 0.0,
    },
    {
      "title": "Computer Graphics",
      "days": ["Mon", "Wed"],
      "value": 0.0,
    },
    {
      "title": "Software Engineering",
      "days": ["Sun", "Tue", "Thu"],
      "value": 0.0,
    },
    {
      "title": "Simulation & Modeling",
      "days": ["Mon", "Wed"],
      "value": 0.0,
    },
  ];

  void updateAbsence(String course, double newValue) {
    final index = absences.indexWhere((c) => c["title"] == course);
    if (index != -1) {
      absences[index]["value"] = newValue;
      notifyListeners();
    }
  }

  int getMaxSections(List<String> days) {
    return days.contains("Thu") ? 7 : 4;
  }
}
