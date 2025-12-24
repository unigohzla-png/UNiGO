import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/student_model.dart';

class ProfileController {
  Future<Student?> getStudent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return null;

    final data = doc.data()!;

    // handle dob which may be a Firestore Timestamp
    String dobString = '';
    final dobValue = data['dob'];
    if (dobValue != null) {
      if (dobValue is Timestamp) {
        final dt = dobValue.toDate();
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        dobString = '${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
      } else {
        dobString = dobValue.toString();
      }
    }

    return Student(
      name: data['name'] ?? '',
      advisor: data['advisor'] ?? '',
      dob: dobString,
      email: data['email'] ?? '',
      gpa: (data['gpa'] is num) ? (data['gpa'] as num).toDouble() : 0.0,
      houseaddress: data['houseaddress'] ?? '',
      id: data['id']?.toString() ?? '',
      identifiers: (data['identifiers'] is Map<String, dynamic>)
          ? (data['identifiers'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            )
          : {},
      location: data['location'] ?? '',
      major: data['major'] ?? '',
      paynum: data['paynum']?.toString() ?? '',
      profileImage: (data['profileImage'] ?? '').toString(),
      university: data['university'] ?? '',
      department: data['department'] ?? '',
    );
  }

  String _contentTypeFromExt(String ext) {
    final e = ext.toLowerCase();
    if (e == 'jpg' || e == 'jpeg') return 'image/jpeg';
    if (e == 'png') return 'image/png';
    return 'application/octet-stream';
  }

  /// Uploads a new profile photo for the current user.
  /// - Saves download URL in: users/{uid}.profileImage
  /// - Saves storage path in: users/{uid}.profileImagePath
  /// - Deletes previous image if profileImagePath exists
  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String extension, // jpg/png
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No logged-in user.');

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final oldSnap = await userRef.get();
    final oldPath = (oldSnap.data()?['profileImagePath'] ?? '').toString();

    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeExt = extension.toLowerCase();
    final newPath = 'profile_photos/$uid/$ts.$safeExt';

    final ref = FirebaseStorage.instance.ref(newPath);

    await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeFromExt(safeExt)),
    );

    final url = await ref.getDownloadURL();

    await userRef.set({
      'profileImage': url,
      'profileImagePath': newPath,
      'profileImageUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Best-effort cleanup
    if (oldPath.isNotEmpty && oldPath != newPath) {
      try {
        await FirebaseStorage.instance.ref(oldPath).delete();
      } catch (_) {}
    }

    return url;
  }

  Future<void> removeProfilePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No logged-in user.');

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await userRef.get();

    final oldPath = (snap.data()?['profileImagePath'] ?? '').toString();

    // Delete the stored file (best effort)
    if (oldPath.isNotEmpty) {
      try {
        await FirebaseStorage.instance.ref(oldPath).delete();
      } catch (_) {}
    }

    // Clear fields in Firestore
    await userRef.set({
      'profileImage': '',
      'profileImagePath': '',
      'profileImageUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
