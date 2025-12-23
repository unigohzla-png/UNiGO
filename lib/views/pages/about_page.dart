import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/glass_appbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appName = 'UniGO';
  static const String inquiryEmail = 'unigo.hzla@gmail.com'; // <- change this

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: 'About'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          Center(
            child: Image.asset(
              'assets/final_logo.png', // same as login
              height: 140,
            ),
          ),
          const SizedBox(height: 10),

          const Center(
            child: Text(
              appName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 18),

          _card(
            child: const Text(
              "UniGO is a university student app designed to centralize your academic journey.\n\n"
              "• Track courses & grades\n"
              "• View academic plan progress\n"
              "• Register for next semester subjects\n"
              "• See deadlines & reminders in the calendar\n\n"
              "Developed by the UniGO Team.",
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
            ),
          ),

          const SizedBox(height: 14),

          _card(
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.black54, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    inquiryEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy email',
                  icon: const Icon(Icons.copy, size: 18, color: Colors.black54),
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: inquiryEmail));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email copied')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}
