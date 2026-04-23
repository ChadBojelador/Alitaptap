import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';
import '../../../core/models/research_post.dart';
import '../../../core/models/community_problem_post.dart';
import '../../../services/api_service.dart';
import '../../../services/session_service.dart';
import 'chat_inbox_page.dart';
import 'create_post_page.dart';
import 'expo_post_detail_page.dart';
import 'people_page.dart';
import 'sdg_story_viewer.dart';

class ExpoFeedPage extends StatefulWidget {
  const ExpoFeedPage({super.key});

  @override
  State<ExpoFeedPage> createState() => _ExpoFeedPageState();
}

class _ExpoFeedPageState extends State<ExpoFeedPage> {
  final _api = ApiService();
  List<ResearchPost> _posts = [];
  List<_FeedItem> _feedItems = [];
  bool _loading = true;

  static const _yellow = Color(0xFFFFD60A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<ResearchPost> posts = _posts;
    try {
      posts = await _api.getPosts();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _feedItems = _buildFeedItems(posts);
      _loading = false;
    });
  }

  List<_FeedItem> _buildFeedItems(List<ResearchPost> posts) {
    final items = <_FeedItem>[
      ...posts.map(_FeedItem.research),
      ...MockData.communityProblems.map(_FeedItem.community),
    ];
    items.sort(
      (a, b) =>
          _parseCreatedAt(b.createdAt).compareTo(_parseCreatedAt(a.createdAt)),
    );
    return items;
  }

  DateTime _parseCreatedAt(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<void> _toggleLike(ResearchPost post) async {
    final uid = SessionService.uid;
    if (uid.isEmpty) return;
    try {
      final updated = await _api.toggleLike(postId: post.postId, userId: uid);
      if (mounted) {
        setState(() {
          final idx = _posts.indexWhere((p) => p.postId == post.postId);
          if (idx != -1) {
            _posts[idx] = updated;
            _feedItems = _buildFeedItems(_posts);
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = SessionService.uid;
    final email = SessionService.email;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: _yellow, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('ALITAPTAP',
                        style: GoogleFonts.poppins(
                          color: _yellow,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        )),
                  ),
                  // People icon
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PeoplePage(currentUid: uid))),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _yellow.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_rounded,
                          color: _yellow, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search icon
                  GestureDetector(
                    onTap: () => _openSearchOverlay(
                      currentUid: uid,
                      currentEmail: email,
                      isDark: isDark,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _yellow.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: _yellow, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Messenger icon
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatInboxPage(currentUid: uid))),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _yellow.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_rounded,
                          color: _yellow, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: _yellow,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Create post bar ────────────────────────────────
                    _CreatePostBar(
                      isDark: isDark,
                      uid: uid,
                      email: email,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (_) => CreatePostPage(
                                authorId: uid, authorEmail: email),
                          ))
                          .then((_) => _load()),
                    ),

                    // ── Stories row ────────────────────────────────────
                    _StoriesRow(
                      isDark: isDark,
                      currentUid: uid,
                      currentEmail: email,
                    ),

                    const SizedBox(height: 14),

                    // ── Feed ───────────────────────────────────────────
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: _yellow, strokeWidth: 2)),
                      )
                    else if (_feedItems.isEmpty)
                      _EmptyFeed(isDark: isDark)
                    else
                      ..._feedItems.map((item) {
                        if (item.researchPost != null) {
                          final post = item.researchPost!;
                          return _PostCard(
                            post: post,
                            currentUid: uid,
                            isDark: isDark,
                            onLike: () => _toggleLike(post),
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                  builder: (_) => ExpoPostDetailPage(
                                    post: post,
                                    currentUid: uid,
                                    currentEmail: email,
                                  ),
                                ))
                                .then((_) => _load()),
                            onShare: () => _sharePost(post),
                            onMessage: () =>
                                Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatInboxPage(currentUid: uid),
                            )),
                          );
                        }

                        return _CommunityProblemCard(
                          problem: item.communityPost!,
                          isDark: isDark,
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(ResearchPost post) {
    Clipboard.setData(ClipboardData(text: '${post.title}\n\n${post.abstract}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post link copied to clipboard!')),
    );
  }

  Future<void> _openSearchOverlay({
    required String currentUid,
    required String currentEmail,
    required bool isDark,
  }) async {
    final controller = TextEditingController();
    final overlayBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);
    final subtle = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final filtered = _posts.where((post) {
              if (query.isEmpty) return true;
              final haystack = [
                post.title,
                post.abstract,
                post.problemSolved,
                post.authorEmail,
                ...post.sdgTags,
              ].join(' ').toLowerCase();
              return haystack.contains(query);
            }).toList();

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              backgroundColor: overlayBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _yellow.withValues(alpha: 0.3)),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: _yellow),
                          ),
                          Expanded(
                            child: Text(
                              'Search Posts',
                              style: GoogleFonts.poppins(
                                color: _yellow,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        onChanged: (value) => setOverlayState(() {
                          query = value.trim().toLowerCase();
                        }),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFF0F0F0)
                              : const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search posts, SDGs, authors...',
                          hintStyle:
                              GoogleFonts.poppins(fontSize: 13, color: subtle),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: _yellow, size: 20),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () => setOverlayState(() {
                                    controller.clear();
                                    query = '';
                                  }),
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                  color: subtle,
                                ),
                          filled: true,
                          fillColor: fieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFEAEAEA),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No matching posts.',
                                style: GoogleFonts.poppins(
                                    color: subtle, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFEAEAEA),
                              ),
                              itemBuilder: (context, index) {
                                final post = filtered[index];
                                return ListTile(
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    Navigator.of(this.context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => ExpoPostDetailPage(
                                              post: post,
                                              currentUid: currentUid,
                                              currentEmail: currentEmail,
                                            ),
                                          ),
                                        )
                                        .then((_) => _load());
                                  },
                                  title: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFFF0F0F0)
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    post.authorEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: subtle,
                                    ),
                                  ),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: _yellow),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeedItem {
  const _FeedItem.research(this.researchPost) : communityPost = null;

  const _FeedItem.community(this.communityPost) : researchPost = null;

  final ResearchPost? researchPost;
  final CommunityProblemPost? communityPost;

  String get createdAt =>
      researchPost?.createdAt ?? communityPost?.createdAt ?? '';
}

// ── Stories row ────────────────────────────────────────────────────────────────
class _StoriesRow extends StatelessWidget {
  const _StoriesRow({
    required this.isDark,
    required this.currentUid,
    required this.currentEmail,
  });
  final bool isDark;
  final String currentUid;
  final String currentEmail;

  static const _yellow = Color(0xFFFFD60A);
  static const _stories = [
    ('SDG 3', 'Health', Icons.favorite_rounded, Color(0xFFEF5350)),
    ('SDG 13', 'Climate', Icons.eco_rounded, Color(0xFF66BB6A)),
    ('SDG 4', 'Education', Icons.school_rounded, Color(0xFF42A5F5)),
    ('SDG 11', 'Cities', Icons.location_city_rounded, Color(0xFFAB47BC)),
    ('SDG 6', 'Water', Icons.water_drop_rounded, Color(0xFF26C6DA)),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 114,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            // Add story
            _StoryBubble(
              label: 'Your Story',
              subtitle: '',
              icon: Icons.add_rounded,
              color: _yellow,
              isDark: isDark,
              isAdd: true,
            ),
            ..._stories.map((s) => _StoryBubble(
                  label: s.$1,
                  subtitle: s.$2,
                  icon: s.$3,
                  color: s.$4,
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SdgStoryViewer(
                          sdgLabel: s.$1,
                          sdgName: s.$2,
                          accentColor: s.$4,
                          currentUid: currentUid,
                          currentEmail: currentEmail,
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isAdd = false,
    this.onTap,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // ── Exterior Gradient Ring ──────────────────────────────
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAdd
                        ? null
                        : SweepGradient(
                            colors: [
                              color,
                              color.withValues(alpha: 0.3),
                              color.withValues(alpha: 0.8),
                              color,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                    color: isAdd
                        ? const Color(0xFFFFD60A).withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                // ── Inner White Gap (The classic 'Story' ring look) ────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    border: isAdd
                        ? Border.all(color: const Color(0xFFFFD60A), width: 1.5)
                        : null,
                  ),
                ),
                // ── Main Bubble ─────────────────────────────────────────
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                // ── Add Icon Badge ─────────────────────────────────────
                if (isAdd)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD60A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Color(0xFF1A1A1A), size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                letterSpacing: 0.2,
              ),
            ),
            if (!isAdd) ...[
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF757575)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Create post bar ────────────────────────────────────────────────────────────
class _CreatePostBar extends StatelessWidget {
  const _CreatePostBar({
    required this.isDark,
    required this.uid,
    required this.email,
    required this.onTap,
  });
  final bool isDark;
  final String uid;
  final String email;
  final VoidCallback onTap;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtle = isDark ? const Color(0xFF616161) : const Color(0xFF9E9E9E);
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(uid: uid, email: email, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text("What's on your research mind?",
                        style:
                            GoogleFonts.poppins(color: subtle, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
              height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickAction(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo',
                  color: const Color(0xFF66BB6A),
                  onTap: onTap),
              _QuickAction(
                  icon: Icons.science_rounded,
                  label: 'Research',
                  color: const Color(0xFF42A5F5),
                  onTap: onTap),
              _QuickAction(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Fund',
                  color: _yellow,
                  onTap: onTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Post card ──────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.isDark,
    required this.onLike,
    required this.onTap,
    required this.onShare,
    required this.onMessage,
  });

  final ResearchPost post;
  final String currentUid;
  final bool isDark;
  final VoidCallback onLike;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onMessage;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showReactions = false;
  static const _yellow = Color(0xFFFFD60A);

  static const _reactionEmojis = {
    'like': ('👍', Color(0xFF42A5F5)),
    'love': ('❤️', Color(0xFFEF5350)),
    'haha': ('😂', Color(0xFFFFCA28)),
    'wow': ('😮', Color(0xFFFFCA28)),
    'sad': ('😢', Color(0xFF42A5F5)),
    'angry': ('😡', Color(0xFFFF7043)),
  };

  bool get _liked => widget.post.likedBy.contains(widget.currentUid);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtle = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
    final divider = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    final totalReactions =
        widget.post.reactions.values.fold(0, (a, b) => a + b);

    return Container(
      color: bg,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _Avatar(
                    uid: widget.post.authorId,
                    email: widget.post.authorEmail,
                    size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorEmail.split('@').first,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _timeAgo(widget.post.createdAt),
                            style: GoogleFonts.poppins(
                                color: subtle, fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.public_rounded, color: subtle, size: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.post.sdgTags.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _yellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _yellow.withValues(alpha: 0.3)),
                    ),
                    child: Text(widget.post.sdgTags.first,
                        style: GoogleFonts.poppins(
                          color: _yellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.more_horiz_rounded, color: subtle, size: 22),
              ],
            ),
          ),

          // ── Title + abstract ─────────────────────────────────────────
          GestureDetector(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.title,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      )),
                  const SizedBox(height: 6),
                  Text(widget.post.abstract,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: subtle,
                        fontSize: 13,
                        height: 1.5,
                      )),
                ],
              ),
            ),
          ),

          // ── Post image(s) ─────────────────────────────────────────
          if (widget.post.imageUrls.isNotEmpty ||
              (widget.post.imageUrl != null &&
                  widget.post.imageUrl!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onTap,
              child: _ImagePeelGallery(
                images: widget.post.imageUrls.isNotEmpty
                    ? widget.post.imageUrls
                    : [widget.post.imageUrl!],
              ),
            ),
          ],

          // ── Funding bar ──────────────────────────────────────────────
          if (widget.post.fundingGoal > 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${widget.post.fundingRaised.toStringAsFixed(0)} raised',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF66BB6A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Goal: ₱${widget.post.fundingGoal.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(color: subtle, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (widget.post.fundingRaised / widget.post.fundingGoal)
                              .clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFEEEEEE),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Reaction + share counts ──────────────────────────────────
          if (widget.post.likes > 0 ||
              totalReactions > 0 ||
              widget.post.shares > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  if (widget.post.likes > 0) ...[
                    const Text('👍', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('${widget.post.likes}',
                        style:
                            GoogleFonts.poppins(color: subtle, fontSize: 12)),
                  ],
                  const Spacer(),
                  if (widget.post.shares > 0)
                    Text('${widget.post.shares} shares',
                        style:
                            GoogleFonts.poppins(color: subtle, fontSize: 12)),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Divider(color: divider, height: 1),

          // ── Action row ───────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Like with long-press reactions
                    GestureDetector(
                      onTap: widget.onLike,
                      onLongPress: () => setState(() => _showReactions = true),
                      child: _ActionBtn(
                        icon: _liked
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        label: 'Like',
                        color: _liked ? const Color(0xFF42A5F5) : subtle,
                      ),
                    ),
                    // Comment
                    GestureDetector(
                      onTap: widget.onTap,
                      child: _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Comment',
                        color: subtle,
                      ),
                    ),
                    // Share
                    GestureDetector(
                      onTap: widget.onShare,
                      child: _ActionBtn(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        color: subtle,
                      ),
                    ),
                    // Message author
                    GestureDetector(
                      onTap: widget.onMessage,
                      child: _ActionBtn(
                        icon: Icons.send_rounded,
                        label: 'Message',
                        color: subtle,
                      ),
                    ),
                  ],
                ),
              ),
              // Reaction picker popup
              if (_showReactions)
                Positioned(
                  bottom: 44,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _showReactions = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _PostCardState._reactionEmojis.entries
                            .map((e) => GestureDetector(
                                  onTap: () {
                                    setState(() => _showReactions = false);
                                    widget.onLike();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(e.value.$1,
                                        style: const TextStyle(fontSize: 28)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Divider(color: divider, height: 1),
        ],
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return iso.split('T').first;
    } catch (_) {
      return iso.split('T').first;
    }
  }
}

class _CommunityProblemCard extends StatelessWidget {
  const _CommunityProblemCard({
    required this.problem,
    required this.isDark,
  });

  final CommunityProblemPost problem;
  final bool isDark;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtle = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
    final divider = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    final trimmedName = problem.reporterName.trim();
    final avatarText =
        trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';
    final images = problem.imageUrls.isNotEmpty
        ? problem.imageUrls
        : (problem.imageUrl != null && problem.imageUrl!.isNotEmpty)
            ? [problem.imageUrl!]
            : const <String>[];

    return Container(
      color: bg,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _yellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _yellow.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      avatarText,
                      style: GoogleFonts.poppins(
                        color: _yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        problem.reporterName,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _timeAgo(problem.createdAt),
                            style: GoogleFonts.poppins(
                                color: subtle, fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.public_rounded, color: subtle, size: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Community Report',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFEF5350),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              problem.title,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              problem.description,
              style: GoogleFonts.poppins(
                color: subtle,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          if (images.isNotEmpty) ...[
            _CommunityImagePreview(
              images: images,
              onOpen: (index) => _openPhotoViewer(context, images, index),
            ),
            const SizedBox(height: 8),
          ],
          if (problem.likes > 0 || problem.shares > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  if (problem.likes > 0) ...[
                    const Text('👍', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${problem.likes}',
                      style: GoogleFonts.poppins(color: subtle, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  if (problem.shares > 0)
                    Text(
                      '${problem.shares} shares',
                      style: GoogleFonts.poppins(color: subtle, fontSize: 12),
                    ),
                ],
              ),
            ),
          Divider(color: divider, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.report_problem_rounded,
                    color: Color(0xFFEF5350), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Community problem report',
                  style: GoogleFonts.poppins(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: divider, height: 1),
        ],
      ),
    );
  }

  void _openPhotoViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _CommunityPhotoViewer(
        images: images,
        initialIndex: initialIndex,
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return iso.split('T').first;
    } catch (_) {
      return iso.split('T').first;
    }
  }
}

class _CommunityImagePreview extends StatefulWidget {
  const _CommunityImagePreview({
    required this.images,
    required this.onOpen,
  });

  final List<String> images;
  final ValueChanged<int> onOpen;

  @override
  State<_CommunityImagePreview> createState() => _CommunityImagePreviewState();
}

class _CommunityImagePreviewState extends State<_CommunityImagePreview> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.length == 1) {
      return GestureDetector(
        onTap: () => widget.onOpen(0),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: _buildImage(widget.images.first),
        ),
      );
    }

    if (widget.images.length == 2) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onOpen(0),
                child: _buildImage(widget.images[0]),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onOpen(1),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildImage(widget.images[1])),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '2 photos',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => widget.onOpen(i),
              child: _buildImage(widget.images[i]),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/${widget.images.length}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? const Color(0xFFFFD60A)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String src) {
    if (src.startsWith('placeholder://')) {
      return _CommunityPlaceholderImage(
        label: _placeholderLabel(src),
        fit: BoxFit.cover,
      );
    }

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CommunityPlaceholderImage(
          label: 'Image Placeholder',
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.network(
      src,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _CommunityPlaceholderImage(
        label: 'Image Placeholder',
        fit: BoxFit.cover,
      ),
    );
  }

  String _placeholderLabel(String source) {
    if (!source.startsWith('placeholder://')) return 'Photo Placeholder';
    final raw = source.replaceFirst('placeholder://', '');
    if (raw.isEmpty) return 'Photo Placeholder';
    final parts = raw.split('-').where((part) => part.isNotEmpty);
    final title = parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
    return title.isEmpty ? 'Photo Placeholder' : title;
  }
}

class _CommunityPhotoViewer extends StatefulWidget {
  const _CommunityPhotoViewer({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_CommunityPhotoViewer> createState() => _CommunityPhotoViewerState();
}

class _CommunityPhotoViewerState extends State<_CommunityPhotoViewer> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final source = widget.images[i];
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _buildImage(source),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_current + 1}/${widget.images.length}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Pinch to zoom',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String src) {
    if (src.startsWith('placeholder://')) {
      return _CommunityPlaceholderImage(
        label: _placeholderLabel(src),
        fit: BoxFit.contain,
      );
    }

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _CommunityPlaceholderImage(
          label: 'Image Placeholder',
          fit: BoxFit.contain,
        ),
      );
    }

    return Image.network(
      src,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _CommunityPlaceholderImage(
        label: 'Image Placeholder',
        fit: BoxFit.contain,
      ),
    );
  }

  String _placeholderLabel(String source) {
    if (!source.startsWith('placeholder://')) return 'Photo Placeholder';
    final raw = source.replaceFirst('placeholder://', '');
    if (raw.isEmpty) return 'Photo Placeholder';
    final parts = raw.split('-').where((part) => part.isNotEmpty);
    final title = parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
    return title.isEmpty ? 'Photo Placeholder' : title;
  }
}

class _CommunityPlaceholderImage extends StatelessWidget {
  const _CommunityPlaceholderImage({
    required this.label,
    required this.fit,
  });

  final String label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF303030), Color(0xFF121212)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined,
                size: 44, color: Color(0xFFFFD60A)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFFD60A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Placeholder Image',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    if (fit == BoxFit.cover) return child;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: child,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.uid, this.email = '', required this.size});
  final String? uid;
  final String email;
  final double size;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    // Try to find mock user data
    Map<String, String>? userData;
    if (uid != null && MockData.mockUsers.containsKey(uid)) {
      userData = MockData.mockUsers[uid];
    } else {
      // Try finding by email
      try {
        final entry = MockData.mockUsers.entries.firstWhere(
            (e) => e.value['email'] == email,
            orElse: () => MapEntry('', {}));
        if (entry.key.isNotEmpty) userData = entry.value;
      } catch (_) {}
    }

    final imageUrl = userData?['avatar'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: _yellow.withValues(alpha: 0.4), width: 1.5),
        ),
      );
    }

    final initials = email.isNotEmpty
        ? email[0].toUpperCase()
        : (userData?['name'] != null
            ? userData!['name']![0].toUpperCase()
            : '?');

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

// ── Image Peel Gallery ────────────────────────────────────────────────────────
class _ImagePeelGallery extends StatefulWidget {
  const _ImagePeelGallery({required this.images});
  final List<String> images;

  @override
  State<_ImagePeelGallery> createState() => _ImagePeelGalleryState();
}

class _ImagePeelGalleryState extends State<_ImagePeelGallery> {
  int _current = 0;

  Widget _buildImage(String src) {
    if (src.startsWith('assets/')) {
      return Image.asset(src,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }
    return Image.network(src,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.length == 1) return _buildImage(widget.images.first);
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _buildImage(widget.images[i]),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? const Color(0xFFFFD60A)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
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

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded,
                size: 56,
                color: const Color(0xFFFFD60A).withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No research posts yet.',
                style: GoogleFonts.poppins(
                  color: isDark
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF666666),
                  fontSize: 14,
                )),
          ],
        ),
      ),
    );
  }
}
