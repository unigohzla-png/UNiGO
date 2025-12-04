import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  bool loadingCourses = false;
  List<String> withdrawnCourseCodes = [];

  Future<void> loadEnrolledCourses() async {
    loadingCourses = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      loadingCourses = false;
      notifyListeners();
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userDoc.data();
      if (data == null) {
        // if user doc doesn't exist, ensure we don't show dummy data
        currentSemesterCourses = [];
        loadingCourses = false;
        notifyListeners();
        return;
      }

      // Clear default dummy data immediately to avoid showing it for users
      currentSemesterCourses = [];

      withdrawnCourseCodes = [];
      final withdrawn = data['withdrawnCourses'];
      if (withdrawn is List) {
        withdrawnCourseCodes = withdrawn.map((e) => e.toString()).toList();
      }

      final enrolled = data['enrolledCourses'];
      if (enrolled is List && enrolled.isNotEmpty) {
        final List<Map<String, String>> courses = [];
        for (final code in enrolled) {
          try {
            final courseDoc = await FirebaseFirestore.instance
                .collection('courses')
                .doc(code.toString())
                .get();
            if (courseDoc.exists) {
              final c = courseDoc.data()!;
              final codeStr = code.toString();
              courses.add({
                'title': c['name']?.toString() ?? codeStr,
                'asset': 'assets/DarkBlue.png', // placeholder mapping
                'code': codeStr,
                'isWithdrawn': withdrawnCourseCodes.contains(codeStr)
                    ? '1'
                    : '0',
              });
            }
          } catch (_) {
            // ignore individual course fetch errors
          }
        }
        // assign even if courses is empty - currentSemesterCourses already cleared
        if (courses.isNotEmpty) {
          currentSemesterCourses = courses;
        }
      }
    } finally {
      loadingCourses = false;
      notifyListeners();
    }
  }
}
