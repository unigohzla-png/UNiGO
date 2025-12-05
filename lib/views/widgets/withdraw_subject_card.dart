import 'package:flutter/material.dart';
import '../../models/subject_model.dart';

class WithdrawSubjectCard extends StatelessWidget {
  final Subject subject;
  final bool isWithdrawn;
  final VoidCallback? onWithdraw;

  const WithdrawSubjectCard({
    super.key,
    required this.subject,
    this.isWithdrawn = false,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final String creditsLabel = '${subject.credits} credits';
    final String codeLabel =
        (subject.code != null && subject.code!.isNotEmpty)
            ? subject.code!
            : '';

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
          // Color stripe
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: subject.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Text info
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      creditsLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (codeLabel.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        codeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isWithdrawn) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Withdrawn',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right-side action / icon
          isWithdrawn
              ? const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 22,
                )
              : IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: onWithdraw,
                ),
        ],
      ),
    );
  }
}
