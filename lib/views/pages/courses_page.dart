import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/courses_controller.dart';
import '../widgets/course_item.dart';
import '../widgets/register_card.dart';
import '../widgets/glass_appbar.dart';
import '../pages/absences_page.dart';
import '../pages/grades_page.dart';
import '../pages/completed_courses_page.dart';
import '../pages/gpa_calc_page.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final CoursesController controller = CoursesController();
  bool showCourses = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.loadUserCourses();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: "Courses"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton("Current"),
                      _buildTabButton("Register"),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: controller.selectedTab == "Current"
                  ? _buildCurrentCourses()
                  : _buildRegisterOptions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = controller.selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => controller.switchTab(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCourses() {
    return ListView(
      children: [
        ListTile(
          title: const Text(
            "Current Courses",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          trailing: Icon(
            showCourses ? Icons.expand_less : Icons.expand_more,
            color: Colors.black54,
          ),
          onTap: () => setState(() => showCourses = !showCourses),
        ),

        if (showCourses) ...[
          if (controller.loadingCourses)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.currentCourses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No current courses found',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: controller.currentCourses.map((course) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/course',
                            arguments: {
                              'title': course['title']!,
                              'asset': course['asset']!,
                            },
                          );
                        },
                        child: CourseItem(
                          title: course["title"]!,
                          assetPath: course["asset"]!,
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 40,
                      endIndent: 12,
                      color: Colors.black12,
                    ),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
        ],

        _buildNavItem(Icons.calendar_month, "Absences"),
        _buildNavItem(Icons.star, "Grades"),
        _buildNavItem(Icons.done_all, "Completed Courses"),
        _buildNavItem(Icons.calculate, "GPA Calculator"),
      ],
    );
  }

  Widget _buildRegisterOptions() {
    return GridView.builder(
      itemCount: controller.registerOptions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final option = controller.registerOptions[index];
        return RegisterCard(
          icon: option["icon"],
          title: option["title"],
          onTap: () {
            switch (option["title"]) {
              case "Reserve Time":
                Navigator.pushNamed(context, '/reserve-time');
                break;
              case "Register Courses":
                Navigator.pushNamed(context, '/register-courses');
                break;
              case "Withdraw Courses":
                Navigator.pushNamed(context, '/withdraw-courses');
                break;
              case "Print Schedule":
                Navigator.pushNamed(context, '/print-schedule');
                break;
              case "Inquiry Subjects":
                Navigator.pushNamed(context, '/inquiry-subjects');
                break;
              case "Academic Plan":
                Navigator.pushNamed(context, '/academic-plan');
                break;
            }
          },
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: () {
        if (label == "Absences") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AbsencesPage()),
          );
        } else if (label == "Grades") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GradesPage()),
          );
        } else if (label == "Completed Courses") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompletedCoursesPage()),
          );
        } else if (label == "GPA Calculator") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GPACalcPage()),
          );
        }
      },
    );
  }
}
