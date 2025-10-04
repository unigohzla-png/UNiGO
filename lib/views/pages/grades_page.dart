import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/grades_controller.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GradesController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Grades",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<GradesController>(
          builder: (context, controller, _) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.grades.length,
              itemBuilder: (context, index) {
                final course = controller.grades[index];
                final expanded = course["expanded"] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              course["title"],
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
                                controller.toggleExpand(course["title"]),
                          ),

                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildMarkRow("Midterm", course["mid"]),
                                  const Divider(
                                    height: 16,
                                    thickness: 0.6,
                                    color: Colors.black26,
                                  ),
                                  _buildMarkRow("Project", course["project"]),
                                  const Divider(
                                    height: 16,
                                    thickness: 0.6,
                                    color: Colors.black26,
                                  ),
                                  _buildMarkRow(
                                    "Total (/50)",
                                    course["total"],
                                    bold: true,
                                  ),
                                ],
                              ),
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

  Widget _buildMarkRow(String label, int value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? Colors.indigo : Colors.black87,
          ),
        ),
      ],
    );
  }
}
