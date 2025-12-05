// lib/models/schedule_course.dart
class ScheduleCourse {
  final String code;
  final String name;
  final int credits;
  final String sectionId;
  final String daysText;
  final String timeText;
  final String location;
  final String doctorName;
  final String grade;

  ScheduleCourse({
    required this.code,
    required this.name,
    required this.credits,
    required this.sectionId,
    required this.daysText,
    required this.timeText,
    required this.location,
    required this.doctorName,
    required this.grade,
  });
}
