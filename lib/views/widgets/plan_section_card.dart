import 'package:flutter/material.dart';
import '../../models/plan_section.dart';

class PlanSectionCard extends StatefulWidget {
  final PlanSection section;

  const PlanSectionCard({super.key, required this.section});

  @override
  State<PlanSectionCard> createState() => _PlanSectionCardState();
}

class _PlanSectionCardState extends State<PlanSectionCard> {
  @override
  Widget build(BuildContext context) {
    final section = widget.section;

    return Column(
      children: [
        // ---------- HEADER ----------
        InkWell(
          onTap: () {
            setState(() {
              section.isExpanded = !section.isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: section.indicatorColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                section.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        section.isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
              ],
            ),
          ),
        ),

        // ---------- EXPANDED COURSE LIST ----------
        if (section.isExpanded)
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 8,
              bottom: 8,
              top: 0,
            ),
            child: Column(
              children: section.courses.map((course) {
                final String name =
                    course['name']?.toString() ?? 'Unknown course';
                final String code =
                    course['code']?.toString() ??
                    course['id']?.toString() ??
                    '';
                final int credits = course['credits'] is int
                    ? course['credits'] as int
                    : 0;

                final bool isCompleted = course['isCompleted'] == true;
                final bool isEnrolled = course['isEnrolled'] == true;
                final String? grade = course['grade'] != null
                    ? course['grade'].toString()
                    : null;

                Color nameColor = Colors.black;
                FontWeight nameWeight = FontWeight.w500;
                IconData? statusIcon;
                Color? statusColor;

                if (isCompleted) {
                  nameColor = Colors.green.shade700;
                  nameWeight = FontWeight.w600;
                  statusIcon = Icons.check_circle;
                  statusColor = Colors.green;
                } else if (isEnrolled) {
                  nameColor = Colors.blue.shade700;
                  nameWeight = FontWeight.w600;
                  statusIcon = Icons.play_circle_fill;
                  statusColor = Colors.blue;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: nameWeight,
                                color: nameColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$credits credits',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // course code
                      if (code.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ),

                      // grade + status icon (for completed)
                      if (isCompleted && grade != null && grade.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            grade,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),

                      if (statusIcon != null)
                        Icon(statusIcon, size: 18, color: statusColor),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
