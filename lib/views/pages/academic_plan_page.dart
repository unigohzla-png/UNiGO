import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/academic_plan_controller.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/plan_section_card.dart';

class AcademicPlanPage extends StatefulWidget {
  const AcademicPlanPage({super.key});

  @override
  State<AcademicPlanPage> createState() => _AcademicPlanPageState();
}

class _AcademicPlanPageState extends State<AcademicPlanPage> {
  late final AcademicPlanController controller;

  @override
  void initState() {
    super.initState();
    controller = AcademicPlanController();
    controller.loadSections();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AcademicPlanController>.value(
      value: controller,
      child: Consumer<AcademicPlanController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Academic Plan"),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PlanSummary(controller: controller),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.planSections.length,
                      itemBuilder: (context, index) {
                        final section = controller.planSections[index];
                        return PlanSectionCard(section: section);
                      },
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
}

class _PlanSummary extends StatelessWidget {
  final AcademicPlanController controller;

  const _PlanSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final remaining = controller.remainingCredits.clamp(0, 999);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overall Progress",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: controller.overallProgressPercent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                label: "Completed",
                value: controller.completedCredits,
                color: Colors.green.shade700,
              ),
              _summaryItem(
                label: "In progress",
                value: controller.inProgressCredits,
                color: Colors.blue.shade700,
              ),
              _summaryItem(
                label: "Remaining",
                value: remaining,
                color: Colors.orange.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "credits",
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
