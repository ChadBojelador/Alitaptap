import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../services/auth_service.dart';
import 'register_page.dart';

const _amber = Color(0xFFFFC700);
const _dark = Color(0xFF1A1A1A);

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
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _setError(dynamic e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    setState(() => _error = msg);
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.signIn(email: email, password: pass);
      final role = (await _authService.getCurrentUserRole()).name;
      widget.onRoleSelected(role);
    } catch (e) {
      if (mounted) _setError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final role = await _authService.signInWithGoogle();
      widget.onRoleSelected(role);
    } catch (e) {
      if (mounted) _setError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _facebookSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final role = await _authService.signInWithFacebook();
      widget.onRoleSelected(role);
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
    final subtleColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Positioned(top: -80, right: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _amber.withValues(alpha: 0.12)))),
          Positioned(bottom: -60, left: -60,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _amber.withValues(alpha: 0.07)))),
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
                            color: _amber,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _amber.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset('assets/branding/logo_source.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('ALITAPTAP', textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: isDark ? _amber : _dark, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 3)),
                      const SizedBox(height: 8),
                      Text('Community problems.\nStudent research.\nReal impact.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: subtleColor, fontSize: 14, height: 1.6)),
                      const SizedBox(height: 32),

                      // ── Social buttons ──────────────────────────────
                      _SocialButton(
                        onTap: _loading ? null : _googleSignIn,
                        icon: _GoogleIcon(),
                        label: 'Continue with Google',
                        isDark: isDark,
                        cardBg: cardBg,
                      ),
                      const SizedBox(height: 10),
                      _SocialButton(
                        onTap: _loading ? null : _facebookSignIn,
                        icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 22),
                        label: 'Continue with Facebook',
                        isDark: isDark,
                        cardBg: cardBg,
                      ),

                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: Divider(color: subtleColor.withValues(alpha: 0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: GoogleFonts.poppins(color: subtleColor, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: subtleColor.withValues(alpha: 0.3))),
                      ]),
                      const SizedBox(height: 20),

                      // ── Email / password ────────────────────────────
                      Text('Email', style: GoogleFonts.poppins(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
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
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: _amber, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subtleColor, size: 20),
                          ),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.4)),
                          ),
                          child: Text(_error!, style: GoogleFonts.poppins(color: const Color(0xFFEF5350), fontSize: 12)),
                        ),
                      ],

                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _loading ? null : _signIn,
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
                                : Text('Sign In', style: GoogleFonts.poppins(color: _dark, fontWeight: FontWeight.w700, fontSize: 15)),
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
                            child: Text('Register', style: GoogleFonts.poppins(color: _amber, fontSize: 13, fontWeight: FontWeight.w700)),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.onTap, required this.icon, required this.label, required this.isDark, required this.cardBg});
  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final bool isDark;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg,
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

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22, height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paints = [
      Paint()..color = const Color(0xFF4285F4),
      Paint()..color = const Color(0xFF34A853),
      Paint()..color = const Color(0xFFFBBC05),
      Paint()..color = const Color(0xFFEA4335),
    ];
    // Simple colored circle as Google icon placeholder
    canvas.drawCircle(Offset(s / 2, s / 2), s / 2, paints[0]);
    canvas.drawArc(Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s / 2),
        0.5, 1.0, false, paints[1]);
    canvas.drawArc(Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s / 2),
        1.5, 1.0, false, paints[2]);
    canvas.drawArc(Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s / 2),
        2.5, 1.0, false, paints[3]);
  }

  @override
  bool shouldRepaint(_) => false;
}
