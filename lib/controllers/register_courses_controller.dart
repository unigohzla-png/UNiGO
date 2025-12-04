import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../services/registration_service.dart';

class RegisterCoursesController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// All courses in the system (from `courses` collection).
  final List<Subject> availableSubjects = [];

  /// Courses the student has registered for the *next* semester.
  /// Mirrors `users/{uid}.upcomingCourses`.
  final List<Subject> registeredSubjects = [];

  bool isLoading = false;
  String? errorMessage;

  // ===== Timer state =====
  static const int _fallbackMinutes = 15;
  Duration remainingTime = const Duration(minutes: _fallbackMinutes);
  Timer? _timer;
  bool _timerStarted = false;

  // ============================================================
  // ================ LOAD DATA FROM FIRESTORE ==================
  // ============================================================

  Future<void> loadInitialData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      // ----- Read user document -----
      final userSnap = await _db.collection('users').doc(uid).get();
      final userData = userSnap.data();
      if (userData == null) {
        throw Exception('User document not found in Firestore');
      }

      // Current semester courses (to block duplicates)
      final enrolledRaw =
          (userData['enrolledCourses'] ?? []) as List<dynamic>;
      final currentCourseCodes =
          enrolledRaw.map((e) => e.toString()).toSet();

      // Upcoming (next semester)
      final upcomingRaw =
          (userData['upcomingCourses'] ?? []) as List<dynamic>;
      final upcomingCodes =
          upcomingRaw.map((e) => e.toString()).toSet();

      // ----- Read all courses -----
      final coursesSnap = await _db.collection('courses').get();
      final List<Subject> allSubjects = [];
      final List<Subject> upcomingSubjects = [];

      for (final doc in coursesSnap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString();

        final creditsRaw = data['credits'];
        int credits = 0;
        if (creditsRaw is int) {
          credits = creditsRaw;
        } else if (creditsRaw != null) {
          credits = int.tryParse(creditsRaw.toString()) ?? 0;
        }

        final subject = Subject(
          name: name.isEmpty ? doc.id : name,
          credits: credits,
          color: Colors.blue,
          code: doc.id,
        );

        allSubjects.add(subject);

        if (upcomingCodes.contains(doc.id)) {
          upcomingSubjects.add(subject);
        }
      }

      availableSubjects
        ..clear()
        ..addAll(allSubjects);

      registeredSubjects
        ..clear()
        ..addAll(upcomingSubjects);

      // Store current codes into RegistrationService so it can block duplicates
      // when adding/replacing courses.
      RegistrationService.instance.currentCourseCodes =
          currentCourseCodes;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ======================= TIMER LOGIC ========================
  // ============================================================

  /// Call this once *after* RegistrationService has loaded config + user window
  /// and only if `canAccess` is true.
  ///
  /// Before 20:00:
  ///   - If we are inside a personal slot, remainingTime = endAt - now.
  ///   - If user leaves/re-enters page, a new controller will recompute from
  ///     the same endAt, so timer does NOT reset.
  ///
  /// After 20:00:
  ///   - Timer is just a UI countdown from 15:00 and can reset freely.
  void ensureTimerStarted({required bool useSlotWindow}) {
    // If already running, don't start another one.
    if (_timerStarted && (_timer?.isActive ?? false)) return;
    _timerStarted = true;

    final now = DateTime.now();
    if (useSlotWindow) {
      final end = RegistrationService.instance.assignedEndAt;
      if (end != null && now.isBefore(end)) {
        remainingTime = end.difference(now);
      } else {
        remainingTime = Duration.zero;
      }
    } else {
      remainingTime = const Duration(minutes: _fallbackMinutes);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nowTick = DateTime.now();

      if (useSlotWindow) {
        final end = RegistrationService.instance.assignedEndAt;
        if (end == null || !nowTick.isBefore(end)) {
          remainingTime = Duration.zero;
          notifyListeners();
          _timer?.cancel();
          return;
        }
        remainingTime = end.difference(nowTick);
      } else {
        if (remainingTime.inSeconds > 0) {
          remainingTime =
              Duration(seconds: remainingTime.inSeconds - 1);
        } else {
          _timer?.cancel();
        }
      }

      notifyListeners();
    });
  }

  String get formattedTime {
    final totalSeconds = remainingTime.inSeconds;
    if (totalSeconds <= 0) return '00:00';
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ============================================================
  // =========== CRUD: upcomingCourses in Firestore =============
  // ============================================================

  /// Add a course to upcomingCourses.
  /// Returns `null` on success, or an error message on failure.
  Future<String?> addSubject(Subject subject) async {
    final code = subject.code;
    if (code == null) {
      return 'Invalid course (missing code).';
    }

    // Block if already in current semester
    if (RegistrationService.instance.currentCourseCodes
        .contains(code)) {
      return 'Student is already taking "${subject.name}" this semester.';
    }

    // Already in upcoming list? Silent no-op
    if (registeredSubjects.any((s) => s.code == code)) {
      return null;
    }

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      await _db.collection('users').doc(uid).update({
        'upcomingCourses': FieldValue.arrayUnion([code]),
      });

      registeredSubjects.add(subject);
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = 'Failed to register course: $e';
      notifyListeners();
      return 'Failed to register course. Please try again.';
    }
  }

  /// Remove a course from upcomingCourses.
  Future<void> removeSubject(Subject subject) async {
    final code = subject.code;
    if (code == null) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      await _db.collection('users').doc(uid).update({
        'upcomingCourses': FieldValue.arrayRemove([code]),
      });

      registeredSubjects.removeWhere((s) => s.code == code);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to remove course: $e';
      notifyListeners();
    }
  }

  /// Replace one upcoming course with another.
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> replaceSubject(
    Subject oldSubject,
    Subject newSubject,
  ) async {
    final String? oldCode = oldSubject.code;
    final String? newCode = newSubject.code;

    if (oldCode == null || newCode == null || oldCode == newCode) {
      return null;
    }

    // Block if new course is already in current semester
    if (RegistrationService.instance.currentCourseCodes
        .contains(newCode)) {
      return 'Student is already taking "${newSubject.name}" this semester.';
    }

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      await _db.runTransaction((tx) async {
        final ref = _db.collection('users').doc(uid);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('User document not found');
        }

        final data = snap.data() as Map<String, dynamic>;
        final raw = (data['upcomingCourses'] ?? []) as List<dynamic>;
        final List<String> codes =
            raw.map((e) => e.toString()).toList();

        // remove old, add new (no duplicates)
        codes.remove(oldCode);
        if (!codes.contains(newCode)) {
          codes.add(newCode);
        }

        tx.update(ref, {'upcomingCourses': codes});
      });

      registeredSubjects.removeWhere((s) => s.code == oldCode);
      if (!registeredSubjects.any((s) => s.code == newCode)) {
        registeredSubjects.add(newSubject);
      }

      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = 'Failed to switch course: $e';
      notifyListeners();
      return 'Failed to switch course. Please try again.';
    }
  }

  // ============================================================
  // ======================== CLEANUP ===========================
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
