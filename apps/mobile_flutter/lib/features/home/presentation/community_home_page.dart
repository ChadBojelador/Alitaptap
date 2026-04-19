import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../civic_intelligence/presentation/issue_map_page.dart';
import '../../civic_intelligence/presentation/issue_submit_page.dart';

/// Community member home — report local problems or browse the map.
/// Entry point for civilians who want to pin a problem on the community map.
class CommunityHomePage extends StatelessWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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

          // Decorative yellow glow top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD60A).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFD60A).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(Icons.people_alt_rounded,
                            color: Color(0xFFFFD60A), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALITAPTAP',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFD60A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Community Hub',
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? const Color(0xFFF0F0F0)
                                  : const Color(0xFF1A1A1A),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Your voice shapes research. Report local problems and help students find real community needs.',
                    style: GoogleFonts.poppins(
                      color: isDark
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF555555),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Report a Problem card
                  _ActionCard(
                    icon: Icons.add_location_alt_rounded,
                    title: 'Report a Problem',
                    subtitle:
                        'Pin a community issue on the map with location and details.',
                    isPrimary: true,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IssueSubmitPage(reporterId: uid),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // View Map card
                  _ActionCard(
                    icon: Icons.map_rounded,
                    title: 'View Community Map',
                    subtitle:
                        'Browse all reported problems pinned across the Philippines.',
                    isPrimary: false,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IssueMapPage()),
                    ),
                  ),

                  const Spacer(),

                  // Footer note
                  Center(
                    child: Text(
                      'Problems you report help students build impactful research.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? const Color(0xFF616161)
                            : const Color(0xFF9E9E9E),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Student home — explore the map or match a research idea to problems.
class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD60A).withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFD60A).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Color(0xFFFFD60A), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALITAPTAP',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFD60A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Research Hub',
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? const Color(0xFFF0F0F0)
                                  : const Color(0xFF1A1A1A),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Turn community problems into research. Explore the map or let AI match your idea to real local issues.',
                    style: GoogleFonts.poppins(
                      color: isDark
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF555555),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Explore map
                  _ActionCard(
                    icon: Icons.explore_rounded,
                    title: 'Explore the Map',
                    subtitle:
                        'Browse community problems on the live map and find your research focus.',
                    isPrimary: true,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IssueMapPage(
                          showIdeaDock: true,
                          studentId: uid,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Match idea
                  _ActionCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Match Your Research Idea',
                    subtitle:
                        'Describe your research and AI will find the most relevant community problems.',
                    isPrimary: false,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _IdeaMatchEntryPage(studentId: uid),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Center(
                    child: Text(
                      'Research that starts in the community creates real impact.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? const Color(0xFF616161)
                            : const Color(0xFF9E9E9E),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable action card used in both home pages.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary
        ? const Color(0xFFFFD60A)
        : isDark
            ? const Color(0xFF242424)
            : const Color(0xFFFFFFFF);

    final textColor = isPrimary
        ? const Color(0xFF1A1A1A)
        : isDark
            ? const Color(0xFFF0F0F0)
            : const Color(0xFF1A1A1A);

    final subtitleColor = isPrimary
        ? const Color(0xFF3A3A3A)
        : isDark
            ? const Color(0xFF9E9E9E)
            : const Color(0xFF666666);

    final iconColor =
        isPrimary ? const Color(0xFF1A1A1A) : const Color(0xFFFFD60A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : const Color(0xFFFFD60A).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFFFFD60A).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? const Color(0xFF1A1A1A).withValues(alpha: 0.1)
                    : const Color(0xFFFFD60A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isPrimary
                  ? const Color(0xFF1A1A1A).withValues(alpha: 0.5)
                  : const Color(0xFFFFD60A).withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone idea match entry page — full screen text input before going to map.
class _IdeaMatchEntryPage extends StatefulWidget {
  const _IdeaMatchEntryPage({required this.studentId});
  final String studentId;

  @override
  State<_IdeaMatchEntryPage> createState() => _IdeaMatchEntryPageState();
}

class _IdeaMatchEntryPageState extends State<_IdeaMatchEntryPage> {
  final _ctrl = TextEditingController();
  final bool _isDark = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _proceed() {
    final text = _ctrl.text.trim();
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least 5 characters.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueMapPage(
          showIdeaDock: true,
          studentId: widget.studentId,
          initialIdeaText: text,
          autoRun: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Match Your Idea',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFFFFD60A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Describe your research idea and AI will find the most relevant community problems on the map.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFF0F0F0)
                            : const Color(0xFF1A1A1A),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Research Idea',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark
                    ? const Color(0xFFF0F0F0)
                    : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              minLines: 5,
              maxLines: 8,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'e.g. Low-cost flood warning system for urban neighborhoods...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF616161)
                      : const Color(0xFF9E9E9E),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFD60A),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _proceed,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Color(0xFF1A1A1A), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Find Matching Problems',
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
          ],
        ),
      ),
    );
  }
}
