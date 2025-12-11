import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/role_service.dart';

class SuperAdminStudentWindowPage extends StatefulWidget {
  const SuperAdminStudentWindowPage({super.key});

  @override
  State<SuperAdminStudentWindowPage> createState() =>
      _SuperAdminStudentWindowPageState();
}

class _SuperAdminStudentWindowPageState
    extends State<SuperAdminStudentWindowPage> {
  final _db = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  final RoleService _roleService = RoleService();

  String? _facultyId;
  bool _facultyLoading = true;
  String? _facultyError;

  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _results;
  bool _loading = false;
  String? _error;

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
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = null;
        _error = null;
      });
      return;
    }

    if (_facultyLoading) {
      // still loading faculty info, avoid firing query
      return;
    }
    if (_facultyId == null || _facultyId!.isEmpty) {
      setState(() {
        _error = 'No faculty assigned to this account.';
        _results = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // base: only students from this faculty
      Query<Map<String, dynamic>> baseQuery = _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('facultyId', isEqualTo: _facultyId);

      final snap = await baseQuery.limit(200).get();

      final qLower = q.toLowerCase();
      final filtered = snap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? data['fullName'] ?? '')
            .toString()
            .toLowerCase();
        final email =
            (data['email'] ?? '').toString().toLowerCase();
        final idStr = (data['id'] ?? data['universityId'] ?? '')
            .toString()
            .toLowerCase();

        return name.contains(qLower) ||
            email.contains(qLower) ||
            idStr.contains(qLower);
      }).toList();

      // sort alphabetically by name for nice UX
      filtered.sort((a, b) {
        final an = (a.data()['name'] ?? a.data()['fullName'] ?? '')
            .toString()
            .toLowerCase();
        final bn = (b.data()['name'] ?? b.data()['fullName'] ?? '')
            .toString()
            .toLowerCase();
        return an.compareTo(bn);
      });

      setState(() {
        _results = filtered;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? current) async {
    final initial = current ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return DateTime(date.year, date.month, date.day);
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _updateWindow({
    required String uid,
    required DateTime? startAt,
    required DateTime? endAt,
  }) async {
    final ref = _db.collection('registrationWindows').doc(uid);

    final data = <String, dynamic>{};
    if (startAt != null) {
      data['startAt'] = Timestamp.fromDate(startAt);
    }
    if (endAt != null) {
      data['endAt'] = Timestamp.fromDate(endAt);
    }

    await ref.set(data, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Window updated')));
  }

  String _fmtDateTime(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_facultyLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student registration windows')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_facultyError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student registration windows')),
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
        appBar: AppBar(title: const Text('Student registration windows')),
        body: const Center(
          child: Text(
            'No faculty assigned to this account.\nPlease set facultyId in roles/{uid}.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Student registration windows')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by ID, email, or name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Search'),
                  onPressed: _loading ? null : _search,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _results == null
                ? const Center(
                    child: Text('Search for a student to edit their window'),
                  )
                : _results!.isEmpty
                    ? const Center(child: Text('No students found for this query.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _results!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = _results![index];
                          final data = doc.data();
                          final uid = doc.id;
                          final name = (data['name'] ?? 'Unknown') as String;
                          final id = (data['id'] ?? '').toString();
                          final email = (data['email'] ?? '') as String;

                          return _StudentWindowTile(
                            uid: uid,
                            name: name,
                            id: id,
                            email: email,
                            db: _db,
                            fmt: _fmtDateTime,
                            pickDateTime: _pickDateTime,
                            updateWindow: _updateWindow,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StudentWindowTile extends StatelessWidget {
  final String uid;
  final String name;
  final String id;
  final String email;
  final FirebaseFirestore db;
  final String Function(DateTime?) fmt;
  final Future<DateTime?> Function(DateTime?) pickDateTime;
  final Future<void> Function({
    required String uid,
    required DateTime? startAt,
    required DateTime? endAt,
  }) updateWindow;

  const _StudentWindowTile({
    required this.uid,
    required this.name,
    required this.id,
    required this.email,
    required this.db,
    required this.fmt,
    required this.pickDateTime,
    required this.updateWindow,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: db.collection('registrationWindows').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        DateTime? startAt;
        DateTime? endAt;

        if (data != null) {
          final s = data['startAt'];
          if (s is Timestamp) startAt = s.toDate();
          final e = data['endAt'];
          if (e is Timestamp) endAt = e.toDate();
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (id.isNotEmpty) 'ID: $id',
                              if (email.isNotEmpty) email,
                            ].join(' • '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start at',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmt(startAt),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End at',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmt(endAt),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final newStart = await pickDateTime(startAt);
                          if (newStart != null) {
                            await updateWindow(
                              uid: uid,
                              startAt: newStart,
                              endAt: endAt,
                            );
                          }
                        },
                        child: const Text('Set start'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final newEnd = await pickDateTime(endAt);
                          if (newEnd != null) {
                            await updateWindow(
                              uid: uid,
                              startAt: startAt,
                              endAt: newEnd,
                            );
                          }
                        },
                        child: const Text('Set end'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await updateWindow(
                          uid: uid,
                          startAt: null,
                          endAt: null,
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
