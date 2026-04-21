import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/usecases/sign_in_anonymously_use_case.dart';
import '../data/repositories/firebase_auth_repository.dart';

/// Landing page where users pick their role before entering the app.
/// Role is passed directly to the app without Firestore.
/// TODO: persist role to Firestore once security rules are configured.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.onRoleSelected});
  final void Function(String role) onRoleSelected;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _authRepository = FirebaseAuthRepository();
  late final SignInAnonymouslyUseCase _signInAnonymouslyUseCase =
      SignInAnonymouslyUseCase(_authRepository);
  bool _loading = false;
  String? _selectedRole; // 'community' | 'student'

  // BYPASS NOTE
  // -----------
  // Originally this method called AuthService.setRole() to persist the chosen
  // role to Firestore so returning users skip this screen. That call was
  // commented out because Firestore security rules are not yet configured,
  // which caused a "permission-denied" error on every sign-in attempt.
  //
  // What was removed:
  //   await _authService.setRole(_selectedRole!);
  //
  // To restore: configure Firestore rules to allow authenticated users to
  // write their own users/{uid} document, then uncomment the line above.
  // See docs/00-governance/firebase-setup.md for the required ruleset.
  Future<void> _proceed() async {
    if (_selectedRole == null || _loading) return;
    setState(() => _loading = true);
    try {
      await _signInAnonymouslyUseCase();
      // TODO: uncomment once Firestore rules allow users/{uid} writes.
      // await _authService.setRole(_selectedRole!);
      widget.onRoleSelected(_selectedRole!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // Warm amber blob top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFA726).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFA726).withValues(alpha: 0.07),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Logo + title
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA726).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Color(0xFF1A1A1A),
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ALITAPTAP',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: isDark ? const Color(0xFFFFA726) : const Color(0xFF1A1A1A),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community problems.\nStudent research.\nReal impact.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: subtleColor,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 48),

                  Text(
                    'Who are you?',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Community role card
                  _RoleCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Community Member',
                    subtitle:
                        'I want to report local problems and help researchers find real community needs.',
                    selected: _selectedRole == 'community',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedRole = 'community'),
                  ),
                  const SizedBox(height: 14),

                  // Student role card
                  _RoleCard(
                    icon: Icons.school_rounded,
                    title: 'Student / Researcher',
                    subtitle:
                        'I want to explore community problems and find research opportunities.',
                    selected: _selectedRole == 'student',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedRole = 'student'),
                  ),
                  const SizedBox(height: 14),

                  // Admin role card
                  _RoleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin',
                    subtitle:
                        'Validate or reject community problem reports.',
                    selected: _selectedRole == 'admin',
                    isDark: isDark,
                    onTap: () => setState(() => _selectedRole = 'admin'),
                  ),

                  const Spacer(),

                  // Continue button
                  GestureDetector(
                    onTap: _selectedRole == null || _loading ? null : _proceed,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedRole == null
                            ? const Color(0xFFFFA726).withValues(alpha: 0.3)
                            : const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedRole == null
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFFFFA726)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_loading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A1A1A),
                              ),
                            )
                          else
                            const Icon(Icons.arrow_forward_rounded,
                                color: Color(0xFF1A1A1A), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _loading ? 'Loading...' : 'Continue',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFA726).withValues(alpha: 0.12)
              : isDark
                  ? const Color(0xFF242424)
                  : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFA726)
                : const Color(0xFFFFA726).withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFA726).withValues(alpha: 0.2)
                    : const Color(0xFFFFA726).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFA726), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: selected
                          ? const Color(0xFFFFA726)
                          : isDark
                              ? const Color(0xFFF0F0F0)
                              : const Color(0xFF1A1A1A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: isDark
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF666666),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFFFFA726)
                  : const Color(0xFFFFA726).withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
