import 'package:flutter/material.dart';

class CoursePage extends StatelessWidget {
  final String title;
  final String asset;

  const CoursePage({super.key, required this.title, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TabBarSection(),
            const SizedBox(height: 16),
            // sample list of materials
            _materialItem('Main Memory', 'PDF', 'Opened: ... Due: ...'),
            _materialItem('Text Book', 'PDF', 'Opened: ... Due: ...'),
            _materialItem('input-output', 'PDF', 'Opened: ... Due: ...'),
          ],
        ),
      ),
    );
  }

  Widget _materialItem(String title, String type, String meta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(type[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(meta, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          ElevatedButton(onPressed: () {}, child: const Text('Mark as done')),
        ],
      ),
    );
  }
}

class TabBarSection extends StatelessWidget {
  const TabBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Course'),
              Tab(text: 'Grades'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                Container(
                  color: Colors.transparent,
                  child: const Center(child: Text('Course materials list')),
                ),
                Container(
                  color: Colors.transparent,
                  child: const Center(child: Text('Grades')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
