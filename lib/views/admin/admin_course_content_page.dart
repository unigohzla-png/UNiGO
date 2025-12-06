import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCourseContentPage extends StatefulWidget {
  final String courseCode;
  final String courseName;

  const AdminCourseContentPage({
    super.key,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<AdminCourseContentPage> createState() => _AdminCourseContentPageState();
}

class _AdminCourseContentPageState extends State<AdminCourseContentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final DocumentReference<Map<String, dynamic>> _courseRef;

  @override
  void initState() {
    super.initState();
    // 0 = Materials, 1 = Announcements, 2 = Students
    _tabController = TabController(length: 3, vsync: this);
    _courseRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseCode);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ------- MATERIALS -------

  Future<void> _addMaterial() async {
    final titleCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'PDF');
    final metaCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add material'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Type (PDF, Link, Video...)',
                    ),
                  ),
                  TextFormField(
                    controller: metaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Meta (optional)',
                      hintText: 'e.g. "Due: 2025-01-10"',
                    ),
                  ),
                  TextFormField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'title': titleCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                  'meta': metaCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                };
                await _courseRef.collection('materials').add(data);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material added')));
    }
  }

  // ------- ANNOUNCEMENTS -------

  Future<void> _addAnnouncement() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool pinned = false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Add announcement'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: bodyCtrl,
                        decoration: const InputDecoration(labelText: 'Body'),
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pinned'),
                        value: pinned,
                        onChanged: (val) {
                          setLocalState(() {
                            pinned = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final data = {
                      'title': titleCtrl.text.trim(),
                      'body': bodyCtrl.text.trim(),
                      'pinned': pinned,
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    await _courseRef.collection('announcements').add(data);
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement added')));
    }
  }

  // ------- SHARED DELETE -------

  Future<void> _deleteDoc(
    CollectionReference<Map<String, dynamic>> col,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete item?'),
          content: const Text('This action cannot be undone. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await col.doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    }
  }

  Widget? _buildFab() {
    // Only show FAB for Materials or Announcements tabs
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _addMaterial,
        child: const Icon(Icons.add),
      );
    }
    if (_tabController.index == 1) {
      return FloatingActionButton(
        onPressed: _addAnnouncement,
        child: const Icon(Icons.add),
      );
    }
    // Students tab → no FAB (grades/absences handled in detail page)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final courseTitle = '${widget.courseCode} – ${widget.courseName}';

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Materials'),
            Tab(text: 'Announcements'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MaterialsTab(
            courseRef: _courseRef,
            onDelete: (id) =>
                _deleteDoc(_courseRef.collection('materials'), id),
          ),
          _AnnouncementsTab(
            courseRef: _courseRef,
            onDelete: (id) =>
                _deleteDoc(_courseRef.collection('announcements'), id),
          ),
          _StudentsTab(
            courseCode: widget.courseCode,
            courseName: widget.courseName,
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}

// ================== MATERIALS TAB ==================

class _MaterialsTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> courseRef;
  final Future<void> Function(String id) onDelete;

  const _MaterialsTab({required this.courseRef, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: courseRef.collection('materials').orderBy('title').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No materials yet.\nTap + to add.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final title = (data['title'] ?? 'Untitled') as String;
            final type = (data['type'] ?? '') as String;
            final meta = (data['meta'] ?? '') as String;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 1,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  child: Text(type.isEmpty ? 'F' : type[0].toUpperCase()),
                ),
                title: Text(title, style: const TextStyle(fontSize: 14)),
                subtitle: meta.isEmpty
                    ? null
                    : Text(meta, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ================== ANNOUNCEMENTS TAB ==================

class _AnnouncementsTab extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> courseRef;
  final Future<void> Function(String id) onDelete;

  const _AnnouncementsTab({required this.courseRef, required this.onDelete});

  String _fmtDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: courseRef
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No announcements yet.\nTap + to add.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final title = (data['title'] ?? 'Untitled') as String;
            final body = (data['body'] ?? '') as String;
            final pinned = (data['pinned'] ?? false) as bool;
            final createdAt = data['createdAt'] as Timestamp?;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 1,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Row(
                  children: [
                    if (pinned)
                      const Icon(Icons.push_pin, size: 16, color: Colors.red),
                    if (pinned) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (body.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(body, style: const TextStyle(fontSize: 13)),
                      ),
                    if (createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          _fmtDate(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ================== STUDENTS TAB (LIST) ==================

class _StudentsTab extends StatelessWidget {
  final String courseCode;
  final String courseName;

  const _StudentsTab({required this.courseCode, required this.courseName});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('users')
          .where('enrolledCourses', arrayContains: courseCode)
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
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No students are currently enrolled in this course.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final d = docs[index];
            final data = d.data();
            final name = (data['name'] ?? 'Unnamed student') as String;
            final uniId = data['id']?.toString() ?? '';
            final email = data['email']?.toString() ?? '';

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
                subtitle: Text(
                  [
                    if (uniId.isNotEmpty) 'ID: $uniId',
                    if (email.isNotEmpty) email,
                  ].join(' • '),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminStudentCoursePage(
                        userId: d.id,
                        studentName: name,
                        studentNumber: uniId,
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
    );
  }
}

// ================== STUDENT COURSE PAGE (GRADES + ABSENCES) ==================

class AdminStudentCoursePage extends StatelessWidget {
  final String userId;
  final String studentName;
  final String studentNumber;
  final String courseCode;
  final String courseName;

  const AdminStudentCoursePage({
    super.key,
    required this.userId,
    required this.studentName,
    required this.studentNumber,
    required this.courseCode,
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final userCourseRef = db
        .collection('users')
        .doc(userId)
        .collection('courses')
        .doc(courseCode);

    final gradesCol = userCourseRef.collection('grades');
    final absencesCol = userCourseRef.collection('absences');

    return Scaffold(
      appBar: AppBar(title: Text('$studentName – $courseCode')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$courseCode – $courseName',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (studentNumber.isNotEmpty)
              Text(
                'Student ID: $studentNumber',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 16),

            // GRADES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grades',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showAddGradeDialog(context, gradesCol),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: gradesCol.orderBy('order').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Text(
                    'No grades yet for this student in this course.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  );
                }

                double total = 0;
                double totalMax = 0;
                for (final d in docs) {
                  final data = d.data();
                  final s = (data['score'] ?? 0) as num;
                  final m = (data['maxScore'] ?? 0) as num;
                  total += s.toDouble();
                  totalMax += m.toDouble();
                }

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = docs[index];
                        final data = d.data();

                        final label = (data['label'] ?? 'Unnamed') as String;
                        final score = (data['score'] ?? 0) as num;
                        final maxScore = (data['maxScore'] ?? 0) as num;
                        final order = data['order'];

                        return ListTile(
                          dense: true,
                          title: Text(
                            label,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: order == null
                              ? null
                              : Text(
                                  'Order: $order',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${score.toString()} / ${maxScore.toString()}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showEditGradeDialog(
                                  context,
                                  gradesCol,
                                  d.id,
                                  data,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  await gradesCol.doc(d.id).delete();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: $total / $totalMax',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ABSENCES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Absences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showAddAbsenceDialog(context, absencesCol),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: absencesCol.orderBy('date', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Text(
                    'No recorded absences for this course.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data();
                    final ts = data['date'] as Timestamp?;
                    final note = data['note']?.toString() ?? '';

                    String dateStr = '';
                    if (ts != null) {
                      final dd = ts.toDate();
                      dateStr =
                          '${dd.year}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')} '
                          '${dd.hour.toString().padLeft(2, '0')}:${dd.minute.toString().padLeft(2, '0')}';
                    }

                    return ListTile(
                      dense: true,
                      title: Text(dateStr.isEmpty ? 'No date' : dateStr),
                      subtitle: note.isEmpty
                          ? null
                          : Text(note, style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          await absencesCol.doc(d.id).delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------- dialogs for grades & absences -------

  static Future<void> _showAddGradeDialog(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> gradesCol,
  ) async {
    final labelCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    final orderCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add grade'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g. Quiz 1)',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: scoreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Score (e.g. 8)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: maxCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Max score (e.g. 10)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: orderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Order (optional, e.g. 1)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final label = labelCtrl.text.trim();
                final score = double.tryParse(scoreCtrl.text.trim()) ?? 0;
                final maxScore = double.tryParse(maxCtrl.text.trim()) ?? 0;
                final order = int.tryParse(orderCtrl.text.trim());

                await gradesCol.add({
                  'label': label,
                  'score': score,
                  'maxScore': maxScore,
                  if (order != null) 'order': order,
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showEditGradeDialog(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> gradesCol,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final labelCtrl = TextEditingController(text: data['label']?.toString());
    final scoreCtrl = TextEditingController(text: data['score']?.toString());
    final maxCtrl = TextEditingController(text: data['maxScore']?.toString());
    final orderCtrl = TextEditingController(
      text: data['order']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit grade'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Label'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: scoreCtrl,
                    decoration: const InputDecoration(labelText: 'Score'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: maxCtrl,
                    decoration: const InputDecoration(labelText: 'Max score'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: orderCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Order (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final label = labelCtrl.text.trim();
                final score = double.tryParse(scoreCtrl.text.trim()) ?? 0;
                final maxScore = double.tryParse(maxCtrl.text.trim()) ?? 0;
                final order = int.tryParse(orderCtrl.text.trim());

                final updateData = <String, dynamic>{
                  'label': label,
                  'score': score,
                  'maxScore': maxScore,
                };
                if (order != null) {
                  updateData['order'] = order;
                } else {
                  updateData.remove('order');
                }

                await gradesCol.doc(docId).update(updateData);

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showAddAbsenceDialog(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> absencesCol,
  ) async {
    final noteCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add absence'),
          content: TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Sick leave, missed quiz',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await absencesCol.add({
                  'date': FieldValue.serverTimestamp(),
                  'note': noteCtrl.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
