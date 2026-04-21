import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/api_service.dart';
import 'issue_map_page.dart';

class MatchIdeaPage extends StatefulWidget {
  const MatchIdeaPage({super.key, required this.studentId});
  final String studentId;

  @override
  State<MatchIdeaPage> createState() => _MatchIdeaPageState();
}

class _MatchIdeaPageState extends State<MatchIdeaPage> {
  final _ideaCtrl = TextEditingController();
  final _api = ApiService();
  bool _matching = false;

  @override
  void dispose() {
    _ideaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitIdea() async {
    final idea = _ideaCtrl.text.trim();
    if (idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your research idea')),
      );
      return;
    }

    setState(() => _matching = true);
    try {
      // Call the matcher API
      await _api.matchIdea(
        studentId: widget.studentId,
        ideaText: idea,
        maxResults: 5,
      );

      if (!mounted) return;

      // Navigate to map with the idea
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => IssueMapPage(
            showIdeaDock: true,
            studentId: widget.studentId,
            autoRun: false,
            initialIdea: idea,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _matching = false);
    }
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Match Your Research Idea',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFFFD60A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter your research idea. AI will match it with real community problems and suggest research directions.',
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
            const SizedBox(height: 24),

            // Idea input label
            Text(
              'Your Research Idea',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // Idea input field
            TextFormField(
              controller: _ideaCtrl,
              maxLines: 5,
              style: GoogleFonts.poppins(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText:
                    'e.g. Low-cost flood warning system for urban neighborhoods using IoT sensors and mobile alerts',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF616161)
                      : const Color(0xFF9E9E9E),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(Icons.auto_awesome_rounded,
                      color: const Color(0xFFFFD60A), size: 20),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFFFD60A), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Helper text
            Text(
              'Be specific about the problem you want to solve, the approach, and the impact you hope to achieve.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: subtleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            GestureDetector(
              onTap: _matching ? null : _submitIdea,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _matching
                      ? const Color(0xFFFFD60A).withValues(alpha: 0.5)
                      : const Color(0xFFFFD60A),
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
                    if (_matching)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A1A1A),
                        ),
                      )
                    else
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF1A1A1A), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _matching ? 'Matching...' : 'Find Matching Problems',
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
