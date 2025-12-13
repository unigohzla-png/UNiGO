// lib/controllers/gpa_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/gpa_service.dart';
import '../models/course_grade.dart';

/// Controller that glues GPAService to the UI.
class GPAController extends ChangeNotifier {
  final GPAService _gpaService = GPAService();
  final List<CourseInput> _courses = [CourseInput()];
  bool _showExplanation = false;

  GPAService get gpaService => _gpaService;
  List<CourseInput> get courses => List.unmodifiable(_courses);
  bool get showExplanation => _showExplanation;

  GPAController() {
    _init();
  }

  Future<void> _init() async {
    await _loadCurrentGpaFromFirestore();
    notifyListeners();
  }

  /// Optional: read existing GPA from user doc (if you still store it).
  Future<void> _loadCurrentGpaFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = snap.data();
      if (data == null) return;

      final gpaValue = data['gpa'];
      double gpa = 0.0;

      if (gpaValue is num) {
        gpa = gpaValue.toDouble();
      } else if (gpaValue is String) {
        final parsed = double.tryParse(gpaValue);
        if (parsed != null) gpa = parsed;
      }

      _gpaService.setCurrentGPA(gpa);
    } catch (_) {
      // If anything fails, keep default 0.0
    }
  }

  void toggleExplanation() {
    _showExplanation = !_showExplanation;
    notifyListeners();
  }

  void addCourse() {
    if (_courses.length < 8) {
      _courses.add(CourseInput());
      notifyListeners();
    }
  }

  void removeCourse(int index) {
    if (_courses.length > 1 && index >= 0 && index < _courses.length) {
      _courses[index].dispose();
      _courses.removeAt(index);
      notifyListeners();
    }
  }

  /// Reads text from all course inputs and triggers calculation.
  void calculateGPA() {
    _gpaService.clearCourses();

    for (final course in _courses) {
      final grade = course.gradeController.text.trim().toUpperCase();
      final creditText = course.creditHoursController.text.trim();

      if (grade.isEmpty || creditText.isEmpty) continue;

      final creditHours = double.tryParse(creditText) ?? 0.0;
      if (creditHours <= 0) continue;

      final gradePoint = _gpaService.getGradePoint(grade);
      if (gradePoint < 0) continue; // invalid grade

      _gpaService.addCourse(
        CourseGrade.fromInput(grade, creditHours, gradePoint),
      );
    }

    _gpaService.calculateGPA();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in _courses) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Helper for a single row of inputs (grade + credits).
class CourseInput {
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController creditHoursController = TextEditingController();

  void dispose() {
    gradeController.dispose();
    creditHoursController.dispose();
  }
}
