import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CalendarController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final DateTime today = DateTime.now();
  late DateTime currentMonth;
  late int selectedDay;

  String selectedTab = "Events";
  String selectedFilter = "All";

  /// All events from Firestore (we will filter them in the UI).
  List<CalendarEvent> events = [];

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
    _listenToEvents();
  }

  // ================= FIRESTORE LISTENER =================

  void _listenToEvents() {
    _eventsSub?.cancel(); // safety

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

            events = snapshot.docs
                .map((doc) => CalendarEvent.fromDoc(doc))
                .toList();
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
      // 🔹 When switching back to "All", reset focus to TODAY
      selectedDay = today.day;
      currentMonth = DateTime(today.year, today.month, 1);
    }

    notifyListeners();
  }

  void selectDate(DateTime date) {
    // Move the calendar to that month
    currentMonth = DateTime(date.year, date.month, 1);
    // Highlight that day
    selectedDay = date.day;
    notifyListeners();
  }

  // ================= ADD REMINDER =================

  /// Add a *personal* reminder for the logged-in student.
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      // optimistic local update
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
        ),
      ];
      notifyListeners();

      debugPrint('[Calendar] reminder created with id ${ref.id}');
    } catch (e, st) {
      debugPrint('[Calendar] addReminder error: $e');
      debugPrint('$st');
    }
  }

  // ================= DELETE REMINDER =================

  /// Delete a *personal reminder* that belongs to the current user.
  ///
  /// - Only works if:
  ///   - event.type == "Reminder"
  ///   - event.scope == "personal"
  ///   - event.ownerId == currentUser.uid
  /// - Does **not** touch Events / Deadlines / course/global items.
  Future<void> deleteReminder(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Calendar] deleteReminder called with no logged-in user');
      return;
    }

    // Only allow deleting personal reminders belonging to this user
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
      // Optimistic local removal
      events = events.where((e) => e.id != event.id).toList();
      notifyListeners();
      debugPrint('[Calendar] reminder ${event.id} deleted');
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
  final String scope; // personal / course / global (optional usage)
  final String ownerId;
  final String? courseCode;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.scope,
    required this.ownerId,
    this.courseCode,
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

    return CalendarEvent(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      date: date,
      type: (data['type'] ?? 'Event').toString(),
      scope: (data['scope'] ?? 'global').toString(),
      ownerId: (data['ownerId'] ?? '').toString(),
      courseCode: data['courseCode']?.toString(),
    );
  }
}
