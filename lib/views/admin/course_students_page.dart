import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_student_course_page.dart';

class CourseStudentsPage extends StatelessWidget {
  final String courseCode;
  final String courseName;

  const CourseStudentsPage({
    super.key,
    required this.courseCode,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('enrolledCourses', arrayContains: courseCode);

    return Scaffold(
      appBar: AppBar(title: Text('$courseCode – $courseName')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No students enrolled.'));
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = (data['name'] ?? 'Unknown') as String;
              final id = (data['id'] ?? '').toString();
              final major = (data['major'] ?? '') as String;

              return Material(
                color: Colors.white,
                elevation: 1,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    id.isEmpty ? major : '$id • $major',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminStudentCoursePage(
                          studentUid: doc.id,
                          studentName: name,
                          studentId: id,
                          courseCode: courseCode,
                          courseName: courseName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
