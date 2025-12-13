import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SuperAdminProfessorDetailsPage extends StatefulWidget {
  final String facultyId;
  final String professorId;
  final String initialName;

  const SuperAdminProfessorDetailsPage({
    super.key,
    required this.facultyId,
    required this.professorId,
    required this.initialName,
  });

  @override
  State<SuperAdminProfessorDetailsPage> createState() =>
      _SuperAdminProfessorDetailsPageState();
}

class _SuperAdminProfessorDetailsPageState
    extends State<SuperAdminProfessorDetailsPage> {
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;

  // Editable fields
  bool _active = true;
  bool _canAdvise = false;
  int _maxAdvisees = 0;

  late TextEditingController _maxAdviseesCtrl;

  List<String> _selectedMajorIds = [];
  List<String> _selectedMajorNames = [];
  List<String> _selectedCourseCodes = [];

  // For UI lists
  List<_MajorItem> _allMajors = [];
  List<_CourseItem> _allCourses = [];

  // Static info
  String _fullName = '';
  String _email = '';
  int _adviseesCount = 0;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _maxAdviseesCtrl = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Load professor doc
      final profRef = _db
          .collection('faculties')
          .doc(widget.facultyId)
          .collection('professors')
          .doc(widget.professorId);

      final profSnap = await profRef.get();
      if (!profSnap.exists) {
        setState(() {
          _error = 'Professor document not found.';
          _loading = false;
        });
        return;
      }

      final data = profSnap.data() as Map<String, dynamic>;
      _fullName =
          (data['fullName'] ?? data['name'] ?? widget.initialName).toString();
      _email = (data['email'] ?? '').toString();
      _active = (data['active'] ?? true) as bool;
      _canAdvise = (data['canAdvise'] ?? false) as bool;
      _adviseesCount = (data['adviseesCount'] ?? 0) as int;

      _maxAdvisees = (data['maxAdvisees'] ?? 0) is int
          ? data['maxAdvisees'] as int
          : int.tryParse(data['maxAdvisees']?.toString() ?? '0') ?? 0;

      _maxAdviseesCtrl.text =
          _maxAdvisees > 0 ? _maxAdvisees.toString() : '';

      _selectedMajorIds =
          (data['majorIds'] as List?)?.cast<String>() ?? <String>[];

      _selectedMajorNames =
          (data['majorNames'] as List?)?.cast<String>() ?? <String>[];

      _selectedCourseCodes = (data['assignedCourseCodes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      // 2) Load majors list
      final majorsSnap = await _db
          .collection('faculties')
          .doc(widget.facultyId)
          .collection('majors')
          .orderBy('name')
          .get();

      _allMajors = majorsSnap.docs
          .map((d) => _MajorItem(
                id: d.id,
                name: (d.data()['name'] ?? d.id).toString(),
              ))
          .toList();

      // 3) Load courses for this faculty
      final coursesSnap = await _db
          .collection('courses')
          .where('facultyId', isEqualTo: widget.facultyId)
          .orderBy('code')
          .get();

      _allCourses = coursesSnap.docs
          .map((d) => _CourseItem(
                code: (d.data()['code'] ?? d.id).toString(),
                name: (d.data()['name'] ?? d.id).toString(),
              ))
          .toList();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_saving) return;

    final maxText = _maxAdviseesCtrl.text.trim();
    int maxAdv = 0;
    if (maxText.isNotEmpty) {
      final parsed = int.tryParse(maxText);
      if (parsed == null || parsed < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max advisees must be a positive number.'),
          ),
        );
        return;
      }
      maxAdv = parsed;
    }

    setState(() {
      _saving = true;
    });

    try {
      final profRef = _db
          .collection('faculties')
          .doc(widget.facultyId)
          .collection('professors')
          .doc(widget.professorId);

      await profRef.set(
        {
          'active': _active,
          'canAdvise': _canAdvise,
          'maxAdvisees': maxAdv,
          'majorIds': _selectedMajorIds,
          'majorNames': _selectedMajorNames,
          'assignedCourseCodes': _selectedCourseCodes,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic staff info updated.')),
      );
      Navigator.of(context).pop(); // back to list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickMajors() async {
    if (_allMajors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No majors found for this faculty.')),
      );
      return;
    }

    final selectedIds = Set<String>.from(_selectedMajorIds);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select majors'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allMajors.length,
              itemBuilder: (context, index) {
                final m = _allMajors[index];
                final checked = selectedIds.contains(m.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(m.name),
                  onChanged: (val) {
                    if (val == true) {
                      selectedIds.add(m.id);
                    } else {
                      selectedIds.remove(m.id);
                    }
                    setState(() {}); // update temp UI
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    // After dialog:
    final newIds = selectedIds.toList();
    final newNames = _allMajors
        .where((m) => selectedIds.contains(m.id))
        .map((m) => m.name)
        .toList();

    setState(() {
      _selectedMajorIds = newIds;
      _selectedMajorNames = newNames;
    });
  }

  Future<void> _pickCourses() async {
    if (_allCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No courses found for this faculty.')),
      );
      return;
    }

    final selectedCodes = Set<String>.from(_selectedCourseCodes);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign courses'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allCourses.length,
              itemBuilder: (context, index) {
                final c = _allCourses[index];
                final checked = selectedCodes.contains(c.code);
                return CheckboxListTile(
                  value: checked,
                  title: Text('${c.code} – ${c.name}'),
                  onChanged: (val) {
                    if (val == true) {
                      selectedCodes.add(c.code);
                    } else {
                      selectedCodes.remove(c.code);
                    }
                    setState(() {});
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    setState(() {
      _selectedCourseCodes = selectedCodes.toList();
    });
  }

  @override
  void dispose() {
    _maxAdviseesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.initialName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.initialName)),
        body: Center(
          child: Text(
            'Error:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_fullName.isEmpty ? widget.initialName : _fullName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Basic info =====
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ActiveDot(active: _active),
                        const SizedBox(width: 16),
                        Text(
                          'Advisees: $_adviseesCount / $_maxAdvisees',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Majors =====
            const Text(
              'Majors',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMajorNames.isNotEmpty
                  ? _selectedMajorNames
                      .map(
                        (m) => Chip(
                          label: Text(m),
                        ),
                      )
                      .toList()
                  : [
                      const Text(
                        'No majors selected.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      )
                    ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickMajors,
                icon: const Icon(Icons.edit),
                label: const Text('Edit majors'),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Advising =====
            const Text(
              'Advising',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _canAdvise,
              title: const Text('Can advise students'),
              subtitle: const Text(
                'If enabled, this professor can be assigned advisees.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _canAdvise = val;
                });
              },
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _maxAdviseesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max advisees',
                hintText: 'e.g. 20',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Assigned courses =====
            const Text(
              'Assigned courses',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedCourseCodes.isEmpty)
              const Text(
                'No courses assigned.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedCourseCodes.map((code) {
                  final course = _allCourses
                      .firstWhere(
                        (c) => c.code == code,
                        orElse: () => _CourseItem(code: code, name: ''),
                      );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${course.code} – ${course.name}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickCourses,
                icon: const Icon(Icons.edit),
                label: const Text('Assign courses'),
              ),
            ),

            const SizedBox(height: 24),

            // ===== Active toggle =====
            SwitchListTile(
              value: _active,
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive professors are hidden from new assignments.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (val) {
                setState(() {
                  _active = val;
                });
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  final bool active;

  const _ActiveDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.redAccent;
    final label = active ? 'Active' : 'Inactive';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MajorItem {
  final String id;
  final String name;

  _MajorItem({required this.id, required this.name});
}

class _CourseItem {
  final String code;
  final String name;

  _CourseItem({required this.code, required this.name});
}
