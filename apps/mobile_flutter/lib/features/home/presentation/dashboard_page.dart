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

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _amber = Color(0xFFFFA726);
const _amberLight = Color(0xFFFFF3E0);
const _dark = Color(0xFF1A1A1A);
const _white = Color(0xFFFFFFFF);

// ── Mock top masters data ─────────────────────────────────────────────────────
const _topMasters = [
  {'name': 'Ana R.', 'projects': 12, 'color': Color(0xFF9C27B0)},
  {'name': 'Ben C.', 'projects': 9, 'color': Color(0xFF2196F3)},
  {'name': 'Lia M.', 'projects': 7, 'color': Color(0xFFE91E63)},
  {'name': 'Jay P.', 'projects': 6, 'color': Color(0xFF4CAF50)},
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.role});
  final AppRole role;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<Issue> _issues = [];
  bool _loading = true;
  int _navIndex = 0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final issues = await _api.getIssues();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      setState(() {
        if (widget.role == AppRole.community) {
          _issues = issues.where((i) => i.reporterId == uid).toList();
        } else {
          _issues = issues.where((i) => i.status == 'validated').toList();
        }
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF242424) : _white;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@')[0] ?? 'there';
    final isCommunity = widget.role == AppRole.community;
    final uid = user?.uid ?? 'anon';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _amber,
          child: CustomScrollView(
            slivers: [
              // ── Greeting header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? const Color(0xFF9E9E9E)
                                    : const Color(0xFF757575),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _capitalize(displayName),
                              style: GoogleFonts.poppins(
                                color: isDark ? _white : _dark,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Avatar
                      GestureDetector(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _amber.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.poppins(
                                color: _dark,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tab bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      _TabChip(
                        label: isCommunity ? 'My Reports' : 'Just For You',
                        selected: _tabController.index == 0,
                        onTap: () => setState(() => _tabController.index = 0),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _TabChip(
                        label: 'Trending',
                        selected: _tabController.index == 1,
                        onTap: () => setState(() => _tabController.index = 1),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _TabChip(
                        label: 'New',
                        selected: _tabController.index == 2,
                        onTap: () => setState(() => _tabController.index = 2),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Horizontal issue cards ───────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _amber, strokeWidth: 2))
                      : _issues.isEmpty
                          ? _EmptyCard(isDark: isDark)
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              itemCount: _issues.length,
                              itemBuilder: (_, i) => _IssueImageCard(
                                issue: _issues[i],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IssueDetailPage(
                                        issueId: _issues[i].issueId),
                                  ),
                                ),
                              ),
                            ),
                ),
              ),

              // ── Top Project Masters ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                  child: Text(
                    'Top Project Masters',
                    style: GoogleFonts.poppins(
                      color: isDark ? _white : _dark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _topMasters.map((m) {
                      final color = m['color'] as Color;
                      final name = m['name'] as String;
                      final projects = m['projects'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  name[0],
                                  style: GoogleFonts.poppins(
                                    color: _white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: isDark ? _white : _dark,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$projects projects',
                              style: GoogleFonts.poppins(
                                color: isDark
                                    ? const Color(0xFF9E9E9E)
                                    : const Color(0xFF9E9E9E),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Quick Actions label ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      color: isDark ? _white : _dark,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── Action cards ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildActions(context, isCommunity, uid, isDark, cardBg),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // ── Bottom nav ───────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        isDark: isDark,
        cardBg: cardBg,
        onTap: (i) {
          if (i == 2) {
            // FAB handled separately
            return;
          }
          setState(() => _navIndex = i);
          if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IssueMapPage()),
            );
          } else if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpoFeedPage()),
            );
          }
        },
      ),

      // ── FAB ──────────────────────────────────────────────────────────
      floatingActionButton: isCommunity
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (_) => IssueSubmitPage(reporterId: uid),
                  ))
                  .then((_) => _loadData()),
              backgroundColor: _amber,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, color: _dark, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  List<Widget> _buildActions(BuildContext context, bool isCommunity,
      String uid, bool isDark, Color cardBg) {
    final actions = isCommunity
        ? [
            _ActionTile(
              icon: Icons.add_location_alt_rounded,
              title: 'Report a Problem',
              subtitle: 'Pin a community issue on the map.',
              isPrimary: true,
              isDark: isDark,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (_) => IssueSubmitPage(reporterId: uid),
                  ))
                  .then((_) => _loadData()),
            ),
            _ActionTile(
              icon: Icons.map_rounded,
              title: 'Community Map',
              subtitle: 'Browse all reported problems.',
              isPrimary: false,
              isDark: isDark,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IssueMapPage())),
            ),
            _ActionTile(
              icon: Icons.science_rounded,
              title: 'Innovation Expo',
              subtitle: 'Discover research projects.',
              isPrimary: false,
              isDark: isDark,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExpoFeedPage())),
            ),
          ]
        : [
            _ActionTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Match Research Idea',
              subtitle: 'AI matches your idea to real problems.',
              isPrimary: true,
              isDark: isDark,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => IssueMapPage(
                    showIdeaDock: true, studentId: uid, autoRun: false),
              )),
            ),
            _ActionTile(
              icon: Icons.explore_rounded,
              title: 'Explore the Map',
              subtitle: 'Browse validated community problems.',
              isPrimary: false,
              isDark: isDark,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    IssueMapPage(showIdeaDock: true, studentId: uid),
              )),
            ),
            _ActionTile(
              icon: Icons.science_rounded,
              title: 'Innovation Expo',
              subtitle: 'Share research and attract investors.',
              isPrimary: false,
              isDark: isDark,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExpoFeedPage())),
            ),
          ];

    return actions
        .expand((w) => [w, const SizedBox(height: 12)])
        .toList()
      ..removeLast();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning!';
    if (h < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Tab chip ──────────────────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _amber : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected
                ? _dark
                : isDark
                    ? const Color(0xFF757575)
                    : const Color(0xFFAAAAAA),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Horizontal issue image card ───────────────────────────────────────────────
class _IssueImageCard extends StatelessWidget {
  const _IssueImageCard({required this.issue, required this.onTap});
  final Issue issue;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (issue.status) {
      case 'validated':
        return const Color(0xFF66BB6A);
      case 'rejected':
        return const Color(0xFFEF5350);
      default:
        return _amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _amber.withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Placeholder gradient background
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _amber.withValues(alpha: 0.3),
                    _amber.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.location_on_rounded,
                    color: _white, size: 40),
              ),
            ),
            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        issue.status,
                        style: GoogleFonts.poppins(
                          color: _white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Amber tag top-left
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: _dark, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state card ──────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _amber.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded,
                  color: _amber.withValues(alpha: 0.5), size: 36),
              const SizedBox(height: 8),
              Text(
                'No issues yet',
                style: GoogleFonts.poppins(
                  color: isDark
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF757575),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
        ? _amber
        : isDark
            ? const Color(0xFF242424)
            : _white;
    final textColor = isPrimary
        ? _dark
        : isDark
            ? const Color(0xFFF0F0F0)
            : _dark;
    final subColor = isPrimary
        ? const Color(0xFF5A3A00)
        : isDark
            ? const Color(0xFF9E9E9E)
            : const Color(0xFF757575);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : _amber.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? _amber.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
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
                    ? _dark.withValues(alpha: 0.1)
                    : _amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: isPrimary ? _dark : _amber, size: 24),
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
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                        color: subColor,
                        fontSize: 11,
                        height: 1.4,
                      )),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: isPrimary
                  ? _dark.withValues(alpha: 0.4)
                  : _amber.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.isDark,
    required this.cardBg,
    required this.onTap,
  });
  final int index;
  final bool isDark;
  final Color cardBg;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
              icon: Icons.home_rounded,
              selected: index == 0,
              onTap: () => onTap(0),
              isDark: isDark),
          _NavIcon(
              icon: Icons.map_rounded,
              selected: index == 1,
              onTap: () => onTap(1),
              isDark: isDark),
          const SizedBox(width: 56), // FAB space
          _NavIcon(
              icon: Icons.notifications_rounded,
              selected: index == 3,
              onTap: () => onTap(3),
              isDark: isDark),
          _NavIcon(
              icon: Icons.person_rounded,
              selected: index == 4,
              onTap: () => onTap(4),
              isDark: isDark),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: selected
              ? _amber
              : isDark
                  ? const Color(0xFF757575)
                  : const Color(0xFFBDBDBD),
          size: 26,
        ),
      ),
    );
  }
}
