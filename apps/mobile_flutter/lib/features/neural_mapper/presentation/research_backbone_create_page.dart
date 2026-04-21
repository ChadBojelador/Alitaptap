import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/research_backbone.dart';
import '../application/usecases/generate_research_backbone_use_case.dart';
import '../data/repositories/api_research_repository.dart';

class ResearchBackboneCreatePage extends StatefulWidget {
  const ResearchBackboneCreatePage({
    super.key,
    required this.studentId,
  });

  final String studentId;

  @override
  State<ResearchBackboneCreatePage> createState() =>
      _ResearchBackboneCreatePageState();
}

class _ResearchBackboneCreatePageState
    extends State<ResearchBackboneCreatePage> {
  final _repository = ApiResearchRepository();
  late final GenerateResearchBackboneUseCase _generateUseCase =
      GenerateResearchBackboneUseCase(_repository);

  final _problemController = TextEditingController();
  final _ideaController = TextEditingController();
  final _approachController = TextEditingController();

  bool _loading = false;
  String? _error;
  ResearchBackbone? _backbone;

  // Editable fields
  late TextEditingController _titleController;
  late TextEditingController _methodologyController;
  late TextEditingController _impactController;

  @override
  void dispose() {
    _problemController.dispose();
    _ideaController.dispose();
    _approachController.dispose();
    _titleController.dispose();
    _methodologyController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  Future<void> _generateBackbone() async {
    final problem = _problemController.text.trim();
    final idea = _ideaController.text.trim();
    final approach = _approachController.text.trim();

    if (problem.length < 10) {
      setState(() => _error = 'Problem must be at least 10 characters.');
      return;
    }
    if (idea.length < 5) {
      setState(() => _error = 'Idea/SDG must be at least 5 characters.');
      return;
    }
    if (approach.length < 10) {
      setState(() => _error = 'Approach must be at least 10 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _backbone = null;
    });

    try {
      final backbone = await _generateUseCase(
        GenerateResearchBackboneInput(
          studentId: widget.studentId,
          problem: problem,
          sdgOrIdea: idea,
          approach: approach,
        ),
      );

      if (mounted) {
        setState(() {
          _backbone = backbone;
          _titleController.text = backbone.researchTitle;
          _methodologyController.text = backbone.methodology;
          _impactController.text = backbone.communityImpactLevel;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  void _saveBackbone() {
    if (_backbone == null) return;

    final updatedBackbone = ResearchBackbone(
      researchTitle: _titleController.text,
      methodology: _methodologyController.text,
      sdgAlignment: _backbone!.sdgAlignment,
      feasibilityScore: _backbone!.feasibilityScore,
      communityImpactLevel: _impactController.text,
    );

    Navigator.of(context).pop(updatedBackbone);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Research Backbone',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_backbone == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFFFD60A), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Describe the community problem, your research idea, and your approach. AI will generate a backbone you can edit.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFF0F0F0)
                            : const Color(0xFF1A1A1A),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Community Problem',
              controller: _problemController,
              hint: 'e.g., Recurring flooding affecting households',
              minLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Research Idea / SDG Focus',
              controller: _ideaController,
              hint: 'e.g., Early warning system for flood prediction',
              minLines: 2,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Proposed Approach',
              controller: _approachController,
              hint: 'e.g., Combine IoT sensors with machine learning',
              minLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Text(
              'AI-Generated Backbone',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Research Title',
              controller: _titleController,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Methodology',
              controller: _methodologyController,
              minLines: 4,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              label: 'SDG Alignment',
              value: _backbone!.sdgAlignment.join(', '),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              label: 'Feasibility Score',
              value:
                  'Cost: ${_backbone!.feasibilityScore.cost} | Time: ${_backbone!.feasibilityScore.time} | Data: ${_backbone!.feasibilityScore.dataAvailability}',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Community Impact Level',
              controller: _impactController,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int minLines = 2,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines + 2,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF616161)
                  : const Color(0xFF9E9E9E),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFFD60A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    int minLines = 2,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Editable',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFD60A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines + 2,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFFFD60A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'AI-Generated',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFFF0F0F0)
                  : const Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: _loading ? null : _generateBackbone,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _loading
              ? const Color(0xFFFFD60A).withValues(alpha: 0.5)
              : const Color(0xFFFFD60A),
          borderRadius: BorderRadius.circular(12),
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
            if (_loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A1A1A),
                ),
              )
            else
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF1A1A1A), size: 20),
            const SizedBox(width: 10),
            Text(
              _loading ? 'Generating...' : 'Generate Backbone',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveBackbone,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD60A),
          borderRadius: BorderRadius.circular(12),
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
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF1A1A1A), size: 20),
            const SizedBox(width: 10),
            Text(
              'Save Backbone',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
