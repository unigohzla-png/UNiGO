import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


/// Super admin – manage courses & their availability next semester.
class SuperAdminCoursesPage extends StatelessWidget {
  const SuperAdminCoursesPage({super.key});

  CollectionReference<Map<String, dynamic>> get _coursesCol =>
      FirebaseFirestore.instance.collection('courses');

  Future<void> _showCreateCourseDialog(BuildContext context) async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');
    final typeCtrl = TextEditingController();

    bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create new course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Course code',
                    hintText: 'e.g. 1901101',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course name',
                    hintText: 'e.g. Discrete Mathematics',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: creditsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Credits',
                    hintText: 'e.g. 3',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    hintText: 'e.g. Elective Speciality Courses',
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final code = codeCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final credits = int.tryParse(creditsCtrl.text.trim());
    final type = typeCtrl.text.trim();

    if (code.isEmpty || name.isEmpty || credits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill code, name and valid credits'),
        ),
      );
      return;
    }

    // Write course doc: courses/{code}
    await _coursesCol.doc(code).set({
      'code': code,
      'name': name,
      'credits': credits,
      'type': type,
      'availableNextSemester': true, // default ON
      // you can later add sections, pre_Requisite, department, etc.
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses & sections')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _coursesCol.orderBy('code').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error loading courses:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No courses found.\nUse the + button to create a course.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final code = data['code']?.toString() ?? doc.id;
              final name = (data['name'] ?? 'Untitled course') as String;
              final credits = data['credits'];
              final type = (data['type'] ?? '') as String;

              // 👇 our flag – default false if missing
              final bool availableNextSemester =
                  (data['availableNextSemester'] ?? false) == true;

              return Material(
                color: Colors.white,
                elevation: 1,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    '$code – $name',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (credits != null) 'Credits: $credits',
                      if (type.isNotEmpty) type,
                    ].join(' • '),
                    style: const TextStyle(fontSize: 12),
                  ),
                  // TODO: you can add onTap later to open a full "edit course" page.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Next sem', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Switch(
                        value: availableNextSemester,
                        onChanged: (value) async {
                          await doc.reference.update({
                            'availableNextSemester': value,
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCourseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
