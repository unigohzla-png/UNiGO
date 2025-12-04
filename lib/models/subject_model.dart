import 'package:flutter/material.dart';

class Subject {
  final String name;
  final int credits;
  final Color color;
  final String? code;

  Subject({
    required this.name,
    required this.credits,
    required this.color,
    this.code,
  });
}
