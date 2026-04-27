import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:alitaptap_mobile/core/models/research_backbone.dart';
import 'package:alitaptap_mobile/services/api_service.dart';

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
  final _approachCtrl = TextEditingController();
  final _aiDescriptionCtrl = TextEditingController();
  
  bool _aiGenerating = false;
  ResearchBackbone? _generatedBackbone;
  
  // Editable backbone fields
  late TextEditingController _titleEditCtrl;
  late TextEditingController _methodologyEditCtrl;
  late List<TextEditingController> _sdgEditCtrls;
  
  // Saved projects list
  final List<Map<String, String>> _savedProjects = [];
  int? _editingProjectIndex;

  @override
  void initState() {
    super.initState();
    _titleEditCtrl = TextEditingController();
    _methodologyEditCtrl = TextEditingController();
    _sdgEditCtrls = [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _sdgCtrl.dispose();
    _problemCtrl.dispose();
    _ideaCtrl.dispose();
    _approachCtrl.dispose();
    _titleEditCtrl.dispose();
    _methodologyEditCtrl.dispose();
    _aiDescriptionCtrl.dispose();
    for (var ctrl in _sdgEditCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _saveProject(String title, String description, String sdg, {bool isAIGuided = false, ResearchBackbone? backbone}) {
    setState(() {
      final impactJson = backbone != null ? jsonEncode(backbone.communityImpact.toJson()) : '';
      if (_editingProjectIndex != null) {
        _savedProjects[_editingProjectIndex!] = {
          'title': title,
          'description': description,
          'sdg': sdg,
          'date': _savedProjects[_editingProjectIndex!]['date']!,
          'mode': isAIGuided ? 'ai' : 'manual',
          'methodology': backbone?.methodology ?? '',
          'impact': impactJson,
          'feasibility': backbone != null ? 'Cost: ${backbone.feasibilityScore.cost} | Time: ${backbone.feasibilityScore.time} | Data: ${backbone.feasibilityScore.dataAvailability}' : '',
        };
        _editingProjectIndex = null;
      } else {
        _savedProjects.add({
          'title': title,
          'description': description,
          'sdg': sdg,
          'date': DateTime.now().toString().split(' ')[0],
          'mode': isAIGuided ? 'ai' : 'manual',
          'methodology': backbone?.methodology ?? '',
          'impact': impactJson,
          'feasibility': backbone != null ? 'Cost: ${backbone.feasibilityScore.cost} | Time: ${backbone.feasibilityScore.time} | Data: ${backbone.feasibilityScore.dataAvailability}' : '',
        });
      }
    });
  }

  void _loadProjectForEdit(int index) {
    final project = _savedProjects[index];
    final isAI = project['mode'] == 'ai';
    setState(() {
      _titleCtrl.text = project['title']!;
      _descriptionCtrl.text = project['description']!;
      _sdgCtrl.text = project['sdg']!;
      
      if (isAI) {
        _titleEditCtrl.text = project['title']!;
        _methodologyEditCtrl.text = project['methodology'] ?? '';
        
        CommunityImpact impact;
        try {
          final decoded = jsonDecode(project['impact'] ?? '{}');
          impact = CommunityImpact.fromJson(decoded);
        } catch (_) {
          impact = CommunityImpact.fromLegacy(project['impact'] ?? 'Medium');
        }

        _generatedBackbone = ResearchBackbone(
          researchTitle: project['title']!,
          methodology: project['methodology'] ?? '',
          sdgAlignment: project['sdg']!.split(', '),
          feasibilityScore: FeasibilityScore(
            cost: 'Medium',
            time: '6-12 months',
            dataAvailability: 'Moderate',
          ),
          communityImpact: impact,
        );
      }
      
      _editingProjectIndex = index;
      _showModeSelection = false;
      _isAIGuided = isAI;
    });
  }

  void _deleteProject(int index) {
    setState(() {
      _savedProjects.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Project deleted')),
    );
  }

  Future<void> _exportProjectToPDF(Map<String, String> project) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ALITAPTAP Project Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Exported on $dateStr',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Project Title',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  project['title']!,
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Description',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  project['description']!,
                  style: const pw.TextStyle(fontSize: 11),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'SDG Topics',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  project['sdg']!,
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Date Created',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  project['date']!,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'project_${project['title']!.replaceAll(' ', '_')}_$dateStr.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ PDF exported: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    }
  }

  Future<void> _exportProjectToTXT(Map<String, String> project) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final content = '''ALITAPTAP Project Report
Exported on $dateStr

${'='*50}

Project Title:
${project['title']}

${'='*50}

Description:
${project['description']}

${'='*50}

SDG Topics:
${project['sdg']}

${'='*50}

Date Created:
${project['date']}

${'='*50}

Methodology:
${project['methodology'] ?? 'N/A'}

${'='*50}

Community Impact Level:
${project['impact'] ?? 'N/A'}

${'='*50}

Feasibility Score:
${project['feasibility'] ?? 'N/A'}
''';

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'project_${project['title']!.replaceAll(' ', '_')}_$dateStr.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ TXT exported: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting TXT: $e')),
      );
    }
  }

  Future<void> _generateWithAI() async {
    final problem = _problemCtrl.text.trim();
    final idea = _ideaCtrl.text.trim();
    final approach = _aiDescriptionCtrl.text.trim();

    if (problem.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem must be at least 10 characters')),
      );
      return;
    }
    if (idea.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea/SDG must be at least 5 characters')),
      );
      return;
    }
    if (approach.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approach must be at least 10 characters')),
      );
      return;
    }

    setState(() => _aiGenerating = true);

    try {
      final apiService = ApiService();
      final backbone = await apiService.generateResearchBackbone(
        studentId: 'user_id',
        problem: problem,
        sdgOrIdea: idea,
        approach: approach,
      );

      if (!mounted) return;

      setState(() {
        _generatedBackbone = backbone;
        _titleEditCtrl.text = backbone.researchTitle;
        _methodologyEditCtrl.text = backbone.methodology;
        _sdgEditCtrls = backbone.sdgAlignment
            .map((sdg) => TextEditingController(text: sdg))
            .toList();
        _aiGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Research backbone generated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : _dark;
    final subtleColor =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575);

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
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: _amber, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Create',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
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
              final index = entry.key;
              final project = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _loadProjectForEdit(index),
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
                            PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _loadProjectForEdit(index);
                                } else if (value == 'delete') {
                                  _deleteProject(index);
                                } else if (value == 'pdf') {
                                  _exportProjectToPDF(project);
                                } else if (value == 'txt') {
                                  _exportProjectToTXT(project);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Export as PDF'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'txt',
                                  child: Row(
                                    children: [
                                      Icon(Icons.description, size: 18, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Export as TXT'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project['date']!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: subtleColor,
                          ),
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
        Row(
          children: [
            if (_editingProjectIndex != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _titleCtrl.clear();
                    _descriptionCtrl.clear();
                    _sdgCtrl.clear();
                    setState(() {
                      _editingProjectIndex = null;
                      _showModeSelection = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: subtleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: subtleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            if (_editingProjectIndex != null) const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_titleCtrl.text.isEmpty ||
                      _descriptionCtrl.text.isEmpty ||
                      _sdgCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
              _saveProject(_titleCtrl.text, _descriptionCtrl.text, _sdgCtrl.text, isAIGuided: false, backbone: null);
                  _titleCtrl.clear();
                  _descriptionCtrl.clear();
                  _sdgCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _editingProjectIndex == null
                            ? '✓ Project saved successfully'
                            : '✓ Project updated successfully',
                      ),
                    ),
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
                        _editingProjectIndex != null ? 'Update Project' : 'Save Project',
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
            ),
          ],
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

        // Show input fields only if not editing
        if (_editingProjectIndex == null && _generatedBackbone == null) ...[
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
        Text(
          'What is your approach or solution idea?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aiDescriptionCtrl,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'e.g. Develop an early warning system using IoT sensors...',
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
          onTap: _aiGenerating ? null : _generateWithAI,
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
                if (_aiGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_dark),
                      strokeWidth: 2,
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

        ] else if (_generatedBackbone != null) ...[
          Divider(color: _amber.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'Edit Project Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Research Title',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleEditCtrl,
            maxLines: 2,
            style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _amberBright.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _amberBright.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _amberBright,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Methodology',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _methodologyEditCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _amberBright.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _amberBright.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: _amberBright,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SDG Alignment',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _amberBright.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _generatedBackbone!.sdgAlignment.join(', '),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Feasibility Score',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _amberBright.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Cost: ${_generatedBackbone!.feasibilityScore.cost} | Time: ${_generatedBackbone!.feasibilityScore.time} | Data: ${_generatedBackbone!.feasibilityScore.dataAvailability}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Community Impact Analysis',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildImpactCard(
            _generatedBackbone!.communityImpact,
            isDark,
            textColor,
            subtleColor,
            cardBg,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _problemCtrl.clear();
                    _aiDescriptionCtrl.clear();
                    _titleEditCtrl.clear();
                    _methodologyEditCtrl.clear();
                    setState(() {
                      _generatedBackbone = null;
                      _editingProjectIndex = null;
                      _showModeSelection = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: subtleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: subtleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _saveProject(
                      _titleEditCtrl.text,
                      _methodologyEditCtrl.text,
                      _generatedBackbone!.sdgAlignment.join(', '),
                      isAIGuided: true,
                      backbone: _generatedBackbone,
                    );
                    _problemCtrl.clear();
                    _aiDescriptionCtrl.clear();
                    _titleEditCtrl.clear();
                    _methodologyEditCtrl.clear();
                    setState(() {
                      _generatedBackbone = null;
                      _editingProjectIndex = null;
                      _showModeSelection = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _editingProjectIndex == null
                              ? '✓ Project saved successfully'
                              : '✓ Project updated successfully',
                        ),
                      ),
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
                          _editingProjectIndex != null ? 'Update Project' : 'Save Project',
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
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildImpactCard(CommunityImpact impact, bool isDark, Color textColor, Color subtleColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amberBright.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  impact.summary,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtleColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _amberBright.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _amberBright.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${impact.overall.toInt()}% OVERALL',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _amberBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnimatedImpactBar('Social', impact.social, Colors.blueAccent, textColor),
          const SizedBox(height: 12),
          _buildAnimatedImpactBar('Environmental', impact.environmental, Colors.greenAccent, textColor),
          const SizedBox(height: 12),
          _buildAnimatedImpactBar('Economic', impact.economic, Colors.orangeAccent, textColor),
        ],
      ),
    );
  }

  Widget _buildAnimatedImpactBar(String label, double value, Color color, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: val,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.5),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

