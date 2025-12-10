import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/civil_person.dart';

class CivilRegistryService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'civilRegistry';

  /// Get person by nationalId, independent of document ID.
  static Future<CivilPerson?> getByNationalId(String nationalId) async {
    final trimmed = nationalId.trim();

    // First try field match
    final byField = await _db
        .collection(_collection)
        .where('nationalId', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (byField.docs.isNotEmpty) {
      return CivilPerson.fromDoc(byField.docs.first);
    }

    // Fallback: try doc id (if you decide to set docId = nationalId)
    final byId =
        await _db.collection(_collection).doc(trimmed).get();

    if (byId.exists) {
      return CivilPerson.fromDoc(byId);
    }

    return null;
  }

  /// Mark that this civil record is now linked to a UniGO uid.
  static Future<void> linkUid({
    required String docId,
    required String uid,
  }) async {
    await _db.collection(_collection).doc(docId).update({
      'linkedUid': uid,
      'linkedAt': FieldValue.serverTimestamp(),
    });
  }
}
