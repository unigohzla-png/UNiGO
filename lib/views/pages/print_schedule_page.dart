import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../controllers/print_schedule_controller.dart';
import '../../models/schedule_course.dart';
import '../widgets/glass_appbar.dart';

class PrintSchedulePage extends StatefulWidget {
  /// If null → normal student (uses logged-in UID).
  /// If non-null → admin/super admin viewing a specific student.
  final String? studentUidOverride;

  const PrintSchedulePage({super.key, this.studentUidOverride});

  @override
  State<PrintSchedulePage> createState() => _PrintSchedulePageState();
}

class _PrintSchedulePageState extends State<PrintSchedulePage> {
  late final PrintScheduleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrintScheduleController(
      studentUidOverride: widget.studentUidOverride,
    );
    _controller.loadInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrintScheduleController>.value(
      value: _controller,
      child: Consumer<PrintScheduleController>(
        builder: (context, controller, _) {
          final isAdminView = controller.isAdminView;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: GlassAppBar(
              title: isAdminView ? 'Student Schedule' : 'Print Schedule',
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -------- Admin banner (when viewing another student) --------
                  if (isAdminView) ...[
                    _AdminInfoBanner(controller: controller),
                    const SizedBox(height: 12),
                  ],

                  // -------- Semester dropdown + status --------
                  _HeaderRow(controller: controller),

                  const SizedBox(height: 16),

                  // -------- Preview table / loading / empty --------
                  Expanded(child: _buildBody(controller)),

                  const SizedBox(height: 12),

                  // -------- Action buttons --------
                  _ActionButtons(controller: controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(PrintScheduleController controller) {
    if (controller.loading && controller.semesterCourses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null &&
        controller.errorMessage!.isNotEmpty &&
        controller.semesterCourses.isEmpty) {
      return Center(
        child: Text(
          'Error: ${controller.errorMessage}',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (controller.semesters.isEmpty) {
      return const Center(
        child: Text(
          'No previous semesters found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    if (controller.semesterCourses.isEmpty) {
      return Center(
        child: Text(
          'No courses found for ${controller.selectedSemester}.',
          style: const TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return _SchedulePreview(controller: controller);
  }
}

// ===========================================================
//                    ADMIN VIEW BANNER
// ===========================================================

class _AdminInfoBanner extends StatelessWidget {
  final PrintScheduleController controller;

  const _AdminInfoBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final name = controller.studentName.isEmpty
        ? 'Unknown student'
        : controller.studentName;
    final id = controller.studentId.isEmpty ? '—' : controller.studentId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Viewing schedule for:\n$name (ID: $id)',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
//                      HEADER ROW
// ===========================================================

class _HeaderRow extends StatelessWidget {
  final PrintScheduleController controller;

  const _HeaderRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: controller.selectedSemester,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Semester',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: controller.semesters
                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              controller.changeSemester(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        if (controller.loading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

// ===========================================================
//                    SCHEDULE PREVIEW
// ===========================================================

class _SchedulePreview extends StatelessWidget {
  final PrintScheduleController controller;

  const _SchedulePreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final courses = controller.semesterCourses;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              color: Colors.grey.shade200,
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Code')),
                Expanded(flex: 4, child: Text('Course')),
                Expanded(flex: 1, child: Text('Cr')),
                Expanded(flex: 1, child: Text('Sec')),
                Expanded(flex: 3, child: Text('Days')),
                Expanded(flex: 3, child: Text('Time')),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          Expanded(
            child: ListView.separated(
              itemCount: courses.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final c = courses[index];
                return _ScheduleRow(course: c);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final ScheduleCourse course;

  const _ScheduleRow({required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code
          Expanded(
            flex: 2,
            child: Text(
              course.code,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          // Name + doctor + location
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr: ${course.doctorName.isEmpty ? '-' : course.doctorName}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                if (course.location.isNotEmpty)
                  Text(
                    'Room: ${course.location}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),

          // Credits
          Expanded(
            flex: 1,
            child: Text(
              course.credits.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Section
          Expanded(
            flex: 1,
            child: Text(
              course.sectionId.isEmpty ? '-' : course.sectionId,
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Days
          Expanded(
            flex: 3,
            child: Text(course.daysText, style: const TextStyle(fontSize: 12)),
          ),

          // Time + grade
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.timeText, style: const TextStyle(fontSize: 12)),
                if (course.grade.isNotEmpty)
                  Text(
                    'Grade: ${course.grade}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
//                     ACTION BUTTONS
// ===========================================================

class _ActionButtons extends StatelessWidget {
  final PrintScheduleController controller;

  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasData =
        controller.semesterCourses.isNotEmpty &&
        controller.selectedSemester != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasData
            ? () async {
                try {
                  final bytes = await controller.buildPdfBytes();
                  final sem = controller.selectedSemester ?? 'schedule';
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: 'schedule_$sem.pdf',
                  );
                } catch (e) {
                  _showError(context, e.toString());
                }
              }
            : null,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Export as PDF'),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
