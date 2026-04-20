import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onRoleSelected});
  final void Function(String role) onRoleSelected;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedRole;
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and select a role.')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      await cred.user?.updateDisplayName(_selectedRole);
      // Save role + email to Firestore
      await ApiService().setUserRole(
        userId: cred.user!.uid,
        role: _selectedRole!,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({'email': email}, SetOptions(merge: true));
      widget.onRoleSelected(_selectedRole!);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('[${e.code}] ${e.message ?? 'Registration failed'}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)]
                    : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
              ),
            ),
          ),
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD60A).withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const SizedBox(height: 24),

                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Color(0xFFFFD60A), size: 16),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text('Create Account',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 6),
                  Text('Join ALITAPTAP and make an impact.',
                      style: GoogleFonts.poppins(
                          color: subtleColor, fontSize: 13)),

                  const SizedBox(height: 32),

                  // Email
                  _label('Email', textColor),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'you@email.com',
                      hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Color(0xFFFFD60A), size: 20),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password
                  _label('Password', textColor),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: Color(0xFFFFD60A), size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePass = !_obscurePass),
                        child: Icon(
                          _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: subtleColor, size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password
                  _label('Confirm Password', textColor),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: Color(0xFFFFD60A), size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: subtleColor, size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role selection
                  _label('I am a...', textColor),
                  const SizedBox(height: 12),

                  _RoleCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Community Member',
                    subtitle: 'I want to report local problems.',
                    selected: _selectedRole == 'community',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedRole = 'community'),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    icon: Icons.school_rounded,
                    title: 'Student / Researcher',
                    subtitle: 'I want to find research opportunities.',
                    selected: _selectedRole == 'student',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedRole = 'student'),
                  ),

                  const SizedBox(height: 32),

                  // Register button
                  GestureDetector(
                    onTap: _loading ? null : _register,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedRole == null
                            ? const Color(0xFFFFD60A).withValues(alpha: 0.3)
                            : const Color(0xFFFFD60A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedRole == null
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFFFFD60A).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF1A1A1A)))
                            : Text('Create Account',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                )),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.poppins(
                              color: subtleColor, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text('Sign In',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFD60A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: GoogleFonts.poppins(
          color: color, fontSize: 13, fontWeight: FontWeight.w600));
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD60A).withValues(alpha: 0.12)
              : isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD60A)
                : const Color(0xFFFFD60A).withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFD60A).withValues(alpha: 0.2)
                    : const Color(0xFFFFD60A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFD60A), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                        color: selected
                            ? const Color(0xFFFFD60A)
                            : isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666),
                        fontSize: 11,
                      )),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFFFFD60A)
                  : const Color(0xFFFFD60A).withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
