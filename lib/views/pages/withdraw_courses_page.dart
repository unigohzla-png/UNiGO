import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/withdraw_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/withdraw_subject_card.dart';

class WithdrawCoursesPage extends StatelessWidget {
  const WithdrawCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WithdrawCoursesController(),
      child: Consumer<WithdrawCoursesController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Withdraw Courses"),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text(
                    "Registered Courses",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.registeredSubjects.isEmpty)
                    const Text(
                      "No registered courses.",
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    ...controller.registeredSubjects.map(
                      (Subject s) => WithdrawSubjectCard(
                        subject: s,
                        onWithdraw: () {
                          _confirmWithdraw(context, controller, s);
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  const Text(
                    "Withdrawn Courses",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (controller.withdrawnSubjects.isEmpty)
                    const Text(
                      "No courses withdrawn yet.",
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    ...controller.withdrawnSubjects.map(
                      (Subject s) =>
                          WithdrawSubjectCard(subject: s, isWithdrawn: true),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmWithdraw(
    BuildContext context,
    WithdrawCoursesController controller,
    Subject subject,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Withdrawal"),
        content: Text(
          "Are you sure you want to withdraw from '${subject.name}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              controller.withdrawSubject(subject);
              Navigator.pop(ctx);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
