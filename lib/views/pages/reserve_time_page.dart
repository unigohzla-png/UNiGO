import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/reserve_time_controller.dart';
import '../../models/reservation_model.dart';
import '../widgets/glass_card_custom.dart';
import '../widgets/glass_input_box.dart';
import '../widgets/glass_appbar.dart';
import '../../services/registration_service.dart';

class ReserveTimePage extends StatelessWidget {
  const ReserveTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReserveTimeController(),
      child: Consumer<ReserveTimeController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const GlassAppBar(title: 'Reserve Time'),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // ================= NEW RESERVATION =================
                  GlassCardCustom(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Reservation',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose a date and a 15-minute slot to register your courses.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ---------- Date picker ----------
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => controller.pickDate(context),
                          child: GlassInputBox(
                            value: controller.selectedDate == null
                                ? 'Tap to select date'
                                : '${controller.selectedDate!.year}/${controller.selectedDate!.month.toString().padLeft(2, '0')}/${controller.selectedDate!.day.toString().padLeft(2, '0')}',
                            icon: Icons.calendar_today,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---------- Time dropdown ----------
                        const Text(
                          'Time slot',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.3),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          initialValue: controller.selectedTime,
                          hint: const Text('Select time slot'),
                          items: controller.timeSlots
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ),
                              )
                              .toList(),
                          onChanged: controller.setTime,
                        ),

                        const SizedBox(height: 20),

                        // ---------- Save button ----------
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (controller.selectedDate == null ||
                                  controller.selectedTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select both date and time first.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                await RegistrationService.instance
                                    .reserveFreeSlotForCurrentUser(
                                  controller.selectedDate!,
                                  controller.selectedTime!,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Time reserved successfully.'),
                                  ),
                                );

                                // ignore: use_build_context_synchronously
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to reserve time: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= RESERVED TIMES =================
                  GlassCardCustom(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reserved Times',
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (controller.reserved.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You have no reserved registration time yet.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          const SizedBox(height: 4),
                          ...controller.reserved.map(
                            (Reservation r) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.event,
                                  color: Colors.blueGrey,
                                ),
                                title: Text(
                                  r.registerDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Time: ${r.registerTime}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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
