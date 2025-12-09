import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_role.dart';

class RoleService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<UserRole> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.student;

    try {
      final doc = await _db.collection('roles').doc(user.uid).get();
      if (!doc.exists) {
        return UserRole.student;
      }

      final data = doc.data() as Map<String, dynamic>;

      // ✅ New schema: { role: "student" | "admin" | "superAdmin" }
      final roleStr = (data['role'] ?? '').toString();

      switch (roleStr) {
        case 'student':
          return UserRole.student;
        case 'admin':
          return UserRole.admin;
        case 'superAdmin':
          return UserRole.superAdmin;
      }

      // 🕰 Backwards-compat: old schema { admin: bool, level: "normal"|"super" }
      final bool isAdmin = (data['admin'] ?? false) == true;
      final String level = (data['level'] ?? 'normal').toString();

      if (!isAdmin) return UserRole.student;
      if (level == 'super') return UserRole.superAdmin;
      return UserRole.admin;
    } catch (e) {
      // safest fallback
      return UserRole.student;
    }
  }
}
