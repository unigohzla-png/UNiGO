import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/role_service.dart';

class AdminCalendarManagePage extends StatefulWidget {
  final UserRole role;

  const AdminCalendarManagePage({super.key, required this.role});

  @override
  State<AdminCalendarManagePage> createState() =>
      _AdminCalendarManagePageState();
}

class _AdminCalendarManagePageState extends State<AdminCalendarManagePage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _roleService = RoleService();

  bool get _isSuper => widget.role == UserRole.superAdmin;

  // Faculty + courses scope
  String? _facultyId;
  String? _scopeError;
  bool _loadingScope = true;

  List<_CourseItem> _courses = []; // all faculty courses (super) or assigned
  List<String> _adminCourseCodes = []; // codes assigned to this admin

  // Form state
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Deadline'; // 'Deadline' or 'Event'
  String _selectedScope = 'course'; // 'course' or 'global'
  String? _selectedCourseCode;

  @override
  void initState() {
    super.initState();
    _loadScopeAndCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadScopeAndCourses() async {
    setState(() {
      _loadingScope = true;
      _scopeError = null;
    });

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _scopeError = 'No logged-in user.';
          _loadingScope = false;
        });
        return;
      }

      // 1) Get facultyId of current user/super admin
      final facultyId = await _roleService.getCurrentFacultyId();
      if (facultyId == null || facultyId.trim().isEmpty) {
        setState(() {
          _scopeError = 'No faculty assigned to this account.';
          _loadingScope = false;
        });
        return;
      }
      final trimmedFacultyId = facultyId.trim();

      final List<_CourseItem> courses = [];
      final List<String> adminCodes = [];

      if (_isSuper) {
        // Super admin → all courses in this faculty
        final snap = await _db
            .collection('courses')
            .where('facultyId', isEqualTo: trimmedFacultyId)
            .orderBy('code')
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final code = (data['code'] ?? doc.id).toString();
          final name = (data['name'] ?? 'Untitled').toString();
          courses.add(_CourseItem(code: code, name: name));
        }
      } else {
        // Normal admin → only assignedCourseCodes from professors subcollection
        final profSnap = await _db
            .collection('faculties')
            .doc(trimmedFacultyId)
            .collection('professors')
            .doc(uid)
            .get();

        final profData = profSnap.data();
        List<String> assignedCodes = [];
        if (profData != null && profData['assignedCourseCodes'] is List) {
          assignedCodes = (profData['assignedCourseCodes'] as List)
              .map((e) => e.toString())
              .toList();
        }

        if (assignedCodes.isNotEmpty) {
          // For each course code, read course doc (only if belongs to same faculty)
          for (final code in assignedCodes) {
            final courseDoc = await _db.collection('courses').doc(code).get();
            if (!courseDoc.exists) continue;

            final data = courseDoc.data()!;
            final cFacultyId = data['facultyId']?.toString();
            if (cFacultyId != trimmedFacultyId) continue;

            final name = (data['name'] ?? 'Untitled').toString();
            courses.add(_CourseItem(code: code, name: name));
          }
        }

        adminCodes.addAll(assignedCodes);
      }

      setState(() {
        _facultyId = trimmedFacultyId;
        _courses = courses;
        _adminCourseCodes = adminCodes;
        _loadingScope = false;
      });
    } catch (e) {
      setState(() {
        _scopeError = e.toString();
        _loadingScope = false;
      });
    }
  }

  // ========= STREAM OF EVENTS FOR THIS FACULTY =========

  Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream() {
    Query<Map<String, dynamic>> q = _db.collection('calendarEvents');

    if (_facultyId != null && _facultyId!.isNotEmpty) {
      q = q.where('facultyId', isEqualTo: _facultyId);
    }

    return q.orderBy('date').snapshots();
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar & Deadlines')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingScope) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_scopeError != null || _facultyId == null) {
      return Center(
        child: Text(
          'Error:\n${_scopeError ?? "Unknown"}',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        // ===== Top form card (same style as before) =====
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Midterm exam, Project 2 deadline',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Type + Scope row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Deadline',
                              child: Text('Deadline'),
                            ),
                            DropdownMenuItem(
                              value: 'Event',
                              child: Text('Event'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _selectedType = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _scopeForUi(),
                          decoration: const InputDecoration(
                            labelText: 'Scope',
                            border: OutlineInputBorder(),
                          ),
                          items: _scopeOptions()
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s == 'course'
                                        ? 'Course only'
                                        : 'Global (whole faculty)',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            // admins can only use 'course'; guarding in _scopeOptions
                            setState(() {
                              _selectedScope = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Course dropdown (only when scope == course)
                  if (_selectedScope == 'course') ...[
                    if (!_isSuper && _courses.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No courses assigned to this account.\n'
                          'Ask your super admin to assign courses in Academic Staff.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourseCode,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(),
                        ),
                        items: _courses
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.code,
                                child: Text('${c.code} – ${c.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseCode = val;
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                  ],

                  // Date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.year}-${_two(_selectedDate.month)}-${_two(_selectedDate.day)}',
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onAddPressed,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ===== Existing events list =====
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _eventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading events:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              // Filter for admin (prof) – only their course events + all faculty global
              if (!_isSuper) {
                docs = docs.where((doc) {
                  final data = doc.data();
                  final scope = (data['scope'] ?? 'global').toString();
                  if (scope == 'global') return true;
                  if (scope == 'course') {
                    final code = data['courseCode']?.toString() ?? '';
                    return _adminCourseCodes.contains(code);
                  }
                  return false;
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No events or deadlines yet.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();

                  final title = (data['title'] ?? 'Untitled').toString();
                  final type = (data['type'] ?? 'Event')
                      .toString(); // Event|Deadline
                  final scope = (data['scope'] ?? 'global')
                      .toString(); // course|global
                  final courseCode = (data['courseCode'] ?? '').toString();

                  final ts = data['date'];
                  DateTime date;
                  if (ts is Timestamp) {
                    date = ts.toDate();
                  } else if (ts is String) {
                    date = DateTime.tryParse(ts) ?? DateTime.now();
                  } else {
                    date = DateTime.now();
                  }

                  final dateStr =
                      '${date.year}-${_two(date.month)}-${_two(date.day)}';

                  String subtitle = '$type • ';
                  if (scope == 'course' && courseCode.isNotEmpty) {
                    subtitle += 'Course $courseCode';
                  } else {
                    subtitle += 'Global (faculty)';
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text('$subtitle • $dateStr'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEvent(doc.id),
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
  }

  // Helpers for UI

  List<String> _scopeOptions() {
    // Super admin can choose course/global
    // Admin: course only
    if (_isSuper) return ['course', 'global'];
    return ['course'];
  }

  String _scopeForUi() {
    final allowed = _scopeOptions();
    if (allowed.contains(_selectedScope)) return _selectedScope;
    return allowed.first;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // ===================== ACTIONS =====================

  Future<void> _onAddPressed() async {
    if (_facultyId == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    // Make sure scope is valid for this role
    final scope = _scopeForUi();

    if (scope == 'course') {
      if (_courses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no courses to attach this to.'),
          ),
        );
        return;
      }
      if (_selectedCourseCode == null || _selectedCourseCode!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a course.')),
        );
        return;
      }
    }

    await _createEvent(
      title: title,
      type: _selectedType,
      scope: scope,
      date: _selectedDate,
      courseCode: scope == 'course' ? _selectedCourseCode : null,
    );

    // Clear title, keep type/scope/date as they are
    _titleController.clear();
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await _db.collection('calendarEvents').doc(id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
    }
  }

  Future<void> _createEvent({
    required String title,
    required String type, // 'Deadline' or 'Event'
    required String scope, // 'course' or 'global'
    required DateTime date,
    String? courseCode,
  }) async {
    try {
      final uid = _auth.currentUser?.uid ?? 'unknown';

      await _db.collection('calendarEvents').add({
        'title': title,
        'type': type,
        'scope': scope,
        'courseCode': courseCode,
        'facultyId': _facultyId,
        'ownerId': uid,
        'createdByRole': _isSuper ? 'superAdmin' : 'admin',
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create item: $e')));
    }
  }
}

class _CourseItem {
  final String code;
  final String name;

  _CourseItem({required this.code, required this.name});
}
