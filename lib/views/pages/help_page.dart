import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/glass_appbar.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  // ✅ edit these to your real university info
  static const List<Map<String, String>> links = [
    {'title': 'University Website', 'url': 'https://www.ju.edu.jo/'},
    {'title': 'Registration', 'url': 'https://regapp.ju.edu.jo/regapp/'},
    {'title': 'Library', 'url': 'https://library.ju.edu.jo/'},
    {'title': 'UJ news', 'url': 'https://news.ju.edu.jo/'},
    {'title': 'IT Support', 'url': 'https://it.example.edu/support'},
  ];

  static const List<String> supportEmails = [
    'helpdesk@example.edu',
    'registrar@example.edu',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: 'Help'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Useful Links',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          ...links.map((item) => _tile(
                title: item['title']!,
                subtitle: item['url']!,
                leading: Icons.link,
                trailing: Icons.open_in_new,
                onTap: () => _openUrl(context, item['url']!),
              )),

          const SizedBox(height: 18),

          const Text(
            'Support Emails',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          ...supportEmails.map((email) => _tile(
                title: email,
                subtitle: 'Tap to copy',
                leading: Icons.email_outlined,
                trailing: Icons.copy,
                onTap: () => _copy(context, email),
              )),
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required IconData leading,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(leading, color: Colors.black54),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: Icon(trailing, size: 18, color: Colors.black54),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }
}
