import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  QuerySnapshot<Map<String, dynamic>>? _results;
  bool _loading = false;
  String? _error;

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

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Query<Map<String, dynamic>> query;

      // If numeric -> search by university ID
      final idNum = int.tryParse(q);
      if (idNum != null) {
        query = _db.collection('users').where('id', isEqualTo: idNum);
      } else if (q.contains('@')) {
        // looks like email
        query = _db.collection('users').where('email', isEqualTo: q);
      } else {
        // fallback: name prefix search (simple)
        query = _db
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: q)
            .where('name', isLessThanOrEqualTo: '$q\uf8ff');
      }

      final snap = await query.limit(20).get();

      setState(() {
        _results = snap;
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
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loading ? null : _search,
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Expanded(
            child: _results == null
                ? const Center(
                    child: Text('Search for a student to edit their window'),
                  )
                : _results!.docs.isEmpty
                ? const Center(child: Text('No students found for this query.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _results!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = _results!.docs[index];
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
  })
  updateWindow;

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
    final winRef = db.collection('registrationWindows').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: winRef.snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final startTs = data?['startAt'] as Timestamp?;
        final endTs = data?['endAt'] as Timestamp?;
        final startAt = startTs?.toDate();
        final endAt = endTs?.toDate();

        return Material(
          color: Colors.white,
          elevation: 1,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Start:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fmt(startAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await pickDateTime(startAt);
                        if (picked != null) {
                          await updateWindow(
                            uid: uid,
                            startAt: picked,
                            endAt: endAt,
                          );
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('End:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fmt(endAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await pickDateTime(endAt);
                        if (picked != null) {
                          await updateWindow(
                            uid: uid,
                            startAt: startAt,
                            endAt: picked,
                          );
                        }
                      },
                      child: const Text('Change'),
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
