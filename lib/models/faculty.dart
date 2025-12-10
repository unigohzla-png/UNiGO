import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  final String id;
  final String name;
  final String code;

  Faculty({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Faculty.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Faculty(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      code: (data['code'] ?? '').toString(),
    );
  }
}
