import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/course_section.dart';
import '../services/registration_service.dart';

class RegisterCoursesController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// All courses in the system (from `courses` collection).
  final List<Subject> availableSubjects = [];

  /// Courses the student has registered for the *next* semester.
  /// Mirrors `users/{uid}.upcomingCourses` + `upcomingSections`.
  final List<Subject> registeredSubjects = [];

  bool isLoading = false;
  String? errorMessage;

  // ===== Timer state =====
  static const int _fallbackMinutes = 15;
  Duration remainingTime = const Duration(minutes: _fallbackMinutes);
  Timer? _timer;
  bool _timerStarted = false;

  /// Max credits allowed per student for registration.
  static const int maxCredits = 18;

  /// Current total credits of all registered subjects.
  int get totalRegisteredCredits =>
      registeredSubjects.fold<int>(0, (sum, s) => sum + s.credits);

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
      final enrolledRaw = (userData['enrolledCourses'] ?? []) as List<dynamic>;
      final currentCourseCodes = enrolledRaw.map((e) => e.toString()).toSet();

      // Upcoming (next semester)
      final upcomingRaw = (userData['upcomingCourses'] ?? []) as List<dynamic>;
      final upcomingCodes = upcomingRaw.map((e) => e.toString()).toSet();

      // Upcoming sections map: { courseCode: sectionId }
      final upcomingSectionsRaw = userData['upcomingSections'];
      final Map<String, String> upcomingSections = {};
      if (upcomingSectionsRaw is Map) {
        upcomingSectionsRaw.forEach((key, value) {
          if (key != null && value != null) {
            upcomingSections[key.toString()] = value.toString();
          }
        });
      }

      // ----- Read all courses -----
      final coursesSnap = await _db.collection('courses').get();
      final List<Subject> allSubjects = [];
      final List<Subject> upcomingSubjects = [];

      for (final doc in coursesSnap.docs) {
        final data = doc.data();
        final String code = doc.id;

        final name = (data['name'] ?? '').toString();

        // parse credits
        final creditsRaw = data['credits'];
        int credits = 0;
        if (creditsRaw is int) {
          credits = creditsRaw;
        } else if (creditsRaw != null) {
          credits = int.tryParse(creditsRaw.toString()) ?? 0;
        }

        // parse sections
        List<CourseSection> sections = [];
        final rawSections = data['sections'];
        if (rawSections is List) {
          sections = rawSections
              .whereType<Map>()
              .map(
                (m) =>
                    CourseSection.fromMap(Map<String, dynamic>.from(m as Map)),
              )
              .toList();
        }

        final baseSubject = Subject(
          name: name.isEmpty ? code : name,
          credits: credits,
          color: Colors.blue,
          code: code,
          sections: sections,
        );

        allSubjects.add(baseSubject);

        if (upcomingCodes.contains(code)) {
          // does the user already have a chosen section for this course?
          final selectedSectionId = upcomingSections[code];
          CourseSection? selectedSection;
          if (selectedSectionId != null) {
            selectedSection = sections.firstWhere(
              (s) => s.id == selectedSectionId,
              orElse: () => CourseSection(
                id: selectedSectionId,
                doctorName: '',
                days: const [],
                startTime: '',
                endTime: '',
              ),
            );
          }

          upcomingSubjects.add(
            baseSubject.copyWith(selectedSection: selectedSection),
          );
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
      RegistrationService.instance.currentCourseCodes = currentCourseCodes;
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

  void ensureTimerStarted({required bool useSlotWindow}) {
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
          remainingTime = Duration(seconds: remainingTime.inSeconds - 1);
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

  /// Add a course to upcomingCourses, and optionally store the selected section.
  ///
  /// Returns `null` on success, or an error message on failure.
  Future<String?> addSubject(Subject subject, {CourseSection? section}) async {
    final code = subject.code;
    if (code == null) {
      return 'Invalid course (missing code).';
    }

    // Block if already in current semester
    if (RegistrationService.instance.currentCourseCodes.contains(code)) {
      return 'Student is already taking "${subject.name}" this semester.';
    }

    // Already in upcoming list? Silent no-op
    if (registeredSubjects.any((s) => s.code == code)) {
      return null;
    }

    // ---- Credit limit check ----
    final currentCredits = totalRegisteredCredits;
    final newTotal = currentCredits + subject.credits;
    if (newTotal > maxCredits) {
      return 'You cannot register more than $maxCredits credits. '
          'Current total is $currentCredits, '
          '"${subject.name}" would make it $newTotal.';
    }

    // If we have a section, check for time conflicts with existing registeredSubjects
    if (section != null) {
      final conflictError = _checkTimeConflict(subject, section);
      if (conflictError != null) {
        return conflictError;
      }
    }

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      final Map<String, dynamic> updates = {
        'upcomingCourses': FieldValue.arrayUnion([code]),
      };

      if (section != null) {
        updates['upcomingSections.$code'] = section.id;
      }

      await _db
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      final withSection = subject.copyWith(selectedSection: section);
      registeredSubjects.add(withSection);
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = 'Failed to register course: $e';
      notifyListeners();
      return 'Failed to register course. Please try again.';
    }
  }

  /// Remove a course from upcomingCourses and its section mapping.
  Future<void> removeSubject(Subject subject) async {
    final code = subject.code;
    if (code == null) return;

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      await _db.collection('users').doc(uid).set({
        'upcomingCourses': FieldValue.arrayRemove([code]),
        'upcomingSections.$code': FieldValue.delete(),
      }, SetOptions(merge: true));

      registeredSubjects.removeWhere((s) => s.code == code);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to remove course: $e';
      notifyListeners();
    }
  }

  /// Replace one upcoming course with another.
  /// Does NOT auto-assign section to the new course.
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> replaceSubject(Subject oldSubject, Subject newSubject) async {
    final String? oldCode = oldSubject.code;
    final String? newCode = newSubject.code;

    if (oldCode == null || newCode == null || oldCode == newCode) {
      return null;
    }

    // Block if new course is already in current semester
    if (RegistrationService.instance.currentCourseCodes.contains(newCode)) {
      return 'Student is already taking "${newSubject.name}" this semester.';
    }

    // ---- Credit limit check for replace ----
    final currentCredits = totalRegisteredCredits;
    final newTotal = currentCredits - oldSubject.credits + newSubject.credits;
    if (newTotal > maxCredits) {
      return 'Switching to "${newSubject.name}" would exceed the '
          '$maxCredits-credit limit. '
          'Current total is $currentCredits, '
          'after switch it would be $newTotal.';
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

        // upcomingCourses
        final raw = (data['upcomingCourses'] ?? []) as List<dynamic>;
        final List<String> codes = raw.map((e) => e.toString()).toList();

        codes.remove(oldCode);
        if (!codes.contains(newCode)) {
          codes.add(newCode);
        }

        // upcomingSections map: remove old course mapping
        final sectionsRaw = data['upcomingSections'];
        Map<String, dynamic> sectionsMap = {};
        if (sectionsRaw is Map<String, dynamic>) {
          sectionsMap = Map<String, dynamic>.from(sectionsRaw);
        }
        sectionsMap.remove(oldCode);

        tx.update(ref, {
          'upcomingCourses': codes,
          'upcomingSections': sectionsMap,
        });
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
  // ==================== TIME CONFLICT LOGIC ===================
  // ============================================================

  /// Returns an error string if the new section conflicts with any already
  /// registered section (same day + overlapping time), otherwise null.
  String? _checkTimeConflict(Subject newSubject, CourseSection newSec) {
    final newDays = newSec.days.map((d) => d.trim()).where((d) => d.isNotEmpty);

    final newStart = _parseTimeToMinutes(newSec.startTime);
    final newEnd = _parseTimeToMinutes(newSec.endTime);

    if (newStart == null || newEnd == null) {
      // If time cannot be parsed, don't enforce conflict logic
      return null;
    }

    for (final existing in registeredSubjects) {
      final existingSec = existing.selectedSection;
      if (existingSec == null) continue;

      final existingStart = _parseTimeToMinutes(existingSec.startTime);
      final existingEnd = _parseTimeToMinutes(existingSec.endTime);
      if (existingStart == null || existingEnd == null) continue;

      // check day intersection
      final existingDays = existingSec.days
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty);
      final commonDays = newDays.toSet().intersection(existingDays.toSet());
      if (commonDays.isEmpty) continue;

      final overlap =
          newStart < existingEnd && existingStart < newEnd; // interval overlap
      if (!overlap) continue;

      final dayString = commonDays.join(', ');
      return 'The selected section for "${newSubject.name}" '
          'conflicts with "${existing.name}" on $dayString at '
          '${newSec.startTime}-${newSec.endTime}.';
    }

    return null;
  }

  /// Parses "HH:mm" into minutes from midnight. Returns null if invalid.
  int? _parseTimeToMinutes(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
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
