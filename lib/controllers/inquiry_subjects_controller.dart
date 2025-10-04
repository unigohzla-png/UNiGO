import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class InquirySubjectsController extends ChangeNotifier {
  final List<Subject> allSubjects = [
    Subject(name: "Calculus II", credits: 3, color: Colors.blue),
    Subject(name: "Database Systems", credits: 3, color: Colors.green),
    Subject(name: "Operating Systems", credits: 4, color: Colors.red),
    Subject(name: "Computer Networks", credits: 3, color: Colors.orange),
    Subject(name: "Artificial Intelligence", credits: 3, color: Colors.purple),
  ];

  String _query = "";
  String get query => _query;

  List<Subject> get filteredSubjects {
    if (_query.isEmpty) return allSubjects;
    return allSubjects
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void updateQuery(String q) {
    _query = q;
    notifyListeners();
  }
}
