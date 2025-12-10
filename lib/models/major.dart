import 'package:cloud_firestore/cloud_firestore.dart';

class Major {
  final String id;
  final String name;
  final String code;
  final String facultyId;

  Major({
    required this.id,
    required this.name,
    required this.code,
    required this.facultyId,
  });

  factory Major.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Major(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      code: (data['code'] ?? '').toString(),
      facultyId: (data['facultyId'] ?? '').toString(),
    );
  }
}
