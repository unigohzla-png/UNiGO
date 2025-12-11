import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'super_admin_student_course_control_page.dart';
import '../../services/role_service.dart';

class SuperAdminStudentsPage extends StatefulWidget {
  const SuperAdminStudentsPage({super.key});

  @override
  State<SuperAdminStudentsPage> createState() =>
      _SuperAdminStudentsPageState();
}

class _SuperAdminStudentsPageState extends State<SuperAdminStudentsPage> {
  final _db = FirebaseFirestore.instance;
  final _roleService = RoleService();

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchTerm = '';

  String? _facultyId;
  String? _facultyError;
  bool _facultyLoading = true;

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
        _facultyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _facultyError = e.toString();
        _facultyLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_facultyLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Students'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_facultyError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Students'),
        ),
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
        appBar: AppBar(
          title: const Text('Students'),
        ),
        body: const Center(
          child: Text(
            'No faculty assigned to this super admin.\n'
            'Please set facultyId in roles/{uid} & users/{uid}.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    // Only students from this faculty
    final stream = _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('facultyId', isEqualTo: _facultyId)
        .orderBy('name')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search by name, ID or email',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
                _searchFocusNode.requestFocus();
              },
            ),
          ),
          // STREAM + FILTERED LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading students:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final queryText = _searchTerm.trim().toLowerCase();

                final filteredDocs = queryText.isEmpty
                    ? docs
                    : docs.where((doc) {
                        final data = doc.data();

                        final name = (data['name'] ??
                                data['fullName'] ??
                                'Unnamed')
                            .toString()
                            .toLowerCase();

                        final email = (data['email'] ?? '')
                            .toString()
                            .toLowerCase();

                        final uniId = (data['id'] ??
                                data['universityId'] ??
                                '')
                            .toString()
                            .toLowerCase();

                        return name.contains(queryText) ||
                            uniId.contains(queryText) ||
                            email.contains(queryText);
                      }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students found for this faculty.',
                      style:
                          TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (queryText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Showing ${filteredDocs.length} of ${docs.length} students',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'No students match this search.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredDocs.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data();

                                final name = (data['name'] ??
                                        data['fullName'] ??
                                        'Unnamed')
                                    .toString();
                                final email =
                                    (data['email'] ?? 'No email')
                                        .toString();
                                final uniId = (data['id'] ??
                                        data['universityId'] ??
                                        '—')
                                    .toString();

                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '$email · ID: $uniId',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SuperAdminStudentCourseControlPage(
                                          studentUid: doc.id,
                                          studentName: name,
                                          studentId: uniId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
