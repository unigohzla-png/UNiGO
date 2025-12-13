// lib/models/course_grade.dart

/// Simple model representing a single course in GPA calculation.
class CourseGrade {
  /// Letter grade, e.g. "A", "B+", "C-"
  final String grade;

  /// Credit hours for the course (e.g. 3.0)
  final double creditHours;

  /// Grade points for this letter (e.g. A = 4.0, B+ = 3.3)
  final double gradePoint;

  CourseGrade({
    required this.grade,
    required this.creditHours,
    required this.gradePoint,
  });

  /// Total points = gradePoint * creditHours
  double get totalPoints => gradePoint * creditHours;

  /// Helper factory used by the controller when taking raw text input.
  factory CourseGrade.fromInput(
    String grade,
    double creditHours,
    double gradePoint,
  ) {
    return CourseGrade(
      grade: grade,
      creditHours: creditHours,
      gradePoint: gradePoint,
    );
  }
}
