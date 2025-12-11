import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/civil_person.dart';
import 'civil_registry_service.dart';
import 'admin_auth_helper.dart';

class ManagedUserSummary {
  final String uid;
  final String name;
  final String email;
  final String id;
  final String role;

  ManagedUserSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.id,
    required this.role,
  });
}

/// Result returned to the UI after creating a user from the civil registry.
class CreatedUserFromCivilResult {
  final String uid;
  final String universityId;
  final String email;
  final String password;

  CreatedUserFromCivilResult({
    required this.uid,
    required this.universityId,
    required this.email,
    required this.password,
  });
}

class SuperAdminUserManagementService {
  SuperAdminUserManagementService._();

  static final SuperAdminUserManagementService instance =
      SuperAdminUserManagementService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // LOAD / ROLES
  // ---------------------------------------------------------------------------

  /// Load all users with their roles.
  /// Load all users with their roles.
  /// If [facultyId] is provided, only users in that faculty are returned.
  Future<List<ManagedUserSummary>> loadUsersWithRoles({
    String? facultyId,
  }) async {
    // Base users query
    Query<Map<String, dynamic>> usersQuery = _db.collection('users');

    if (facultyId != null && facultyId.trim().isNotEmpty) {
      usersQuery = usersQuery.where('facultyId', isEqualTo: facultyId.trim());
    }

    final usersSnap = await usersQuery.get();
    final rolesSnap = await _db.collection('roles').get();

    final roleMap = <String, String>{};
    for (final doc in rolesSnap.docs) {
      final data = doc.data();
      final r = (data['role'] ?? 'student').toString();
      roleMap[doc.id] = r;
    }

    final result = <ManagedUserSummary>[];

    for (final doc in usersSnap.docs) {
      final data = doc.data();
      final uid = doc.id;
      final name = (data['name'] ?? data['fullName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final id = (data['id'] ?? '').toString().trim();
      final role = roleMap[uid] ?? 'student';

      result.add(
        ManagedUserSummary(
          uid: uid,
          name: name,
          email: email,
          id: id,
          role: role,
        ),
      );
    }

    // Sort alphabetically by name for nicer UX
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return result;
  }

  /// Change the role of an existing user.
  Future<void> setUserRole({
    required String uid,
    required String role, // 'student' | 'admin' | 'superAdmin'
  }) async {
    await _db.collection('roles').doc(uid).set({
      'role': role,
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // OLD "FIRESTORE ONLY" CREATION (kept for backward compatibility)
  // ---------------------------------------------------------------------------

  /// Create a new user document + role in Firestore only (no civil registry).
  /// Not used by the new civil-registry flow, but kept for compatibility.
  Future<String> createUserFirestoreOnly({
    required String fullName,
    required String email,
    required String universityId,
    required String major,
    required String department,
    required String role, // 'student' | 'admin' | 'superAdmin'
  }) async {
    final password = _generatePassword(fullName);

    final docRef = _db.collection('users').doc();
    final uid = docRef.id;

    await docRef.set({
      'name': fullName,
      'email': email,
      'id': universityId,
      'major': major,
      'faculty': department,
      'gpa': 0.0,
      'location': '',
      'houseaddress': '',
      'identifiers': {},
      'paynum': '',
      'university': '',
      'advisor': '',
      'dob': null,
      'enrolledCourses': [],
      'upcomingCourses': [],
      'previousCourses': {},
      'withdrawnCourses': [],
      'upcomingSections': {},
      'courseGrades': {},
      'year': '',
      'createdAt': FieldValue.serverTimestamp(),
      'markForAuthCreation': true,
      'initialPassword': password,
    });

    await _db.collection('roles').doc(uid).set({'role': role});

    return password;
  }

  // ---------------------------------------------------------------------------
  // NEW: CREATE FROM CIVIL REGISTRY
  // ---------------------------------------------------------------------------

  /// Create a full UniGO user from a civil registry record.
  ///
  /// - Reads civilRegistry by nationalId
  /// - Generates universityId, university email, password
  /// - Creates users/{uid} + roles/{uid}
  /// - Links civilRegistry doc with linkedUid + linkedAt
  /// - Increments advisor's adviseesCount in faculties/{facultyId}/professors
  Future<CreatedUserFromCivilResult> createUserFromCivilRegistry({
    required String nationalId,
    required String role, // 'student' | 'admin' | 'superAdmin'
    required String createdByUid,
    required String facultyId,
    required String facultyName,
    required String majorId,
    required String majorName,
    required String advisorId,
    required String advisorName,
  }) async {
    // 1) Load civil registry person
    final CivilPerson? person = await CivilRegistryService.getByNationalId(
      nationalId,
    );

    if (person == null) {
      throw Exception('Civil registry record not found for this national ID.');
    }

    if (person.linkedUid != null && person.linkedUid!.isNotEmpty) {
      throw Exception(
        'This civil record is already linked to a UniGO account.',
      );
    }

    // 2) Generate IDs + credentials
    final String universityId = _generateUniversityId();
    final String password = _generatePassword(person.fullName);
    final String email = _generateUniversityEmail(
      person.fullName,
      universityId,
    );

    // 3) Create Firebase Auth user via secondary app
    //    (so we get the real uid and don't log out the super admin)
    final String uid = await AdminAuthHelper.createUser(
      email: email,
      password: password,
    );

    // 4) Prepare Firestore refs using that uid
    final usersRef = _db.collection('users').doc(uid);
    final rolesRef = _db.collection('roles').doc(uid);

    // Find the civilRegistry document for this nationalId
    // NOTE: change 'nationalId' below if your field name is different
    final civilSnap = await _db
        .collection('civilRegistry')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();

    if (civilSnap.docs.isEmpty) {
      throw Exception(
        'Civil registry document not found for this national ID.',
      );
    }

    final civilRef = civilSnap.docs.first.reference;

    // advisor doc inside faculty
    final advisorRef = _db
        .collection('faculties')
        .doc(facultyId)
        .collection('professors')
        .doc(advisorId);

    final batch = _db.batch();

    // 5) users/{uid}
    batch.set(usersRef, {
      'name': person.fullName,
      'email': email,
      'id': universityId,
      'nationalId': person.nationalId,
      'dob': person.dob, // keep as stored in registry (string)
      'location': person.location ?? person.placeOfBirth ?? '',
      'houseaddress': person.houseAddress ?? '',
      'paynum': person.paynum ?? '',
      'identifiers': person.identifiers,
      'phone': person.primaryPhone ?? '',
      'university': 'JU',
      'facultyId': facultyId,
      'faculty': facultyName,
      'majorId': majorId,
      'major': majorName,
      'advisorId': advisorId,
      'advisor': advisorName,
      'gpa': 0.0,
      'year': '',
      'enrolledCourses': [],
      'upcomingCourses': [],
      'previousCourses': {},
      'withdrawnCourses': [],
      'upcomingSections': {},
      'courseGrades': {},
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdByUid,
      'initialPassword': password,
    });

    // 6) roles/{uid}
    batch.set(rolesRef, {'role': role}, SetOptions(merge: true));

    // 7) Link civilRegistry record to this uid
    batch.update(civilRef, {
      'linkedUid': uid,
      'linkedAt': FieldValue.serverTimestamp(),
      'linkedBy': createdByUid,
    });

    // 8) Increment advisor's adviseesCount (create field if missing)
    batch.set(advisorRef, {
      'adviseesCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 9) Commit batch
    await batch.commit();

    return CreatedUserFromCivilResult(
      uid: uid,
      universityId: universityId,
      email: email,
      password: password,
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE USER DATA
  // ---------------------------------------------------------------------------

  /// Delete a student's Firestore data (users doc, roles doc, personal calendar).
  ///
  /// NOTE: This does NOT delete the Firebase Auth user; that must be done
  /// with the Admin SDK (Cloud Functions / console).
  Future<void> deleteUserDataFirestore(String uid) async {
    // Delete roles/{uid}
    await _db.collection('roles').doc(uid).delete();

    // Delete personal calendar events owned by this user
    final eventsSnap = await _db
        .collection('calendarEvents')
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final doc in eventsSnap.docs) {
      await doc.reference.delete();
    }

    await _db.collection('users').doc(uid).delete();

    // Mark for Auth deletion (to be handled by backend or manually)
    await _db.collection('deletedUsers').doc(uid).set({
      'uid': uid,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hard delete a UniGO user from Firestore.
  ///
  /// - Deletes their users/{uid} document
  /// - Deletes their roles/{uid} document
  /// - Deletes their registrationWindows/{uid} document (if exists)
  ///
  /// NOTE:
  /// - This does NOT delete the Firebase Auth user account.
  /// - This does NOT clean grades / enrollments / calendar events, etc.
  ///   Those should be handled separately if needed.
  Future<void> hardDeleteUser({required String uid}) async {
    final batch = _db.batch();

    final userRef = _db.collection('users').doc(uid);
    final roleRef = _db.collection('roles').doc(uid);
    final regWindowRef = _db.collection('registrationWindows').doc(uid);

    batch.delete(userRef);
    batch.delete(roleRef);
    batch.delete(regWindowRef);

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _generatePassword(String fullName) {
    final trimmed = fullName.trim();
    final firstLetter = trimmed.isEmpty
        ? 'u'
        : trimmed[0].toLowerCase(); // first char
    const symbol = '@';
    final random = Random.secure();
    final number = random.nextInt(10000); // 0..9999
    final digits = number.toString().padLeft(4, '0');
    return '$firstLetter$symbol$digits';
  }

  /// 0 + last two digits of year + 4 random digits
  /// e.g. 2025 → 0251234
  String _generateUniversityId() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final random = Random.secure().nextInt(10000).toString().padLeft(4, '0');
    return '0$yy$random';
  }

  /// three letters from first name + universityId + @ju.edu.jo
  String _generateUniversityEmail(String fullName, String universityId) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isEmpty ? 'std' : parts.first;
    String prefix;
    if (firstName.length >= 3) {
      prefix = firstName.substring(0, 3).toLowerCase();
    } else {
      prefix = firstName.toLowerCase().padRight(3, 'x');
    }
    return '$prefix$universityId@ju.edu.jo';
  }
}
