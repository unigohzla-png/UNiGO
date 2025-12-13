// lib/views/widgets/grade_point_table.dart

import 'package:flutter/material.dart';

class GradePointTable extends StatelessWidget {
  const GradePointTable({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['A+', '4.0'],
      ['A', '4.0'],
      ['A-', '3.7'],
      ['B+', '3.3'],
      ['B', '3.0'],
      ['B-', '2.7'],
      ['C+', '2.3'],
      ['C', '2.0'],
      ['C-', '1.7'],
      ['D+', '1.3'],
      ['D', '1.0'],
      ['F', '0.0'],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Grade',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r[0],
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r[1],
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
