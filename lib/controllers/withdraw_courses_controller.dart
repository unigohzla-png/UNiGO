import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subject_model.dart';

class WithdrawCoursesController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Subject> registeredSubjects = [];
  List<Subject> withdrawnSubjects = [];

  bool loading = false;
  String? errorMessage;

  int totalRegisteredCredits = 0;
  int totalWithdrawnCredits = 0;

  Future<void> loadRegisteredCourses() async {
    loading = true;
    errorMessage = null;
    registeredSubjects = [];
    withdrawnSubjects = [];
    totalRegisteredCredits = 0;
    totalWithdrawnCredits = 0;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      loading = false;
      errorMessage = 'User not logged in.';
      notifyListeners();
      return;
    }

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data == null) {
        loading = false;
        errorMessage = 'User document not found in Firestore.';
        notifyListeners();
        return;
      }

      // ---------------- Registered (enrolledCourses) ----------------
      final enrolled = data['enrolledCourses'];
      final List<Subject> enrolledList = [];

      if (enrolled is List && enrolled.isNotEmpty) {
        for (final codeRaw in enrolled) {
          final code = codeRaw.toString();
          try {
            final courseDoc =
                await _db.collection('courses').doc(code).get();
            if (courseDoc.exists) {
              final c = courseDoc.data()!;
              final credits = _parseCredits(c['credits']);
              totalRegisteredCredits += credits;

              enrolledList.add(
                Subject(
                  name: c['name']?.toString() ?? code,
                  credits: credits,
                  color: Colors.blue,
                  code: code,
                ),
              );
            }
          } catch (_) {
            // ignore individual course load errors
          }
        }
      }

      // ---------------- Withdrawn (withdrawnCourses) ----------------
      final withdrawn = data['withdrawnCourses'];
      final List<Subject> withdrawnList = [];

      if (withdrawn is List && withdrawn.isNotEmpty) {
        for (final codeRaw in withdrawn) {
          final code = codeRaw.toString();
          try {
            final courseDoc =
                await _db.collection('courses').doc(code).get();
            if (courseDoc.exists) {
              final c = courseDoc.data()!;
              final credits = _parseCredits(c['credits']);
              totalWithdrawnCredits += credits;

              withdrawnList.add(
                Subject(
                  name: c['name']?.toString() ?? code,
                  credits: credits,
                  color: Colors.grey,
                  code: code,
                ),
              );
            } else {
              // fallback if course doc missing
              withdrawnList.add(
                Subject(
                  name: code,
                  credits: 0,
                  color: Colors.grey,
                  code: code,
                ),
              );
            }
          } catch (_) {
            // ignore individual course load errors
          }
        }
      }

      // Avoid duplicates: if course appears in withdrawn, remove it from registered
      final withdrawnCodes = withdrawnList.map((s) => s.code).toSet();
      enrolledList.removeWhere(
        (s) => s.code != null && withdrawnCodes.contains(s.code),
      );

      registeredSubjects = enrolledList;
      withdrawnSubjects = withdrawnList;
    } catch (e) {
      errorMessage = 'Failed to load courses: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> withdrawSubject(Subject subject) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      errorMessage = 'User not logged in.';
      notifyListeners();
      return;
    }
    if (subject.code == null) return;

    try {
      // Remove from enrolledCourses and add to withdrawnCourses atomically-ish
      await _db.collection('users').doc(uid).set(
        {
          'enrolledCourses': FieldValue.arrayRemove([subject.code]),
          'withdrawnCourses': FieldValue.arrayUnion([subject.code]),
        },
        SetOptions(merge: true),
      );

      // Update local lists + credits
      registeredSubjects.removeWhere((s) => s.code == subject.code);
      withdrawnSubjects.add(
        subject.copyWith(color: Colors.grey),
      );

      totalRegisteredCredits -= subject.credits;
      if (totalRegisteredCredits < 0) totalRegisteredCredits = 0;
      totalWithdrawnCredits += subject.credits;

      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to withdraw course: $e';
      notifyListeners();
    }
  }

  int _parseCredits(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v != null) {
      return int.tryParse(v.toString()) ?? 0;
    }
    return 0;
  }
}
