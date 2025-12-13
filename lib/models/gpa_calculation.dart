// lib/models/gpa_calculation.dart

import 'course_grade.dart';

/// Model representing a full GPA calculation result.
class GPACalculation {
  /// The GPA value for the current calculation.
  final double currentGPA;

  /// Optionally a "new GPA" (kept for compatibility / future use).
  final double newGPA;

  /// Courses included in this calculation.
  final List<CourseGrade> courses;

  /// Total credit hours for all included courses.
  final double totalCreditHours;

  /// Total grade points (sum of gradePoint * creditHours).
  final double totalGradePoints;

  const GPACalculation({
    required this.currentGPA,
    required this.newGPA,
    required this.courses,
    required this.totalCreditHours,
    required this.totalGradePoints,
  });

  /// Empty calculation (used as initial/default state).
  factory GPACalculation.empty() {
    return const GPACalculation(
      currentGPA: 0.0,
      newGPA: 0.0,
      courses: [],
      totalCreditHours: 0.0,
      totalGradePoints: 0.0,
    );
  }
}
