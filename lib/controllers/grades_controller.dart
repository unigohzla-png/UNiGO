import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/grade_models.dart';

class GradesController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isLoading = true;
  List<CourseGrades> courses = [];

  GradesController() {
    _load();
  }

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        courses = [];
        return;
      }

      final userSnap = await _db.collection('users').doc(uid).get();
      final userData = userSnap.data();

      if (userData == null) {
        courses = [];
        return;
      }

      // Collect course codes from enrolled + previousCourses
      final Set<String> courseCodes = {};

      final enrolledRaw = (userData['enrolledCourses'] as List?) ?? [];
      courseCodes.addAll(enrolledRaw.map((e) => e.toString()));

      final prev = userData['previousCourses'];
      if (prev is Map) {
        for (final entry in prev.entries) {
          courseCodes.add(entry.key.toString());
        }
      }

      final List<CourseGrades> result = [];

      for (final code in courseCodes) {
        final trimmedCode = code.trim();
        if (trimmedCode.isEmpty) continue;

        // Get course name from courses collection
        final courseDoc = await _db
            .collection('courses')
            .doc(trimmedCode)
            .get();
        final courseData = courseDoc.data();
        final courseName =
            courseData?['name']?.toString() ??
            courseData?['title']?.toString() ??
            trimmedCode;

        // Load only CONFIRMED grade items
        final gradesSnap = await _db
            .collection('users')
            .doc(uid)
            .collection('courses')
            .doc(trimmedCode)
            .collection('grades')
            .where('confirmed', isEqualTo: true)
            .get();

        final items =
            gradesSnap.docs
                .map((doc) => GradeItem.fromDoc(doc))
                .where((g) => g.confirmed)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order)); // 🔹 local sort

        if (items.isEmpty) {
          // no confirmed grades for this course yet
          continue;
        }

        result.add(
          CourseGrades(
            courseCode: trimmedCode,
            courseName: courseName,
            items: items,
          ),
        );
      }

      courses = result;
    } catch (e, st) {
      debugPrint('GradesController _load ERROR: $e');
      debugPrint(st.toString());
      courses = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
