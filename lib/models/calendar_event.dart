// lib/models/calendar_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String type; // "Event", "Deadline", "Reminder"
  final String scope; // "personal", "course", "global"
  final String? courseCode;
  final String? ownerId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.scope,
    this.courseCode,
    this.ownerId,
  });

  factory CalendarEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    final ts = data['date'];
    DateTime date = DateTime.now();
    if (ts is Timestamp) {
      date = ts.toDate();
    }

    return CalendarEvent(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      date: date,
      type: (data['type'] ?? 'Event').toString(),
      scope: (data['scope'] ?? 'personal').toString(),
      courseCode: data['courseCode']?.toString(),
      ownerId: data['ownerId']?.toString(),
    );
  }
}
