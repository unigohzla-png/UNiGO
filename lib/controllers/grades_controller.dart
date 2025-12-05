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
    try {
      final uid = _auth.currentUser!.uid;

      final userSnap = await _db.collection('users').doc(uid).get();
      if (!userSnap.exists) {
        courses = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      final uData = userSnap.data() ?? {};
      final List<dynamic> rawEnrolled =
          (uData['enrolledCourses'] ?? []) as List<dynamic>;
      final enrolledCodes = rawEnrolled.map((e) => e.toString()).toList();

      final List<CourseGrades> result = [];

      for (final code in enrolledCodes) {
        // get course name
        final courseSnap =
            await _db.collection('courses').doc(code).get();
        if (!courseSnap.exists) continue;

        final cData = courseSnap.data() as Map<String, dynamic>;
        final String name = (cData['name'] ?? code) as String;

        // get grade items
        final gradesQuery = await _db
            .collection('users')
            .doc(uid)
            .collection('courses')
            .doc(code)
            .collection('grades')
            .orderBy('order')
            .get();

        final items = gradesQuery.docs
            .map((doc) =>
                GradeItem.fromDoc(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();

        result.add(
          CourseGrades(
            courseCode: code,
            courseName: name,
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
