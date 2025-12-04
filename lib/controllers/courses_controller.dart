import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  bool loadingCourses = false;

  Future<void> loadUserCourses() async {
    loadingCourses = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      currentCourses = [];
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
      // clear default data immediately
      currentCourses = [];
      if (data == null) {
        return;
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
              courses.add({
                'title': c['name']?.toString() ?? code.toString(),
                'asset': 'assets/DarkBlue.png',
              });
            }
          } catch (_) {
            // ignore per-course errors
          }
        }
        if (courses.isNotEmpty) currentCourses = courses;
      }
    } finally {
      loadingCourses = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> registerOptions = [
    {"icon": Icons.access_time, "title": "Reserve Time"},
    {"icon": Icons.bookmark, "title": "Register Courses"},
    {"icon": Icons.remove_circle_outline, "title": "Withdraw Courses"},
    {"icon": Icons.print, "title": "Print Schedule"},
    {"icon": Icons.search, "title": "Inquiry Subjects"},
    {"icon": Icons.manage_search, "title": "Academic Plan"},
  ];
}
