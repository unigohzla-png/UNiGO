// lib/services/gpa_service.dart

import 'package:flutter/material.dart';

import '../models/course_grade.dart';
import '../models/gpa_calculation.dart';

/// Pure GPA calculation logic + state holder.
class GPAService extends ChangeNotifier {
  double _currentGPA = 0.0;
  final List<CourseGrade> _courses = [];
  GPACalculation _calculation = GPACalculation.empty();

  double get currentGPA => _currentGPA;
  List<CourseGrade> get courses => List.unmodifiable(_courses);
  GPACalculation get calculation => _calculation;

  /// Optionally set by the app if you have a stored GPA.
  void setCurrentGPA(double gpa) {
    _currentGPA = gpa;
    notifyListeners();
  }

  void clearCourses() {
    _courses.clear();
    _calculation = GPACalculation.empty();
    notifyListeners();
  }

  void addCourse(CourseGrade course) {
    _courses.add(course);
    notifyListeners();
  }

  void removeCourse(int index) {
    if (index >= 0 && index < _courses.length) {
      _courses.removeAt(index);
      notifyListeners();
    }
  }

  /// Main GPA calculation: GPA = total grade points / total credit hours
  void calculateGPA() {
    if (_courses.isEmpty) {
      _currentGPA = 0.0;
      _calculation = GPACalculation.empty();
      notifyListeners();
      return;
    }

    double totalGradePoints = 0.0;
    double totalCreditHours = 0.0;

    for (final course in _courses) {
      totalGradePoints += course.totalPoints;
      totalCreditHours += course.creditHours;
    }

    if (totalCreditHours <= 0) {
      _currentGPA = 0.0;
      _calculation = GPACalculation.empty();
    } else {
      final gpa = totalGradePoints / totalCreditHours;
      _currentGPA = gpa;

      _calculation = GPACalculation(
        currentGPA: gpa,
        newGPA: gpa, // kept for compatibility with your teammates’ model
        courses: List<CourseGrade>.from(_courses),
        totalCreditHours: totalCreditHours,
        totalGradePoints: totalGradePoints,
      );
    }

    notifyListeners();
  }

  /// Letter grade → numeric points (standard 4.0 scale)
  /// Returns -1 for invalid grade strings.
  double getGradePoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return -1; // invalid grade
    }
  }
}
