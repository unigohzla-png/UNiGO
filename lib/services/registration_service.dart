import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationService {
  RegistrationService._();
  static final RegistrationService instance = RegistrationService._();
  /// Codes of courses the student is already taking this semester
  /// (used to block re-registering the same course in upcomingCourses).
  Set<String> currentCourseCodes = <String>{};

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // -------- GLOBAL CONFIG (config/registration) --------

  /// Is registration globally enabled?
  bool globalRegisterOpen = true;

  /// Global registration window (if set).
  DateTime? globalStartAt;
  DateTime? globalEndAt;

  // -------- USER WINDOW (registrationWindows/{uid}) --------

  /// Effective personal slot (assigned or reserved).
  DateTime? assignedStartAt;
  DateTime? assignedEndAt;

  /// Reserved slot (we’ll use this later when Reserve Time writes its own range).
  DateTime? reservedStartAt;
  DateTime? reservedEndAt;

  // ======================================================
  // =============== FIRESTORE LOADERS ====================
  // ======================================================

  /// Read `config/registration`:
  ///   globalOpen (bool)
  ///   globalStartAt (timestamp)
  ///   globalEndAt (timestamp)
  Future<void> loadGlobalConfig() async {
    try {
      final snap = await _db.collection('config').doc('registration').get();
      if (!snap.exists) {
        // If there is no config, safest is to close registration.
        globalRegisterOpen = false;
        globalStartAt = null;
        globalEndAt = null;
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final open = data['globalOpen'];
      globalRegisterOpen = open == true;

      final startTs = data['globalStartAt'];
      final endTs = data['globalEndAt'];

      globalStartAt = startTs is Timestamp ? startTs.toDate() : null;
      globalEndAt = endTs is Timestamp ? endTs.toDate() : null;
    } catch (_) {
      // On error, keep previous values (or defaults).
      globalRegisterOpen = false;
      globalStartAt = null;
      globalEndAt = null;
    }
  }

  /// Read `registrationWindows/{uid}` for the current user.
  ///
  /// For now we treat `startAt`/`endAt` as the active personal slot
  /// (whether initially assigned or later reserved).
  Future<void> loadUserWindow() async {
    final user = _auth.currentUser;
    if (user == null) {
      assignedStartAt = null;
      assignedEndAt = null;
      reservedStartAt = null;
      reservedEndAt = null;
      return;
    }

    try {
      final snap = await _db
          .collection('registrationWindows')
          .doc(user.uid)
          .get();
      if (!snap.exists) {
        assignedStartAt = null;
        assignedEndAt = null;
        reservedStartAt = null;
        reservedEndAt = null;
        return;
      }

      final data = snap.data() as Map<String, dynamic>;
      final startTs = data['startAt'];
      final endTs = data['endAt'];

      assignedStartAt = startTs is Timestamp ? startTs.toDate() : null;
      assignedEndAt = endTs is Timestamp ? endTs.toDate() : null;

      // We’ll later optionally store explicit reservedStartAt/reservedEndAt
      // as separate fields if we want to distinguish them.
      reservedStartAt = null;
      reservedEndAt = null;
    } catch (_) {
      assignedStartAt = null;
      assignedEndAt = null;
      reservedStartAt = null;
      reservedEndAt = null;
    }
  }

  /// Load global config + user window.
  Future<void> reloadFromFirestore() async {
    await Future.wait([loadGlobalConfig(), loadUserWindow()]);
  }

  // ======================================================
  // =============== ACCESS LOGIC =========================
  // ======================================================

  bool get isInsideGlobalWindow {
    if (!globalRegisterOpen) return false;
    final now = DateTime.now();
    if (globalStartAt != null && now.isBefore(globalStartAt!)) return false;
    if (globalEndAt != null && now.isAfter(globalEndAt!)) return false;
    return true;
  }

  bool _isNowWithinRange(DateTime? start, DateTime? end, DateTime now) {
    if (start == null || end == null) return false;
    return (now.isAfter(start) || now.isAtSameMomentAs(start)) &&
        now.isBefore(end);
  }

  /// Final rule:
  ///   - must be inside global window
  ///   - AND (
  ///       in personal slot (assigned/reserved)
  ///       OR after 20:00 (everyone)
  ///     )
  ///
  /// NOTE: [userId] is unused for now; we rely on FirebaseAuth for current user.
 bool canUserRegisterNow(String _) {
  final now = DateTime.now();

  final bool hasAssignedWindow =
      assignedStartAt != null &&
      assignedEndAt != null &&
      now.isAfter(assignedStartAt!) &&
      now.isBefore(assignedEndAt!);

  debugPrint('--- canUserRegisterNow ---');
  debugPrint('now: $now');
  debugPrint('assignedStartAt: $assignedStartAt');
  debugPrint('assignedEndAt  : $assignedEndAt');
  debugPrint('hasAssignedWindow: $hasAssignedWindow');
  debugPrint('now.hour >= 20: ${now.hour >= 20}');

  // ✅ If student has a valid personal window → always allow
  if (hasAssignedWindow) {
    debugPrint('RESULT: true (personal window)');
    return true;
  }

  // ✅ After 20:00 → allow global registration
  if (now.hour >= 20) {
    debugPrint('RESULT: true (after 20:00 fallback)');
    return true;
  }

  // ❌ Otherwise → closed
  debugPrint('RESULT: false (no window)');
  return false;
}

  // ======================================================
  // =============== HELPERS / FUTURE USE =================
  // ======================================================
   /// Reserve a 15-minute free slot for the *current* user.
  ///
  /// - [date]: selected day (only Y/M/D used)
  /// - [slot]: string like "13:00 - 13:15" from the dropdown
  /// Writes to: registrationWindows/{uid}
  Future<void> reserveFreeSlotForCurrentUser(
    DateTime date,
    String slot,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // slot format expected: "HH:MM - HH:MM"
    DateTime startAt;
    try {
      final parts = slot.split('-');
      if (parts.isEmpty) {
        throw Exception('Invalid slot format');
      }
      final startStr = parts[0].trim(); // "13:00"
      final hm = startStr.split(':');
      final hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);

      startAt = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
    } catch (_) {
      throw Exception('Invalid time slot: "$slot"');
    }

    final endAt = startAt.add(const Duration(minutes: 15));

    await _db.collection('registrationWindows').doc(user.uid).set(
      {
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'reservedBy': 'user',
        'status': 'reserved',
      },
      SetOptions(merge: true),
    );

    // Update in-memory state so canUserRegisterNow() sees it immediately
    assignedStartAt = startAt;
    assignedEndAt = endAt;
    reservedStartAt = null;
    reservedEndAt = null;
  }

    /// Helper to generate 15-min slots between [startHour] and [endHour).
  /// Returns a non-null List<TimeOfDay>.
  List<TimeOfDay> generateFreeSlotStarts({
    int startHour = 13,
    int endHour = 18,
  }) {
    final slots = <TimeOfDay>[];

    for (var h = startHour; h < endHour; h++) {
      for (var m = 0; m < 60; m += 15) {
        slots.add(TimeOfDay(hour: h, minute: m));
      }
    }

    return slots;
  }
}
