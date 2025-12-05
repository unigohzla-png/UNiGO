import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/withdraw_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/withdraw_subject_card.dart';

class WithdrawCoursesPage extends StatefulWidget {
  const WithdrawCoursesPage({super.key});

  @override
  State<WithdrawCoursesPage> createState() => _WithdrawCoursesPageState();
}

class _WithdrawCoursesPageState extends State<WithdrawCoursesPage> {
  late WithdrawCoursesController controller;

  @override
  void initState() {
    super.initState();
    controller = WithdrawCoursesController();
    controller.loadRegisteredCourses();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WithdrawCoursesController>.value(
      value: controller,
      child: Consumer<WithdrawCoursesController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: 'Withdraw Courses'),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _WithdrawSummary(controller: controller),
                        if (controller.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(message: controller.errorMessage!),
                        ],
                        const SizedBox(height: 16),
                        Expanded(
                          child: _BodyLists(controller: controller),
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

class _WithdrawSummary extends StatelessWidget {
  final WithdrawCoursesController controller;

  const _WithdrawSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalRegistered = controller.registeredSubjects.length;
    final totalWithdrawn = controller.withdrawnSubjects.length;

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
            'Current semester status',
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
                label: 'Registered',
                value:
                    '$totalRegistered (${controller.totalRegisteredCredits} cr.)',
              ),
              const SizedBox(width: 24),
              _summaryItem(
                label: 'Withdrawn',
                value:
                    '$totalWithdrawn (${controller.totalWithdrawnCredits} cr.)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Withdrawal affects only your current semester registered courses.\n'
            'It does not change completed or upcoming courses.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
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
            fontSize: 14,
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

class _BodyLists extends StatelessWidget {
  final WithdrawCoursesController controller;

  const _BodyLists({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasRegistered = controller.registeredSubjects.isNotEmpty;
    final hasWithdrawn = controller.withdrawnSubjects.isNotEmpty;

    if (!hasRegistered && !hasWithdrawn) {
      return const Center(
        child: Text(
          'You have no registered or withdrawn courses this semester.',
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      children: [
        // Registered
        const Text(
          'Registered Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (!hasRegistered)
          const Text(
            'No registered courses.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          )
        else
          ...controller.registeredSubjects.map(
            (Subject s) => WithdrawSubjectCard(
              subject: s,
              onWithdraw: () => _confirmWithdraw(context, controller, s),
            ),
          ),

        const SizedBox(height: 24),

        // Withdrawn
        const Text(
          'Withdrawn Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (!hasWithdrawn)
          const Text(
            'No courses withdrawn yet.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          )
        else
          ...controller.withdrawnSubjects.map(
            (Subject s) => WithdrawSubjectCard(
              subject: s,
              isWithdrawn: true,
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

void _confirmWithdraw(
  BuildContext context,
  WithdrawCoursesController controller,
  Subject subject,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm Withdrawal'),
      content: Text(
        "Are you sure you want to withdraw from '${subject.name}'?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            await controller.withdrawSubject(subject);
            // ignore: use_build_context_synchronously
            Navigator.pop(ctx);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}
