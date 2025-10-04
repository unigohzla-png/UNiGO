import 'package:flutter/material.dart';

class CoursesController extends ChangeNotifier {
  String selectedTab = "Current";

  void switchTab(String tab) {
    selectedTab = tab;
    notifyListeners();
  }

  List<Map<String, String>> currentCourses = [
    {"title": "Digital Logic", "asset": "assets/DarkBlue.png"},
    {"title": "Computer Graphics", "asset": "assets/DarkGreen.png"},
    {"title": "Software Engineering", "asset": "assets/DarkYellow.png"},
    {"title": "Simulation & Modeling", "asset": "assets/DarkRed.png"},
  ];

  List<Map<String, dynamic>> registerOptions = [
    {"icon": Icons.access_time, "title": "Reserve Time"},
    {"icon": Icons.bookmark, "title": "Register Courses"},
    {"icon": Icons.remove_circle_outline, "title": "Withdraw Courses"},
    {"icon": Icons.print, "title": "Print Schedule"},
    {"icon": Icons.search, "title": "Inquiry Subjects"},
    {"icon": Icons.search, "title": "Academic Plan"},
  ];
}
