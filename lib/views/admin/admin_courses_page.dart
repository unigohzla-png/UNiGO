import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'course_students_page.dart';

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({super.key});

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by code or name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .orderBy('code')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No courses found.'));
                }

                final q = _searchCtrl.text.trim().toLowerCase();
                final docs = snap.data!.docs.where((doc) {
                  final data = doc.data();
                  final code = (data['code'] ?? '').toString().toLowerCase();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  if (q.isEmpty) return true;
                  return code.contains(q) || name.contains(q);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No results for this search.'));
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final code = (data['code'] ?? doc.id).toString();
                    final name = (data['name'] ?? 'Unnamed course') as String;
                    final type =
                        (data['type'] ?? '') as String; // e.g. "Obligatory..."

                    return Material(
                      color: Colors.white,
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          type.isEmpty ? code : '$code • $type',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseStudentsPage(
                                courseCode: code,
                                courseName: name,
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
          ),
        ],
      ),
    );
  }
}
