// lib/views/pages/absences_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/absences_controller.dart';
import '../../models/absence_models.dart';
import 'absence_details_page.dart';

class SegmentedAbsenceBar extends StatelessWidget {
  final int current;
  final int max;

  const SegmentedAbsenceBar({
    super.key,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final clampedCurrent = current.clamp(0, max);

    return SizedBox(
      height: 10,
      child: Row(
        children: List.generate(max, (index) {
          final bool filled = index < clampedCurrent;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == max - 1 ? 0 : 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: filled ? Colors.orange.shade600 : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class AbsencesPage extends StatelessWidget {
  const AbsencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AbsencesController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Absences',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<AbsencesController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.courses.isEmpty) {
              return const Center(child: Text('No courses this semester.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.courses.length,
              itemBuilder: (context, index) {
                final AbsenceCourse course = controller.courses[index];
                final max = course.maxAbsences;
                final current = course.currentAbsences;

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AbsenceDetailsPage(course: course),
                      ),
                    );
                  },
                  child: Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      course.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (controller.showWarning(course))
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (course.days.isNotEmpty)
                                Text(
                                  course.days.join(' • '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              const SizedBox(height: 14),

                              SegmentedAbsenceBar(
                                current: current,
                                max: max,
                              ),

                              const SizedBox(height: 6),
                              Text(
                                'Absences: $current / $max',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
