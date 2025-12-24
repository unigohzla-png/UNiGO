import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ui/services/push_notifications_service.dart';

import 'firebase_options.dart';

// ✅ NEW
import 'services/session_prefs.dart';
import 'views/pages/forgot_password_page.dart';

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

import 'views/pages/about_page.dart';
import 'views/pages/help_page.dart';
import 'views/pages/notifications_page.dart';

// admin + roles
import 'models/user_role.dart';
import 'services/role_service.dart';
import 'views/admin/admin_root_page.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Push notifications init
  await PushNotificationsService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniGO',
      navigatorKey: navigatorKey,
      theme: ThemeData(fontFamily: 'IBMPlexSans'),
      initialRoute: '/',
      routes: {
        // both "/" and "/home" go through the auth+role gate
        '/': (context) => const AuthRoleGate(),
        '/home': (context) => const AuthRoleGate(),

        // ✅ forgot password
        '/forgot-password': (context) => const ForgotPasswordPage(),

        // student-only sub-pages
        '/reserve-time': (context) => const ReserveTimePage(),
        '/register-courses': (context) => const RegisterCoursesPage(),
        '/withdraw-courses': (context) => const WithdrawCoursesPage(),
        '/print-schedule': (context) => const PrintSchedulePage(),
        '/inquiry-subjects': (context) => const InquirySubjectsPage(),
        '/about': (context) => const AboutPage(),
        '/help': (context) => const HelpPage(),
        '/notifications': (context) => const NotificationsPage(),
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

/// ✅ UPDATED:
/// - If Remember Me is OFF → we force sign-out on app start
/// - If Remember Me is ON  → we keep session and auto-login works
class AuthRoleGate extends StatefulWidget {
  const AuthRoleGate({super.key});

  @override
  State<AuthRoleGate> createState() => _AuthRoleGateState();
}

class _AuthRoleGateState extends State<AuthRoleGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _applyRememberMePolicy();
  }

  Future<void> _applyRememberMePolicy() async {
    final remember = await SessionPrefs.rememberMe();

    // If remember-me is OFF, do not keep old session
    if (!remember && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // not logged in -> login screen
        final user = snap.data;
        if (user == null) {
          return const LoginPage();
        }

        // logged in -> check role
        return FutureBuilder<UserRole>(
          future: RoleService().getCurrentUserRole(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnap.hasError) {
              // safest fallback is student app
              return const MainScaffold();
            }

            if (!roleSnap.hasData) {
              return const MainScaffold();
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
    final media = MediaQuery.of(context);
    final safeBottom = media.padding.bottom;

    const navMargin = 24.0; // bottom padding
    const navHeight = 72.0; // reserve space for the floating bar itself
    final contentBottomPad = navHeight + navMargin + safeBottom;

    final barWidth = (media.size.width * 0.9).clamp(280.0, 420.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ✅ Give pages space so they don't get covered by the floating nav
          Padding(
            padding: EdgeInsets.only(bottom: contentBottomPad),
            child: IndexedStack(index: selectedIndex, children: _pages),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // ✅ Keep nav above device safe area (gesture bar)
              padding: EdgeInsets.only(bottom: navMargin + safeBottom),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: barWidth,
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
              fontFamily: "IBMPlexSans",
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
