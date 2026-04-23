import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/auth_service.dart';
import 'register_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.onRoleSelected});
  final void Function(String role) onRoleSelected;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _authService.signIn(email: email, password: pass);
      final role = (await _authService.getCurrentUserRole()).name;
      widget.onRoleSelected(role);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
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
    const amber = Color(0xFFFFC700);
    const dark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: amber.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: amber.withValues(alpha: 0.07),
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
                      const SizedBox(height: 48),
                      Center(
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: amber,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: amber.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/branding/logo_source.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('ALITAPTAP',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: isDark ? amber : dark,
                            fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 3,
                          )),
                      const SizedBox(height: 8),
                      Text('Community problems.\nStudent research.\nReal impact.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: subtleColor, fontSize: 14, height: 1.6)),
                      const SizedBox(height: 48),
                      Text('Email', style: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'you@email.com',
                          hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.email_outlined, color: amber, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Password', style: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                        onSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: amber, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subtleColor, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _loading ? null : _signIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: amber,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: amber.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: dark))
                                : Text('Sign In', style: GoogleFonts.poppins(color: dark, fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: GoogleFonts.poppins(color: subtleColor, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => RegisterPage(onRoleSelected: widget.onRoleSelected),
                            )),
                            child: Text('Register', style: GoogleFonts.poppins(color: amber, fontSize: 13, fontWeight: FontWeight.w700)),
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
}
