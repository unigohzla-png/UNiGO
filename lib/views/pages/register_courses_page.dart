import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/register_courses_controller.dart';
import '../../models/subject_model.dart';
import '../widgets/glass_appbar.dart';
import 'add_subjects_page.dart';
import '../../services/registration_service.dart';

class RegisterCoursesPage extends StatefulWidget {
  const RegisterCoursesPage({super.key});

  @override
  State<RegisterCoursesPage> createState() => _RegisterCoursesPageState();
}

class _RegisterCoursesPageState extends State<RegisterCoursesPage> {
  late final Future<void> _loadRegistrationState;

  @override
  void initState() {
    super.initState();
    // Load global + user window ONCE when the page is created
    _loadRegistrationState = RegistrationService.instance.reloadFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = RegisterCoursesController();
        controller.loadInitialData();
        return controller;
      },
      child: Consumer<RegisterCoursesController>(
        builder: (context, controller, _) {
          return FutureBuilder<void>(
            future: _loadRegistrationState,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final service = RegistrationService.instance;
              final now = DateTime.now();

              final canAccess = service.canUserRegisterNow('ignored');

              // Before 20:00 and inside a personal slot → tie timer to slot end
              final useSlotWindow =
                  now.hour < 20 &&
                  service.assignedEndAt != null &&
                  now.isBefore(service.assignedEndAt!);

              if (canAccess) {
                controller.ensureTimerStarted(useSlotWindow: useSlotWindow);
              }

              // ✅ Can edit only if registration open AND time still remaining
              final canEdit =
                  canAccess && controller.remainingTime.inSeconds > 0;

              return Scaffold(
                backgroundColor: Colors.white,
                appBar: const GlassAppBar(title: 'Register Courses'),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Header(
                        canAccess: canAccess,
                        canEdit: canEdit,
                        controller: controller,
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: controller.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : controller.registeredSubjects.isEmpty
                            ? const Center(
                                child: Text(
                                  'No subjects registered yet.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : ListView.builder(
                                itemCount: controller.registeredSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject =
                                      controller.registeredSubjects[index];
                                  return _subjectCard(
                                    context,
                                    controller,
                                    subject,
                                    canEdit: canEdit,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                floatingActionButton: FloatingActionButton(
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    if (!canEdit) {
                      _showRegistrationClosedSheet(context);
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: const AddSubjectsPage(),
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add, size: 28),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool canAccess;
  final bool canEdit;
  final RegisterCoursesController controller;

  const _Header({
    required this.canAccess,
    required this.canEdit,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final creditsText =
        'Total: ${controller.totalRegisteredCredits} / ${RegisterCoursesController.maxCredits} credits';

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
          if (canAccess && canEdit) ...[
            const Text(
              'Registration window',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  controller.formattedTime,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You have limited time to add or remove subjects.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else if (canAccess && !canEdit) ...[
            Row(
              children: const [
                Icon(Icons.timer_off, size: 18, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Time ended. Registration actions are locked now.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registration is currently closed. You can still view your registered subjects.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          Text(
            creditsText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              value:
                  (controller.totalRegisteredCredits /
                          RegisterCoursesController.maxCredits)
                      .clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _subjectCard(
  BuildContext context,
  RegisterCoursesController controller,
  Subject subject, {
  required bool canEdit,
}) {
  final sec = subject.selectedSection;
  final hasRealSection = sec != null && sec.id.isNotEmpty;

  final String courseTitle = subject.name;

  final String sectionLabel = hasRealSection ? 'Sec ${sec.id}' : 'No section';
  final String doctorLabel = hasRealSection
      ? (sec.doctorName.isEmpty ? 'Doctor: TBA' : 'Doctor: ${sec.doctorName}')
      : '';

  String scheduleLabel = '';
  if (hasRealSection) {
    final days = sec.days.join(', ');
    final time = (sec.startTime.isNotEmpty && sec.endTime.isNotEmpty)
        ? '${sec.startTime}–${sec.endTime}'
        : '';
    if (days.isNotEmpty && time.isNotEmpty) {
      scheduleLabel = '$days • $time';
    } else if (days.isNotEmpty) {
      scheduleLabel = days;
    } else if (time.isNotEmpty) {
      scheduleLabel = time;
    }
  }

  final String creditsLabel = '${subject.credits} credits';

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.4),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 48,
          decoration: BoxDecoration(
            color: subject.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      courseTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (hasRealSection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        sectionLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              if (doctorLabel.isNotEmpty) ...[
                Text(
                  doctorLabel,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
              ],

              if (scheduleLabel.isNotEmpty) ...[
                Text(
                  scheduleLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
              ],

              Text(
                creditsLabel,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: canEdit ? 'Remove' : 'Locked',
              icon: const Icon(
                Icons.delete_outline,
                size: 22,
                color: Colors.red,
              ),
              onPressed: () async {
                if (!canEdit) {
                  _showRegistrationClosedSheet(context);
                  return;
                }
                await controller.removeSubject(subject);
              },
            ),
            IconButton(
              tooltip: canEdit ? 'Switch' : 'Locked',
              icon: const Icon(Icons.swap_horiz, size: 22, color: Colors.blue),
              onPressed: () {
                if (!canEdit) {
                  _showRegistrationClosedSheet(context);
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: controller,
                      child: AddSubjectsPage(subjectToReplace: subject),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  );
}

void _showRegistrationClosedSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.lock_clock, color: Colors.black54),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Registration is not open for you now.\n'
              'Please check your reserved time in the Reserve Time page.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    ),
  );
}
