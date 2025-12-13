import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/role_service.dart';
import 'super_admin_professor_details_page.dart';

class SuperAdminAcademicStaffPage extends StatefulWidget {
  const SuperAdminAcademicStaffPage({super.key});

  @override
  State<SuperAdminAcademicStaffPage> createState() =>
      _SuperAdminAcademicStaffPageState();
}

class _SuperAdminAcademicStaffPageState
    extends State<SuperAdminAcademicStaffPage> {
  final _db = FirebaseFirestore.instance;
  final _roleService = RoleService();

  String? _facultyId;
  String? _facultyError;
  bool _loadingFaculty = true;

  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  Future<void> _loadFaculty() async {
    try {
      final id = await _roleService.getCurrentFacultyId();
      if (!mounted) return;
      if (id == null || id.trim().isEmpty) {
        setState(() {
          _facultyError = 'No faculty assigned to this account.';
          _loadingFaculty = false;
        });
        return;
      }
      setState(() {
        _facultyId = id.trim();
        _loadingFaculty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _facultyError = e.toString();
        _loadingFaculty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFaculty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Academic Staff')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_facultyError != null || _facultyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Academic Staff')),
        body: Center(
          child: Text(
            'Error loading faculty:\n${_facultyError ?? "Unknown error"}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final profsCol = _db
        .collection('faculties')
        .doc(_facultyId)
        .collection('professors')
        .orderBy('fullName');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Staff'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search professors by name or email',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: profsCol.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading professors:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                // Local filter by search
                if (_search.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data();
                    final name =
                        (data['fullName'] ?? data['name'] ?? '').toString();
                    final email = (data['email'] ?? '').toString();
                    return name.toLowerCase().contains(_search) ||
                        email.toLowerCase().contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No professors found for this faculty.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final fullName =
                        (data['fullName'] ?? data['name'] ?? 'Unnamed')
                            .toString();
                    final email =
                        (data['email'] ?? 'no-email@unknown').toString();
                    final active = (data['active'] ?? true) as bool;
                    final majorNames =
                        (data['majorNames'] as List?)?.cast<String>() ??
                            (data['majorIds'] as List?)?.cast<String>() ??
                            const <String>[];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          fullName.isNotEmpty
                              ? fullName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          email,
                          if (majorNames.isNotEmpty)
                            'Majors: ${majorNames.join(", ")}',
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _ActiveDot(active: active),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SuperAdminProfessorDetailsPage(
                              facultyId: _facultyId!,
                              professorId: doc.id,
                              initialName: fullName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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
