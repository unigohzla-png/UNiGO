import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/plan_section.dart';

class PlanSectionCard extends StatelessWidget {
  final PlanSection section;

  const PlanSectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 6,
          height: 48,
          decoration: BoxDecoration(
            color: section.indicatorColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              section.subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        children: [
          if (section.loading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (section.courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'No courses available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...section.courses.map((c) {
              final title = c['name'] ?? c['title'] ?? 'Course';
              final code = c['id'] ?? '';
              final credits = c['credits']?.toString() ?? '';

              // normalize prerequisites: could be list of ids or empty/['0']
              final rawPrereqs =
                  c['pre_requisites'] ??
                  c['prePrerequisite'] ??
                  c['pre_Requisites'] ??
                  [];
              List<String> prereqIds = [];
              if (rawPrereqs is List) {
                for (final v in rawPrereqs) {
                  final s = v?.toString() ?? '';
                  if (s.isNotEmpty && s != '0') prereqIds.add(s);
                }
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                title: Text(title, textAlign: TextAlign.right),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(code, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                subtitle: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$credits credits',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                leading: prereqIds.isEmpty
                    ? const SizedBox(width: 40)
                    : IconButton(
                        onPressed: () async {
                          // fetch prerequisite course names
                          final names = <String>[];
                          for (final pid in prereqIds) {
                            try {
                              final doc = await FirebaseFirestore.instance
                                  .collection('courses')
                                  .doc(pid)
                                  .get();
                              if (doc.exists) {
                                final data = doc.data();
                                if (data != null) {
                                  names.add(data['name']?.toString() ?? pid);
                                } else {
                                  names.add(pid);
                                }
                              } else {
                                names.add(pid);
                              }
                            } catch (_) {
                              names.add(pid);
                            }
                          }

                          // show dialog with prerequisite names
                          if (!Navigator.canPop(context)) {
                            // still show dialog even if navigator can't pop; use showDialog directly
                          }
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Prerequisites'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: names.length,
                                  itemBuilder: (_, i) => ListTile(
                                    title: Text(
                                      names[i],
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
              );
            }),
        ],
      ),
    );
  }
}

