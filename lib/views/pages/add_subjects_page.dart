import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/register_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';

class AddSubjectsPage extends StatelessWidget {
  /// If not null, we are *replacing* this course instead of just adding.
  final Subject? subjectToReplace;

  const AddSubjectsPage({super.key, this.subjectToReplace});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterCoursesController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const GlassAppBar(title: "Add Subjects"),

          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.availableSubjects.length,
            itemBuilder: (context, index) {
              final subject = controller.availableSubjects[index];
              return _subjectCard(
                context,
                controller,
                subject,
                subjectToReplace,
              );
            },
          ),
        );
      },
    );
  }

  Widget _subjectCard(
    BuildContext context,
    RegisterCoursesController controller,
    Subject subject,
    Subject? subjectToReplace,
  ) {
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
                  "${subject.credits} credits",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
            onPressed: () async {
              String? error;

              if (subjectToReplace != null) {
                // switch mode
                error = await controller.replaceSubject(
                  subjectToReplace,
                  subject,
                );
              } else {
                // normal add mode
                error = await controller.addSubject(subject);
              }

              if (error != null) {
                // 🔹 show warning popup instead of closing the page
                // You can use dialog or bottom sheet; here we use a simple dialog.
                // (Keep it simple and clear.)
                // ignore: use_build_context_synchronously
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cannot register course'),
                    content: Text('error'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              // Success → close AddSubjectsPage
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
