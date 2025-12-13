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
    // listen to controller changes so UI rebuilds when courses load
    controller.addListener(_onControllerChanged);
    controller.loadEnrolledCourses();
    controller.loadStats(); // 👈 NEW
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadGpa() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() {
            gpa = '—';
          });
        }
        return;
      }

      final data = doc.data() ?? {};
      final prev = data['previousCourses'];

      // If no previous courses → no GPA
      if (prev is! Map<String, dynamic> || prev.isEmpty) {
        if (mounted) {
          setState(() {
            gpa = '—';
          });
        }
        return;
      }

      // Same grade → points mapping as the GPA calculator
      const Map<String, double> gradePoints = {
        'A': 4.0,
        'A-': 3.7,
        'B+': 3.3,
        'B': 3.0,
        'B-': 2.7,
        'C+': 2.3,
        'C': 2.0,
        'C-': 1.7,
        'D+': 1.3,
        'D': 1.0,
        'F': 0.0,
      };

      double totalCredits = 0.0;
      double totalPoints = 0.0;

      for (final entry in prev.entries) {
        final courseCode = entry.key;
        final value = entry.value;

        if (value is! Map<String, dynamic>) continue;

        // 1) Grade letter
        String? gradeStr;
        for (final key in ['gradeLetter', 'grade', 'letter', 'finalGrade']) {
          final tmp = value[key];
          if (tmp != null && tmp.toString().trim().isNotEmpty) {
            gradeStr = tmp.toString().trim().toUpperCase();
            break;
          }
        }
        if (gradeStr == null) continue;

        final double? point = gradePoints[gradeStr];
        if (point == null) continue; // ignore W, IP, etc.

        // 2) Credits
        num? creditsNum;
        for (final key in ['credits', 'creditHours', 'hours', 'creditHour']) {
          final tmp = value[key];
          if (tmp is num) {
            creditsNum = tmp;
            break;
          }
        }

        double credits = (creditsNum?.toDouble() ?? 0);

        // Optional fallback: read from courses/{code}.credits
        if (credits <= 0 && courseCode.isNotEmpty) {
          try {
            final courseDoc = await FirebaseFirestore.instance
                .collection('courses')
                .doc(courseCode)
                .get();
            final cData = courseDoc.data();
            if (cData != null && cData['credits'] is num) {
              credits = (cData['credits'] as num).toDouble();
            }
          } catch (_) {
            // ignore per-course error
          }
        }

        if (credits <= 0) continue;

        totalCredits += credits;
        totalPoints += point * credits;
      }

      String gpaStr;
      if (totalCredits <= 0) {
        gpaStr = '—';
      } else {
        final gpaValue = totalPoints / totalCredits;
        gpaStr = gpaValue.toStringAsFixed(2);
      }

      if (mounted) {
        setState(() {
          gpa = gpaStr;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          gpa = '—';
        });
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

            // show loading indicator while courses are loading
            if (controller.loadingCourses)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              (isGrid ? _buildGridView() : _buildListView()),
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

        // determine GPA color band
        double? gpaNum;
        if (gpa != null) {
          try {
            gpaNum = double.parse(gpa!);
          } catch (_) {
            gpaNum = null;
          }
        }

        Color? gpaColor;
        if (gpaNum == null) {
          gpaColor = null; // default gradient
        } else if (gpaNum < 2.0) {
          gpaColor = Colors.redAccent.withOpacity(0.9); // poor
        } else if (gpaNum < 2.5) {
          gpaColor = const Color.fromARGB(
            255,
            253,
            152,
            19,
          ).withOpacity(0.9); // accepted
        } else if (gpaNum < 3.0) {
          gpaColor = Colors.amber.withOpacity(0.9); // good
        } else if (gpaNum < 3.65) {
          gpaColor = Colors.lightGreen.withOpacity(0.9); // very good
        } else {
          gpaColor = Colors.green.withOpacity(0.9); // excellent
        }

        final completionStr =
            "${controller.completionRate.toStringAsFixed(0)}%";
        final completedHoursStr = controller.completedHours.toString();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(value: completionStr, label: "Completion Rate"),
            _StatCard(value: completedHoursStr, label: "Completed Hours"),
            _StatCard(value: gpa ?? '—', label: "GPA", valueColor: gpaColor),
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
          isWithdrawn: course["isWithdrawn"] == '1',
          isListView: true,
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(24);
    return Container(
      width: 100,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x59FFFFFF), Color(0x26FFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black,
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
      ),
    );
  }
}
