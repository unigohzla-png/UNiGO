// absences_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/absence_models.dart';

class AbsencesController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isLoading = true;
  List<AbsenceCourse> courses = [];

  AbsencesController() {
    _load();
  }

  // Mon/Wed -> 5, Sun/Tue/Thu -> 7 (your rule)
  int computeMaxAbsences(List<String> days) {
    final set = days.toSet();
    if (set.contains('Sun') || set.contains('Tue') || set.contains('Thu')) {
      return 7;
    }
    if (set.contains('Mon') || set.contains('Wed')) {
      return 5;
    }
    // fallback if we can't detect properly
    return 5;
  }

  bool showWarning(AbsenceCourse c) {
    if (c.maxAbsences == 0) return false;
    return c.ratio >= 0.8; // >= 80%
  }

  Future<void> _load() async {
    try {
      debugPrint('Absences _load START');

      final uid = _auth.currentUser!.uid;
      debugPrint('Absences UID = $uid');

      // 1) enrolled courses list from user doc
      final userSnap = await _db.collection('users').doc(uid).get();
      if (!userSnap.exists) {
        debugPrint('Absences: user doc NOT found for uid=$uid');
        courses = [];
        return;
      }

      final uData = userSnap.data() ?? {};
      debugPrint('Absences user data: $uData');

      final List<dynamic> rawEnrolled =
          (uData['enrolledCourses'] ?? []) as List<dynamic>;
      final enrolledCodes = rawEnrolled.map((e) => e.toString()).toList();

      debugPrint('Absences enrolledCodes = $enrolledCodes');

      final List<AbsenceCourse> result = [];

      for (final code in enrolledCodes) {
        debugPrint('--- Handling course code: $code');

        // 2) global course info
        final courseSnap = await _db.collection('courses').doc(code).get();
        if (!courseSnap.exists) {
          debugPrint('  courses/$code DOES NOT EXIST');
          continue;
        }

        final cData = courseSnap.data() as Map<String, dynamic>;
        debugPrint('  course data: $cData');

        final String name = (cData['name'] ?? code) as String;

        // sections array – TEMP: use first section
        final List<dynamic> rawSections =
            (cData['sections'] ?? []) as List<dynamic>;
        List<String> days = [];
        if (rawSections.isNotEmpty) {
          final sec = rawSections.first as Map<String, dynamic>;
          final List<dynamic> rawDays = (sec['days'] ?? []) as List<dynamic>;
          days = rawDays.map((e) => e.toString()).toList();
        }

        final maxAbs = computeMaxAbsences(days);

        // 3) absences for this student+course
        final absQuery = await _db
            .collection('users')
            .doc(uid)
            .collection('courses')
            .doc(code)
            .collection('absences')
            .orderBy('date')
            .get();

        debugPrint('  found ${absQuery.docs.length} absence docs for $code');

        final sessions = absQuery.docs
            .map((doc) => AbsenceSession.fromDoc(doc))
            .toList();

        result.add(
          AbsenceCourse(
            code: code,
            name: name,
            days: days,
            maxAbsences: maxAbs,
            sessions: sessions,
          ),
        );
      }

      debugPrint('Absences _load DONE, result length = ${result.length}');

      courses = result;
    } catch (e, st) {
      debugPrint('Absences _load ERROR: $e');
      debugPrint(st.toString());
      courses = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
