import 'package:flutter/material.dart';
import 'course_section.dart';

class Subject {
  final String name;
  final int credits;
  final Color color;
  final String? code;

  /// All offered sections for this course (from Firestore `courses.sections`).
  final List<CourseSection> sections;

  /// The section chosen by the student (for register/selected lists).
  final CourseSection? selectedSection;

  Subject({
    required this.name,
    required this.credits,
    required this.color,
    this.code,
    this.sections = const [],
    this.selectedSection,
  });

  Subject copyWith({
    String? name,
    int? credits,
    Color? color,
    String? code,
    List<CourseSection>? sections,
    CourseSection? selectedSection,
    bool clearSelectedSection = false,
  }) {
    return Subject(
      name: name ?? this.name,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      code: code ?? this.code,
      sections: sections ?? this.sections,
      selectedSection: clearSelectedSection
          ? null
          : (selectedSection ?? this.selectedSection),
    );
  }
}
