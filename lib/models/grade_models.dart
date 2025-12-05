import 'package:cloud_firestore/cloud_firestore.dart';

class GradeItem {
  final String id;
  final String label;
  final double score;
  final double maxScore;
  final int order;

  GradeItem({
    required this.id,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.order,
  });

  factory GradeItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GradeItem(
      id: doc.id,
      label: (data['label'] ?? '') as String,
      score: (data['score'] ?? 0).toDouble(),
      maxScore: (data['maxScore'] ?? 0).toDouble(),
      order: (data['order'] ?? 0) as int,
    );
  }
}

class CourseGrades {
  final String courseCode;
  final String courseName;
  final List<GradeItem> items;

  CourseGrades({
    required this.courseCode,
    required this.courseName,
    required this.items,
  });

  double get totalScore =>
      items.fold(0.0, (sum, item) => sum + item.score);

  double get totalMax =>
      items.fold(0.0, (sum, item) => sum + item.maxScore);
}
