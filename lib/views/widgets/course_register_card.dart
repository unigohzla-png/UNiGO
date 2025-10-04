import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/course_registration_model.dart';

class CourseRegisterCard extends StatelessWidget {
  final CourseRegistration course;
  final VoidCallback onToggle;

  const CourseRegisterCard({
    super.key,
    required this.course,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    course.name,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    "${course.credits} credits",
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: course.isRegistered
                      ? Colors.red.shade400
                      : Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onToggle,
                child: Text(
                  course.isRegistered ? "Withdraw" : "Register",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
