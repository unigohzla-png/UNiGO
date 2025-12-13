// lib/views/widgets/course_input_row.dart

import 'package:flutter/material.dart';

import '../../controllers/gpa_controller.dart';

class CourseInputRow extends StatelessWidget {
  final CourseInput course;
  final int index;
  final VoidCallback? onDelete;

  const CourseInputRow({
    super.key,
    required this.course,
    required this.index,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade (A, B+, ...)
          Expanded(
            flex: 2,
            child: TextField(
              controller: course.gradeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Grade',
                hintText: 'A, B+, C-',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Credit hours
          Expanded(
            flex: 1,
            child: TextField(
              controller: course.creditHoursController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Credits',
                hintText: '3',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Remove course',
            ),
          ],
        ],
      ),
    );
  }
}
