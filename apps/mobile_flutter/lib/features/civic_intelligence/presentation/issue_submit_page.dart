import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _amber = Color(0xFFFFC700);
const _amberBright = Color(0xFFFFD60A);
const _dark = Color(0xFF1A1A1A);

class IssueSubmitPage extends StatefulWidget {
  const IssueSubmitPage({super.key, required this.reporterId, this.reporterName});
  final String reporterId;
  final String? reporterName;

  @override
  State<IssueSubmitPage> createState() => _IssueSubmitPageState();
}

class _IssueSubmitPageState extends State<IssueSubmitPage> {
  bool _isAIGuided = false;
  final _problemCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _elaborating = false;
  String? _elaboratedText;
  String? _suggestedSDG;
  List<Map<String, String>> _savedReports = [];

  @override
  void dispose() {
    _problemCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _saveReport(String title, String description, String sdg) {
    setState(() {
      _savedReports.add({
        'title': title,
        'description': description,
        'sdg': sdg,
        'date': DateTime.now().toString().split(' ')[0],
      });
    });
  }

  void _deleteReport(int index) {
    setState(() {
      _savedReports.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Report deleted')),
    );
  }

  Future<void> _elaborateWithAI() async {
    final problem = _problemCtrl.text.trim();
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the problem')),
      );
      return;
    }

    setState(() => _elaborating = true);
    
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final elaborated = _generateElaboratedDescription(problem);
    final sdg = _suggestSDG(problem);

    setState(() {
      _elaboratedText = elaborated;
      _suggestedSDG = sdg;
      _elaborating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Problem analyzed by AI')),
    );
  }

  String _generateElaboratedDescription(String problem) {
    return 'Impact: The issue affects community members and local infrastructure.\n\n'
        'Scope: This problem requires immediate attention and community involvement.\n\n'
        'Solution Potential: Addressing this requires coordinated efforts and resource allocation.\n\n'
        'Community Benefit: Resolution will improve quality of life and sustainability.';
  }

  String _suggestSDG(String problem) {
    final lowerProblem = problem.toLowerCase();
    
    if (lowerProblem.contains('water') || lowerProblem.contains('flood') || lowerProblem.contains('sanitation')) {
      return 'SDG 6: Clean Water and Sanitation';
    } else if (lowerProblem.contains('health') || lowerProblem.contains('disease') || lowerProblem.contains('medical')) {
      return 'SDG 3: Good Health and Well-being';
    } else if (lowerProblem.contains('education') || lowerProblem.contains('school') || lowerProblem.contains('learning')) {
      return 'SDG 4: Quality Education';
    } else if (lowerProblem.contains('poverty') || lowerProblem.contains('income') || lowerProblem.contains('employment')) {
      return 'SDG 1: No Poverty';
    } else if (lowerProblem.contains('climate') || lowerProblem.contains('environment') || lowerProblem.contains('pollution')) {
      return 'SDG 13: Climate Action';
    } else if (lowerProblem.contains('waste') || lowerProblem.contains('garbage') || lowerProblem.contains('recycl')) {
      return 'SDG 12: Responsible Consumption';
    } else if (lowerProblem.contains('energy') || lowerProblem.contains('electricity') || lowerProblem.contains('power')) {
      return 'SDG 7: Affordable Clean Energy';
    } else if (lowerProblem.contains('infrastructure') || lowerProblem.contains('road') || lowerProblem.contains('transport')) {
      return 'SDG 9: Industry, Innovation and Infrastructure';
    } else if (lowerProblem.contains('gender') || lowerProblem.contains('women') || lowerProblem.contains('discrimination')) {
      return 'SDG 5: Gender Equality';
    } else {
      return 'SDG 17: Partnerships for the Goals';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : _dark;
    final subtleColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Report a Problem',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _amberBright.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _amberBright.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _amberBright, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Help us understand community problems better.',
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

            Text(
              'Report Method',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAIGuided = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isAIGuided
                            ? _amber
                            : (isDark
                                ? const Color(0xFF242424)
                                : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isAIGuided
                              ? _amber
                              : _amber.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: !_isAIGuided ? _dark : subtleColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Manual',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !_isAIGuided ? _dark : subtleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAIGuided = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAIGuided
                            ? _amberBright
                            : (isDark
                                ? const Color(0xFF242424)
                                : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAIGuided
                              ? _amberBright
                              : _amberBright.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: _isAIGuided ? _dark : subtleColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AI-Guided',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isAIGuided ? _dark : subtleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_isAIGuided) ...[
              Text(
                'Describe the Problem',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _problemCtrl,
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Describe the community problem in your own words...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtleColor,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amberBright.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amberBright.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _amberBright,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: _elaborating ? null : _elaborateWithAI,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _elaborating
                        ? _amberBright.withValues(alpha: 0.5)
                        : _amberBright,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _elaborating
                        ? []
                        : [
                            BoxShadow(
                              color: _amberBright.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_elaborating)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _dark,
                          ),
                        )
                      else
                        const Icon(Icons.auto_awesome_rounded,
                            color: _dark, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _elaborating ? 'Analyzing...' : 'Analyze with AI',
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_elaboratedText != null) ...[
                const SizedBox(height: 24),
                Text(
                  'AI Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _amberBright.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _amberBright.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _elaboratedText!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                      if (_suggestedSDG != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _amberBright.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flag_rounded,
                                  color: _amberBright, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _suggestedSDG!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _amberBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    _saveReport(_problemCtrl.text, _elaboratedText!, _suggestedSDG ?? 'SDG 17');
                    _problemCtrl.clear();
                    setState(() {
                      _elaboratedText = null;
                      _suggestedSDG = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Report saved successfully')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _amberBright,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _amberBright.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, color: _dark, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Save Report',
                          style: GoogleFonts.poppins(
                            color: _dark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Problem Title',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'e.g. Recurring flooding on Main Street',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtleColor,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _amber,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Describe the problem in detail — who is affected, how often, what impact...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtleColor,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _amber,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  if (_titleCtrl.text.isEmpty || _descriptionCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  _saveReport(_titleCtrl.text, _descriptionCtrl.text, 'Manual Report');
                  _titleCtrl.clear();
                  _descriptionCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Report saved successfully')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _amber,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _amber.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, color: _dark, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Save Report',
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_savedReports.isNotEmpty) ...[
              const SizedBox(height: 40),
              Text(
                'Your Reports',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              ..._savedReports.asMap().entries.map((entry) {
                final index = entry.key;
                final report = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                report['title']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _deleteReport(index),
                              child: Icon(Icons.delete_rounded,
                                  color: subtleColor, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report['date']!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: subtleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report['description']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: subtleColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            report['sdg']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: _amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
