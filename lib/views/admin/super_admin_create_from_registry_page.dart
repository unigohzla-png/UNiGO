import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../services/role_service.dart';

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

  // Role of the user we are creating
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

  // Faculty scope for this super admin
  final RoleService _roleService = RoleService();
  String? _currentFacultyId;
  bool _loadingFacultyScope = true;

  @override
  void initState() {
    super.initState();
    _initFacultyScope();
  }

  @override
  void dispose() {
    _nationalIdCtrl.dispose();
    super.dispose();
  }

  /// Determine which faculty this super admin belongs to and
  /// restrict the faculties list to that single faculty.
  Future<void> _initFacultyScope() async {
    setState(() {
      _loadingFacultyScope = true;
    });

    final facultyId = await _roleService.getCurrentFacultyId();

    if (!mounted) return;

    if (facultyId == null || facultyId.isEmpty) {
      // Fallback: no faculty assigned → load all faculties (old behaviour)
      await _loadFaculties();
      if (!mounted) return;
      setState(() {
        _currentFacultyId = null;
        _loadingFacultyScope = false;
      });
      return;
    }

    _currentFacultyId = facultyId;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('faculties')
          .doc(facultyId)
          .get();

      if (!doc.exists) {
        // If faculty document is missing, fallback to all
        await _loadFaculties();
      } else {
        final faculty = Faculty.fromDoc(doc);

        setState(() {
          _faculties = [faculty];
          _selectedFaculty = faculty;
        });

        // Automatically load majors/advisors for this faculty
        await _loadMajorsForFaculty(faculty);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingFacultyScope = false;
        });
      }
    }
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

  Future<void> _loadMajorsForFaculty(Faculty faculty) async {
    setState(() {
      _loadingMajors = true;
      _majors = [];
      _selectedMajor = null;
      _advisors = [];
      _selectedAdvisor = null;
    });

    try {
      final majors = await FacultyService.getMajorsForFaculty(faculty.id);
      if (!mounted) return;
      setState(() {
        _majors = majors;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load majors: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loadingMajors = false;
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

    _advisors.shuffle();
    setState(() {
      _selectedAdvisor = _advisors.first;
    });
  }

  // ====== CIVIL REGISTRY ======

  Future<void> _fetchPerson() async {
    if (_nationalIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a national ID first.')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch from civil registry: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ====== CREATE USER ======

  Future<void> _queueWelcomeEmail({
    required String toEmail,
    required CreatedUserFromCivilResult result,
    required String fullName,
  }) async {
    final subject = 'Welcome to UniGo 🎓';
    final loginEmail = result.email;
    final tempPassword = result.password;
    final uniId = result.universityId;

    final docRef = await FirebaseFirestore.instance.collection('mail').add({
      'to': [toEmail],
      'message': {
        'subject': subject,
        'text':
            'Hello $fullName,\n\n'
            'Your UniGo account has been created.\n\n'
            'Uni ID: $uniId\n'
            'UniGo Login Email: $loginEmail\n'
            'Temporary Password: $tempPassword\n\n'
            'Please log in and change your password after the first login.\n',
        'html':
            '<p>Hello <b>$fullName</b>,</p>'
            '<p>Your UniGo account has been created.</p>'
            '<p><b>Uni ID:</b> $uniId<br/>'
            '<b>UniGo Login Email:</b> $loginEmail<br/>'
            '<b>Temporary Password:</b> $tempPassword</p>'
            '<p>Please log in and change your password after the first login.</p>',
      },
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ mail queued: ${docRef.id}');
  }

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

    // Role-specific validation
    if (_role == 'student') {
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
    } else if (_role == 'admin' || _role == 'superAdmin') {
      // For professors/admins we still want at least one major
      if (_selectedMajor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one major.')),
        );
        return;
      }
      // Advisor is NOT required for admins
    }

    final current = FirebaseAuth.instance.currentUser;
    final createdByUid = current?.uid;
    if (createdByUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in super admin.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _creationResult = null;
    });

    try {
      final svc = SuperAdminUserManagementService.instance;

      CreatedUserFromCivilResult result;

      if (_role == 'student') {
        // Existing student flow
        result = await svc.createUserFromCivilRegistry(
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
      } else {
        // New admin/professor (and optionally super admin) flow
        final majorsIds = <String>[_selectedMajor!.id];
        final majorsNames = <String>[_selectedMajor!.name];

        result = await svc.createAdminFromCivilRegistry(
          nationalId: _loadedPerson!.nationalId,
          createdByUid: createdByUid,
          facultyId: _selectedFaculty!.id,
          facultyName: _selectedFaculty!.name,
          majorIds: majorsIds,
          majorNames: majorsNames,
          isSuperAdmin: _role == 'superAdmin',
        );
      }
      final toEmail = (_loadedPerson!.email ?? '').trim();
      debugPrint('📩 Civil email = "$toEmail"');

      if (toEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email found in Civil Registry for this person.'),
          ),
        );
      } else {
        try {
          await _queueWelcomeEmail(
            toEmail: toEmail,
            result: result,
            fullName: _loadedPerson!.fullName,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome email queued ✅')),
          );
        } catch (e) {
          debugPrint('❌ Email queue failed: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Email queue failed: $e')));
        }
      }

      if (!mounted) return;
      setState(() {
        _creationResult =
            'User created:\n'
            'Uni ID: ${result.universityId}\n'
            'Email: ${result.email}\n'
            'Temp password: ${result.password}';
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

  // ====== UI BUILDERS ======

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create From Civil Registry')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNationalIdCard(),
                const SizedBox(height: 16),
                if (_loadedPerson != null) _buildCivilInfoCard(),
                const SizedBox(height: 16),
                _buildAcademicSection(),
                const SizedBox(height: 24),
                _buildCreateButton(),
                if (_creationResult != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Result',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _creationResult!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNationalIdCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Civil Registry',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nationalIdCtrl,
              decoration: const InputDecoration(
                labelText: 'National ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                final trimmed = val?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'National ID is required';
                }
                if (trimmed.length < 5) {
                  return 'Enter a valid national ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchPerson,
                icon: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Fetch from registry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCivilInfoCard() {
    final person = _loadedPerson!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Civil Record',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Full name', person.fullName),
            _buildInfoRow('National ID', person.nationalId),
            if (person.email != null) _buildInfoRow('Email', person.email!),
            if (person.dob != null) _buildInfoRow('Date of birth', person.dob!),
            if (person.location != null)
              _buildInfoRow('Location', person.location!),
            if (person.houseAddress != null)
              _buildInfoRow('Address', person.houseAddress!),
            if (person.primaryPhone != null)
              _buildInfoRow('Phone', person.primaryPhone!),
            if (person.motherName != null)
              _buildInfoRow('Mother', person.motherName!),
            if (person.fatherName != null)
              _buildInfoRow('Father', person.fatherName!),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic assignment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Role selector
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text('Admin (faculty staff)'),
                ),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _role = val;

                  // ✅ If not student, advisor is not used
                  if (_role != 'student') {
                    _selectedAdvisor = null;
                    _advisors = [];
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true, // 👈 important
              initialValue: _selectedFaculty?.id,
              decoration: const InputDecoration(
                labelText: 'Faculty',
                border: OutlineInputBorder(),
              ),
              items: _faculties
                  .map(
                    (f) => DropdownMenuItem<String>(
                      value: f.id,
                      child: Text(
                        f.name,
                        overflow: TextOverflow.ellipsis, // 👈 avoid overflow
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (_loadingFaculties || _currentFacultyId != null)
                  ? null
                  : (val) {
                      if (val == null) return;
                      final faculty = _faculties.firstWhere((f) => f.id == val);
                      setState(() {
                        _selectedFaculty = faculty;
                      });
                      _loadMajorsForFaculty(faculty);
                    },
            ),
            if (_loadingFaculties)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 12),
            // Majors
            // ===== Major =====
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedMajor?.id,
              decoration: const InputDecoration(
                labelText: 'Major',
                border: OutlineInputBorder(),
              ),
              items: _majors
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: _loadingMajors
                  ? null
                  : (val) {
                      if (val == null) return;
                      final major = _majors.firstWhere((m) => m.id == val);
                      setState(() {
                        _selectedMajor = major;

                        // ✅ reset advisor when changing major (only for students)
                        if (_role == 'student') {
                          _selectedAdvisor = null;
                          _advisors = [];
                        }
                      });

                      // ✅ only students need advisors
                      if (_role == 'student') {
                        _loadAdvisorsForMajor(major);
                      }
                    },
            ),
            if (_loadingMajors)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 12),
            if (_role == 'student') ...[
              const SizedBox(height: 12),

              // ===== Advisor =====
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedAdvisor?.id,
                decoration: const InputDecoration(
                  labelText: 'Advisor',
                  border: OutlineInputBorder(),
                ),
                items: _advisors
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(
                          p.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _loadingAdvisors
                    ? null
                    : (val) {
                        if (val == null) return;
                        final prof = _advisors.firstWhere((p) => p.id == val);
                        setState(() {
                          _selectedAdvisor = prof;
                        });
                      },
              ),
              if (_loadingAdvisors)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _advisors.isEmpty || _loadingAdvisors
                      ? null
                      : _pickRandomAdvisor,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Pick random advisor'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _isCreating ? null : _createUser,
        icon: _isCreating
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add),
        label: const Text('Create user'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
