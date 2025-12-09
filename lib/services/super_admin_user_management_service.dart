import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

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

class SuperAdminUserManagementService {
  SuperAdminUserManagementService._();

  static final SuperAdminUserManagementService instance =
      SuperAdminUserManagementService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Load all users with their roles.
  Future<List<ManagedUserSummary>> loadUsersWithRoles() async {
    final usersSnap = await _db.collection('users').get();
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

    // sort alphabetically by name
    result.sort((a, b) => a.name.compareTo(b.name));
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

  /// Create a new user document + role in Firestore only.
  ///
  /// NOTE: This does NOT create the Firebase Auth user; that requires Admin SDK
  /// (Cloud Functions / backend). We store the generated password in the user
  /// doc so you can sync it later.
  Future<String> createUserFirestoreOnly({
    required String fullName,
    required String email,
    required String universityId,
    required String major,
    required String department,
    required String role, // 'student' | 'admin' | 'superAdmin'
  }) async {
    // Temporary password using your rule:
    // firstLetterOfFirstName + symbol + 4 random digits
    final password = _generatePassword(fullName);

    // Generate a Firestore doc with a random ID as the uid
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
      // flags for backend / manual work
      'markForAuthCreation': true,
      'initialPassword': password,
    });

    await _db.collection('roles').doc(uid).set({'role': role});

    return password;
  }

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

    // TODO: delete any subcollections under users/{uid} if you add them later
    await _db.collection('users').doc(uid).delete();

    // Mark for Auth deletion (to be handled by backend or manually)
    await _db.collection('deletedUsers').doc(uid).set({
      'uid': uid,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

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
}
