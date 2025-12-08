import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_role.dart';

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

  bool _loadingCourses = true;
  bool _loadingHeader = true;
  String? _headerError;

  String? _instructorName; // for admins
  final List<_CourseOption> _courses = [];

  // form fields
  String _type = 'Deadline'; // Admin: fixed; Super: Deadline/Event
  String _scope = 'course'; // 'course' or 'global' (super only)
  _CourseOption? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _titleCtrl = TextEditingController();

  bool get _isSuper => widget.role == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _initHeaderAndCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _initHeaderAndCourses() async {
    setState(() {
      _loadingCourses = true;
      _loadingHeader = true;
      _headerError = null;
    });

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('Not logged in');
      }

      // ----- load user doc to get instructorName (for normal admins) -----
      final userSnap = await _db.collection('users').doc(uid).get();
      final userData = userSnap.data() ?? {};

      _instructorName = (userData['instructorName'] ??
              userData['fullName'] ??
              userData['name'] ??
              '')
          .toString();

      _loadingHeader = false;

      // ----- load courses -----
      Query<Map<String, dynamic>> q =
          _db.collection('courses').orderBy('code');

      // normal admin → only their courses
      if (!_isSuper &&
          _instructorName != null &&
          _instructorName!.trim().isNotEmpty) {
        q = q.where('instructorName', isEqualTo: _instructorName);
      }

      final snap = await q.get();

      _courses.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        final code = data['code']?.toString() ?? doc.id;
        final name = (data['name'] ?? 'Untitled course').toString();
        _courses.add(_CourseOption(code: code, name: name));
      }

      if (_courses.isNotEmpty) {
        _selectedCourse ??= _courses.first;
      }

      setState(() {
        _loadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _headerError = e.toString();
        _loadingCourses = false;
        _loadingHeader = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createItem() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    // Admin → can only create deadlines, course scope
    final String finalType = _isSuper ? _type : 'Deadline';
    final String finalScope = _isSuper ? _scope : 'course';

    if (finalScope == 'course' && _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    final normalized = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    try {
      await _db.collection('calendarEvents').add({
        'title': title,
        'date': Timestamp.fromDate(normalized),
        'type': finalType, // "Deadline" or "Event"
        'scope': finalScope, // "global" or "course"
        'courseCode':
            finalScope == 'course' ? _selectedCourse?.code : null,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$finalType added successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteItem(
    String id,
    String ownerId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bool canDelete =
        _isSuper || user.uid == ownerId; // super → all, admin → own only

    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete items you created.'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _db.collection('calendarEvents').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isSuper ? 'Calendar – events & deadlines' : 'Calendar – deadlines';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            Expanded(child: _buildExistingList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    if (_headerError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Text(
          'Error loading data:\n$_headerError',
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create new item',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Type row (super admin only)
            if (_isSuper) ...[
              Row(
                children: [
                  const Text(
                    'Type:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Deadline'),
                    selected: _type == 'Deadline',
                    onSelected: (_) {
                      setState(() => _type = 'Deadline');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Event'),
                    selected: _type == 'Event',
                    onSelected: (_) {
                      setState(() => _type = 'Event');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text(
                'Type: Deadline (admins can only add deadlines)',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
            ],

            // Scope row
            if (_isSuper) ...[
              Row(
                children: [
                  const Text(
                    'Scope:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Course'),
                    selected: _scope == 'course',
                    onSelected: (_) {
                      setState(() => _scope = 'course');
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Global'),
                    selected: _scope == 'global',
                    onSelected: (_) {
                      setState(() => _scope = 'global');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text(
                'Scope: course (linked to one of your courses)',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
            ],

            // Course dropdown (if scope == course)
            if (_scope == 'course' || !_isSuper) ...[
              if (_loadingCourses)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                )
              else if (_courses.isEmpty)
                const Text(
                  'No courses found to attach.\nCheck that you have courses assigned.',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                )
              else
                DropdownButtonFormField<_CourseOption>(
                  initialValue: _selectedCourse,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: _courses
                      .map(
                        (c) => DropdownMenuItem<_CourseOption>(
                          value: c,
                          child: Text('${c.code} – ${c.name}',
                              overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourse = value;
                    });
                  },
                ),
              const SizedBox(height: 10),
            ],

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. OS Project deadline',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Date picker row
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change date'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _loadingCourses && (_scope == 'course' || !_isSuper)
                        ? null
                        : _createItem,
                icon: const Icon(Icons.save),
                label: const Text('Save item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingList() {
    final user = _auth.currentUser;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('calendarEvents')
          .orderBy('date')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error loading items:\n${snap.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No deadlines or events yet.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        final String? myUid = user?.uid;
        final myCourseCodes = _courses.map((c) => c.code).toSet();

        final filtered = docs.where((d) {
          final data = d.data();
          final type = (data['type'] ?? '').toString();
          final scope = (data['scope'] ?? 'global').toString();
          final courseCode = data['courseCode']?.toString();

          if (type != 'Deadline' && type != 'Event') return false;

          // Super admin → see all
          if (_isSuper) return true;

          // Admin → only deadlines
          if (type != 'Deadline') return false;

          // Admin sees:
          // - global deadlines
          // - course deadlines for their courses
          if (scope == 'global') return true;
          if (scope == 'course' && courseCode != null) {
            return myCourseCodes.contains(courseCode);
          }
          return false;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'No items relevant to you.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data();

            final id = doc.id;
            final title = (data['title'] ?? '').toString();
            final type = (data['type'] ?? 'Deadline').toString();
            final scope = (data['scope'] ?? 'global').toString();
            final courseCode = data['courseCode']?.toString();
            final ownerId = (data['ownerId'] ?? '').toString();

            final ts = data['date'];
            DateTime date = DateTime.now();
            if (ts is Timestamp) {
              date = ts.toDate();
            }

            final bool canDelete =
                _isSuper || (myUid != null && myUid == ownerId);

            final typeColor =
                type == 'Event' ? Colors.green : Colors.redAccent;
            final scopeLabel = scope == 'global'
                ? 'Global'
                : (courseCode ?? 'Course');

            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              leading: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
              title: Text(
                title.isEmpty ? '(no title)' : title,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                '$dateStr • $scopeLabel',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing: canDelete
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _deleteItem(id, ownerId),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

// simple helper for course dropdown
class _CourseOption {
  final String code;
  final String name;

  _CourseOption({required this.code, required this.name});
}
