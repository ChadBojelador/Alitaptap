import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';
import '../../../core/models/research_post.dart';
import '../../../services/api_service.dart';

class ExpoPostDetailPage extends StatefulWidget {
  const ExpoPostDetailPage({
    super.key,
    required this.post,
    required this.currentUid,
    required this.currentEmail,
  });

  final ResearchPost post;
  final String currentUid;
  final String currentEmail;

  @override
  State<ExpoPostDetailPage> createState() => _ExpoPostDetailPageState();
}

class _ExpoPostDetailPageState extends State<ExpoPostDetailPage> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();

  late ResearchPost _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  bool _submittingComment = false;
  bool _funding = false;

  static const _yellow = Color(0xFFFFD60A);

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final comments = await _api.getComments(_post.postId);
      if (mounted) setState(() => _comments = comments);
    } catch (_) {}
    if (mounted) setState(() => _loadingComments = false);
  }

  Future<void> _toggleLike() async {
    try {
      final updated = await _api.toggleLike(
          postId: _post.postId, userId: widget.currentUid);
      if (mounted) setState(() => _post = updated);
    } catch (_) {}
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submittingComment = true);
    try {
      final comment = await _api.addComment(
        postId: _post.postId,
        authorId: widget.currentUid,
        authorEmail: widget.currentEmail,
        text: text,
      );
      _commentCtrl.clear();
      if (mounted) setState(() => _comments.insert(0, comment));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
    if (mounted) setState(() => _submittingComment = false);
  }

  Future<void> _showFundDialog() async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Fund this Research',
            style: GoogleFonts.poppins(
              color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the amount (₱) you want to contribute to "${_post.title}".',
              style: GoogleFonts.poppins(
                color: isDark
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF666666),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. 500',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.poppins(
                    color: _yellow, fontWeight: FontWeight.w700),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: _yellow, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: isDark
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF666666))),
          ),
          GestureDetector(
            onTap: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null && val > 0) Navigator.of(ctx).pop(val);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Confirm',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
          ),
        ],
      ),
    );

    if (amount == null) return;
    setState(() => _funding = true);
    try {
      final updated = await _api.fundPost(
        postId: _post.postId,
        userId: widget.currentUid,
        amount: amount,
      );
      if (mounted) {
        setState(() => _post = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '₱${amount.toStringAsFixed(0)} contributed! Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Funding failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _funding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF0F0F0);
    final cardBg =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final liked = _post.likedBy.contains(widget.currentUid);
    final fundingPercent = _post.fundingGoal > 0
        ? (_post.fundingRaised / _post.fundingGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Research Post',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: _yellow, size: 16),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Author ───────────────────────────────────────────────
                Row(
                  children: [
                    _Avatar(uid: _post.authorId, email: _post.authorEmail, size: 44),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(MockData.mockUsers[_post.authorId]?['name'] ?? _post.authorEmail.split('@').first,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(_post.createdAt.split('T').first,
                            style: GoogleFonts.poppins(
                                color: subtleColor, fontSize: 11)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Title ────────────────────────────────────────────────
                Text(_post.title,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    )),

                const SizedBox(height: 16),

                // ── Abstract ─────────────────────────────────────────────
                _Section(
                  label: 'Abstract',
                  isDark: isDark,
                  cardBg: cardBg,
                  child: Text(_post.abstract,
                      style: GoogleFonts.poppins(
                          color: textColor, fontSize: 13, height: 1.7)),
                ),

                const SizedBox(height: 12),

                // ── Problem solved ───────────────────────────────────────
                _Section(
                  label: 'Problem Addressed',
                  isDark: isDark,
                  cardBg: cardBg,
                  child: Text(_post.problemSolved,
                      style: GoogleFonts.poppins(
                          color: textColor, fontSize: 13, height: 1.7)),
                ),

                // ── SDG tags ─────────────────────────────────────────────
                if (_post.sdgTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    label: 'SDG Alignment',
                    isDark: isDark,
                    cardBg: cardBg,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _post.sdgTags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _yellow.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _yellow.withValues(alpha: 0.3)),
                                ),
                                child: Text(t,
                                    style: GoogleFonts.poppins(
                                      color: _yellow,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // ── Funding ──────────────────────────────────────────────
                if (_post.fundingGoal > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF66BB6A)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volunteer_activism_rounded,
                                color: Color(0xFF66BB6A), size: 16),
                            const SizedBox(width: 6),
                            Text('Funding Progress',
                                style: GoogleFonts.poppins(
                                  color: subtleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₱${_post.fundingRaised.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF66BB6A),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'of ₱${_post.fundingGoal.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  color: subtleColor, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fundingPercent,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFEEEEEE),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF66BB6A)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(fundingPercent * 100).toStringAsFixed(1)}% funded',
                          style: GoogleFonts.poppins(
                              color: subtleColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Like + Fund actions ──────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: liked
                               ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                              : isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: liked
                                ? const Color(0xFFEF5350)
                                    .withValues(alpha: 0.4)
                                : subtleColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: liked
                                  ? const Color(0xFFEF5350)
                                  : subtleColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text('${_post.likes}',
                                style: GoogleFonts.poppins(
                                  color: liked
                                      ? const Color(0xFFEF5350)
                                      : subtleColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_post.fundingGoal > 0)
                      GestureDetector(
                        onTap: _funding ? null : _showFundDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _yellow,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _yellow.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _funding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1A1A1A)))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.volunteer_activism_rounded,
                                        color: Color(0xFF1A1A1A),
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text('Fund this Research',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        )),
                                  ],
                                ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Comments header ──────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: _yellow, size: 16),
                    const SizedBox(width: 6),
                    Text('Comments',
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),

                const SizedBox(height: 12),

                if (_loadingComments)
                  const Center(
                    child: CircularProgressIndicator(
                        color: _yellow, strokeWidth: 2),
                  )
                else if (_comments.isEmpty)
                  Text('No comments yet. Be the first!',
                      style: GoogleFonts.poppins(
                          color: subtleColor, fontSize: 12))
                else
                  ..._comments.map((c) => _CommentTile(
                        comment: c,
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        subtleColor: subtleColor,
                      )),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Comment input bar ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
              border: Border(
                top: BorderSide(
                    color: _yellow.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF616161)
                            : const Color(0xFF9E9E9E),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF242424)
                          : const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submittingComment ? null : _submitComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _yellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _yellow.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _submittingComment
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A1A1A)),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Color(0xFF1A1A1A), size: 18),
                  ),
                ),
              ],
            ),
          ),
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
    Map<String, String>? userData;
    if (uid != null && MockData.mockUsers.containsKey(uid)) {
      userData = MockData.mockUsers[uid];
    } else {
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
        : (userData?['name'] != null ? userData!['name']![0].toUpperCase() : '?');

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

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.isDark,
    required this.cardBg,
    required this.child,
  });
  final String label;
  final bool isDark;
  final Color cardBg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFFD60A).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                color: isDark
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF666666),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subtleColor,
  });
  final Map<String, dynamic> comment;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final authorId = comment['author_id'] as String? ?? '';
    final email = (comment['author_email'] as String? ?? '').split('@').first;
    final name = MockData.mockUsers[authorId]?['name'] ?? email;
    final text = comment['text'] as String? ?? '';
    final date = (comment['created_at'] as String? ?? '').split('T').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFFD60A).withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(uid: authorId, email: comment['author_email'] ?? '', size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        )),
                    const Spacer(),
                    Text(date,
                        style: GoogleFonts.poppins(
                            color: subtleColor, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text,
                    style: GoogleFonts.poppins(
                        color: textColor, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
