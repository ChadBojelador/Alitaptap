import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/api_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({
    super.key,
    required this.authorId,
    required this.authorEmail,
  });

  final String authorId;
  final String authorEmail;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _api = ApiService();

  final List<String> _sdgTags = [];
  File? _pickedImage;
  bool _submitting = false;

  static const _yellow = Color(0xFFFFD60A);

  static const _sdgOptions = [
    'SDG 1 - No Poverty', 'SDG 2 - Zero Hunger', 'SDG 3 - Good Health',
    'SDG 4 - Quality Education', 'SDG 5 - Gender Equality', 'SDG 6 - Clean Water',
    'SDG 7 - Clean Energy', 'SDG 8 - Decent Work', 'SDG 9 - Industry & Innovation',
    'SDG 10 - Reduced Inequalities', 'SDG 11 - Sustainable Cities',
    'SDG 12 - Responsible Consumption', 'SDG 13 - Climate Action',
    'SDG 14 - Life Below Water', 'SDG 15 - Life on Land',
    'SDG 16 - Peace & Justice', 'SDG 17 - Partnerships',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _problemCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _api.createPost(
        authorId: widget.authorId,
        authorEmail: widget.authorEmail,
        title: _titleCtrl.text.trim(),
        abstract: _abstractCtrl.text.trim(),
        problemSolved: _problemCtrl.text.trim(),
        sdgTags: _sdgTags,
        fundingGoal: double.tryParse(_goalCtrl.text.trim()) ?? 0.0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Research published to the Expo!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to publish: $e')));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtle =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close_rounded, color: _yellow, size: 20),
          ),
        ),
        title: Row(
          children: [
            _Avatar(email: widget.authorEmail, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.authorEmail.split('@').first,
                    style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public_rounded,
                              size: 12, color: subtle),
                          const SizedBox(width: 4),
                          Text('Public',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: subtle,
                                  fontWeight: FontWeight.w600)),
                          Icon(Icons.expand_more_rounded,
                              size: 14, color: subtle),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _submitting ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _submitting
                      ? _yellow.withValues(alpha: 0.5)
                      : _yellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A)))
                    : Text('Post',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Text fields ──────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'Research title...',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            color: subtle,
                            fontWeight: FontWeight.w700),
                        border: InputBorder.none,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _abstractCtrl,
                      maxLines: null,
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Share your abstract, findings, or ideas...',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 15, color: subtle),
                        border: InputBorder.none,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _problemCtrl,
                      maxLines: null,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'What community problem does this address?',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 14, color: subtle),
                        border: InputBorder.none,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Photo preview ────────────────────────────────────────
              if (_pickedImage != null)
                Stack(
                  children: [
                    Image.file(_pickedImage!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // ── SDG tags ─────────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SDG Alignment',
                        style: GoogleFonts.poppins(
                            color: subtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF242424)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _yellow.withValues(alpha: 0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: Text('Select an SDG',
                              style: GoogleFonts.poppins(
                                  color: subtle, fontSize: 13)),
                          dropdownColor: isDark
                              ? const Color(0xFF242424)
                              : Colors.white,
                          isExpanded: true,
                          icon: const Icon(Icons.expand_more_rounded,
                              color: _yellow),
                          items: _sdgOptions
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: GoogleFonts.poppins(
                                            color: textColor,
                                            fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null && !_sdgTags.contains(v)) {
                              setState(() => _sdgTags.add(v));
                            }
                          },
                        ),
                      ),
                    ),
                    if (_sdgTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sdgTags
                            .map((t) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _sdgTags.remove(t)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          _yellow.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _yellow
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(t,
                                            style: GoogleFonts.poppins(
                                              color: _yellow,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            )),
                                        const SizedBox(width: 4),
                                        Icon(Icons.close_rounded,
                                            color: _yellow
                                                .withValues(alpha: 0.7),
                                            size: 12),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Funding goal ─────────────────────────────────────────
              Container(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Funding Goal (₱) — optional',
                        style: GoogleFonts.poppins(
                            color: subtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _goalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. 50000',
                        hintStyle:
                            GoogleFonts.poppins(fontSize: 13, color: subtle),
                        prefixText: '₱ ',
                        prefixStyle: GoogleFonts.poppins(
                            color: _yellow, fontWeight: FontWeight.w700),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF242424)
                            : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: _yellow.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: _yellow.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _yellow, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // ── Bottom toolbar ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        child: Row(
          children: [
            _ToolbarBtn(
              icon: Icons.photo_library_rounded,
              label: 'Photo',
              color: const Color(0xFF66BB6A),
              onTap: _pickImage,
            ),
            _ToolbarBtn(
              icon: Icons.tag_rounded,
              label: 'Tag',
              color: const Color(0xFF42A5F5),
              onTap: () {},
            ),
            _ToolbarBtn(
              icon: Icons.emoji_emotions_rounded,
              label: 'Feeling',
              color: const Color(0xFFFFCA28),
              onTap: () {},
            ),
            _ToolbarBtn(
              icon: Icons.location_on_rounded,
              label: 'Location',
              color: const Color(0xFFEF5350),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.email, required this.size});
  final String email;
  final double size;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: _yellow.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
              color: _yellow,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}
