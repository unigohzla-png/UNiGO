import 'package:flutter/material.dart';

import '../widgets/glass_appbar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: 'Notifications'),
      body: const Center(
        child: Text(
          'No notifications yet.',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
