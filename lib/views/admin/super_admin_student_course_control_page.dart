import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui/services/super_admin_course_override_service.dart';

class SuperAdminStudentCourseControlPage extends StatefulWidget {
  final String studentUid;
  final String studentName;
  final String studentId; // university ID, not uid

  const SuperAdminStudentCourseControlPage({
    super.key,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
  });

  @override
  State<SuperAdminStudentCourseControlPage> createState() =>
      _SuperAdminStudentCourseControlPageState();
}

// ---------------------------------------------------------------------------
// Small in-file models for course/section picker
// ---------------------------------------------------------------------------

class _SectionOption {
  final String id;
  final String label; // e.g. "Sun, Tue • 10:00–11:00"

  _SectionOption({required this.id, required this.label});
}

class _CourseOption {
  final String code;
  final String name;
  final List<_SectionOption> sections;

  _CourseOption({
    required this.code,
    required this.name,
    required this.sections,
  });
}

class _SuperAdminStudentCourseControlPageState
    extends State<SuperAdminStudentCourseControlPage> {
  final _db = FirebaseFirestore.instance;

  // student data
  bool _loadingStudent = true;
  String? _studentError;
  Map<String, dynamic> _userData = <String, dynamic>{};

  // course picker data
  bool _loadingCourses = true;
  String? _coursesError;
  List<_CourseOption> _courseOptions = <_CourseOption>[];

  @override
  void initState() {
    super.initState();
    _loadStudent();
    _loadCourses();
  }

  // ---------------------------------------------------------------------------
  // Loaders
  // ---------------------------------------------------------------------------

  Future<void> _loadStudent() async {
    setState(() {
      _loadingStudent = true;
      _studentError = null;
    });

    try {
      final snap = await _db.collection('users').doc(widget.studentUid).get();
      if (!snap.exists) {
        throw Exception('User document not found.');
      }
      _userData = snap.data() as Map<String, dynamic>;
    } catch (e) {
      _studentError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingStudent = false);
      }
    }
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loadingCourses = true;
      _coursesError = null;
    });

    try {
      final snap = await _db.collection('courses').orderBy('code').get();

      final List<_CourseOption> list = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final code = data['code']?.toString() ?? doc.id;
        final name = (data['name'] ?? 'Untitled course') as String;

        final List<_SectionOption> sections = [];
        final rawSections = data['sections'];

        if (rawSections is List) {
          for (final s in rawSections) {
            if (s is Map) {
              final map = Map<String, dynamic>.from(s);
              final id = map['id']?.toString() ?? '';
              if (id.isEmpty) continue;

              final daysList =
                  (map['days'] as List?)?.cast<String>() ?? const [];
              final days = daysList.join(', ');

              final start = map['startTime']?.toString() ?? '';
              final end = map['endTime']?.toString() ?? '';

              String label;
              if (days.isNotEmpty && start.isNotEmpty && end.isNotEmpty) {
                label = '$days • $start–$end';
              } else if (days.isNotEmpty) {
                label = days;
              } else if (start.isNotEmpty && end.isNotEmpty) {
                label = '$start–$end';
              } else {
                label = 'Section $id';
              }

              sections.add(_SectionOption(id: id, label: label));
            }
          }
        }

        list.add(_CourseOption(code: code, name: name, sections: sections));
      }

      _courseOptions = list;
    } catch (e) {
      _coursesError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingCourses = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Shortcuts to student arrays/maps
  // ---------------------------------------------------------------------------

  List<String> get _enrolledCourses =>
      List<String>.from(_userData['enrolledCourses'] ?? const []);

  List<String> get _upcomingCourses =>
      List<String>.from(_userData['upcomingCourses'] ?? const []);

  Map<String, dynamic> get _upcomingSections => Map<String, dynamic>.from(
    _userData['upcomingSections'] ?? <String, dynamic>{},
  );

  List<String> get _withdrawnCourses =>
      List<String>.from(_userData['withdrawnCourses'] ?? const []);

  // ---------------------------------------------------------------------------
  // Actions (using course picker)
  // ---------------------------------------------------------------------------

  Future<void> _addUpcomingCourseDialog() async {
    if (_loadingCourses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courses are still loading, please wait.'),
        ),
      );
      return;
    }

    if (_coursesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load courses: $_coursesError')),
      );
      return;
    }

    if (_courseOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No courses found in Firestore.')),
      );
      return;
    }

    _CourseOption? selectedCourse;
    _SectionOption? selectedSection;
    String searchQuery = '';

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            // Filter courses based on search query
            final lower = searchQuery.toLowerCase();
            final filteredCourses = _courseOptions.where((c) {
              if (lower.isEmpty) return true;
              return c.code.toLowerCase().contains(lower) ||
                  c.name.toLowerCase().contains(lower);
            }).toList();

            return AlertDialog(
              title: const Text('Add upcoming course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------- SEARCH BAR ----------
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search by code or name',
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // ---------- COURSE DROPDOWN ----------
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<_CourseOption>(
                        isExpanded: true,
                        initialValue: selectedCourse,
                        decoration: const InputDecoration(labelText: 'Course'),
                        items: filteredCourses
                            .map(
                              (c) => DropdownMenuItem<_CourseOption>(
                                value: c,
                                child: Text(
                                  '${c.code} – ${c.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedCourse = value;
                            final sections = selectedCourse?.sections ?? [];
                            selectedSection = sections.isNotEmpty
                                ? sections.first
                                : null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---------- SECTION DROPDOWN ----------
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<_SectionOption>(
                        isExpanded: true,
                        initialValue: selectedSection,
                        decoration: const InputDecoration(labelText: 'Section'),
                        items: (selectedCourse?.sections ?? [])
                            .map(
                              (s) => DropdownMenuItem<_SectionOption>(
                                value: s,
                                child: Text(
                                  'Sec ${s.id} – ${s.label}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedSection = value;
                          });
                        },
                      ),
                    ),

                    if (selectedCourse != null &&
                        (selectedCourse!.sections).isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'This course has no sections defined.\n'
                          'Please choose another course.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (selectedCourse == null || selectedSection == null)
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    if (selectedCourse == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick both course and section.')),
      );
      return;
    }

    try {
      await SuperAdminCourseOverrideService.instance.addUpcomingCourse(
        studentUid: widget.studentUid,
        courseCode: selectedCourse!.code,
        sectionId: selectedSection!.id,
      );
      await _loadStudent();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _openGradesApprovalSheet(String courseCode) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _SuperAdminGradesApprovalSheet(
          studentUid: widget.studentUid,
          studentName: widget.studentName,
          courseCode: courseCode,
        );
      },
    );
  }

  Future<void> _removeUpcomingCourse(String courseCode) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove upcoming course?'),
        content: Text('Remove $courseCode from upcoming courses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await SuperAdminCourseOverrideService.instance.removeUpcomingCourse(
        studentUid: widget.studentUid,
        courseCode: courseCode,
      );
      await _loadStudent();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _withdrawCurrentCourse(String courseCode) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw from course?'),
        content: Text(
          'Withdraw the student from $courseCode in the current semester?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await SuperAdminCourseOverrideService.instance.withdrawCurrentCourse(
        studentUid: widget.studentUid,
        courseCode: courseCode,
      );
      await _loadStudent();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final subtitle =
        'ID: ${widget.studentId} • UID: ${widget.studentUid.substring(0, 8)}…';

    final isLoading = _loadingStudent;

    return Scaffold(
      appBar: AppBar(title: Text('Course control – ${widget.studentName}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentError != null
          ? Center(child: Text(_studentError!, textAlign: TextAlign.center))
          : RefreshIndicator(
              onRefresh: () async {
                await _loadStudent();
                await _loadCourses();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingCourses)
                    const Text(
                      'Loading courses…',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    )
                  else if (_coursesError != null)
                    Text(
                      'Courses error: $_coursesError',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Upcoming courses
                  _sectionHeader(
                    title: 'Upcoming courses (next semester)',
                    actionLabel: 'Add',
                    onAction: _addUpcomingCourseDialog,
                  ),
                  if (_upcomingCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'No upcoming courses.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    )
                  else
                    ..._upcomingCourses.map(
                      (c) => ListTile(
                        dense: true,
                        title: Text(c),
                        subtitle: Text(
                          'Section: ${_upcomingSections[c]?.toString() ?? '—'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeUpcomingCourse(c),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Current enrolled
                  const Text(
                    'Current semester – enrolled courses',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (_enrolledCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'No courses currently enrolled.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    )
                  else
                    ..._enrolledCourses.map(
                      (c) => ListTile(
                        dense: true,
                        title: Text(c),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _openGradesApprovalSheet(c),
                              child: const Text(
                                'Grades',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Withdraw from this course',
                              onPressed: () => _withdrawCurrentCourse(c),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Withdrawn
                  const Text(
                    'Withdrawn courses (this semester)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (_withdrawnCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'No courses withdrawn yet.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    )
                  else
                    ..._withdrawnCourses.map(
                      (c) => ListTile(
                        dense: true,
                        title: Text(c),
                        leading: const Icon(
                          Icons.block,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for grades approval
// ---------------------------------------------------------------------------

class _SuperAdminGradesApprovalSheet extends StatelessWidget {
  final String studentUid;
  final String studentName;
  final String courseCode;

  const _SuperAdminGradesApprovalSheet({
    required this.studentUid,
    required this.studentName,
    required this.courseCode,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    final gradesRef = db
        .collection('users')
        .doc(studentUid)
        .collection('courses')
        .doc(courseCode)
        .collection('grades');

    final height = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Grades for $courseCode',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentName,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: gradesRef.orderBy('order').snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Error loading grades:\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No grades recorded yet for this course.',
                          style: TextStyle(fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();

                        final label =
                            (data['label'] ?? data['typeLabel'] ?? 'Unnamed')
                                .toString();
                        final score =
                            (data['score'] as num?)?.toDouble() ?? 0.0;
                        final maxScore =
                            (data['maxScore'] as num?)?.toDouble() ?? 0.0;

                        final confirmed = (data['confirmed'] ?? false) == true;
                        final submitted =
                            (data['submittedForApproval'] ?? false) == true;

                        final scoreStr = maxScore == 0
                            ? score.toStringAsFixed(1)
                            : '${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(1)}';

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
                          dense: true,
                          title: Text(
                            label,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            scoreStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          // 🔹 Only show the status chip, no Confirm button here
                          trailing: statusChip,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
