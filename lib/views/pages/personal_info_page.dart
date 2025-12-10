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

  // Text controllers for each editable field
  final TextEditingController addressC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController altPhoneC = TextEditingController();
  final TextEditingController id1C = TextEditingController();
  final TextEditingController id1PhoneC = TextEditingController();
  final TextEditingController id2C = TextEditingController();
  final TextEditingController id2PhoneC = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await controller.loadInfo();
      if (info != null) {
        addressC.text = info.address;
        emailC.text = info.email;
        phoneC.text = info.phone;
        altPhoneC.text = info.altPhone;
        id1C.text = info.identifier1;
        id1PhoneC.text = info.identifier1Phone;
        id2C.text = info.identifier2;
        id2PhoneC.text = info.identifier2Phone;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load info: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final info = PersonalInfo(
        address: addressC.text.trim(),
        email: emailC.text.trim(),
        phone: phoneC.text.trim(),
        altPhone: altPhoneC.text.trim(),
        identifier1: id1C.text.trim(),
        identifier1Phone: id1PhoneC.text.trim(),
        identifier2: id2C.text.trim(),
        identifier2Phone: id2PhoneC.text.trim(),
      );

      await controller.updateInfo(info);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Personal info saved.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save info: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: 'Student’s Personal Info'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactInfoCard(primaryColor),
                  const SizedBox(height: 24),
                  _buildIdentifiersCard(primaryColor),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(primaryColor),
    );
  }

  // ===== UI helpers =====

  Widget _buildContactInfoCard(Color primaryColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: addressC,
                hint: 'Amman - Tabarbor',
                icon: Icons.home,
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: emailC,
                hint: 'your.personal@email.com',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: phoneC,
                hint: '07834737335',
                icon: Icons.phone,
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: altPhoneC,
                hint: '079736462084',
                icon: Icons.phone_android,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifiersCard(Color primaryColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identifiers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GlassTextField(
                      controller: id1C,
                      hint: 'Identifier 1',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: GlassTextField(
                      controller: id1PhoneC,
                      hint: '079999999',
                      icon: Icons.contact_phone_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GlassTextField(
                      controller: id2C,
                      hint: 'Identifier 2',
                      icon: Icons.badge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: GlassTextField(
                      controller: id2PhoneC,
                      hint: '078888888',
                      icon: Icons.contact_page_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                backgroundColor: Colors.white.withOpacity(0.3),
                side: BorderSide(color: Colors.red.shade400, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Cancel',
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
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
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
    );
  }
}
