import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// student views
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
import 'views/pages/course_page.dart';

// admin + roles
import 'models/user_role.dart';
import 'services/role_service.dart';
import 'views/admin/admin_root_page.dart';
import 'views/admin/admin_courses_page.dart'; // add this import at top
import 'views/admin/admin_home_page.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
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
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        // both "/" and "/home" go through the auth+role gate
        '/': (context) => const AuthRoleGate(),
        '/home': (context) => const AuthRoleGate(),

        '/admin-courses': (context) => const AdminCoursesPage(), // 👈 NEW
        '/admin-home': (context) => const AdminHomePage(), // 👈 NEW

        // student-only sub-pages
        '/reserve-time': (context) => const ReserveTimePage(),
        '/register-courses': (context) => const RegisterCoursesPage(),
        '/withdraw-courses': (context) => const WithdrawCoursesPage(),
        '/print-schedule': (context) => const PrintSchedulePage(),
        '/inquiry-subjects': (context) => const InquirySubjectsPage(),
        '/academic-plan': (context) => const AcademicPlanPage(),
        '/course': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          final title = args != null && args['title'] != null
              ? args['title'] as String
              : 'Course';
          final asset = args != null && args['asset'] != null
              ? args['asset'] as String
              : '';
          return CoursePage(title: title, asset: asset);
        },
      },
    );
  }
}

/// This widget decides which root to show:
/// - not logged in  -> LoginPage
/// - student        -> MainScaffold (your existing bottom-nav)
/// - admin/super    -> AdminRootPage
class AuthRoleGate extends StatelessWidget {
  const AuthRoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // not logged in -> login screen
        if (!snap.hasData) {
          return const LoginPage();
        }

        // logged in -> check role
        return FutureBuilder<UserRole>(
          future: RoleService().getCurrentUserRole(),
          builder: (context, roleSnap) {
            if (roleSnap.hasError) {
              // if anything goes wrong, safest fallback is student app
              return const MainScaffold();
            }

            if (!roleSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnap.data!;
            switch (role) {
              case UserRole.student:
                return const MainScaffold();
              case UserRole.admin:
              case UserRole.superAdmin:
                return AdminRootPage(role: role);
            }
          },
        );
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

  final List<Widget> _pages = const [
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
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                        _buildNavItem(Icons.calendar_today, "Calendar", 2),
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
