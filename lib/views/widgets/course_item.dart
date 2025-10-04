import 'package:flutter/material.dart';

class CourseItem extends StatelessWidget {
  final String title;
  final String assetPath;

  const CourseItem({super.key, required this.title, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(assetPath, width: 28, height: 28),
        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
