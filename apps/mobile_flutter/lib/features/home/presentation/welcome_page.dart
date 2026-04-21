import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/main_shell.dart';

const _amber = Color(0xFFFFA726);
const _dark = Color(0xFF1A1A1A);

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, this.onToggleTheme});
  final VoidCallback? onToggleTheme;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  bool _starting = false;

  Future<void> _getStarted() async {
    if (_starting) return;
    setState(() => _starting = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            MainShell(onToggleTheme: widget.onToggleTheme),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          // Amber blob top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _amber.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Amber blob bottom-left
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _amber.withValues(alpha: 0.10),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: size.height * 0.10),

                      // Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _amber,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: _amber.withValues(alpha: 0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: _dark,
                          size: 38,
                        ),
                      ),

                      SizedBox(height: size.height * 0.06),

                      // App name
                      Text(
                        'ALITAPTAP',
                        style: GoogleFonts.poppins(
                          color: _amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Headline
                      Text(
                        'Ready to tap your next research project',
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Subtitle
                      Text(
                        'Discover real community problems,\nmatch your ideas, and make an impact.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9E9E9E),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      const Spacer(),

                      // Feature pills
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _Pill(icon: Icons.map_rounded, label: 'Community Map'),
                          _Pill(icon: Icons.auto_awesome_rounded, label: 'AI Matching'),
                          _Pill(icon: Icons.science_rounded, label: 'Innovation Expo'),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Get Started button
                      GestureDetector(
                        onTap: _starting ? null : _getStarted,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          scale: _starting ? 0.98 : 1,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: _starting ? 0.85 : 1,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: _amber,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _amber.withValues(alpha: 0.45),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _starting ? 'Starting...' : 'Get Started',
                                    style: GoogleFonts.poppins(
                                      color: _dark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    _starting
                                        ? Icons.hourglass_top_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: _dark,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _amber),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _dark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
