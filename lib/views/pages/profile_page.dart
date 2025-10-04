import 'package:flutter/material.dart';
import '../../controllers/profile_controller.dart';
import '../../models/student_model.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_card_custom.dart';
import 'personal_info_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: "Profile"),
      body: FutureBuilder<Student?>(
        future: controller.getStudent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No student data found."));
          }
          final student = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(student.profileImage),
                ),
                const SizedBox(height: 12),
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'University of Jordan - Amman',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  student.major,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Basic Information",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  title: "Payment Number",
                  value: student.paynum,
                  isRectangular: true,
                ),
                GlassCard(
                  title: "University Email",
                  value: student.email,
                  isRectangular: true,
                ),
                GlassCard(
                  title: "Advisor",
                  value: student.advisor,
                  isRectangular: true,
                ),
                GlassCardCustom(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location & DOB',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.location,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              student.dob,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInfoPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.6),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 6,
                      shadowColor: Colors.black26,
                    ),
                    child: const Text("View Personal Info"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
