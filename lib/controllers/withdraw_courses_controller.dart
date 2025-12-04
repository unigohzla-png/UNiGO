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

      // Load withdrawn courses (so withdrawnSubjects persist across sessions)
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
              // fallback to code-based subject if course doc missing
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

        // Ensure withdrawnSubjects doesn't duplicate any currently registered subject
        final withdrawnCodes = wlist.map((s) => s.code).toSet();
        registeredSubjects.removeWhere(
          (s) => s.code != null && withdrawnCodes.contains(s.code),
        );

        withdrawnSubjects = wlist;
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> withdrawSubject(Subject subject) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (subject.code == null) return;

    // remove from enrolledCourses array in Firestore
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'enrolledCourses': FieldValue.arrayRemove([subject.code]),
      });
      // also add to withdrawnCourses array so HomePage can mark it
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'withdrawnCourses': FieldValue.arrayUnion([subject.code]),
      }, SetOptions(merge: true));
    } catch (_) {
      // ignore Firestore update errors for now
    }

    // update local lists
    registeredSubjects.removeWhere((s) => s.code == subject.code);
    withdrawnSubjects.add(subject);
    notifyListeners();
  }
}
