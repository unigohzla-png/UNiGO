import 'package:flutter/material.dart';

class CourseSection {
  final String id;
  final String doctorName;
  final List<String> days;
  final String startTime;
  final String endTime;

  CourseSection({
    required this.id,
    required this.doctorName,
    required this.days,
    required this.startTime,
    required this.endTime,
  });

  factory CourseSection.fromMap(Map<String, dynamic> map) {
    return CourseSection(
      id: map['id']?.toString() ?? '',
      doctorName: map['doctorName']?.toString() ?? '',
      days: (map['days'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
    );
  }
}