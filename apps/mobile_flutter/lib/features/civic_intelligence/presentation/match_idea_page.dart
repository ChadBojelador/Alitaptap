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
  List<Map<String, String>> _matches = [];
  String? _selectedLocation;
  Map<String, bool> _expandedDetails = {};

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

      // Simulate finding matches (in real app, this comes from API)
      setState(() {
        _matches = [
          {
            'location': 'Batangas City',
            'problem': 'Recurring flooding in coastal areas',
            'submittedBy': 'Maria Santos',
            'submittedDate': '2 days ago',
            'details': 'The coastal barangays experience severe flooding during monsoon season, affecting over 500 households. Infrastructure damage costs approximately ₱2M annually.',
          },
          {
            'location': 'Pagbilao, Quezon',
            'problem': 'Drainage system overflow during monsoon',
            'submittedBy': 'Juan Dela Cruz',
            'submittedDate': '5 days ago',
            'details': 'Municipal drainage system lacks capacity during heavy rainfall, causing waterlogging in commercial and residential areas. Affects local businesses and transportation.',
          },
        ];
        _matching = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      if (mounted) setState(() => _matching = false);
    }
  }

  Future<void> _proceedToMap() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    if (!mounted) return;

    // Navigate to map with the idea
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => IssueMapPage(
          showIdeaDock: true,
          studentId: widget.studentId,
          autoRun: false,
          initialIdeaText: _ideaCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);
    
    // Yellow color hierarchy
    const accentYellowBright = Color(0xFFFFD60A); // Primary - bright yellow
    const accentYellowMuted = Color(0xFFFFC700); // Secondary - muted yellow
    const accentYellowDark = Color(0xFFFFB700); // Tertiary - dark yellow

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
            // Info banner - Primary yellow
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentYellowBright.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentYellowBright.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: accentYellowBright, size: 18),
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

            // Idea input field - Secondary yellow
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
                      color: accentYellowMuted, size: 20),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: accentYellowMuted.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: accentYellowMuted.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: accentYellowMuted, width: 1.5),
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

            // AI Insights - Matches found
            if (_matches.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: accentYellowBright, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'AI Found ${_matches.length} Matching Problems',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._matches.asMap().entries.map((entry) {
                    final match = entry.value;
                    final location = match['location'] ?? '';
                    final isSelected = _selectedLocation == location;
                    final isExpanded = _expandedDetails[location] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedLocation = location),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentYellowBright.withValues(alpha: 0.15)
                                    : accentYellowMuted.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? accentYellowBright
                                      : accentYellowMuted.withValues(alpha: 0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accentYellowBright,
                                        width: 2,
                                      ),
                                      color: isSelected
                                          ? accentYellowBright
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                            color: Color(0xFF1A1A1A), size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          match['location']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          match['problem']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: subtleColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Expandable details section (only show if selected)
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                children: [
                                  // Submission info dropdown - Tertiary yellow
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _expandedDetails[location] = !isExpanded;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: accentYellowDark
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: accentYellowDark
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: accentYellowDark,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Submitted by ${match['submittedBy'] ?? 'Unknown'}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  match['submittedDate']!,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: subtleColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            color: accentYellowDark,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Expanded details - Secondary yellow
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: accentYellowMuted
                                              .withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: accentYellowMuted
                                                .withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Problem Details',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              match['details']!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: subtleColor,
                                                height: 1.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _selectedLocation == null ? null : _proceedToMap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedLocation == null
                            ? accentYellowBright.withValues(alpha: 0.4)
                            : accentYellowBright,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedLocation == null
                            ? []
                            : [
                                BoxShadow(
                                  color: accentYellowBright
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward_rounded,
                              color: Color(0xFF1A1A1A), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Proceed to Map',
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

            // Submit button (only show if no matches yet) - Primary yellow
            if (_matches.isEmpty)
              GestureDetector(
                onTap: _matching ? null : _submitIdea,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _matching
                        ? accentYellowBright.withValues(alpha: 0.5)
                        : accentYellowBright,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentYellowBright.withValues(alpha: 0.3),
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
