import 'dart:ui';
import 'package:flutter/material.dart';
import 'views/pages/login_page.dart';
import 'views/pages/home_page.dart';
import 'views/pages/courses_page.dart';
import 'views/pages/calendar_page.dart';
import 'views/pages/profile_page.dart';
import 'views/pages/reserve_time_page.dart';
import 'views/pages/register_courses_page.dart';
import 'views/pages/withdraw_courses_page.dart';
import 'views/pages/print_schedule_page.dart';
import 'views/pages/inquiry_subjects_page.dart';
import 'views/pages/academic_plan_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University IT Student',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(), // start at login
        '/home': (context) => const MainScaffold(), // main scaffold after login
        '/reserve-time': (context) => const ReserveTimePage(),
        '/register-courses': (context) => const RegisterCoursesPage(),
        '/withdraw-courses': (context) => const WithdrawCoursesPage(),
        '/print-schedule': (context) => const PrintSchedulePage(),
        '/inquiry-subjects': (context) => const InquirySubjectsPage(),
        '/academic-plan': (context) => const AcademicPlanPage(),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    CoursesPage(),
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(index: selectedIndex, children: _pages),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home, "Home", 0),
                        _buildNavItem(Icons.book, "Courses", 1),
                        _buildNavItem(Icons.calendar_today, "Schedule", 2),
                        _buildNavItem(Icons.person, "Profile", 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.black54),
          Text(
            label,
            style: TextStyle(
              fontFamily: "AnekTelugu",
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
//blah blah