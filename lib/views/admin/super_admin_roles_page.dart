import 'package:flutter/material.dart';

import '../../services/super_admin_user_management_service.dart';

class SuperAdminRolesPage extends StatefulWidget {
  const SuperAdminRolesPage({super.key});

  @override
  State<SuperAdminRolesPage> createState() => _SuperAdminRolesPageState();
}

class _SuperAdminRolesPageState extends State<SuperAdminRolesPage> {
  final _service = SuperAdminUserManagementService.instance;

  bool _loading = true;
  bool _busy = false; // for inline operations (change role / delete)
  String _search = '';

  List<ManagedUserSummary> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
    });

    try {
      final users = await _service.loadUsersWithRoles();
      setState(() {
        _users = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<ManagedUserSummary> get _filteredUsers {
    if (_search.trim().isEmpty) return _users;
    final q = _search.trim().toLowerCase();
    return _users.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.id.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _changeRole(ManagedUserSummary user, String newRole) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      await _service.setUserRole(uid: user.uid, role: newRole);
      // update local list
      setState(() {
        final idx = _users.indexWhere((u) => u.uid == user.uid);
        if (idx != -1) {
          _users[idx] = ManagedUserSummary(
            uid: user.uid,
            name: user.name,
            email: user.email,
            id: user.id,
            role: newRole,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $newRole for ${user.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteUser(ManagedUserSummary user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Are you sure you want to delete "${user.name}" '
          'and all of their data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await _service.deleteUserDataFirestore(user.uid);
      setState(() {
        _users.removeWhere((u) => u.uid == user.uid);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User "${user.name}" deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _showCreateUserDialog() async {
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final majorCtrl = TextEditingController();
    final departmentCtrl = TextEditingController();
    String selectedRole = 'student';

    final createdPassword = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('Create new user'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g. Hamzeh Ahmad Ali Alsyouf',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'student@example.edu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: idCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'University ID',
                        hintText: 'e.g. 8110211720',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: majorCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Major',
                        hintText: 'e.g. Computer Science',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: departmentCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Faculty / Department',
                        hintText:
                            'e.g. King Abdullah II School of Information Technology',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Role:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: selectedRole,
                          items: const [
                            DropdownMenuItem(
                              value: 'student',
                              child: Text('Student'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'superAdmin',
                              child: Text('Super Admin'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setLocalState(() {
                              selectedRole = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final fullName = fullNameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final uniId = idCtrl.text.trim();
                    final major = majorCtrl.text.trim();
                    final dept = departmentCtrl.text.trim();

                    if (fullName.isEmpty ||
                        email.isEmpty ||
                        uniId.isEmpty ||
                        major.isEmpty ||
                        dept.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    try {
                      final password = await _service.createUserFirestoreOnly(
                        fullName: fullName,
                        email: email,
                        universityId: uniId,
                        major: major,
                        department: dept,
                        role: selectedRole,
                      );

                      Navigator.of(ctx).pop(password);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create user: $e')),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (createdPassword != null) {
      // Reload users list so the new user appears
      await _loadUsers();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('User created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The user has been created in Firestore.\n\n'
                'Temporary password:',
              ),
              const SizedBox(height: 8),
              SelectableText(
                createdPassword,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Please share this password securely with the user.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Users'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _showCreateUserDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add user'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, email, or ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _search = val;
                });
              },
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (users.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No users found.\nUse "Add user" to create a new account.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(
                      user.name.isEmpty ? '(No name)' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${user.email.isEmpty ? 'No email' : user.email} · '
                      'ID: ${user.id.isEmpty ? '—' : user.id}',
                    ),
                    leading: CircleAvatar(
                      child: Text(
                        user.name.isEmpty
                            ? '?'
                            : user.name.characters.first.toUpperCase(),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: user.role,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'student',
                              child: Text('Student'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'superAdmin',
                              child: Text('Super Admin'),
                            ),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value == null || value == user.role) {
                                    return;
                                  }
                                  _changeRole(user, value);
                                },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: _busy ? null : () => _deleteUser(user),
                          tooltip: 'Delete user',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
