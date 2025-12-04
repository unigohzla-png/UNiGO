import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/withdraw_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/withdraw_subject_card.dart';

class WithdrawCoursesPage extends StatefulWidget {
  const WithdrawCoursesPage({super.key});

  @override
  State<WithdrawCoursesPage> createState() => _WithdrawCoursesPageState();
}

class _WithdrawCoursesPageState extends State<WithdrawCoursesPage> {
  late WithdrawCoursesController controller;

  @override
  void initState() {
    super.initState();
    controller = WithdrawCoursesController();
    controller.loadRegisteredCourses();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WithdrawCoursesController>.value(
      value: controller,
      child: Consumer<WithdrawCoursesController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Withdraw Courses"),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        _sectionTitle("Registered Courses"),
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
                              onWithdraw: () =>
                                  _confirmWithdraw(context, controller, s),
                            ),
                          ),

                        const SizedBox(height: 32),

                        _sectionTitle("Withdrawn Courses"),
                        const SizedBox(height: 12),

                        if (controller.withdrawnSubjects.isEmpty)
                          const Text(
                            "No courses withdrawn yet.",
                            style: TextStyle(color: Colors.black54),
                          )
                        else
                          ...controller.withdrawnSubjects.map(
                            (Subject s) => WithdrawSubjectCard(
                              subject: s,
                              isWithdrawn: true,
                            ),
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------
  // Small cleaner widget for section title
  // -------------------------------------
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  // -------------------------------------
  // Confirm withdraw dialog
  // -------------------------------------
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
            onPressed: () async {
              await controller.withdrawSubject(subject);
              Navigator.pop(ctx);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
