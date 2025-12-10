import 'package:cloud_firestore/cloud_firestore.dart';

class Professor {
  final String id;
  final String fullName;
  final String email;
  final String facultyId;
  final List<String> majorIds;

  final bool canAdvise;
  final int maxAdvisees;
  final int adviseesCount;

  Professor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.facultyId,
    required this.majorIds,
    required this.canAdvise,
    required this.maxAdvisees,
    required this.adviseesCount,
  });

  factory Professor.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final majorsRaw = data['majorIds'];
    List<String> majorIds = [];
    if (majorsRaw is List) {
      majorIds = majorsRaw.map((e) => e.toString()).toList();
    }

    return Professor(
      id: doc.id,
      fullName: (data['fullName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      facultyId: (data['facultyId'] ?? '').toString(),
      majorIds: majorIds,
      canAdvise: data['canAdvise'] == true,
      maxAdvisees: (data['maxAdvisees'] ?? 0) as int,
      adviseesCount: (data['adviseesCount'] ?? 0) as int,
    );
  }
}
