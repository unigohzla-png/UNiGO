import 'dart:async';
import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class RegisterCoursesController extends ChangeNotifier {
  final List<Subject> availableSubjects = [
    Subject(name: "Calculus II", credits: 3, color: Colors.blue),
    Subject(name: "Database Systems", credits: 3, color: Colors.green),
    Subject(name: "Operating Systems", credits: 4, color: Colors.red),
    Subject(name: "Computer Networks", credits: 3, color: Colors.orange),
    Subject(name: "Artificial Intelligence", credits: 3, color: Colors.purple),
  ];

  final List<Subject> registeredSubjects = [];

  static const int _initialMinutes = 15;
  Duration remainingTime = const Duration(minutes: _initialMinutes);
  Timer? _timer;

  void startTimer() {
    remainingTime = const Duration(minutes: _initialMinutes);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds > 0) {
        remainingTime = Duration(seconds: remainingTime.inSeconds - 1);
        notifyListeners();
      } else {
        _timer?.cancel();
      }
    });
  }

  String get formattedTime {
    final minutes = remainingTime.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remainingTime.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void addSubject(Subject subject) {
    if (!registeredSubjects.contains(subject)) {
      registeredSubjects.add(subject);
      notifyListeners();
    }
  }

  void disposeController() {
    _timer?.cancel();
  }
}
