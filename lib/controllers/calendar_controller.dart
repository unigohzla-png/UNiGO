import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/reminder_notifications_service.dart';

class CalendarController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final DateTime today = DateTime.now();
  late DateTime currentMonth;
  late int selectedDay;

  String selectedTab = "Events";
  String selectedFilter = "All";

  /// All events from Firestore AFTER applying per-student visibility rules.
  List<CalendarEvent> events = [];

  /// Course codes the current student is related to.
  Set<String> myCourseCodes = <String>{};

  /// Current user id (student)
  String? _currentUserId;

  /// Current student's faculty
  String _myFacultyId = '';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;

  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  CalendarController() {
    currentMonth = DateTime(today.year, today.month, 1);
    selectedDay = today.day;
    _init(); // load user courses then start listening
  }

  // ================= INITIALIZATION =================

  Future<void> _init() async {
    await _loadUserCourseCodes();
    _listenToEvents();
  }

  /// Load the current student's course codes from `users/{uid}`.
  ///
  /// We now rely mainly on `enrolledCourses` (array of course codes),
  /// but still try a few legacy shapes just in case.
  Future<void> _loadUserCourseCodes() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print('[Calendar] No logged-in user, cannot load course codes.');
      }
      return;
    }

    _currentUserId = user.uid;

    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final data = snap.data() ?? <String, dynamic>{};

      // 👇 NEW: store student's facultyId
      _myFacultyId = (data['facultyId'] ?? '').toString();
      if (kDebugMode) {
        print('[Calendar] myFacultyId = $_myFacultyId');
      }

      final temp = <String>{};

      // 0) NEW: enrolledCourses: ["1901101", "XYZ123", ...]
      final enrolled = data['enrolledCourses'];
      if (enrolled is List) {
        for (final c in enrolled) {
          if (c != null) temp.add(c.toString());
        }
      }

      // 1) Other simple list fields (legacy support)
      for (final key in [
        'currentCourseCodes',
        'courseCodes',
        'registeredCourseCodes',
      ]) {
        final value = data[key];
        if (value is List) {
          for (final c in value) {
            if (c != null) temp.add(c.toString());
          }
        }
      }

      // 2) map fields where keys are course codes (legacy)
      for (final key in ['enrolledCoursesMap', 'currentCourses']) {
        final value = data[key];
        if (value is Map) {
          value.forEach((k, _) {
            if (k != null) temp.add(k.toString());
          });
        }
      }

      // 3) list of maps with a 'code' field (legacy)
      for (final key in ['registeredCourses']) {
        final value = data[key];
        if (value is List) {
          for (final elem in value) {
            if (elem is Map && elem['code'] != null) {
              temp.add(elem['code'].toString());
            }
          }
        }
      }

      myCourseCodes = temp;

      if (kDebugMode) {
        print('[Calendar] myCourseCodes (final) = $myCourseCodes');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[Calendar] Error loading user course codes: $e');
        print(st);
      }
      myCourseCodes = <String>{};
    }
  }

  // ================= FIRESTORE LISTENER =================

  void _listenToEvents() {
    _eventsSub?.cancel(); // safety in case re-called

    _eventsSub = _db
        .collection('calendarEvents')
        .orderBy('date')
        .snapshots()
        .listen(
          (snapshot) {
            if (kDebugMode) {
              print(
                '[Calendar] snapshot received, docs = ${snapshot.docs.length}',
              );
            }

            final all = snapshot.docs
                .map((doc) => CalendarEvent.fromDoc(doc))
                .toList();

            final String? uid = _currentUserId ?? _auth.currentUser?.uid;
            final Set<String> courseCodes = myCourseCodes;
            final String facultyId = _myFacultyId;

            events = all.where((e) {
              final scope = e.scope;

              // 1) Personal → only owner sees, ignore faculty
              if (scope == 'personal') {
                return uid != null && e.ownerId == uid;
              }

              // 2) For non-personal items, respect faculty if both sides have it
              if (e.facultyId != null &&
                  e.facultyId!.isNotEmpty &&
                  facultyId.isNotEmpty &&
                  e.facultyId != facultyId) {
                // Event belongs to another faculty → hide
                return false;
              }

              // 3) Course-scoped items (deadlines / events per course)
              if (scope == 'course') {
                // ❌ If student has NO courses, they should see NO course items.
                if (courseCodes.isEmpty) {
                  return false;
                }

                if (e.courseCode == null || e.courseCode!.isEmpty) {
                  return false;
                }
                return courseCodes.contains(e.courseCode);
              }

              // 4) Global (or legacy records with no scope) → everyone in that faculty sees
              return true;
            }).toList();

            if (kDebugMode) {
              print(
                '[Calendar] visible events after filter = ${events.length}',
              );
            }

            notifyListeners();
          },
          onError: (e) {
            if (kDebugMode) {
              print('[Calendar] error listening to calendarEvents: $e');
            }
          },
        );
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  // ================= DATE HELPERS =================

  int daysInMonth(DateTime m) => DateUtils.getDaysInMonth(m.year, m.month);

  int mondayBasedWeekday(DateTime d) => d.weekday % 7;

  DateTime dateFor(int day) =>
      DateTime(currentMonth.year, currentMonth.month, day);

  /// All events exactly on the given date (used for dots).
  List<CalendarEvent> eventsForDate(DateTime date) {
    return events
        .where(
          (e) =>
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
        )
        .toList();
  }

  Color dotColor(String type) {
    switch (type) {
      case "Event":
        return Colors.greenAccent.shade400;
      case "Deadline":
        return Colors.redAccent.shade200;
      case "Reminder":
        return Colors.amber.shade400;
      default:
        return Colors.grey;
    }
  }

  // ================= STATE CHANGES =================

  void selectDay(int day) {
    selectedDay = day;
    notifyListeners();
  }

  void changeMonth(int delta) {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + delta, 1);
    notifyListeners();
  }

  void toggleTab(String tab) {
    selectedTab = tab;
    notifyListeners();
  }

  void selectFilter(String filter) {
    selectedFilter = filter;

    if (filter == "All") {
      // When switching back to "All", reset focus to TODAY
      selectedDay = today.day;
      currentMonth = DateTime(today.year, today.month, 1);
    }

    notifyListeners();
  }

  void selectDate(DateTime date) {
    currentMonth = DateTime(date.year, date.month, 1);
    selectedDay = date.day;
    notifyListeners();
  }

  // ================= ADD REMINDER =================

  Future<void> addReminder(String title, DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Calendar] addReminder called with no logged-in user');
      return;
    }

    final normalized = DateTime(date.year, date.month, date.day);

    try {
      final ref = await _db.collection('calendarEvents').add({
        'title': title,
        'date': Timestamp.fromDate(normalized),
        'type': 'Reminder',
        'scope': 'personal',
        'ownerId': user.uid,
        'facultyId': _myFacultyId, // keep data consistent
        'createdAt': FieldValue.serverTimestamp(),
      });

      events = [
        ...events,
        CalendarEvent(
          id: ref.id,
          title: title,
          date: normalized,
          type: 'Reminder',
          scope: 'personal',
          ownerId: user.uid,
          courseCode: null,
          facultyId: _myFacultyId.isEmpty ? null : _myFacultyId,
        ),
      ];
      notifyListeners();

      debugPrint('[Calendar] reminder created with id ${ref.id}');
      // Schedule notifications: 1 day before @ 7AM + same day @ 7AM
      await ReminderNotificationsService.scheduleForReminder(
        reminderId: ref.id,
        title: title,
        reminderDate: normalized,
      );
    } catch (e, st) {
      debugPrint('[Calendar] addReminder error: $e');
      debugPrint('$st');
    }
  }

  // ================= DELETE REMINDER =================

  Future<void> deleteReminder(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Calendar] deleteReminder called with no logged-in user');
      return;
    }

    if (event.type != 'Reminder') {
      debugPrint('[Calendar] deleteReminder ignored: not a Reminder type');
      return;
    }
    if (event.scope != 'personal') {
      debugPrint('[Calendar] deleteReminder ignored: scope != personal');
      return;
    }
    if (event.ownerId != user.uid) {
      debugPrint('[Calendar] deleteReminder ignored: not owner');
      return;
    }

    try {
      await _db.collection('calendarEvents').doc(event.id).delete();
      events = events.where((e) => e.id != event.id).toList();
      notifyListeners();
      debugPrint('[Calendar] reminder ${event.id} deleted');
      // Cancel scheduled notifications for this reminder
      await ReminderNotificationsService.cancelForReminder(event.id);
    } catch (e, st) {
      debugPrint('[Calendar] deleteReminder error: $e');
      debugPrint('$st');
    }
  }
}

// ================= MODEL =================

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String type; // Event / Deadline / Reminder
  final String scope; // personal / course / global (or legacy)
  final String ownerId;
  final String? courseCode;
  final String? facultyId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.scope,
    required this.ownerId,
    this.courseCode,
    this.facultyId,
  });

  factory CalendarEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDate = data['date'];

    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    final rawFaculty = (data['facultyId'] ?? '').toString();

    return CalendarEvent(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      date: date,
      type: (data['type'] ?? 'Event').toString(),
      scope: (data['scope'] ?? 'global').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      courseCode: data['courseCode']?.toString(),
      facultyId: rawFaculty.isEmpty ? null : rawFaculty,
    );
  }
}
