import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProgress {
  final int totalCredits;
  final int completedCredits;
  final int inProgressCredits;

  const StudentProgress({
    required this.totalCredits,
    required this.completedCredits,
    required this.inProgressCredits,
  });

  double get completionPercent =>
      totalCredits == 0 ? 0.0 : completedCredits / totalCredits;
}

class StudentProgressService {
  StudentProgressService._();
  static final instance = StudentProgressService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<StudentProgress?> loadCurrentStudentProgress() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userSnap = await _db.collection('users').doc(uid).get();
    final userData = userSnap.data();
    if (userData == null) return null;

    // Same idea as AcademicPlanController:
    final completedCodes = <String>{};
    final enrolledCodes = <String>{};

    final enrolledRaw = (userData['enrolledCourses'] as List?) ?? [];
    enrolledCodes.addAll(enrolledRaw.map((e) => e.toString()));

    final prev = userData['previousCourses'];
    if (prev is Map) {
      prev.forEach((key, value) {
        completedCodes.add(key.toString());
      });
    }

    final coursesSnap = await _db.collection('courses').get();

    int totalCredits = 0;
    int completedCredits = 0;
    int inProgressCredits = 0;

    for (final doc in coursesSnap.docs) {
      final data = doc.data();
      final code = doc.id;
      final altCode = data['code']?.toString();

      final creditsRaw = data['credits'];
      int credits;
      if (creditsRaw is int) {
        credits = creditsRaw;
      } else if (creditsRaw is num) {
        credits = creditsRaw.toInt();
      } else {
        credits = int.tryParse(creditsRaw?.toString() ?? '') ?? 0;
      }

      totalCredits += credits;

      final bool isCompleted =
          completedCodes.contains(code) ||
          (altCode != null && completedCodes.contains(altCode));
      final bool isEnrolled =
          enrolledCodes.contains(code) ||
          (altCode != null && enrolledCodes.contains(altCode));

      if (isCompleted) {
        completedCredits += credits;
      } else if (isEnrolled) {
        inProgressCredits += credits;
      }
    }

    return StudentProgress(
      totalCredits: totalCredits,
      completedCredits: completedCredits,
      inProgressCredits: inProgressCredits,
    );
  }
}
