import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/inquiry_subjects_controller.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/inquiry_subject_card.dart';

class InquirySubjectsPage extends StatelessWidget {
  const InquirySubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InquirySubjectsController(),
      child: Consumer<InquirySubjectsController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: "Inquiry Subjects"),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search subjects...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: controller.updateQuery,
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: controller.filteredSubjects.isEmpty
                        ? const Center(
                            child: Text(
                              "No subjects found",
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: controller.filteredSubjects.length,
                            itemBuilder: (context, index) {
                              final subject =
                                  controller.filteredSubjects[index];
                              return InquirySubjectCard(subject: subject);
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
