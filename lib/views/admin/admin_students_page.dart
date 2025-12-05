import 'package:flutter/material.dart';

class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: const Center(
        child: Text('Students tab – search & tools will be added later'),
      ),
    );
  }
}
