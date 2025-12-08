import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeController extends ChangeNotifier {
  double completionRate = 0.0; // %
  int completedHours = 0;
  double gpa = 0.0;

  bool loadingStats = false;

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

  Future<void> loadStats() async {
    loadingStats = true;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1) Read user doc and gather completed course codes
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = userSnap.data();
      if (userData == null) return;

      final completedCodes = <String>{};

      final prev = userData['previousCourses'];
      if (prev is Map) {
        // keys of previousCourses map are the course codes
        for (final key in prev.keys) {
          completedCodes.add(key.toString());
        }
      }

      // 2) Scan all courses to compute total + completed credits
      final coursesSnap = await FirebaseFirestore.instance
          .collection('courses')
          .get();

      int totalCredits = 0;
      int completedCredits = 0;

      for (final doc in coursesSnap.docs) {
        final data = doc.data();
        final code = doc.id;
        final altCode = data['code']?.toString();

        // credits can be int / num / string
        final raw = data['credits'];
        int credits;
        if (raw is int) {
          credits = raw;
        } else if (raw is num) {
          credits = raw.toInt();
        } else {
          credits = int.tryParse(raw?.toString() ?? '') ?? 0;
        }

        totalCredits += credits;

        final isCompleted =
            completedCodes.contains(code) ||
            (altCode != null && completedCodes.contains(altCode));

        if (isCompleted) {
          completedCredits += credits;
        }
      }

      completedHours = completedCredits;
      completionRate = totalCredits == 0
          ? 0.0
          : (completedCredits / totalCredits) * 100.0;
    } finally {
      loadingStats = false;
      notifyListeners();
    }
  }

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
