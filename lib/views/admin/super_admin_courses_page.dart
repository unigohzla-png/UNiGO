import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/role_service.dart';
import 'super_admin_add_course_page.dart';

/// Super admin – manage courses & their availability next semester.
/// Scoped by facultyId.
class SuperAdminCoursesPage extends StatefulWidget {
  const SuperAdminCoursesPage({super.key});

  @override
  State<SuperAdminCoursesPage> createState() => _SuperAdminCoursesPageState();
}

class _SuperAdminCoursesPageState extends State<SuperAdminCoursesPage> {
  final _db = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();

  String? _facultyId;
  bool _loadingFaculty = true;
  String? _facultyError;

  CollectionReference<Map<String, dynamic>> get _coursesCol =>
      _db.collection('courses');

  @override
  void initState() {
    super.initState();
    _loadFacultyScope();
  }

  Future<void> _loadFacultyScope() async {
    try {
      final id = await _roleService.getCurrentFacultyId();
      if (!mounted) return;
      setState(() {
        _facultyId = id;
        _loadingFaculty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _facultyError = e.toString();
        _loadingFaculty = false;
      });
    }
  }

  Future<void> _toggleAvailableNextSemester(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool value,
  ) async {
    try {
      await _coursesCol
          .doc(doc.id)
          .set({'availableNextSemester': value}, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteCourse(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String code,
    String name,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete course'),
          content: Text(
            'Are you sure you want to delete this course?\n\n'
            '$code – $name\n\n'
            'This will remove the course document (and its sections array). '
            'Any other references using this course code will NOT be auto-cleaned.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _coursesCol.doc(doc.id).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course $code deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting course: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFaculty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Courses & sections')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_facultyError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Courses & sections')),
        body: Center(
          child: Text(
            'Error loading faculty scope:\n$_facultyError',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_facultyId == null || _facultyId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Courses & sections')),
        body: const Center(
          child: Text(
            'No faculty assigned to this account.\n'
            'Please set facultyId in roles/{uid}.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Courses & sections')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _coursesCol
            .where('facultyId', isEqualTo: _facultyId)
            .orderBy('code')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error loading courses:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No courses found for this faculty.\nUse the + button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final code = (data['code'] ?? doc.id).toString();
              final name = (data['name'] ?? 'Untitled course').toString();
              final credits = data['credits'];
              final type = (data['type'] ?? 'Unknown type').toString();
              final bool available =
                  (data['availableNextSemester'] ?? false) as bool;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top row: code + name + next-sem + delete
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$code – $name',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Next sem',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: available,
                                    onChanged: (val) =>
                                        _toggleAvailableNextSemester(
                                            doc, val),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete course',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _confirmDeleteCourse(
                                      doc,
                                      code,
                                      name,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // second row: type + credits
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          if (credits != null)
                            Text(
                              'Credits: $credits',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Faculty: $_facultyId',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SuperAdminAddCoursePage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
