import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/register_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';
import 'add_subjects_page.dart';

class RegisterCoursesPage extends StatelessWidget {
  const RegisterCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = RegisterCoursesController();
        controller.startTimer();
        return controller;
      },
      child: Consumer<RegisterCoursesController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Register Courses"),

            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Timer message
                  const Text(
                    "You have 15 minutes to add subjects",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.formattedTime,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Registered subjects list
                  Expanded(
                    child: controller.registeredSubjects.isEmpty
                        ? const Center(
                            child: Text(
                              "No subjects registered yet",
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: controller.registeredSubjects.length,
                            itemBuilder: (context, index) {
                              final subject =
                                  controller.registeredSubjects[index];
                              return _subjectCard(subject);
                            },
                          ),
                  ),
                ],
              ),
            ),

            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: const AddSubjectsPage(),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 28),
            ),
          );
        },
      ),
    );
  }

  Widget _subjectCard(Subject subject) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }
}
