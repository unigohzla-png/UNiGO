import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/home_controller.dart';
import '../widgets/folder_card.dart';
import '../widgets/glass_appbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = HomeController();
  final ValueNotifier<bool> showStats = ValueNotifier(true);
  bool isGrid = true;

  String? studentName; // first name
  String? fullStudentName; // full name
  String? gpa; // student's GPA as string

  @override
  void initState() {
    super.initState();
    _loadStudentName();
    _loadGpa();
  }

  Future<void> _loadGpa() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final gpaValue = doc.data()?['gpa'];
        String gpaStr;
        if (gpaValue == null) {
          gpaStr = '—';
        } else if (gpaValue is num) {
          gpaStr = gpaValue.toStringAsFixed(1);
        } else {
          gpaStr = gpaValue.toString();
        }
        if (mounted) {
          setState(() {
            gpa = gpaStr;
          });
        }
      }
    }
  }

  Future<void> _loadStudentName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final fullName = doc['name'];
        final firstName = fullName
            .toString()
            .split(" ")
            .first; // only first name

        setState(() {
          studentName = firstName; // for "Welcome"
          fullStudentName = fullName; // keep full name for profile later
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: "HOME"),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerRow(),
            const SizedBox(height: 20),
            _studentStats(),
            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Current Semester",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view, size: 22),
                      color: isGrid ? Colors.black : Colors.grey,
                      onPressed: () => setState(() => isGrid = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.view_list, size: 24),
                      color: !isGrid ? Colors.black : Colors.grey,
                      onPressed: () => setState(() => isGrid = false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            isGrid ? _buildGridView() : _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          studentName == null ? "Welcome 👋" : "Welcome, $studentName 👋",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            const Text("Show Stats"),
            const SizedBox(width: 6),
            ValueListenableBuilder<bool>(
              valueListenable: showStats,
              builder: (context, visible, _) {
                return Transform.scale(
                  scale: 0.6,
                  child: CupertinoSwitch(
                    value: visible,
                    onChanged: (val) => showStats.value = val,
                    activeTrackColor: Colors.indigo,
                    thumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _studentStats() {
    return ValueListenableBuilder<bool>(
      valueListenable: showStats,
      builder: (context, visible, _) {
        if (!visible) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade200,
            ),
            child: const Center(
              child: Text(
                "Stats Hidden",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _StatCard(value: "82%", label: "Completion Rate"),
            const _StatCard(value: "120", label: "Completed Hours"),
            _StatCard(value: gpa ?? '3.8', label: "GPA"),
          ],
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.currentSemesterCourses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final course = controller.currentSemesterCourses[index];
        return FolderCard(
          title: course["title"]!,
          assetPath: course["asset"]!,
          isListView: false,
        );
      },
    );
  }

  Widget _buildListView() {
    return Column(
      children: controller.currentSemesterCourses.map((course) {
        return FolderCard(
          title: course["title"]!,
          assetPath: course["asset"]!,
          isListView: true,
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
