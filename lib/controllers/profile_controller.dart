import '../models/student_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        // format as '13 Feb 2003'
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
      profileImage: data['profileImage'] ?? '',
      university: data['university'] ?? '',
      department: data['department'] ?? '',
    );
  }
}
