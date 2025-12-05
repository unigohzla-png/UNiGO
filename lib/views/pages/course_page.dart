// lib/views/pages/course_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/course_details_controller.dart';
import '../../models/grade_models.dart';

class CoursePage extends StatelessWidget {
  final String title;
  final String asset;

  const CoursePage({super.key, required this.title, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourseDetailsController(courseTitle: title),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
            bottom: const TabBar(
              isScrollable: true,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Course'),
                Tab(text: 'Sessions'),
                Tab(text: 'Announcements'),
                Tab(text: 'Grades'),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          body: const TabBarView(
            children: [
              _CourseMaterialsTab(),
              _CourseSessionsTab(),
              _CourseAnnouncementsTab(),
              _CourseGradesTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ COURSE TAB (materials) ============

class _CourseMaterialsTab extends StatelessWidget {
  const _CourseMaterialsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDetailsController>(
      builder: (context, ctrl, _) {
        if (ctrl.loadingCourse || ctrl.loadingMaterials) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header card
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    ctrl.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (ctrl.courseCode == null) ...[
                const Text(
                  'This course is not linked to Firestore (no matching "courses" document).',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ] else if (ctrl.materials.isEmpty) ...[
                const Text(
                  'No materials have been added yet for this course.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ] else ...[
                const Text(
                  'Materials',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Column(
                  children: ctrl.materials
                      .map((m) => _MaterialItem(material: m))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MaterialItem extends StatelessWidget {
  final MaterialItem material;

  const _MaterialItem({required this.material});

  String _firstChar(String s) {
    if (s.isEmpty) return '?';
    return s[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final type = material.type.isEmpty ? 'File' : material.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(_firstChar(type))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (material.meta.isNotEmpty)
                  Text(
                    material.meta,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: null, // later: mark as done per student
            child: const Text('Mark as done'),
          ),
        ],
      ),
    );
  }
}

// ============ SESSIONS TAB ============

class _CourseSessionsTab extends StatelessWidget {
  const _CourseSessionsTab();

  String _joinDays(List<String> days) {
    if (days.isEmpty) return '—';
    return days.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDetailsController>(
      builder: (context, ctrl, _) {
        debugPrint('SessionsTab: loading=${ctrl.loadingCourse}, '
            'courseCode=${ctrl.courseCode}, sections=${ctrl.sections.length}');

        if (ctrl.loadingCourse) {
          return const Center(child: CircularProgressIndicator());
        }


        if (ctrl.courseCode == null || ctrl.sections.isEmpty) {
          return const Center(
            child: Text(
              'No session schedule found for this course.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.sections.length,
          itemBuilder: (context, index) {
            final sec = ctrl.sections[index];

            return Container(
              margin: EdgeInsets.only(
                bottom: index == ctrl.sections.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Section ${sec.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sec.doctorName != null && sec.doctorName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        sec.doctorName!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _joinDays(sec.days),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (sec.location != null && sec.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sec.location!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if ((sec.startTime ?? '').isNotEmpty ||
                      (sec.endTime ?? '').isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${sec.startTime ?? '?'} – ${sec.endTime ?? '?'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============ ANNOUNCEMENTS TAB ============

class _CourseAnnouncementsTab extends StatelessWidget {
  const _CourseAnnouncementsTab();

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDetailsController>(
      builder: (context, ctrl, _) {
        if (ctrl.loadingCourse || ctrl.loadingAnnouncements) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.courseCode == null) {
          return const Center(
            child: Text(
              'This course is not linked to Firestore, announcements unavailable.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (ctrl.announcements.isEmpty) {
          return const Center(
            child: Text(
              'No announcements have been posted yet.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: ctrl.announcements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final a = ctrl.announcements[index];

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (a.pinned)
                        const Icon(Icons.push_pin, size: 16, color: Colors.red),
                      if (a.pinned) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(a.body, style: const TextStyle(fontSize: 13)),
                  if (a.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _fmtDate(a.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============ GRADES TAB ============

class _CourseGradesTab extends StatelessWidget {
  const _CourseGradesTab();

  String _format(double v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDetailsController>(
      builder: (context, ctrl, _) {
        if (ctrl.loadingCourse || ctrl.loadingGrades) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.courseCode == null) {
          return const Center(
            child: Text(
              'This course is not linked to Firestore, grades unavailable.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (ctrl.grades.isEmpty) {
          return const Center(
            child: Text(
              'No grades recorded yet for this course.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final items = ctrl.grades;
        final total = ctrl.totalScore;
        final totalMax = ctrl.totalMax;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return ListTile(
                title: Text(
                  'Total (/${_format(totalMax)})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  _format(total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              );
            }

            final GradeItem g = items[index];

            return ListTile(
              title: Text(g.label, style: const TextStyle(fontSize: 14)),
              trailing: Text(
                '${_format(g.score)} / ${_format(g.maxScore)}',
                style: const TextStyle(fontSize: 14),
              ),
            );
          },
        );
      },
    );
  }
}
