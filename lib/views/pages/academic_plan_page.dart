import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/academic_plan_controller.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/inquiry_subject_card.dart';

class AcademicPlanPage extends StatelessWidget {
  const AcademicPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicPlanController(),
      child: Consumer<AcademicPlanController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Academic Plan"),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: controller.allMajorSubjects.length,
                itemBuilder: (context, index) {
                  final subject = controller.allMajorSubjects[index];
                  return InquirySubjectCard(subject: subject);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
