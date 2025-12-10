import 'package:cloud_firestore/cloud_firestore.dart';

class GradeItem {
  final String id;
  final String label;
  final double score;
  final double maxScore;
  final int order;

  /// NEW: confirmation fields
  final bool confirmed;
  final String? confirmedBy;
  final Timestamp? confirmedAt;

  GradeItem({
    required this.id,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.order,
    required this.confirmed,
    this.confirmedBy,
    this.confirmedAt,
  });

  /// Build from Firestore document
  factory GradeItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final dynamic rawScore = data['score'];
    final dynamic rawMaxScore = data['maxScore'];

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return GradeItem(
      id: doc.id,
      label: (data['typeLabel'] ?? data['label'] ?? '').toString(),
      score: parseDouble(rawScore),
      maxScore: parseDouble(rawMaxScore),
      order: (data['order'] is int)
          ? data['order'] as int
          : int.tryParse(data['order']?.toString() ?? '') ?? 0,
      confirmed: (data['confirmed'] ?? false) == true,
      confirmedBy: data['confirmedBy']?.toString(),
      confirmedAt: data['confirmedAt'] is Timestamp
          ? data['confirmedAt'] as Timestamp
          : null,
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

  double get totalScore => items.fold(0.0, (sum, item) => sum + item.score);

  double get totalMax => items.fold(0.0, (sum, item) => sum + item.maxScore);

  double get percentage {
    if (totalMax == 0) return 0.0;
    return (totalScore / totalMax) * 100;
  }
}
