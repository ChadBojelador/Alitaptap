import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/api_service.dart';
import '../../../core/models/issue.dart';
import '../../civic_intelligence/presentation/issue_detail_page.dart';
import '../../civic_intelligence/presentation/issue_map_page.dart';

const _amber = Color(0xFFFFC700);
const _dark = Color(0xFF1A1A1A);
const _white = Color(0xFFFFFFFF);

/// Student home page — matches the travel-app UI reference.
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  List<Issue> _issues = [];
  bool _loading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
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
      if (mounted) {
        setState(() {
          _issues = issues.where((i) => i.status == 'validated').toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Issue> get _filteredIssues {
    if (_tabController.index == 1) {
      return [..._issues]
        ..sort((a, b) => b.title.length.compareTo(a.title.length));
    }
    if (_tabController.index == 2) {
      return _issues.reversed.toList();
    }
    return _issues;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Day, there!';
    if (h < 17) return 'Good Day, there!';
    return 'Good Evening!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@')[0] ?? 'there';
    final uid = user?.uid ?? 'anon';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _amber,
          child: CustomScrollView(
            slivers: [
              // ── Greeting ──────────────────────────────────────────────
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
                      GestureDetector(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
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

              // ── Tabs ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'Just For You',
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

              // ── Horizontal cards ──────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _amber, strokeWidth: 2))
                      : _filteredIssues.isEmpty
                          ? _EmptyCard(isDark: isDark)
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              itemCount: _filteredIssues.length,
                              itemBuilder: (_, i) => _IssueCard(
                                issue: _filteredIssues[i],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => IssueDetailPage(
                                        issueId: _filteredIssues[i].issueId),
                                  ),
                                ),
                              ),
                            ),
                ),
              ),

              // ── Quick Actions ─────────────────────────────────────────
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
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
                    const SizedBox(height: 12),
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
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
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

// ── Issue card ────────────────────────────────────────────────────────────────
class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.onTap});
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF34495E),
                    const Color(0xFF2C3E50),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, color: _amber, size: 36),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${issue.lat.toStringAsFixed(2)}°',
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              color: _amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${issue.lng.toStringAsFixed(2)}°',
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              color: _amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
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
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded, color: _dark, size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty card ────────────────────────────────────────────────────────────────
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
            color:
                isPrimary ? Colors.transparent : _amber.withValues(alpha: 0.2),
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
              child: Icon(icon, color: isPrimary ? _dark : _amber, size: 24),
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

/// Community member home — kept for backward compat.
class CommunityHomePage extends StatelessWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context) => const StudentHomePage();
}
