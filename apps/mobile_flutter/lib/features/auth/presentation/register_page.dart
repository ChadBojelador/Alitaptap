import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/auth_service.dart';

const _amber = Color(0xFFFFC700);
const _dark = Color(0xFF1A1A1A);
const _white = Color(0xFFFFFFFF);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onRoleSelected});
  final void Function(String role) onRoleSelected;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedRole = 'student'; // always student, kept for Google sign-in defaultRole
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _setError(dynamic e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    setState(() => _error = msg);
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await _authService.register(email: email, password: pass, role: 'student');
      widget.onRoleSelected('student');
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) _setError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    final role = _selectedRole ?? 'student';
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _authService.signInWithGoogle(defaultRole: role);
      widget.onRoleSelected(result);
    } catch (e) {
      if (mounted) _setError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF0F0F0) : _dark;
    final subtleColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _amber.withValues(alpha: 0.10)),
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
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _amber.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_rounded, color: _amber, size: 16),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Create Account', style: GoogleFonts.poppins(color: textColor, fontSize: 26, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('Join ALITAPTAP and make an impact.', style: GoogleFonts.poppins(color: subtleColor, fontSize: 13)),
                      const SizedBox(height: 24),

                      // ── Google button ──────────────────────────────
                      _SocialBtn(
                        onTap: _loading ? null : _googleSignIn,
                        icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFF4285F4), size: 26),
                        label: 'Continue with Google',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: Divider(color: subtleColor.withValues(alpha: 0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or register with email', style: GoogleFonts.poppins(color: subtleColor, fontSize: 11)),
                        ),
                        Expanded(child: Divider(color: subtleColor.withValues(alpha: 0.3))),
                      ]),
                      const SizedBox(height: 20),
                      _label('Email', textColor),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'you@email.com',
                          hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.email_outlined, color: _amber, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Password', textColor),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: _amber, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePass = !_obscurePass),
                            child: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subtleColor, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Confirm Password', textColor),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.poppins(color: subtleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: _amber, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            child: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subtleColor, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _label('I am a...', textColor),
                      const SizedBox(height: 12),
                      _RoleCard(icon: Icons.people_alt_rounded, title: 'Student / Researcher', subtitle: 'Report problems and find research opportunities.', selected: true, isDark: isDark, onTap: () {}),
                      const SizedBox(height: 32),
                      if (_error != null) ...[  
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.4)),
                          ),
                          child: Text(_error!, style: GoogleFonts.poppins(color: const Color(0xFFEF5350), fontSize: 12)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      GestureDetector(
                        onTap: _loading ? null : _register,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _amber,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: _amber.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _dark))
                                : Text('Create Account', style: GoogleFonts.poppins(color: _dark, fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ', style: GoogleFonts.poppins(color: subtleColor, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text('Sign In', style: GoogleFonts.poppins(color: _amber, fontSize: 13, fontWeight: FontWeight.w700)),
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

  Widget _label(String text, Color color) => Text(text, style: GoogleFonts.poppins(color: color, fontSize: 13, fontWeight: FontWeight.w600));
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.onTap, required this.icon, required this.label, required this.isDark});
  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF0F0F0) : _dark)),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.selected, required this.isDark, required this.onTap});
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
          color: selected ? _amber.withValues(alpha: 0.12) : isDark ? const Color(0xFF242424) : _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _amber : _amber.withValues(alpha: 0.2), width: selected ? 1.5 : 1),
          boxShadow: selected ? [BoxShadow(color: _amber.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: selected ? _amber.withValues(alpha: 0.2) : _amber.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _amber, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: selected ? _amber : isDark ? const Color(0xFFF0F0F0) : _dark, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: GoogleFonts.poppins(color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575), fontSize: 11)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? _amber : _amber.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}
