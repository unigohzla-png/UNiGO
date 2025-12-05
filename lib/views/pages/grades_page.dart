// lib/views/pages/grades_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/grades_controller.dart';
import '../../models/grade_models.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GradesController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Grades',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<GradesController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.courses.isEmpty) {
              return const Center(child: Text('No grades available.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.courses.length,
              itemBuilder: (context, index) {
                final CourseGrades course = controller.courses[index];
                return _GradeCourseCard(course: course);
              },
            );
          },
        ),
      ),
    );
  }
}

class _GradeCourseCard extends StatefulWidget {
  final CourseGrades course;

  const _GradeCourseCard({required this.course});

  @override
  State<_GradeCourseCard> createState() => _GradeCourseCardState();
}

class _GradeCourseCardState extends State<_GradeCourseCard> {
  bool _expanded = true; // default open like your screenshot

  String _format(double v) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final items = course.items;
    final total = course.totalScore;
    final totalMax = course.totalMax;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  course.courseName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onTap: () {
                  setState(() => _expanded = !_expanded);
                },
              ),
              if (_expanded) const Divider(height: 1),

              if (_expanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No grades recorded yet.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // grade items
                            ...items.map((g) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      g.label,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '${_format(g.score)} / ${_format(g.maxScore)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // total row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total (/${_format(totalMax)})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _format(total),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
