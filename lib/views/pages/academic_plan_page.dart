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
  late AcademicPlanController controller;

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
              child: ListView.builder(
                itemCount: controller.planSections.length,
                itemBuilder: (context, index) {
                  final section = controller.planSections[index];
                  return PlanSectionCard(section: section);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
