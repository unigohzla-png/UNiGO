import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/register_courses_controller.dart';
import '../../models/subject_model.dart';
import '../../models/course_section.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/section_picker_dialog.dart';

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
          appBar: const GlassAppBar(title: 'Add Subjects'),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                child: Text(
                  subjectToReplace == null
                      ? 'Select a subject to add. Conflicting times or exceeding the credit limit will be blocked automatically.'
                      : 'Select a subject to replace "${subjectToReplace!.name}". Conflicts and credit limit rules still apply.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.availableSubjects.isEmpty
                        ? const Center(
                            child: Text(
                              'No subjects available to register.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
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
              ),
            ],
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
    final alreadyRegistered = controller.registeredSubjects.any((s) => s.code == subject.code);

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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${subject.credits} credits',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    if (subject.sections.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        '• ${subject.sections.length} sections',
                        style: const TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                    ],
                  ],
                ),
                if (subject.sections.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Section required',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            icon: Icon(
              alreadyRegistered ? Icons.check_circle : Icons.add_circle,
              color: alreadyRegistered ? Colors.green : Colors.blue,
              size: 28,
            ),
            onPressed: alreadyRegistered
                ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Already registered'),
                        content: Text('You already registered "${subject.name}".'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                : () async {
                    // Pick section if available (both add & replace)
                    CourseSection? chosenSection;
                    if (subject.sections.isNotEmpty) {
                      chosenSection = await showDialog<CourseSection>(
                        context: context,
                        builder: (_) => SectionPickerDialog(subject: subject),
                      );

                      // User cancelled dialog
                      if (chosenSection == null) return;
                    }

                    String? error;

                    if (subjectToReplace != null) {
                      // ✅ Replace flow with section support:
                      // Remove old course first, then add new course with chosen section.
                      // This keeps Firestore data consistent (upcomingCourses + upcomingSections).
                      await controller.removeSubject(subjectToReplace);

                      error = await controller.addSubject(
                        subject,
                        section: chosenSection,
                      );

                      // If add failed, rollback by re-adding the old one (best effort)
                      if (error != null) {
                        await controller.addSubject(
                          subjectToReplace,
                          section: subjectToReplace.selectedSection,
                        );
                      }
                    } else {
                      // Normal add flow
                      error = await controller.addSubject(
                        subject,
                        section: chosenSection,
                      );
                    }

                    if (error != null) {
                      // ignore: use_build_context_synchronously
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cannot register course'),
                          content: Text('error'), // ✅ FIXED
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
