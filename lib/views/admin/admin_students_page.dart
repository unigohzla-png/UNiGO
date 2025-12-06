// lib/views/admin/admin_students_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../pages/print_schedule_page.dart';

class AdminStudentsPage extends StatefulWidget {
  /// If true, show “View schedule” (uses studentUidOverride).
  final bool isSuper;

  const AdminStudentsPage({super.key, this.isSuper = false});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchTerm = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Column(
        children: [
          // ---------- Search field ----------
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search by name, ID, or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ---------- List of students ----------
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('users')
                  .orderBy('name')
                  .limit(200) // adjust if you have many students
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading students:\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students found.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                // client-side filter by search term
                final filtered = docs.where((d) {
                  if (_searchTerm.isEmpty) return true;
                  final data = d.data();
                  final name =
                      (data['name'] ?? data['fullName'] ?? '').toString();
                  final id = (data['id'] ?? data['studentId'] ?? '').toString();
                  final email = (data['email'] ?? '').toString();

                  final sName = name.toLowerCase();
                  final sId = id.toLowerCase();
                  final sEmail = email.toLowerCase();

                  return sName.contains(_searchTerm) ||
                      sId.contains(_searchTerm) ||
                      sEmail.contains(_searchTerm);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students match your search.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    final uid = doc.id;
                    final name =
                        (data['name'] ?? data['fullName'] ?? 'Unnamed')
                            .toString();
                    final studentId =
                        (data['id'] ?? data['studentId'] ?? '').toString();
                    final email = (data['email'] ?? '').toString();
                    final major =
                        (data['major'] ?? data['department'] ?? '').toString();

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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (studentId.isNotEmpty)
                              Text(
                                'ID: $studentId',
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            if (major.isNotEmpty)
                              Text(
                                major,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                        trailing: widget.isSuper
                            ? IconButton(
                                tooltip: 'View schedule',
                                icon: const Icon(Icons.calendar_month_outlined),
                                onPressed: () {
                                  _openScheduleForStudent(
                                    context: context,
                                    studentUid: uid,
                                    studentName: name,
                                  );
                                },
                              )
                            : null,
                        // you could add onTap to open a “Student details” page later
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

  void _openScheduleForStudent({
    required BuildContext context,
    required String studentUid,
    required String studentName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrintSchedulePage(
          studentUidOverride: studentUid,
        ),
      ),
    );
  }
}
