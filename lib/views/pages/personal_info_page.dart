import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/personal_info_controller.dart';
import '../../models/personal_info_model.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/glass_text_field.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final PersonalInfoController controller = PersonalInfoController();

  late TextEditingController addressC;
  late TextEditingController emailC;
  late TextEditingController phoneC;
  late TextEditingController altPhoneC;
  late TextEditingController id1C;
  late TextEditingController id1PhoneC;
  late TextEditingController id2C;
  late TextEditingController id2PhoneC;

  @override
  void initState() {
    super.initState();
    final info = controller.info;
    addressC = TextEditingController(text: info.address);
    emailC = TextEditingController(text: info.email);
    phoneC = TextEditingController(text: info.phone);
    altPhoneC = TextEditingController(text: info.altPhone);
    id1C = TextEditingController(text: info.identifier1);
    id1PhoneC = TextEditingController(text: info.identifier1Phone);
    id2C = TextEditingController(text: info.identifier2);
    id2PhoneC = TextEditingController(text: info.identifier2Phone);
  }

  @override
  void dispose() {
    addressC.dispose();
    emailC.dispose();
    phoneC.dispose();
    altPhoneC.dispose();
    id1C.dispose();
    id1PhoneC.dispose();
    id2C.dispose();
    id2PhoneC.dispose();
    super.dispose();
  }

  void _save() {
    controller.updateInfo(
      PersonalInfo(
        address: addressC.text,
        email: emailC.text,
        phone: phoneC.text,
        altPhone: altPhoneC.text,
        identifier1: id1C.text,
        identifier1Phone: id1PhoneC.text,
        identifier2: id2C.text,
        identifier2Phone: id2PhoneC.text,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: "Student’s Personal Info"),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: addressC,
              hint: "Amman - Tabarbor",
              icon: Icons.home_outlined,
            ),
            GlassTextField(
              controller: emailC,
              hint: "johncena@gmail.com",
              icon: Icons.email_outlined,
            ),
            GlassTextField(
              controller: phoneC,
              hint: "07834737335",
              icon: Icons.phone,
            ),
            GlassTextField(
              controller: altPhoneC,
              hint: "079736462084",
              icon: Icons.phone_android,
            ),

            const SizedBox(height: 28),

            const Text(
              "Identifiers",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: id1C,
              hint: "Identifier 1",
              icon: Icons.badge_outlined,
            ),
            GlassTextField(
              controller: id1PhoneC,
              hint: "Phone of Identifier 1",
              icon: Icons.contact_phone_outlined,
            ),
            GlassTextField(
              controller: id2C,
              hint: "Identifier 2",
              icon: Icons.badge,
            ),
            GlassTextField(
              controller: id2PhoneC,
              hint: "Phone of Identifier 2",
              icon: Icons.contact_phone,
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        side: BorderSide(
                          color: Colors.red.shade400,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withValues(alpha: 0.85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
