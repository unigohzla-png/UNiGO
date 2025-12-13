// lib/views/pages/gpa_calc_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/gpa_controller.dart';
import '../widgets/gpa_card.dart';
import '../widgets/grade_point_table.dart';
import '../widgets/course_input_row.dart';
import '../widgets/glass_appbar.dart';

class GPACalcPage extends StatefulWidget {
  const GPACalcPage({super.key});

  @override
  State<GPACalcPage> createState() => _GPACalcPageState();
}

class _GPACalcPageState extends State<GPACalcPage> {
  late final GPAController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GPAController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GPAController>.value(
      value: _controller,
      child: Consumer<GPAController>(
        builder: (context, controller, _) {
          final calc = controller.gpaService.calculation;
          final gpaValue = controller.gpaService.currentGPA;
          final gpaText = gpaValue.toStringAsFixed(2);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "GPA Calculator"),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Plan your GPA",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter the grade and credit hours for each course you want "
                    "to include, then tap Calculate.",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // GPA result card
                  GPACard(
                    title: "Calculated GPA",
                    value: calc.totalCreditHours > 0 ? gpaText : "0.00",
                  ),

                  const SizedBox(height: 24),

                  // Course inputs section
                  _buildCourseInputsSection(controller),

                  const SizedBox(height: 24),

                  // Calculate button
                  _buildCalculateButton(controller, context),

                  const SizedBox(height: 32),

                  // Explanation section
                  _buildExplanationSection(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseInputsSection(GPAController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Courses in this calculation",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "You can add up to 8 courses. "
          "Type the letter grade and the credit hours for each one.",
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // Dynamic list of input rows
        ...controller.courses.asMap().entries.map((entry) {
          final index = entry.key;
          final course = entry.value;
          return CourseInputRow(
            course: course,
            index: index,
            onDelete: controller.courses.length > 1
                ? () => controller.removeCourse(index)
                : null,
          );
        }),

        const SizedBox(height: 8),

        Center(
          child: TextButton.icon(
            onPressed: controller.courses.length >= 8
                ? null
                : () => controller.addCourse(),
            icon: const Icon(Icons.add),
            label: Text(
              controller.courses.length >= 8
                  ? "Maximum of 8 courses"
                  : "Add another course",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton(GPAController controller, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.calculate),
        onPressed: () {
          controller.calculateGPA();

          if (controller.gpaService.calculation.totalCreditHours <= 0) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("No valid courses"),
                content: const Text(
                  "Please enter at least one course with a valid letter grade "
                  "and credit hours greater than 0.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        },
        label: const Text("Calculate GPA"),
      ),
    );
  }

  Widget _buildExplanationSection(GPAController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: controller.toggleExplanation,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                "How GPA is calculated",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              Icon(
                controller.showExplanation
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        if (controller.showExplanation) ...[
          const SizedBox(height: 12),
          const Text(
            "GPA (Grade Point Average) = total grade points ÷ total credit hours.",
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Grade points are calculated by multiplying the course's credit "
            "hours by the grade value (on a 4.0 scale).",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text(
            "Grade point values:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const GradePointTable(),
        ],
      ],
    );
  }
}
 