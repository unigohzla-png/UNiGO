import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/personal_info_model.dart';

/// Handles loading and saving the student's personal info
/// from/to the Firestore `users/{uid}` document.
class PersonalInfoController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Load the currently logged-in student's personal info.
  ///
  /// Mapping:
  ///  - address      -> users.houseaddress
  ///  - email        -> users.personalEmail
  ///  - phone        -> users.phone
  ///  - altPhone     -> users.altPhone
  ///  - identifiers* -> users.identifiers (Map<label, value>)
  Future<PersonalInfo?> loadInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? <String, dynamic>{};

    // Basic contact fields
    final address = (data['houseaddress'] ?? '').toString();
    final personalEmail = (data['personalEmail'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final altPhone = (data['altPhone'] ?? '').toString();

    // Identifiers map: label -> value (for example "Identifier 1" -> "0799...")
    String id1Label = '';
    String id1Value = '';
    String id2Label = '';
    String id2Value = '';

    final identifiers = data['identifiers'];
    if (identifiers is Map<String, dynamic>) {
      final entries = identifiers.entries.toList();
      if (entries.isNotEmpty) {
        id1Label = entries[0].key;
        id1Value = entries[0].value.toString();
      }
      if (entries.length > 1) {
        id2Label = entries[1].key;
        id2Value = entries[1].value.toString();
      }
    } else if (identifiers is List) {
      // Backwards-compat: if you ever stored identifiers as a list,
      // we just show the first two as generic identifiers.
      if (identifiers.isNotEmpty) {
        id1Label = 'Identifier 1';
        id1Value = identifiers[0].toString();
      }
      if (identifiers.length > 1) {
        id2Label = 'Identifier 2';
        id2Value = identifiers[1].toString();
      }
    }

    return PersonalInfo(
      address: address,
      email: personalEmail,
      phone: phone,
      altPhone: altPhone,
      identifier1: id1Label,
      identifier1Phone: id1Value,
      identifier2: id2Label,
      identifier2Phone: id2Value,
    );
  }

  /// Persist the given personal info back to Firestore.
  ///
  /// Only a limited, safe subset of the user document is updated.
  Future<void> updateInfo(PersonalInfo info) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No logged-in user.');
    }

    // Build identifiers map (label -> value) from the two rows.
    final identifiers = <String, String>{};
    if (info.identifier1.trim().isNotEmpty &&
        info.identifier1Phone.trim().isNotEmpty) {
      identifiers[info.identifier1.trim()] = info.identifier1Phone.trim();
    }
    if (info.identifier2.trim().isNotEmpty &&
        info.identifier2Phone.trim().isNotEmpty) {
      identifiers[info.identifier2.trim()] = info.identifier2Phone.trim();
    }

    await _db.collection('users').doc(uid).set({
      'houseaddress': info.address.trim(),
      // Keep `location` roughly in sync with the address for now
      'location': info.address.trim(),
      'personalEmail': info.email.trim(),
      'phone': info.phone.trim(),
      'altPhone': info.altPhone.trim(),
      'identifiers': identifiers,
    }, SetOptions(merge: true));
  }
}
