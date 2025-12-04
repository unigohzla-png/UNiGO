import 'package:flutter/material.dart';
import '../../models/subject_model.dart';

class InquirySubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isCompleted;
  final bool isEnrolled;

  const InquirySubjectCard({
    super.key,
    required this.subject,
    this.isCompleted = false,
    this.isEnrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    if (isCompleted) {
      statusText = "Completed";
      statusColor = Colors.green;
    } else if (isEnrolled) {
      statusText = "Already registered";
      statusColor = Colors.blue;
    } else {
      statusText = "Available to register";
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: subject.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "${subject.credits} credits • ${subject.code}",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
