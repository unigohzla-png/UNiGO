import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject_model.dart';

class WithdrawCoursesController extends ChangeNotifier {
  List<Subject> registeredSubjects = [];
  List<Subject> withdrawnSubjects = [];

  bool loading = false;

  Future<void> loadRegisteredCourses() async {
    loading = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = userDoc.data();
      if (data == null) return;

      registeredSubjects = [];
      withdrawnSubjects = [];

      // ------------------------------
      // LOAD ENROLLED COURSES
      // ------------------------------
      final enrolled = data['enrolledCourses'];
      if (enrolled is List && enrolled.isNotEmpty) {
        final List<Subject> list = [];

        for (final code in enrolled) {
          try {
            final courseDoc = await FirebaseFirestore.instance
                .collection('courses')
                .doc(code.toString())
                .get();

            if (courseDoc.exists) {
              final c = courseDoc.data()!;
              list.add(
                Subject(
                  name: c['name']?.toString() ?? code.toString(),
                  credits: (c['credits'] is int)
                      ? c['credits']
                      : (c['credits'] is num
                            ? (c['credits'] as num).toInt()
                            : 0),
                  color: Colors.blue,
                  code: code.toString(),
                ),
              );
            }
          } catch (_) {}
        }

        registeredSubjects = list;
      }

      // ------------------------------
      // LOAD WITHDRAWN COURSES
      // ------------------------------
      final withdrawn = data['withdrawnCourses'];
      if (withdrawn is List && withdrawn.isNotEmpty) {
        final List<Subject> wlist = [];

        for (final code in withdrawn) {
          try {
            final courseDoc = await FirebaseFirestore.instance
                .collection('courses')
                .doc(code.toString())
                .get();

            if (courseDoc.exists) {
              final c = courseDoc.data()!;
              wlist.add(
                Subject(
                  name: c['name']?.toString() ?? code.toString(),
                  credits: (c['credits'] is int)
                      ? c['credits']
                      : (c['credits'] is num
                            ? (c['credits'] as num).toInt()
                            : 0),
                  color: Colors.grey,
                  code: code.toString(),
                ),
              );
            } else {
              wlist.add(
                Subject(
                  name: code.toString(),
                  credits: 0,
                  color: Colors.grey,
                  code: code.toString(),
                ),
              );
            }
          } catch (_) {}
        }

        withdrawnSubjects = wlist;
      }

      // ------------------------------
      // CLEAN UP DUPLICATES
      // ------------------------------
      final withdrawnCodes = withdrawnSubjects.map((s) => s.code).toSet();

      // remove any registered course that has been withdrawn
      registeredSubjects.removeWhere((s) => withdrawnCodes.contains(s.code));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------
  // ATOMIC WITHDRAW FUNCTION
  // --------------------------------------------------------
  Future<void> withdrawSubject(Subject subject) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || subject.code == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      // One atomic update
      await userRef.update({
        'enrolledCourses': FieldValue.arrayRemove([subject.code]),
        'withdrawnCourses': FieldValue.arrayUnion([subject.code]),
      });

      // Update local state
      registeredSubjects.removeWhere((s) => s.code == subject.code);

      // add withdrawn card with grey color
      withdrawnSubjects.add(
        Subject(
          name: subject.name,
          credits: subject.credits,
          color: Colors.grey,
          code: subject.code,
        ),
      );

      notifyListeners();
    } catch (e) {
      print("Withdraw error: $e");
    }
  }
}
