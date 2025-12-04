import 'package:cloud_firestore/cloud_firestore.dart';

class TermService {
  TermService._();
  static final instance = TermService._();

  final _db = FirebaseFirestore.instance;

  /// Promote upcomingCourses -> enrolledCourses for a single user.
  ///
  /// - previousCourses += old enrolledCourses (merged, no duplicates)
  /// - enrolledCourses = upcomingCourses
  /// - upcomingCourses = []
  Future<void> promoteUpcomingToCurrentForUser(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) {
        throw Exception('User $uid does not exist');
      }

      final data = snap.data() as Map<String, dynamic>;

      final List<dynamic> enrolledRaw =
          (data['enrolledCourses'] ?? []) as List<dynamic>;
      final List<dynamic> upcomingRaw =
          (data['upcomingCourses'] ?? []) as List<dynamic>;
      final List<dynamic> previousRaw =
          (data['previousCourses'] ?? []) as List<dynamic>;

      final current = enrolledRaw.map((e) => e.toString()).toList();
      final upcoming = upcomingRaw.map((e) => e.toString()).toList();
      final previous = previousRaw.map((e) => e.toString()).toList();

      // Merge old current into previous (unique)
      final newPrevious = <String>{...previous, ...current}.toList();

      tx.update(userRef, {
        'previousCourses': newPrevious,
        'enrolledCourses': upcoming,
        'upcomingCourses': [],
      });
    });
  }
}
