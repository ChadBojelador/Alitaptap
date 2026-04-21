import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/main_shell.dart';

const _amber = Color(0xFFFFA726);
const _dark = Color(0xFF1A1A1A);

class OnboardingCarouselPage extends StatefulWidget {
  const OnboardingCarouselPage({super.key, this.onToggleTheme});

  final VoidCallback? onToggleTheme;

  @override
  State<OnboardingCarouselPage> createState() => _OnboardingCarouselPageState();
}

class _OnboardingCarouselPageState extends State<OnboardingCarouselPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _finishing = false;

  static const _cards = [
    _OnboardingCardData(
      icon: Icons.map_rounded,
      title: 'Spot Real Community Problems',
      subtitle:
          'Browse reports on a live map and discover issues that need research-backed solutions.',
      accent: Color(0xFFFFB74D),
      visual: _OnboardingVisual.map,
    ),
    _OnboardingCardData(
      icon: Icons.auto_awesome_rounded,
      title: 'Match Ideas With AI',
      subtitle:
          'Use smart suggestions to connect your concepts with local needs and project goals.',
      accent: Color(0xFFFFCC80),
      visual: _OnboardingVisual.ai,
    ),
    _OnboardingCardData(
      icon: Icons.science_rounded,
      title: 'Build Impactful Projects',
      subtitle:
          'Turn research into action, collaborate, and showcase outcomes in the innovation expo.',
      accent: Color(0xFFFFE0B2),
      visual: _OnboardingVisual.lab,
    ),
  ];

  Future<void> _completeOnboarding() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => MainShell(onToggleTheme: widget.onToggleTheme),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _onPrimaryAction() {
    if (_currentIndex < _cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA);
    final skipColor = isDark ? const Color(0xFFB5B5B5) : const Color(0xFF8A8A8A);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishing ? null : _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: skipColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _cards.length,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return _OnboardingCard(card: card, isDark: isDark);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _cards.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? _amber
                          : (isDark
                              ? const Color(0xFF4B4B4B)
                              : const Color(0xFFE2E2E2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishing ? null : _onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: _dark,
                    minimumSize: const Size.fromHeight(56),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentIndex == _cards.length - 1
                        ? (_finishing ? 'Starting...' : 'Start Exploring')
                        : 'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.card, required this.isDark});

  final _OnboardingCardData card;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.accent.withValues(alpha: isDark ? 0.30 : 0.28),
            isDark ? const Color(0xFF262626) : const Color(0xFFFFFFFF),
          ],
        ),
        border: Border.all(color: card.accent.withValues(alpha: isDark ? 0.62 : 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardIllustration(card: card, isDark: isDark),
          const SizedBox(height: 20),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(card.icon, color: _dark, size: 28),
          ),
          const SizedBox(height: 22),
          Text(
            card.title,
            style: GoogleFonts.poppins(
              color: isDark ? const Color(0xFFF1F1F1) : _dark,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            card.subtitle,
            style: GoogleFonts.poppins(
              color: isDark ? const Color(0xFFC2C2C2) : const Color(0xFF6E6E6E),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.swipe_left_rounded, color: _amber.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                'Swipe left to continue',
                style: GoogleFonts.poppins(
                  color: isDark ? const Color(0xFFC2C2C2) : const Color(0xFF6E6E6E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingCardData {
  const _OnboardingCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.visual,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final _OnboardingVisual visual;
}

enum _OnboardingVisual { map, ai, lab }

class _CardIllustration extends StatelessWidget {
  const _CardIllustration({required this.card, required this.isDark});

  final _OnboardingCardData card;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.accent.withValues(alpha: 0.35),
            card.accent.withValues(alpha: isDark ? 0.16 : 0.12),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -34,
            left: -22,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _amber.withValues(alpha: isDark ? 0.12 : 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: card.accent.withValues(alpha: isDark ? 0.18 : 0.25),
              ),
            ),
          ),
          Center(child: _buildVisual()),
        ],
      ),
    );
  }

  Widget _buildVisual() {
    switch (card.visual) {
      case _OnboardingVisual.map:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _tile(icon: Icons.place_rounded, label: 'Map', color: _amber),
            const SizedBox(width: 10),
            _tile(
              icon: Icons.report_problem_rounded,
              label: 'Issues',
              color: const Color(0xFFFF8A65),
            ),
            const SizedBox(width: 10),
            _tile(
              icon: Icons.location_searching_rounded,
              label: 'Near You',
              color: const Color(0xFFFFD180),
            ),
          ],
        );
      case _OnboardingVisual.ai:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(icon: Icons.lightbulb_rounded, color: _amber),
            const SizedBox(width: 12),
            Icon(
              Icons.sync_alt_rounded,
              size: 24,
              color: (isDark ? Colors.white : _dark).withValues(alpha: 0.65),
            ),
            const SizedBox(width: 12),
            _chip(icon: Icons.psychology_rounded, color: const Color(0xFFFFC266)),
          ],
        );
      case _OnboardingVisual.lab:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _tile(
              icon: Icons.science_rounded,
              label: 'Research',
              color: const Color(0xFFFFCC80),
            ),
            const SizedBox(width: 10),
            _tile(
              icon: Icons.groups_rounded,
              label: 'Team',
              color: _amber,
            ),
            const SizedBox(width: 10),
            _tile(
              icon: Icons.emoji_events_rounded,
              label: 'Expo',
              color: const Color(0xFFFFAB40),
            ),
          ],
        );
    }
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2F2F2F).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: _dark),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isDark ? const Color(0xFFECECEC) : _dark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required Color color}) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2F2F2F).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white,
        ),
      ),
      child: Center(
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _dark, size: 24),
        ),
      ),
    );
  }
}
