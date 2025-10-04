import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class AcademicPlanController extends ChangeNotifier {
  final List<Subject> allMajorSubjects = [
    Subject(name: "Calculus I", credits: 3, color: Colors.blue),
    Subject(name: "Calculus II", credits: 3, color: Colors.teal),
    Subject(name: "Linear Algebra", credits: 3, color: Colors.indigo),
    Subject(name: "Probability & Statistics", credits: 3, color: Colors.purple),
    Subject(name: "Database Systems", credits: 3, color: Colors.green),
    Subject(name: "Operating Systems", credits: 4, color: Colors.red),
    Subject(name: "Computer Networks", credits: 3, color: Colors.orange),
    Subject(name: "Artificial Intelligence", credits: 3, color: Colors.pink),
    Subject(name: "Software Engineering", credits: 4, color: Colors.cyan),
    Subject(name: "Digital Logic", credits: 3, color: Colors.deepOrange),
    Subject(name: "Computer Graphics", credits: 3, color: Colors.amber),
    Subject(name: "Simulation & Modelling", credits: 3, color: Colors.brown),
  ];
}
