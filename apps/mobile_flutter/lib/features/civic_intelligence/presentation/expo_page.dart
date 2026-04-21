import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/issue.dart';
import '../../../../services/api_service.dart';

class ExpoPage extends StatefulWidget {
  const ExpoPage({super.key});

  @override
  State<ExpoPage> createState() => _ExpoPageState();
}

class _ExpoPageState extends State<ExpoPage> {
  final _apiService = ApiService();
  late Future<List<Issue>> _expoIssuesFuture;

  @override
  void initState() {
    super.initState();
    _expoIssuesFuture = _apiService.getExpoIssues();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _extractSdgNumber(String? sdgTag) {
    if (sdgTag == null) return '';
    final match = RegExp(r'SDG-(\d+)').firstMatch(sdgTag);
    return match?.group(1) ?? '';
  }

  Color _getSdgColor(String? sdgTag) {
    final num = _extractSdgNumber(sdgTag);
    final colors = {
      '1': Color(0xFFE5243B),
      '2': Color(0xFFDDA63B),
      '3': Color(0xFF4C9F38),
      '4': Color(0xFFC6192E),
      '5': Color(0xFFDD3E39),
      '6': Color(0xFF26BDE2),
      '7': Color(0xFFFCC30B),
      '8': Color(0xFFA21942),
      '9': Color(0xFFE74C3C),
      '10': Color(0xFFDD1C3B),
      '11': Color(0xFFFD6925),
      '12': Color(0xFFBF8B2E),
      '13': Color(0xFF407D52),
      '14': Color(0xFF0A97D9),
      '15': Color(0xFF56C596),
      '16': Color(0xFF00689D),
      '17': Color(0xFF1F4788),
    };
    return colors[num] ?? Color(0xFF666666);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Problems Expo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<Issue>>(
        future: _expoIssuesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFFFD60A),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: subtleColor),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load problems',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final issues = snapshot.data ?? [];

          if (issues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: subtleColor),
                  const SizedBox(height: 16),
                  Text(
                    'No problems yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community problems will appear here once validated by AI',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return _buildProblemCard(
                issue,
                textColor,
                subtleColor,
                bgColor,
                isDark,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProblemCard(
    Issue issue,
    Color textColor,
    Color subtleColor,
    Color bgColor,
    bool isDark,
  ) {
    final sdgColor = _getSdgColor(issue.aiSdgTag);
    final sdgNumber = _extractSdgNumber(issue.aiSdgTag);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
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
          // Header with SDG badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14, color: subtleColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              issue.reporterName ?? 'Anonymous',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: subtleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: subtleColor),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(issue.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: subtleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // SDG Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sdgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sdgColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SDG',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: sdgColor,
                        ),
                      ),
                      Text(
                        sdgNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sdgColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // AI Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    issue.aiSummary ??
                        'No AI summary available for this problem.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 16, color: const Color(0xFFFFD60A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${issue.lat.toStringAsFixed(4)}, ${issue.lng.toStringAsFixed(4)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // SDG Tag
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sdgColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                issue.aiSdgTag ?? 'SDG-11: Sustainable Cities and Communities',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sdgColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
