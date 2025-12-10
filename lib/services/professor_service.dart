import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/professor.dart';

class ProfessorService {
  static final _db = FirebaseFirestore.instance;

  /// Get professors who can advise for a faculty (and optionally a major).
  static Future<List<Professor>> getAdvisors({
    required String facultyId,
    String? majorId,
  }) async {
    // professors are now in: faculties/{facultyId}/professors
    Query<Map<String, dynamic>> q = _db
        .collection('faculties')
        .doc(facultyId)
        .collection('professors')
        .where('canAdvise', isEqualTo: true);

    // optional major filter
    if (majorId != null && majorId.isNotEmpty) {
      q = q.where('majorIds', arrayContains: majorId);
    }

    final snap = await q.get();
    return snap.docs.map(Professor.fromDoc).toList();
  }
}
