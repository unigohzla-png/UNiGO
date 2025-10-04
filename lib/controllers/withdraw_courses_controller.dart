import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class WithdrawCoursesController extends ChangeNotifier {
  final List<Subject> registeredSubjects = [
    Subject(name: "Digital Logic", credits: 3, color: Colors.blue),
    Subject(name: "Computer Graphics", credits: 3, color: Colors.green),
    Subject(name: "Software Engineering", credits: 4, color: Colors.orange),
    Subject(name: "Simulation & Modelling", credits: 3, color: Colors.purple),
  ];

  final List<Subject> withdrawnSubjects = [];

  void withdrawSubject(Subject subject) {
    registeredSubjects.remove(subject);
    withdrawnSubjects.add(subject);
    notifyListeners();
  }
}
