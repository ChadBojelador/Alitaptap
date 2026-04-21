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
    ),
    _OnboardingCardData(
      icon: Icons.auto_awesome_rounded,
      title: 'Match Ideas With AI',
      subtitle:
          'Use smart suggestions to connect your concepts with local needs and project goals.',
      accent: Color(0xFFFFCC80),
    ),
    _OnboardingCardData(
      icon: Icons.science_rounded,
      title: 'Build Impactful Projects',
      subtitle:
          'Turn research into action, collaborate, and showcase outcomes in the innovation expo.',
      accent: Color(0xFFFFE0B2),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
                      color: const Color(0xFF8A8A8A),
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
                    return _OnboardingCard(card: card);
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
                          : const Color(0xFFE2E2E2),
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
  const _OnboardingCard({required this.card});

  final _OnboardingCardData card;

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
            card.accent.withValues(alpha: 0.28),
            const Color(0xFFFFFFFF),
          ],
        ),
        border: Border.all(color: card.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(card.icon, color: _dark, size: 34),
          ),
          const SizedBox(height: 28),
          Text(
            card.title,
            style: GoogleFonts.poppins(
              color: _dark,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            card.subtitle,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6E6E6E),
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
                  color: const Color(0xFF6E6E6E),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
}
