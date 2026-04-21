import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/research_post.dart';
import '../../../services/api_service.dart';
import '../../expo/presentation/expo_post_detail_page.dart';

class AdminExpoPage extends StatefulWidget {
  const AdminExpoPage({super.key});

  @override
  State<AdminExpoPage> createState() => _AdminExpoPageState();
}

class _AdminExpoPageState extends State<AdminExpoPage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabCtrl;
  List<ResearchPost> _posts = [];
  bool _loading = true;

  static const _yellow = Color(0xFFFFD60A);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await _api.getPosts();
      if (mounted) setState(() => _posts = posts);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _removePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Remove Post',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Text(
              'This will permanently remove the post from the Expo.',
              style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E))),
            ),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Remove',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    // Optimistic remove
    setState(() => _posts.removeWhere((p) => p.postId == postId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post removed from Expo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtle =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF0F0F0);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    // Stats
    final totalFunding =
        _posts.fold<double>(0, (s, p) => s + p.fundingRaised);
    final totalLikes = _posts.fold<int>(0, (s, p) => s + p.likes);
    final funded = _posts.where((p) => p.fundingGoal > 0).toList();

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Stats row ──────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _StatPill(
                    label: 'Posts',
                    value: '${_posts.length}',
                    color: const Color(0xFF42A5F5),
                    isDark: isDark),
                const SizedBox(width: 8),
                _StatPill(
                    label: 'Total Likes',
                    value: '$totalLikes',
                    color: const Color(0xFFEF5350),
                    isDark: isDark),
                const SizedBox(width: 8),
                _StatPill(
                    label: 'Funding Raised',
                    value: '₱${totalFunding.toStringAsFixed(0)}',
                    color: const Color(0xFF66BB6A),
                    isDark: isDark),
              ],
            ),
          ),

          // ── Tab bar ────────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF1A1A1A),
                unselectedLabelColor: subtle,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                tabs: [
                  Tab(text: 'All Posts (${_posts.length})'),
                  Tab(text: 'Funded (${funded.length})'),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _yellow, strokeWidth: 2))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _PostList(
                        posts: _posts,
                        isDark: isDark,
                        textColor: textColor,
                        subtle: subtle,
                        currentUid: uid,
                        currentEmail: email,
                        onRefresh: _load,
                        onRemove: _removePost,
                      ),
                      _PostList(
                        posts: funded,
                        isDark: isDark,
                        textColor: textColor,
                        subtle: subtle,
                        currentUid: uid,
                        currentEmail: email,
                        onRefresh: _load,
                        onRemove: _removePost,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({
    required this.posts,
    required this.isDark,
    required this.textColor,
    required this.subtle,
    required this.currentUid,
    required this.currentEmail,
    required this.onRefresh,
    required this.onRemove,
  });

  final List<ResearchPost> posts;
  final bool isDark;
  final Color textColor;
  final Color subtle;
  final String currentUid;
  final String currentEmail;
  final Future<void> Function() onRefresh;
  final void Function(String postId) onRemove;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded,
                size: 56, color: _yellow.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No posts here.',
                style: GoogleFonts.poppins(color: subtle, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _yellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, i) => _AdminPostCard(
          post: posts[i],
          isDark: isDark,
          textColor: textColor,
          subtle: subtle,
          currentUid: currentUid,
          currentEmail: currentEmail,
          onRemove: () => onRemove(posts[i].postId),
        ),
      ),
    );
  }
}

class _AdminPostCard extends StatelessWidget {
  const _AdminPostCard({
    required this.post,
    required this.isDark,
    required this.textColor,
    required this.subtle,
    required this.currentUid,
    required this.currentEmail,
    required this.onRemove,
  });

  final ResearchPost post;
  final bool isDark;
  final Color textColor;
  final Color subtle;
  final String currentUid;
  final String currentEmail;
  final VoidCallback onRemove;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fundingPercent = post.fundingGoal > 0
        ? (post.fundingRaised / post.fundingGoal).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ExpoPostDetailPage(
          post: post,
          currentUid: currentUid,
          currentEmail: currentEmail,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _yellow.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  _Avatar(email: post.authorEmail, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorEmail.split('@').first,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(post.createdAt.split('T').first,
                            style: GoogleFonts.poppins(
                                color: subtle, fontSize: 10)),
                      ],
                    ),
                  ),
                  // Engagement badges
                  Row(
                    children: [
                      _Badge(
                          icon: Icons.favorite_rounded,
                          value: '${post.likes}',
                          color: const Color(0xFFEF5350)),
                      const SizedBox(width: 6),
                      if (post.fundingGoal > 0)
                        _Badge(
                            icon: Icons.volunteer_activism_rounded,
                            value:
                                '₱${post.fundingRaised.toStringAsFixed(0)}',
                            color: const Color(0xFF66BB6A)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Remove button
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFEF5350)
                                .withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF5350), size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // ── Title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(post.title,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  )),
            ),

            // ── Abstract ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Text(post.abstract,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: subtle, fontSize: 12, height: 1.5)),
            ),

            // ── SDG tags ─────────────────────────────────────────────
            if (post.sdgTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Wrap(
                  spacing: 6,
                  children: post.sdgTags
                      .take(3)
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _yellow.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _yellow.withValues(alpha: 0.3)),
                            ),
                            child: Text(t,
                                style: GoogleFonts.poppins(
                                  color: _yellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                )),
                          ))
                      .toList(),
                ),
              ),

            // ── Funding bar ──────────────────────────────────────────
            if (post.fundingGoal > 0) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${post.fundingRaised.toStringAsFixed(0)} raised',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF66BB6A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(fundingPercent * 100).toStringAsFixed(0)}% of ₱${post.fundingGoal.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              color: subtle, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fundingPercent,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFEEEEEE),
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF66BB6A)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(value,
            style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                )),
            Text(label,
                style: GoogleFonts.poppins(
                  color: isDark
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF666666),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.email, required this.size});
  final String email;
  final double size;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: _yellow.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
              color: _yellow,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}
