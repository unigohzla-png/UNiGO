import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/civil_person.dart';
import '../../models/faculty.dart';
import '../../models/major.dart';
import '../../models/professor.dart';
import '../../services/civil_registry_service.dart';
import '../../services/faculty_service.dart';
import '../../services/professor_service.dart';
import '../../services/super_admin_user_management_service.dart';

class SuperAdminCreateFromRegistryPage extends StatefulWidget {
  const SuperAdminCreateFromRegistryPage({super.key});

  @override
  State<SuperAdminCreateFromRegistryPage> createState() =>
      _SuperAdminCreateFromRegistryPageState();
}

class _SuperAdminCreateFromRegistryPageState
    extends State<SuperAdminCreateFromRegistryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nationalIdCtrl = TextEditingController();

  String _role = 'student';
  CivilPerson? _loadedPerson;
  bool _isLoading = false;
  bool _isCreating = false;
  String? _creationResult;

  // Academic data
  List<Faculty> _faculties = [];
  Faculty? _selectedFaculty;

  List<Major> _majors = [];
  Major? _selectedMajor;

  List<Professor> _advisors = [];
  Professor? _selectedAdvisor;

  bool _loadingFaculties = false;
  bool _loadingMajors = false;
  bool _loadingAdvisors = false;

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  // ====== LOADERS ======

  Future<void> _loadFaculties() async {
    setState(() {
      _loadingFaculties = true;
    });
    try {
      final items = await FacultyService.getFaculties();
      if (!mounted) return;
      setState(() {
        _faculties = items;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load faculties: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingFaculties = false;
        });
      }
    }
  }

  Future<void> _loadMajorsAndAdvisorsForFaculty(Faculty faculty) async {
    setState(() {
      _loadingMajors = true;
      _loadingAdvisors = true;
      _majors = [];
      _advisors = [];
      _selectedMajor = null;
      _selectedAdvisor = null;
    });

    try {
      final majors = await FacultyService.getMajorsForFaculty(faculty.id);
      final advisors = await ProfessorService.getAdvisors(
        facultyId: faculty.id,
      );

      if (!mounted) return;
      setState(() {
        _majors = majors;
        _advisors = advisors;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load majors/advisors: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingMajors = false;
          _loadingAdvisors = false;
        });
      }
    }
  }

  Future<void> _loadAdvisorsForMajor(Major major) async {
    if (_selectedFaculty == null) return;

    setState(() {
      _loadingAdvisors = true;
      _advisors = [];
      _selectedAdvisor = null;
    });

    try {
      final advisors = await ProfessorService.getAdvisors(
        facultyId: _selectedFaculty!.id,
        majorId: major.id,
      );
      if (!mounted) return;
      setState(() {
        _advisors = advisors;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load advisors: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingAdvisors = false;
        });
      }
    }
  }

  void _pickRandomAdvisor() {
    if (_advisors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No advisors available for selection.')),
      );
      return;
    }

    // choose advisor with smallest adviseesCount (simple balancing)
    _advisors.sort((a, b) => a.adviseesCount.compareTo(b.adviseesCount));
    setState(() {
      _selectedAdvisor = _advisors.first;
    });
  }

  @override
  void dispose() {
    _nationalIdCtrl.dispose();
    super.dispose();
  }

  // ====== CIVIL REGISTRY FETCH ======

  Future<void> _fetchPerson() async {
    setState(() {
      _isLoading = true;
      _loadedPerson = null;
      _creationResult = null;
    });

    try {
      final person = await CivilRegistryService.getByNationalId(
        _nationalIdCtrl.text.trim(),
      );

      if (!mounted) return;

      if (person == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No record found in civil registry.')),
        );
      } else {
        setState(() {
          _loadedPerson = person;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch record: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ====== CREATE USER ======

  Future<void> _createUser() async {
    if (_loadedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetch a civil record first.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFaculty == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a faculty.')));
      return;
    }
    if (_selectedMajor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a major.')));
      return;
    }
    if (_selectedAdvisor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an advisor.')));
      return;
    }

    final current = FirebaseAuth.instance.currentUser;
    final createdByUid = current?.uid;
    if (createdByUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged in super admin.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _creationResult = null;
    });

    try {
      final result = await SuperAdminUserManagementService.instance
          .createUserFromCivilRegistry(
            nationalId: _loadedPerson!.nationalId,
            role: _role,
            createdByUid: createdByUid,
            facultyId: _selectedFaculty!.id,
            facultyName: _selectedFaculty!.name,
            majorId: _selectedMajor!.id,
            majorName: _selectedMajor!.name,
            advisorId: _selectedAdvisor!.id,
            advisorName: _selectedAdvisor!.fullName,
          );

      if (!mounted) return;
      setState(() {
        _creationResult =
            'User created:\n'
            'UID: ${result.uid}\n'
            'University ID: ${result.universityId}\n'
            'Email: ${result.email}\n'
            'Initial password: ${result.password}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create user: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  // ====== UI ======

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create User from Civil Registry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side: form
            Expanded(
              flex: 2,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Step 1: Search civil record',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nationalIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'National ID (civil registry)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _fetchPerson,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Fetch from civil registry'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Step 2: UniGO account details',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _role, // fixes the deprecation warning
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'superAdmin',
                          child: Text('Super Admin'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _role = val;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Faculty
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedFaculty?.id,
                      decoration: const InputDecoration(
                        labelText: 'Faculty',
                        border: OutlineInputBorder(),
                      ),
                      items: _faculties
                          .map(
                            (f) => DropdownMenuItem<String>(
                              value: f.id,
                              child: Text(f.name),
                            ),
                          )
                          .toList(),
                      onChanged: _loadingFaculties
                          ? null
                          : (val) {
                              if (val == null) return;
                              final faculty = _faculties.firstWhere(
                                (f) => f.id == val,
                              );
                              setState(() {
                                _selectedFaculty = faculty;
                              });
                              _loadMajorsAndAdvisorsForFaculty(faculty);
                            },
                    ),
                    const SizedBox(height: 12),
                    // Major
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedMajor?.id,
                      decoration: const InputDecoration(
                        labelText: 'Major',
                        border: OutlineInputBorder(),
                      ),
                      items: _majors
                          .map(
                            (m) => DropdownMenuItem<String>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          )
                          .toList(),
                      onChanged: (_loadingMajors || _selectedFaculty == null)
                          ? null
                          : (val) {
                              if (val == null) return;
                              final major = _majors.firstWhere(
                                (m) => m.id == val,
                              );
                              setState(() {
                                _selectedMajor = major;
                              });
                              _loadAdvisorsForMajor(major);
                            },
                    ),
                    const SizedBox(height: 12),
                    // Advisor + random button
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedAdvisor?.id,
                            decoration: const InputDecoration(
                              labelText: 'Advisor',
                              border: OutlineInputBorder(),
                            ),
                            items: _advisors
                                .map(
                                  (p) => DropdownMenuItem<String>(
                                    value: p.id,
                                    child: Text(p.fullName),
                                  ),
                                )
                                .toList(),
                            onChanged: (_loadingAdvisors || _advisors.isEmpty)
                                ? null
                                : (val) {
                                    if (val == null) return;
                                    final prof = _advisors.firstWhere(
                                      (p) => p.id == val,
                                    );
                                    setState(() {
                                      _selectedAdvisor = prof;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Pick random advisor',
                          onPressed: _loadingAdvisors || _advisors.isEmpty
                              ? null
                              : _pickRandomAdvisor,
                          icon: const Icon(Icons.casino_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createUser,
                      icon: _isCreating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: const Text('Create UniGO user'),
                    ),
                    if (_creationResult != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _creationResult!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right side: preview
            Expanded(
              flex: 3,
              child: _loadedPerson == null
                  ? Center(
                      child: Text(
                        'No civil record loaded yet.\nSearch by National ID to preview.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Civil Record Preview',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),

                            // ===== BASIC IDENTIFIERS =====
                            _infoRow('Full name', _loadedPerson!.fullName),
                            _infoRow('National ID', _loadedPerson!.nationalId),
                            _infoRow('DOB', _loadedPerson!.dob ?? '-'),

                            // ===== ADDRESS / LOCATION =====
                            _infoRow(
                              'Location',
                              _loadedPerson!.location ?? '-',
                            ),
                            _infoRow(
                              'Birth place',
                              _loadedPerson!.placeOfBirth ?? '-',
                            ),
                            _infoRow(
                              'House address',
                              _loadedPerson!.houseAddress ?? '-',
                            ),

                            // ===== PAYMENT / PHONES =====
                            _infoRow(
                              'Payment number',
                              _loadedPerson!.paynum ?? '-',
                            ),
                            _infoRow(
                              'Phones',
                              _loadedPerson!.identifiers.isNotEmpty
                                  ? _loadedPerson!.identifiers.join(', ')
                                  : (_loadedPerson!.primaryPhone ?? '-'),
                            ),

                            // ===== FAMILY =====
                            _infoRow(
                              'Mother name',
                              _loadedPerson!.motherName ?? '-',
                            ),
                            _infoRow(
                              'Father name',
                              _loadedPerson!.fatherName ?? '-',
                            ),

                            const Divider(),

                            // ===== LINK STATUS =====
                            _infoRow(
                              'Linked uid',
                              _loadedPerson!.linkedUid ?? 'None',
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
