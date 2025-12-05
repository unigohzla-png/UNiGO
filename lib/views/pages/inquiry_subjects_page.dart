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
          if (controller.loading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              appBar: GlassAppBar(title: 'Inquiry Subjects'),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final bool hasAny =
              controller.sections.any((s) => s.courses.isNotEmpty);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: 'Inquiry Subjects'),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: hasAny
                  ? Column(
                      children: [
                        _InquirySummary(controller: controller),
                        if (controller.error != null) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(message: controller.error!),
                        ],
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: controller.sections.length,
                            itemBuilder: (context, index) {
                              final section = controller.sections[index];
                              return PlanSectionCard(section: section);
                            },
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 40,
                            color: Colors.black45,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No subjects are marked as available\nfor next semester yet.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (controller.error != null) ...[
                            const SizedBox(height: 8),
                            _ErrorBanner(message: controller.error!),
                          ],
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _InquirySummary extends StatelessWidget {
  final InquirySubjectsController controller;

  const _InquirySummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalCourses = controller.totalAvailableCourses;
    final totalHours = controller.totalAvailableHours;

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
            'Available next semester',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _summaryItem(
                label: 'Courses',
                value: totalCourses.toString(),
              ),
              const SizedBox(width: 24),
              _summaryItem(
                label: 'Total hours',
                value: totalHours.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
