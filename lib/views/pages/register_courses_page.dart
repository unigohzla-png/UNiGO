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
            future: _loadRegistrationState, // same future every rebuild
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final service = RegistrationService.instance;
              final now = DateTime.now();

              final canAccess = service.canUserRegisterNow(
                'ignored',
              ); // param not used

              // Before 20:00 and inside a personal slot → tie timer to slot end
              final useSlotWindow =
                  now.hour < 20 &&
                  service.assignedEndAt != null &&
                  now.isBefore(service.assignedEndAt!);

              if (canAccess) {
                controller.ensureTimerStarted(useSlotWindow: useSlotWindow);
              }

              return Scaffold(
                backgroundColor: Colors.white,
                appBar: const GlassAppBar(title: 'Register Courses'),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ---------- Timer / header ----------
                      if (canAccess) ...[
                        const Text(
                          'You have 15 minutes to add subjects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.formattedTime,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // ---------- Credits summary ----------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total: ${controller.totalRegisteredCredits} / ${RegisterCoursesController.maxCredits} credits',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------- Registered subjects list ----------
                      Expanded(
                        child: controller.registeredSubjects.isEmpty
                            ? const Center(
                                child: Text(
                                  'No subjects registered yet',
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
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // ---------- FAB ----------
                floatingActionButton: FloatingActionButton(
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    if (!canAccess) {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: const [
                              Icon(Icons.lock_clock, color: Colors.black54),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Registration is not open for you now. Check reservation time.',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
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

Widget _subjectCard(
  BuildContext context,
  RegisterCoursesController controller,
  Subject subject,
) {
  final sec = subject.selectedSection;

  final hasRealSection = sec != null && sec.id.isNotEmpty; // basic sanity check

  final String courseTitle = subject.name;

  final String sectionLabel = hasRealSection ? 'Sec ${sec!.id}' : 'No section';
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
        // Color stripe
        Container(
          width: 6,
          height: 48,
          decoration: BoxDecoration(
            color: subject.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),

        // Subject + section info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course name + section pill
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

              // Doctor
              if (doctorLabel.isNotEmpty) ...[
                Text(
                  doctorLabel,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
              ],

              // Days + time
              if (scheduleLabel.isNotEmpty) ...[
                Text(
                  scheduleLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
              ],

              // Credits
              Text(
                creditsLabel,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Actions: Remove + Switch
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(
                Icons.delete_outline,
                size: 22,
                color: Colors.red,
              ),
              onPressed: () async {
                await controller.removeSubject(subject);
              },
            ),
            IconButton(
              tooltip: 'Switch',
              icon: const Icon(Icons.swap_horiz, size: 22, color: Colors.blue),
              onPressed: () {
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
