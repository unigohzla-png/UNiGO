import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlassAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  const GlassAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(60);
  @override
  State<GlassAppBar> createState() => _GlassAppBarState();
}

class _GlassAppBarState extends State<GlassAppBar> {
  bool isArabic = false;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () => _showSettingsMenu(context),
        ),
      ],
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final lang = ValueNotifier<bool>(isArabic);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 70, right: 16),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: lang,
                      builder: (context, arabic, __) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _menuText("About"),
                            _menuText("Help"),
                            _menuText("Notifications"),
                            _logoutItem(),
                            const Divider(thickness: 0.8),
                            Row(
                              children: [
                                _roundIconButton(
                                  icon: Icons.nightlight_round,
                                  color: Colors.amber,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 12),
                                _langToggle(
                                  arabic: arabic,
                                  onTap: () {
                                    lang.value = !arabic;
                                    setState(() => isArabic = !arabic);
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _logoutItem() {
    return GestureDetector(
      onTap: () async {
        // close the settings dialog first
        Navigator.pop(context);
        try {
          await FirebaseAuth.instance.signOut();
          // navigate back to login screen and clear navigation stack
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Logged out')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: const [
            Icon(Icons.logout, size: 18, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              "Logout",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuText(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
  );

  Widget _roundIconButton({
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1),
          color: Colors.white.withOpacity(0.25),
        ),
        child: Center(
          child: Icon(icon, color: color ?? Colors.black, size: 20),
        ),
      ),
    );
  }

  // Animated language toggle: A <-> ع
  Widget _langToggle({required bool arabic, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1),
          color: Colors.white.withOpacity(0.25),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              arabic ? "ع" : "A",
              key: ValueKey(arabic),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

