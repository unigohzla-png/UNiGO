import 'package:flutter/material.dart';
import '../models/reservation_model.dart';

class ReserveTimeController extends ChangeNotifier {
  DateTime? selectedDate;
  String? selectedTime;

  final List<String> timeSlots = [
    "10:30 - 10:45",
    "11:00 - 11:15",
    "15:30 - 15:45",
    "16:00 - 16:15",
  ];

  final List<Reservation> reserved = [
    Reservation(
      registerDate: "2025/08/24",
      registerTime: "10:30 - 10:45",
      freeDate: "2025/08/24",
      freeTime: "15:30 - 15:45",
    ),
  ];

  void pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025, 1),
      lastDate: DateTime(2026, 12),
    );
    if (picked != null) {
      selectedDate = picked;
      notifyListeners();
    }
  }

  void setTime(String? time) {
    selectedTime = time;
    notifyListeners();
  }

  void addReservation() {
    if (selectedDate != null && selectedTime != null) {
      final dateStr =
          "${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}";
      reserved.add(
        Reservation(
          registerDate: dateStr,
          registerTime: selectedTime!,
          freeDate: dateStr,
          freeTime: selectedTime!,
        ),
      );
      notifyListeners();
    }
  }
}
