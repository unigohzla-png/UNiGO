import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/reserve_time_controller.dart';
import '../../models/reservation_model.dart';
import '../widgets/glass_card_custom.dart';
import '../widgets/glass_input_box.dart';

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
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Reserve Time",
                style: TextStyle(
                  fontFamily: "AnekTelugu",
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // 🔹 New Reservation
                  GlassCardCustom(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "New Reservation",
                          style: TextStyle(
                            fontFamily: "AnekTelugu",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pick date
                        GestureDetector(
                          onTap: () => controller.pickDate(context),
                          child: GlassInputBox(
                            value: controller.selectedDate == null
                                ? "---"
                                : "${controller.selectedDate!.year}/${controller.selectedDate!.month.toString().padLeft(2, '0')}/${controller.selectedDate!.day.toString().padLeft(2, '0')}",
                            icon: Icons.calendar_today,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Pick time
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          initialValue: controller.selectedTime,
                          hint: const Text("Select Time"),
                          items: controller.timeSlots
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (val) => controller.setTime(val),
                        ),

                        const SizedBox(height: 20),

                        // Save Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: controller.addReservation,
                            icon: const Icon(Icons.save),
                            label: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GlassCardCustom(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Reserved Times",
                          style: TextStyle(
                            fontFamily: "AnekTelugu",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...controller.reserved.map(
                          (Reservation r) => ListTile(
                            title: Text("Register: ${r.registerDate}"),
                            subtitle: Text("Time: ${r.registerTime}"),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                          ),
                        ),
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
