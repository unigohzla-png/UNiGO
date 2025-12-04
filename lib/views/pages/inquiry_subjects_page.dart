import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/inquiry_subjects_controller.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/plan_section_card.dart';

class InquirySubjectsPage extends StatefulWidget {
  const InquirySubjectsPage({super.key});

  @override
  State<InquirySubjectsPage> createState() => _InquirySubjectsPageState();
}

class _InquirySubjectsPageState extends State<InquirySubjectsPage> {
  late InquirySubjectsController controller;

  @override
  void initState() {
    super.initState();
    controller = InquirySubjectsController();
    controller.loadSections();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InquirySubjectsController>.value(
      value: controller,
      child: Consumer<InquirySubjectsController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Inquiry Subjects"),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : controller.sections.every((s) => s.courses.isEmpty)
                  ? const Center(
                      child: Text(
                        "No subjects available for next semester.",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.sections.length,
                      itemBuilder: (context, index) {
                        final section = controller.sections[index];
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
