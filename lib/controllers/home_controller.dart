import 'package:flutter/material.dart';

class HomeController extends ChangeNotifier {
  double completionRate = 82.0;
  int completedHours = 120;
  double gpa = 3.8;

  List<Map<String, String>> currentSemesterCourses = [
    {"title": "Digital Logic", "asset": "assets/DarkBlue.png"},
    {"title": "Computer Graphics", "asset": "assets/DarkGreen.png"},
    {"title": "Software Engineering", "asset": "assets/DarkYellow.png"},
    {"title": "Simulation and Modeling", "asset": "assets/DarkRed.png"},
    {"title": "Simulation and Modeling", "asset": "assets/DarkRed.png"},
    {"title": "Simulation and Modeling", "asset": "assets/DarkRed.png"},
    {"title": "Simulation and Modeling", "asset": "assets/DarkRed.png"},
    {"title": "Simulation and Modeling", "asset": "assets/DarkRed.png"},
  ];
}
