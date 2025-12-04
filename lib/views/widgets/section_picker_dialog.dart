import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../models/course_section.dart';

class SectionPickerDialog extends StatefulWidget {
  final Subject subject;

  const SectionPickerDialog({
    super.key,
    required this.subject,
  });

  @override
  State<SectionPickerDialog> createState() => _SectionPickerDialogState();
}

class _SectionPickerDialogState extends State<SectionPickerDialog> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    final sections = widget.subject.sections;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Choose section for\n${widget.subject.name}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: sections.isEmpty
          ? const Text(
              'No sections defined for this course.',
              style: TextStyle(fontSize: 14),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: sections.map((sec) {
                  final subtitle =
                      '${sec.days.join(', ')} • ${sec.startTime}–${sec.endTime}';

                  return RadioListTile<String>(
                    value: sec.id,
                    groupValue: selectedId,
                    onChanged: (v) => setState(() => selectedId = v),
                    title: Text(
                      'Section ${sec.id} – ${sec.doctorName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (selectedId == null || sections.isEmpty)
              ? null
              : () {
                  final sec =
                      sections.firstWhere((s) => s.id == selectedId);
                  Navigator.pop<CourseSection>(context, sec);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
