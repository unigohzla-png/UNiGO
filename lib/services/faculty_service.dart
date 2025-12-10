import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/faculty.dart';
import '../models/major.dart';

class FacultyService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<Faculty>> getFaculties() async {
    final snap = await _db.collection('faculties').orderBy('name').get();
    return snap.docs.map(Faculty.fromDoc).toList();
  }

  static Future<List<Major>> getMajorsForFaculty(String facultyId) async {
    final snap = await _db
        .collection('faculties')
        .doc(facultyId)
        .collection('majors')
        .orderBy('name') // no where filter here → no index needed
        .get();

    return snap.docs.map(Major.fromDoc).toList();
  }
}
