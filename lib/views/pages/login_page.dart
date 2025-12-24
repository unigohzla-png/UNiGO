import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/session_prefs.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberState();
  }

  Future<void> _loadRememberState() async {
    final remember = await SessionPrefs.rememberMe();
    final lastEmail = await SessionPrefs.lastEmail();
    if (!mounted) return;

    setState(() {
      _rememberMe = remember;
      if (lastEmail != null && lastEmail.isNotEmpty) {
        _emailController.text = lastEmail;
      }
    });
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final pass = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Failed to get signed-in user.',
        );
      }

      // Save remember-me choice
      await SessionPrefs.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await SessionPrefs.setLastEmail(email);
      } else {
        await SessionPrefs.clearLastEmail();
      }

      // Role routing
      final uid = user.uid;
      final roleDoc = await FirebaseFirestore.instance
          .collection('roles')
          .doc(uid)
          .get();
      final roleData = roleDoc.data() ?? {};
      final String roleStr = (roleData['role'] ?? '').toString();

      bool isAdmin = false;
      bool isSuperAdmin = false;

      switch (roleStr) {
        case 'admin':
          isAdmin = true;
          break;
        case 'superAdmin':
          isSuperAdmin = true;
          break;
        default:
          final bool legacyAdmin = (roleData['admin'] ?? false) == true;
          final bool legacySuperAdmin =
              (roleData['super_admin'] ?? false) == true;
          isAdmin = legacyAdmin;
          isSuperAdmin = legacySuperAdmin;
      }

      if (!mounted) return;

      if (isAdmin || isSuperAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(color: Colors.black.withOpacity(0)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(170, 193, 221, 208),
                  Color.fromARGB(170, 11, 62, 2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/final_logo.png', height: 180),
                          const SizedBox(height: 16),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: "Email",
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(
                                          0.2,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText: "Password",
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(
                                          0.2,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    if (_errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                        ),
                                        onPressed: _loading ? null : _login,
                                        child: _loading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                "Log In",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (val) {
                                            setState(
                                              () => _rememberMe = val ?? false,
                                            );
                                          },
                                        ),
                                        const Text(
                                          "Remember me",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            '/forgot-password',
                                          ),
                                          child: const Text(
                                            "Forgot password?",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
