import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/news_article.dart';

const _amber = Color(0xFFFFC700);
const _dark = Color(0xFF1A1A1A);
const _white = Color(0xFFFFFFFF);

class NewsFeedWidget extends StatelessWidget {
  const NewsFeedWidget({super.key, required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _NewsCard(article: article, isDark: isDark);
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.isDark});

  final NewsArticle article;
  final bool isDark;

  Future<void> _openUrl() async {
    try {
      if (await canLaunchUrl(Uri.parse(article.url))) {
        await launchUrl(Uri.parse(article.url),
            mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A3A3A)
                : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    article.source,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amber,
                    ),
                  ),
                ),
                Text(
                  _formatDate(article.publishedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF0F0F0) : _dark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: _amber.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Read more',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
