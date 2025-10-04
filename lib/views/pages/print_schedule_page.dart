import 'package:flutter/material.dart';
import '../widgets/glass_appbar.dart';

class PrintSchedulePage extends StatelessWidget {
  const PrintSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: GlassAppBar(title: "Print Schedule"),
      body: Center(
        child: Text(
          "Print Schedule Page (to be implemented)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
