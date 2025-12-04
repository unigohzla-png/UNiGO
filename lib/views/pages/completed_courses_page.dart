import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/completed_courses_controller.dart';

class CompletedCoursesPage extends StatelessWidget {
  const CompletedCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompletedCoursesController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Completed Courses",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<CompletedCoursesController>(
          builder: (context, controller, _) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.semesters.length,
              itemBuilder: (context, index) {
                final semester = controller.semesters[index];
                final expanded = semester["expanded"] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              semester["term"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.black54,
                            ),
                            onTap: () =>
                                controller.toggleExpand(semester["term"]),
                          ),

                          if (expanded)
                            Column(
                              children: (semester["courses"] as List)
                                  .map<Widget>((course) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            course["title"],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            course["grade"],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _gradeColor(
                                                course["grade"],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case "A":
      case "A-":
        return Colors.green;
      case "B+":
      case "B":
        return Colors.blue;
      case "C":
        return Colors.orange;
      case "D":
        return Colors.redAccent;
      case "F":
        return Colors.red;
      default:
        return Colors.black87;
    }
  }
}
