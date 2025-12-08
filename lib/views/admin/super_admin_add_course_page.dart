import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuperAdminAddCoursePage extends StatefulWidget {
  const SuperAdminAddCoursePage({super.key});

  @override
  State<SuperAdminAddCoursePage> createState() =>
      _SuperAdminAddCoursePageState();
}

class _SuperAdminAddCoursePageState extends State<SuperAdminAddCoursePage> {
  final _db = FirebaseFirestore.instance;

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController();

  final List<String> _courseTypes = const [
    'University Requirements',
    'University Electives',
    'Obligatory School Courses',
    'Elective School Courses',
  ];

  String _selectedType = 'Obligatory School Courses';

  // departments (same ones you already use in Firestore)
  final List<String> _allDepartments = const [
    'Computer Science',
    'Computer Information System',
    'Business Information Technology',
    'Artificial Intelligence ',
    'Cybersecurity ',
    'Data Science ',
  ];
  final Set<String> _selectedDepartments = {};

  // pre-requisites as course codes
  final TextEditingController _prereqCtrl = TextEditingController();
  final List<String> _prereqs = [];

  // sections
  final List<_SectionDraft> _sections = [
    _SectionDraft(), // start with one empty section
  ];

  bool _saving = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _creditsCtrl.dispose();
    _instructorCtrl.dispose();
    _prereqCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final creditsStr = _creditsCtrl.text.trim();
    final instructorName = _instructorCtrl.text.trim();

    if (code.isEmpty || name.isEmpty || creditsStr.isEmpty) {
      _showSnack('Code, name and credits are required.');
      return;
    }

    final credits = int.tryParse(creditsStr);
    if (credits == null || credits <= 0) {
      _showSnack('Credits must be a positive integer.');
      return;
    }

    if (_selectedDepartments.isEmpty) {
      _showSnack('Select at least one department.');
      return;
    }

    if (_sections.isEmpty) {
      _showSnack('Add at least one section.');
      return;
    }

    for (final s in _sections) {
      if (!s.isValid) {
        _showSnack(
          'Each section needs: ID, doctor name, location, at least one day, start time and end time.',
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      // build sections array
      final sectionsData = _sections
          .map((s) => {
                'id': s.id,
                'doctorName': s.doctorName,
                'location': s.location,
                'days': s.days,
                'startTime': s.startTime,
                'endTime': s.endTime,
              })
          .toList();

      final data = <String, dynamic>{
        'code': code, // store as string (doc id will also be code)
        'name': name,
        'credits': credits,
        'instructorName': instructorName,
        'type': _selectedType,
        'department': _selectedDepartments.toList(),
        'pre_Requisite': _prereqs,
        'sections': sectionsData,
      };

      final docRef = _db.collection('courses').doc(code);

      final existing = await docRef.get();
      if (existing.exists) {
        // simple safety check so you don't overwrite by mistake
        _showSnack('Course with code $code already exists.');
        setState(() => _saving = false);
        return;
      }

      await docRef.set(data);

      if (!mounted) return;
      _showSnack('Course created successfully.');
      Navigator.of(context).pop(); // go back to list
    } catch (e) {
      _showSnack('Failed to save course: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _addPrereqFromField() {
    final value = _prereqCtrl.text.trim();
    if (value.isEmpty) return;
    if (!_prereqs.contains(value)) {
      setState(() {
        _prereqs.add(value);
      });
    }
    _prereqCtrl.clear();
  }

  void _addSection() {
    setState(() {
      _sections.add(_SectionDraft());
    });
  }

  void _removeSection(int index) {
    if (_sections.length == 1) {
      _showSnack('You must have at least one section.');
      return;
    }
    setState(() {
      _sections.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new course'),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- basic course info ---
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Course code',
                      hintText: 'e.g. 1901101',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Course name',
                      hintText: 'Discrete Mathematics',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _creditsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      hintText: 'e.g. 3',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Default instructor name',
                      hintText: 'Dr. A',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- type ---
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Course type',
                    ),
                    items: _courseTypes
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedType = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- departments ---
                  const Text(
                    'Departments',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children: _allDepartments.map((dep) {
                      final selected = _selectedDepartments.contains(dep);
                      return FilterChip(
                        label: Text(dep.trim()),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedDepartments.add(dep);
                            } else {
                              _selectedDepartments.remove(dep);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // --- pre requisites ---
                  const Text(
                    'Pre-requisite courses (codes)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prereqCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Enter course code then press +',
                          ),
                          onSubmitted: (_) => _addPrereqFromField(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addPrereqFromField,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_prereqs.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _prereqs.map((code) {
                        return Chip(
                          label: Text(code),
                          onDeleted: () {
                            setState(() {
                              _prereqs.remove(code);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // --- sections ---
                  const Text(
                    'Sections',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_sections.length, (index) {
                      final section = _sections[index];
                      return _SectionCard(
                        index: index,
                        section: section,
                        onRemove: () => _removeSection(index),
                        onChanged: () => setState(() {}),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addSection,
                      icon: const Icon(Icons.add),
                      label: const Text('Add section'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveCourse,
                      child: const Text('Save course to Firestore'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionDraft {
  String id = '';
  String doctorName = '';
  String location = '';
  String startTime = ''; // "10:00"
  String endTime = ''; // "11:00"
  final Set<String> days = {}; // 'Sun', 'Mon', ...

  bool get isValid =>
      id.trim().isNotEmpty &&
      doctorName.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      startTime.trim().isNotEmpty &&
      endTime.trim().isNotEmpty &&
      days.isNotEmpty;
}

class _SectionCard extends StatelessWidget {
  final int index;
  final _SectionDraft section;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _SectionCard({
    required this.index,
    required this.section,
    required this.onRemove,
    required this.onChanged,
  });

  static const _weekDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Section ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Section ID (e.g. 1)',
              ),
              controller: TextEditingController(text: section.id)
                ..selection = TextSelection.collapsed(
                  offset: section.id.length,
                ),
              onChanged: (v) {
                section.id = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Doctor name',
              ),
              controller: TextEditingController(text: section.doctorName)
                ..selection = TextSelection.collapsed(
                  offset: section.doctorName.length,
                ),
              onChanged: (v) {
                section.doctorName = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Location (e.g. Lab 304)',
              ),
              controller: TextEditingController(text: section.location)
                ..selection = TextSelection.collapsed(
                  offset: section.location.length,
                ),
              onChanged: (v) {
                section.location = v;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Start time (e.g. 10:00)',
                    ),
                    controller: TextEditingController(text: section.startTime)
                      ..selection = TextSelection.collapsed(
                        offset: section.startTime.length,
                      ),
                    onChanged: (v) {
                      section.startTime = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'End time (e.g. 11:00)',
                    ),
                    controller: TextEditingController(text: section.endTime)
                      ..selection = TextSelection.collapsed(
                        offset: section.endTime.length,
                      ),
                    onChanged: (v) {
                      section.endTime = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Days',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: _weekDays.map((d) {
                final selected = section.days.contains(d);
                return FilterChip(
                  label: Text(d),
                  selected: selected,
                  onSelected: (v) {
                    if (v) {
                      section.days.add(d);
                    } else {
                      section.days.remove(d);
                    }
                    onChanged();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
