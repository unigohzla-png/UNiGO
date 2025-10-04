import 'package:flutter/material.dart';

class GPACalcPage extends StatelessWidget {
  const GPACalcPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "GPA Calculator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          "GPA Calculator Page (coming soon)",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
