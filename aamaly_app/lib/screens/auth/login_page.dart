// ============================================
// FILE: lib/screens/login_page.dart
// UI MATCHES REGISTER PAGE (Glass Card + Dark BG)
// FUNCTIONS/LOGIC SAME AS YOUR LOGIN PAGE
// ============================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';
import '../dashboard/dashboard_page.dart';
import 'register_page.dart';
import '../../services/admin_service.dart';
import '../dashboard/admin_dashboard_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // ✅ SAME FUNCTION (UNCHANGED)
  Future<void> _checkAutoLogin() async {
    final user = await _authService.autoLogin();
    if (user != null && mounted) {
      if (AdminService.isAdmin(user.email)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    }
  }

  // ✅ SAME FUNCTION (UNCHANGED)
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (AdminService.isAdmin(_emailController.text.trim())) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ SAME FUNCTION (UNCHANGED)
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ====== UI HELPERS (same style as Register) ======
  static const Color _bg = Color(0xFF0E141B);
  static const Color _primary = Color(0xFF7C4DFF);
  static const Color _text = Color(0xFFF2F4F8);
  static const Color _muted = Color(0xFF9AA7B4);

  OutlineInputBorder _outline(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: 1),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background image (YOU can change this)
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_aamaly1.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Dark overlay (matches register feel)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Stack(
                    children: [
                      // ✅ GLASS CARD (same structure as RegisterPage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 28,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 10),

                                  // ✅ LOGO PLACEHOLDER (you replace image yourself)
                                  Center(
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/logoaamaly.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  const Text(
                                    'Welcome Back',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // ✅ Email (same style as Register fields)
                                  _GlassField(
                                    label: 'Email address',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@') ||
                                          !value.contains('.')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    outlineBuilder: _outline,
                                  )
                                      .animate()
                                      .fadeIn(delay: 300.ms)
                                      .scale(begin: const Offset(0.9, 0.9)),

                                  const SizedBox(height: 14),

                                  // ✅ Password (same style as Register fields)
                                  _GlassField(
                                    label: 'Password',
                                    controller: _passwordController,
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white.withOpacity(0.75),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    outlineBuilder: _outline,
                                  )
                                      .animate()
                                      .fadeIn(delay: 300.ms)
                                      .scale(begin: const Offset(0.9, 0.9)),

                                  const SizedBox(height: 10),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ✅ Login button (same as register feel, purple gradient-like)
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // ✅ bottom link (same layout as register)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Are you new member? ',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.70),
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _navigateToRegister,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            decoration:
                                                TextDecoration.underline,
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
                      ),

                      // ✅ Back button (top-left like your register)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _bg,
    );
  }
}

// ============================================
// Glass Field Widget (same look as Register page fields)
// ============================================

class _GlassField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  // Pass in outline builder so it matches page settings
  final OutlineInputBorder Function(Color) outlineBuilder;

  const _GlassField({
    required this.label,
    required this.controller,
    required this.outlineBuilder,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const kText = Color(0xFFF2F4F8);
    const kPrimary = Color(0xFF7C4DFF);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: outlineBuilder(Colors.white.withOpacity(0.35)),
        focusedBorder: outlineBuilder(kPrimary.withOpacity(0.95)),
        errorBorder: outlineBuilder(Colors.red.withOpacity(0.9)),
        focusedErrorBorder: outlineBuilder(Colors.red.withOpacity(0.9)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: Colors.white.withOpacity(0.70)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
