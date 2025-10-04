import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/register_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';

class AddSubjectsPage extends StatelessWidget {
  const AddSubjectsPage({super.key});

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
              return _subjectCard(context, controller, subject);
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
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

          // Subject details
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
            onPressed: () {
              controller.addSubject(subject);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
