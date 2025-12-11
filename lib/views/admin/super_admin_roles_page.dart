import 'package:flutter/material.dart';

import '../../services/super_admin_user_management_service.dart';
import '../../services/role_service.dart';

class SuperAdminRolesPage extends StatefulWidget {
  const SuperAdminRolesPage({super.key});

  @override
  State<SuperAdminRolesPage> createState() => _SuperAdminRolesPageState();
}

class _SuperAdminRolesPageState extends State<SuperAdminRolesPage> {
  final _service = SuperAdminUserManagementService.instance;

  bool _loading = true;
  bool _busy = false; // for change role / delete operations
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
      final roleService = RoleService();
      final facultyId = await roleService.getCurrentFacultyId();

      if (facultyId == null || facultyId.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No faculty assigned to this account.'),
            ),
          );
        }
        if (mounted) {
          setState(() {
            _users = [];
          });
        }
        return;
      }

      final users =
          await _service.loadUsersWithRoles(facultyId: facultyId.trim());
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to change role: $e')));
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
    if (_busy) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Are you sure you want to delete "${user.name.isEmpty ? user.email : user.name}"?\n'
          'This will remove their user document and role.\n\n'
          'Auth account and other references (like grades, calendar events, etc.) '
          'are NOT automatically cleaned.',
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

    setState(() {
      _busy = true;
    });

    try {
      await _service.hardDeleteUser(uid: user.uid);
      if (mounted) {
        setState(() {
          _users.removeWhere((u) => u.uid == user.uid);
        });
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
      // No FAB – creation is via "Create from registry"
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
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (users.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No users found for this faculty.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
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
                  final leadingLetter = user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : (user.email.isNotEmpty
                          ? user.email[0].toUpperCase()
                          : '?');

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(leadingLetter),
                    ),
                    title: Text(
                      user.name.isEmpty ? '(No name)' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${user.email.isEmpty ? "No email" : user.email} · '
                      'ID: ${user.id.isEmpty ? "—" : user.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              : (val) {
                                  if (val == null || val == user.role) return;
                                  _changeRole(user, val);
                                },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed:
                              _busy ? null : () => _deleteUser(user),
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
