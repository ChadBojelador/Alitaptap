import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_role.dart';
import '../../../core/models/issue.dart';
import '../../../features/civic_intelligence/presentation/issue_detail_page.dart';
import '../../../features/civic_intelligence/presentation/issue_map_page.dart';
import '../../../features/civic_intelligence/presentation/issue_submit_page.dart';
import '../../../features/expo/presentation/expo_feed_page.dart';
import '../../../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.role});
  final AppRole role;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = ApiService();
  List<Issue> _recentIssues = [];
  bool _loading = true;
  int _pendingCount = 0;
  int _validatedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final issues = await _api.getIssues();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      setState(() {
        if (widget.role == AppRole.community) {
          final mine = issues.where((i) => i.reporterId == uid).toList();
          _recentIssues = mine.take(5).toList();
          _pendingCount = mine.where((i) => i.status == 'pending').length;
          _validatedCount = mine.where((i) => i.status == 'validated').length;
          _rejectedCount = mine.where((i) => i.status == 'rejected').length;
        } else {
          _recentIssues = issues.where((i) => i.status == 'validated').take(5).toList();
          _validatedCount = issues.where((i) => i.status == 'validated').length;
        }
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anon';
    final email = user?.email ?? '';
    final isCommunity = widget.role == AppRole.community;

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
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD60A).withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFFFD60A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Top bar ──────────────────────────────────────────
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
                          child: Icon(
                            isCommunity ? Icons.people_alt_rounded : Icons.school_rounded,
                            color: const Color(0xFFFFD60A), size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ALITAPTAP',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFFFD60A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  )),
                              Text(
                                isCommunity ? 'Community Dashboard' : 'Research Dashboard',
                                style: GoogleFonts.poppins(
                                  color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: Color(0xFFFFD60A), size: 18),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Welcome card ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.waving_hand_rounded,
                              color: Color(0xFFFFD60A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Welcome${email.isNotEmpty ? ', ${email.split('@')[0]}' : ''}!',
                              style: GoogleFonts.poppins(
                                color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Stats row ────────────────────────────────────────
                    if (isCommunity) ...[
                      _sectionLabel('My Reports Overview', isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(label: 'Pending', count: _pendingCount,
                              color: const Color(0xFFFFA726), isDark: isDark),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Validated', count: _validatedCount,
                              color: const Color(0xFF66BB6A), isDark: isDark),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Rejected', count: _rejectedCount,
                              color: const Color(0xFFEF5350), isDark: isDark),
                        ],
                      ),
                    ] else ...[
                      _sectionLabel('Community Overview', isDark),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(label: 'Validated Issues', count: _validatedCount,
                              color: const Color(0xFF66BB6A), isDark: isDark),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Available for Research', count: _validatedCount,
                              color: const Color(0xFFFFD60A), isDark: isDark),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Quick Actions ────────────────────────────────────
                    _sectionLabel('Quick Actions', isDark),
                    const SizedBox(height: 12),

                    if (isCommunity) ...[
                      _ActionCard(
                        icon: Icons.add_location_alt_rounded,
                        title: 'Report a Problem',
                        subtitle: 'Pin a community issue on the map with location and details.',
                        isPrimary: true,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IssueSubmitPage(reporterId: uid),
                          ),
                        ).then((_) => _loadData()),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.map_rounded,
                        title: 'View Community Map',
                        subtitle: 'Browse all reported problems pinned across the Philippines.',
                        isPrimary: false,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const IssueMapPage()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.science_rounded,
                        title: 'Innovation Expo',
                        subtitle: 'Discover research projects and fund promising ideas.',
                        isPrimary: false,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ExpoFeedPage()),
                        ),
                      ),
                    ] else ...[
                      _ActionCard(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Match Research Idea',
                        subtitle: 'AI matches your idea to real community problems.',
                        isPrimary: true,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IssueMapPage(
                              showIdeaDock: true,
                              studentId: uid,
                              autoRun: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.explore_rounded,
                        title: 'Explore the Map',
                        subtitle: 'Browse validated community problems on the live map.',
                        isPrimary: false,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IssueMapPage(showIdeaDock: true, studentId: uid),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.science_rounded,
                        title: 'Innovation Expo',
                        subtitle: 'Share your research and attract investors and collaborators.',
                        isPrimary: false,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ExpoFeedPage()),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Recent Issues ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel(
                          isCommunity ? 'My Recent Reports' : 'Recent Validated Issues',
                          isDark,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const IssueMapPage()),
                          ),
                          child: Text('View all',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFFFD60A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD60A), strokeWidth: 2,
                        ),
                      )
                    else if (_recentIssues.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                color: const Color(0xFFFFD60A).withValues(alpha: 0.5),
                                size: 40),
                            const SizedBox(height: 8),
                            Text(
                              isCommunity
                                  ? 'No reports yet. Tap "Report a Problem" to get started.'
                                  : 'No validated issues yet. Check back soon.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...(_recentIssues.map((issue) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _IssueCard(
                              issue: issue,
                              isDark: isDark,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => IssueDetailPage(issueId: issue.issueId),
                                ),
                              ),
                            ),
                          ))),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(
        text,
        style: GoogleFonts.poppins(
          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ────────────────────────────────────────────────────────────────
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
        : isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF);
    final textColor = isPrimary
        ? const Color(0xFF1A1A1A)
        : isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtitleColor = isPrimary
        ? const Color(0xFF3A3A3A)
        : isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final iconColor = isPrimary ? const Color(0xFF1A1A1A) : const Color(0xFFFFD60A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : const Color(0xFFFFD60A).withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFFFFD60A).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
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
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontSize: 11,
                        height: 1.4,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isPrimary
                    ? const Color(0xFF1A1A1A).withValues(alpha: 0.4)
                    : const Color(0xFFFFD60A).withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Issue Card ─────────────────────────────────────────────────────────────────
class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.issue,
    required this.isDark,
    required this.onTap,
  });
  final Issue issue;
  final bool isDark;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (issue.status) {
      case 'validated': return const Color(0xFF66BB6A);
      case 'rejected': return const Color(0xFFEF5350);
      default: return const Color(0xFFFFA726);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD60A).withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: Color(0xFFFFD60A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 3),
                  Text(issue.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666),
                        fontSize: 11,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(issue.status,
                  style: GoogleFonts.poppins(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
