// absence_details_page.dart
import 'package:flutter/material.dart';
import '../../models/absence_models.dart';

class AbsenceDetailsPage extends StatelessWidget {
  final AbsenceCourse course;

  const AbsenceDetailsPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final sessions = course.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: sessions.isEmpty
          ? const Center(
              child: Text('No absences recorded for this course.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = sessions[index];
                final d = s.date;
                final dateStr =
                    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.day,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${s.startTime} – ${s.endTime}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
