import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _amber = Color(0xFFFFC700);
const _amberMuted = Color(0xFFFFB700);
const _amberBright = Color(0xFFFFD60A);
const _dark = Color(0xFF1A1A1A);

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  bool _showModeSelection = true;
  bool _isAIGuided = false;
  
  // Manual mode controllers
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _sdgCtrl = TextEditingController();
  
  // AI guided mode controllers
  final _problemCtrl = TextEditingController();
  final _ideaCtrl = TextEditingController();
  final _aiDescriptionCtrl = TextEditingController();
  
  bool _aiGenerating = false;
  
  // Saved projects list
  List<Map<String, String>> _savedProjects = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _sdgCtrl.dispose();
    _problemCtrl.dispose();
    _ideaCtrl.dispose();
    _aiDescriptionCtrl.dispose();
    super.dispose();
  }

  void _saveProject(String title, String description, String sdg) {
    setState(() {
      _savedProjects.add({
        'title': title,
        'description': description,
        'sdg': sdg,
        'date': DateTime.now().toString().split(' ')[0],
      });
    });
  }

  Future<void> _generateWithAI() async {
    final problem = _problemCtrl.text.trim();
    final idea = _ideaCtrl.text.trim();
    final description = _aiDescriptionCtrl.text.trim();

    if (problem.isEmpty || idea.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _aiGenerating = true);
    
    // Simulate AI generation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Generate sample title and description
    final generatedTitle = 'AI-Generated: $idea Solution for $problem';
    final generatedDesc = 'This research project addresses the community problem of "$problem" '
        'through the lens of "$idea". The proposed solution aims to create sustainable impact '
        'by implementing the following approach: $description. This initiative aligns with '
        'multiple SDG targets and focuses on scalability and community engagement.';

    setState(() {
      _titleCtrl.text = generatedTitle;
      _descriptionCtrl.text = generatedDesc;
      _aiGenerating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ AI generated title and description')),
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
      body: SafeArea(
        child: _showModeSelection
            ? _buildModeSelection(isDark, textColor, subtleColor, cardBg)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showModeSelection = true),
                          child: const Icon(Icons.arrow_back_ios_rounded,
                              color: _amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAIGuided ? 'AI-Guided Creation' : 'Manual Creation',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _isAIGuided
                                    ? 'Let AI help you create your project'
                                    : 'Create your project manually',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: subtleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isAIGuided)
                      _buildAIGuidedMode(isDark, textColor, subtleColor, cardBg)
                    else
                      _buildManualMode(isDark, textColor, subtleColor, cardBg),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModeSelection(bool isDark, Color textColor, Color subtleColor, Color cardBg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How would you like to create your project?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: subtleColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // AI Guided Option
          GestureDetector(
            onTap: () => setState(() {
              _isAIGuided = true;
              _showModeSelection = false;
            }),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _amberBright.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _amberBright.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _amberBright.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _amberBright,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI-Guided Creation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Answer guided questions and let AI compile your project details',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtleColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Manual Option
          GestureDetector(
            onTap: () => setState(() {
              _isAIGuided = false;
              _showModeSelection = false;
            }),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _amber.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: _amber,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manual Creation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Write your project title, description, and SDG topics directly',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtleColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Saved Projects Section
          if (_savedProjects.isNotEmpty) ...[
            Text(
              'Your Projects',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ..._savedProjects.asMap().entries.map((entry) {
              final project = entry.value;
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
                              project['title']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            project['date']!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: subtleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project['description']!,
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
                          project['sdg']!,
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
        ],
      ),
    );
  }

  Widget _buildManualMode(bool isDark, Color textColor, Color subtleColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Project Title',
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
            hintText: 'e.g. Community Flood Early Warning System',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: subtleColor,
            ),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amberMuted.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amberMuted.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _amberMuted,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Description
        Text(
          'Project Description',
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
            hintText: 'Describe your project, approach, and expected impact...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: subtleColor,
            ),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amberMuted.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amberMuted.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _amberMuted,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // SDG Topics
        Text(
          'SDG Topics',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sdgCtrl,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'e.g. SDG 6 (Clean Water), SDG 13 (Climate Action)...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: subtleColor,
            ),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amberMuted.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _amberMuted.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _amberMuted,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Save Button
        GestureDetector(
          onTap: () {
            if (_titleCtrl.text.isEmpty ||
                _descriptionCtrl.text.isEmpty ||
                _sdgCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            _saveProject(_titleCtrl.text, _descriptionCtrl.text, _sdgCtrl.text);
            _titleCtrl.clear();
            _descriptionCtrl.clear();
            _sdgCtrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Project saved successfully')),
            );
            setState(() => _showModeSelection = true);
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
                  'Save Project',
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
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAIGuidedMode(bool isDark, Color textColor, Color subtleColor, Color cardBg) {
    return Column(
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
              const Icon(Icons.lightbulb_outline_rounded,
                  color: _amberBright, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Answer these questions and AI will compile your project details',
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

        // Problem
        Text(
          'What is the community problem?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _problemCtrl,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'e.g. Recurring flooding in coastal areas...',
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

        // SDG Idea
        Text(
          'What SDG or idea do you want to focus on?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ideaCtrl,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'e.g. Early warning system using IoT sensors...',
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

        // Description
        Text(
          'Describe your approach',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aiDescriptionCtrl,
          maxLines: 4,
          style: GoogleFonts.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'Add timeline, resources, methods, expected outcomes...',
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
        const SizedBox(height: 32),

        // Generate Button
        GestureDetector(
          onTap: _aiGenerating ? null : _generateWithAI,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _aiGenerating
                  ? _amberBright.withValues(alpha: 0.5)
                  : _amberBright,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _aiGenerating
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
                if (_aiGenerating)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _dark,
                    ),
                  )
                else
                  const Icon(Icons.auto_awesome_rounded, color: _dark, size: 20),
                const SizedBox(width: 10),
                Text(
                  _aiGenerating ? 'Generating...' : 'Generate with AI',
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
        const SizedBox(height: 24),

        // Generated fields (if any)
        if (_titleCtrl.text.isNotEmpty) ...[
          Divider(color: _amber.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'Generated Project Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
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
                  'Title',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _amberBright,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _titleCtrl.text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _amberBright,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _descriptionCtrl.text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtleColor,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              _saveProject(_titleCtrl.text, _descriptionCtrl.text, 'AI-Generated');
              _titleCtrl.clear();
              _descriptionCtrl.clear();
              _problemCtrl.clear();
              _ideaCtrl.clear();
              _aiDescriptionCtrl.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Project saved successfully')),
              );
              setState(() => _showModeSelection = true);
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
                    'Save Project',
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
        const SizedBox(height: 24),
      ],
    );
  }
}
