import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _searchingNearest = false;
  bool _useLocationSearch = false;
  List<Map<String, dynamic>> _nearestMatches = [];
  String? _selectedIssueId;


  @override
  void dispose() {
    _ideaCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getSampleProblems() {
    return [
      {
        'issueId': 'sample_1',
        'score': 0.92,
        'reason': 'Recurring flooding in coastal barangays during monsoon season affecting 500+ households',
      },
      {
        'issueId': 'sample_2',
        'score': 0.87,
        'reason': 'Inadequate drainage system causing waterlogging in commercial districts',
      },
      {
        'issueId': 'sample_3',
        'score': 0.81,
        'reason': 'Limited access to clean water in rural communities - 3km average distance to nearest source',
      },
      {
        'issueId': 'sample_4',
        'score': 0.76,
        'reason': 'Plastic waste accumulation in rivers affecting aquatic ecosystems and local fisheries',
      },
      {
        'issueId': 'sample_5',
        'score': 0.71,
        'reason': 'Poor road infrastructure limiting access to health facilities in remote areas',
      },
    ];
  }

  Future<void> _searchNearestProblems() async {
    setState(() => _searchingNearest = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final nearest = await _api.findNearestIssues(
        lat: position.latitude,
        lng: position.longitude,
        maxResults: 5,
      );

      if (!mounted) return;
      setState(() {
        _nearestMatches = nearest
            .map((m) => {
              'issueId': m.issueId,
              'score': m.score,
              'reason': m.reason,
            })
            .toList();
        _searchingNearest = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Show sample problems on error or if no real data
      setState(() {
        _nearestMatches = _getSampleProblems();
        _searchingNearest = false;
      });
    }
  }

  Future<void> _toggleLocationSearch() async {
    if (!_useLocationSearch) {
      // Turning ON location search
      setState(() => _useLocationSearch = true);
      await _searchNearestProblems();
    } else {
      // Turning OFF location search
      setState(() {
        _useLocationSearch = false;
        _nearestMatches = [];
        _selectedIssueId = null;
      });
    }
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
      await _api.matchIdea(
        studentId: widget.studentId,
        ideaText: idea,
        maxResults: 5,
      );

      if (!mounted) return;
      setState(() => _matching = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea matched successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      if (mounted) setState(() => _matching = false);
    }
  }

  Future<void> _proceedToMap() async {
    if (_selectedIssueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a problem')),
      );
      return;
    }

    if (!mounted) return;

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

    const accentYellowBright = Color(0xFFFFD60A);
    const accentYellowMuted = Color(0xFFFFC700);

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
                      'Describe your research idea or find problems near you.',
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
            // Toggle button for location search
            GestureDetector(
              onTap: _toggleLocationSearch,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _useLocationSearch
                      ? accentYellowBright.withValues(alpha: 0.15)
                      : accentYellowMuted.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _useLocationSearch
                        ? accentYellowBright
                        : accentYellowMuted.withValues(alpha: 0.2),
                    width: _useLocationSearch ? 2 : 1,
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
                        color: _useLocationSearch
                            ? accentYellowBright
                            : Colors.transparent,
                      ),
                      child: _useLocationSearch
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFF1A1A1A), size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Nearest Problems',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search for problems near your location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: subtleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      color: accentYellowBright,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Loading state for nearest problems
            if (_searchingNearest)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: accentYellowBright.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentYellowBright.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(accentYellowBright),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Looking for nearest problems...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scanning your location for community issues',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: subtleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            // Display nearest problems
            if (_useLocationSearch && _nearestMatches.isNotEmpty && !_searchingNearest)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearest Problems',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._nearestMatches.asMap().entries.map((entry) {
                    final match = entry.value;
                    final issueId = match['issueId'] as String;
                    final isSelected = _selectedIssueId == issueId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIssueId = issueId),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      match['reason'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: textColor,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentYellowBright.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${((match['score'] as double) * 100).toStringAsFixed(0)}% proximity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accentYellowBright,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _selectedIssueId == null ? null : _proceedToMap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedIssueId == null
                            ? accentYellowBright.withValues(alpha: 0.4)
                            : accentYellowBright,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedIssueId == null
                            ? []
                            : [
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
            // Show idea input only if not using location search
            if (!_useLocationSearch) ...[
              Text(
                'Your Research Idea',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
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
              Text(
                'Be specific about the problem you want to solve, the approach, and the impact you hope to achieve.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: subtleColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
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
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
