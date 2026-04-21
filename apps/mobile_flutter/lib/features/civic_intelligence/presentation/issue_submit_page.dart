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
  bool _elaborating = false;
  String? _elaboratedText;

  @override
  void dispose() {
    _problemCtrl.dispose();
    super.dispose();
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
    
    // Simulate AI elaboration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Generate elaborated text
    final elaborated = 'Problem: $problem\n\n'
        'Elaborated Description:\n'
        'This is a community issue that requires attention. The problem described above affects local residents and infrastructure. '
        'It requires immediate action and community involvement to address effectively. '
        'The impact is significant and needs to be documented for research and intervention purposes.';

    setState(() {
      _elaboratedText = elaborated;
      _elaborating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Problem elaborated by AI')),
    );
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
            // Info banner
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

            // Toggle buttons
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

            // AI-Guided mode
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

              // Elaborate button
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
                        _elaborating ? 'Elaborating...' : 'Elaborate with AI',
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

              // Elaborated result
              if (_elaboratedText != null) ...[
                const SizedBox(height: 24),
                Text(
                  'AI-Elaborated Description',
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
                  child: Text(
                    _elaboratedText!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Manual mode placeholder
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _amber.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          color: _amber.withValues(alpha: 0.5), size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Manual Report',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manual report form coming soon',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: subtleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
