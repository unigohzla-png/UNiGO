import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminStudentCoursePage extends StatefulWidget {
  final String studentUid;
  final String studentName;
  final String studentId;
  final String courseCode;
  final String courseName;

  const AdminStudentCoursePage({
    super.key,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<AdminStudentCoursePage> createState() => _AdminStudentCoursePageState();
}

class _AdminStudentCoursePageState extends State<AdminStudentCoursePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CollectionReference<Map<String, dynamic>> _gradesRef;
  late final CollectionReference<Map<String, dynamic>> _absencesRef;

  final _auth = FirebaseAuth.instance; // 👈 NEW

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentUid);
    final courseDoc = userDoc.collection('courses').doc(widget.courseCode);

    _gradesRef = courseDoc.collection('grades');
    _absencesRef = courseDoc.collection('absences');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------- GRADES ----------

  Future<void> _showGradeDialog({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final isEdit = doc != null;
    String label = isEdit ? (doc.data()?['label'] ?? '') as String : '';
    String score = isEdit ? (doc.data()?['score'] ?? 0).toString() : '';
    String maxScore = isEdit ? (doc.data()?['maxScore'] ?? 0).toString() : '';

    // compute order for new item
    int? order = isEdit ? (doc.data()?['order'] as int? ?? 0) : null;

    // NEW: status flags
    bool confirmed = isEdit
        ? ((doc.data()?['confirmed'] ?? false) as bool)
        : false;
    bool submittedForApproval = isEdit
        ? ((doc.data()?['submittedForApproval'] ?? false) as bool)
        : false;

    if (!isEdit) {
      final last = await _gradesRef
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      if (last.docs.isNotEmpty) {
        order = (last.docs.first.data()['order'] as int? ?? 0) + 1;
      } else {
        order = 1;
      }
    }

    final labelCtrl = TextEditingController(text: label);
    final scoreCtrl = TextEditingController(text: score);
    final maxCtrl = TextEditingController(text: maxScore);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit grade item' : 'Add grade item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label (e.g. Midterm)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: scoreCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Score'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Max score'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final l = labelCtrl.text.trim();
                final s = double.tryParse(scoreCtrl.text.trim());
                final m = double.tryParse(maxCtrl.text.trim());

                if (l.isEmpty || s == null || m == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid label and numbers'),
                    ),
                  );
                  return;
                }

                // Grades created/edited by admin are always "pending"
                confirmed = false;

                final data = {
                  'label': l,
                  'score': s,
                  'maxScore': m,
                  'order': order,
                  'confirmed': confirmed,
                  'submittedForApproval': submittedForApproval,
                  'updatedAt': FieldValue.serverTimestamp(),
                  if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
                  if (!isEdit) 'createdBy': _auth.currentUser?.uid,
                };

                try {
                  if (isEdit) {
                    await _gradesRef.doc(doc.id).update(data);
                  } else {
                    await _gradesRef.add(data);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving grade: $e')),
                  );
                }
              },
              child: Text(isEdit ? 'Save changes' : 'Add grade'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGrade(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete grade item?'),
        content: Text('This will remove "${doc.data()?['label']}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _gradesRef.doc(doc.id).delete();
    }
  }

  Widget _buildGradesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _gradesRef.orderBy('order').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text('No grades recorded.'));
              }

              final docs = snap.data!.docs;

              double total = 0;
              double totalMax = 0;
              for (final d in docs) {
                final data = d.data();
                total += (data['score'] ?? 0).toDouble();
                totalMax += (data['maxScore'] ?? 0).toDouble();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == docs.length) {
                    // total row
                    return ListTile(
                      title: Text(
                        'Total (/${totalMax.toStringAsFixed(0)})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Text(
                        total.toStringAsFixed(
                          total == total.roundToDouble() ? 0 : 1,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                    );
                  }

                  final doc = docs[index];
                  final data = doc.data();

                  final label = (data['label'] ?? '') as String;
                  final score = (data['score'] ?? 0).toDouble();
                  final maxScore = (data['maxScore'] ?? 0).toDouble();

                  final bool confirmed = (data['confirmed'] ?? false) == true;
                  final bool submitted =
                      (data['submittedForApproval'] ?? false) == true;

                  final scoreStr = score.toStringAsFixed(
                    score == score.roundToDouble() ? 0 : 1,
                  );
                  final maxStr = maxScore.toStringAsFixed(
                    maxScore == maxScore.roundToDouble() ? 0 : 1,
                  );

                  Widget statusChip;
                  if (confirmed) {
                    statusChip = const Chip(
                      label: Text('Confirmed'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(fontSize: 11),
                    );
                  } else if (submitted) {
                    statusChip = const Chip(
                      label: Text('Pending'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(fontSize: 11),
                    );
                  } else {
                    statusChip = const Chip(
                      label: Text('Draft'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(fontSize: 11),
                    );
                  }

                  return ListTile(
                    title: Text(label),
                    subtitle: Text('$scoreStr / $maxStr'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        statusChip,
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: confirmed
                              ? null
                              : () => _showGradeDialog(doc: doc),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: confirmed ? null : () => _deleteGrade(doc),
                        ),
                        if (!confirmed && !submitted)
                          TextButton(
                            onPressed: () => _requestConfirmation(doc),
                            child: const Text('Request'),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showGradeDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add grade item'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestConfirmation(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      await _gradesRef.doc(doc.id).update({
        'submittedForApproval': true,
        'requestedBy': _auth.currentUser?.uid,
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Confirmation requested.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request confirmation: $e')),
      );
    }
  }

  // ---------- ABSENCES ----------

  Future<void> _showAbsenceDialog({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final isEdit = doc != null;
    DateTime date = isEdit
        ? (doc.data()?['date'] as Timestamp).toDate()
        : DateTime.now();

    String startTime = isEdit
        ? (doc.data()?['startTime'] ?? '10:00') as String
        : '10:00';
    String endTime = isEdit
        ? (doc.data()?['endTime'] ?? '11:00') as String
        : '11:00';

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          date = picked;
        });
      }
    }

    final startCtrl = TextEditingController(text: startTime);
    final endCtrl = TextEditingController(text: endTime);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit absence' : 'Add absence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ),
                ),
                TextButton(onPressed: pickDate, child: const Text('Change')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(
                labelText: 'Start time (e.g. 10:00)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(
                labelText: 'End time (e.g. 11:00)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              startTime = startCtrl.text.trim();
              endTime = endCtrl.text.trim();
              if (startTime.isEmpty || endTime.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter start and end time')),
                );
                return;
              }

              final weekdayNames = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ];
              final String day =
                  weekdayNames[(date.weekday + 6) % 7]; // make Mon index 0

              final data = {
                'date': Timestamp.fromDate(date),
                'day': day,
                'startTime': startTime,
                'endTime': endTime,
              };

              if (isEdit) {
                await _absencesRef.doc(doc.id).update(data);
              } else {
                await _absencesRef.add(data);
              }

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAbsence(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete absence?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _absencesRef.doc(doc.id).delete();
    }
  }

  Widget _buildAbsencesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _absencesRef.orderBy('date', descending: true).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text('No absences recorded.'));
              }

              final docs = snap.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final ts = data['date'] as Timestamp;
                  final date = ts.toDate();
                  final day = (data['day'] ?? '') as String;
                  final startTime = (data['startTime'] ?? '') as String;
                  final endTime = (data['endTime'] ?? '') as String;

                  final dateStr =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                  return ListTile(
                    title: Text('$day • $dateStr'),
                    subtitle: Text('$startTime - $endTime'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAbsenceDialog(doc: doc),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteAbsence(doc),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAbsenceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add absence'),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    final subtitle =
        '${widget.studentName} (${widget.studentId})\n${widget.courseCode} – ${widget.courseName}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Grades'),
            Tab(text: 'Absences'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildGradesTab(), _buildAbsencesTab()],
            ),
          ),
        ],
      ),
    );
  }
}
