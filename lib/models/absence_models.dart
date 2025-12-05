import 'package:cloud_firestore/cloud_firestore.dart';

class AbsenceSession {
  final String id;
  final DateTime date;
  final String day;
  final String startTime;
  final String endTime;

  AbsenceSession({
    required this.id,
    required this.date,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory AbsenceSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['date'] as Timestamp?;
    return AbsenceSession(
      id: doc.id,
      date: ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      day: (data['day'] ?? '') as String,
      startTime: (data['startTime'] ?? '') as String,
      endTime: (data['endTime'] ?? '') as String,
    );
  }
}

class AbsenceCourse {
  final String code;
  final String name;
  final List<String> days;
  final int maxAbsences;
  final List<AbsenceSession> sessions;

  AbsenceCourse({
    required this.code,
    required this.name,
    required this.days,
    required this.maxAbsences,
    required this.sessions,
  });

  int get currentAbsences => sessions.length;

  double get ratio =>
      maxAbsences == 0 ? 0 : currentAbsences / maxAbsences;
}
