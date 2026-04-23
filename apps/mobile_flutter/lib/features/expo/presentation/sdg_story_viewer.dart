import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';
import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/services/api_service.dart';
import 'expo_post_detail_page.dart';

class SdgStoryViewer extends StatefulWidget {
  const SdgStoryViewer({
    super.key,
    required this.sdgLabel,
    required this.sdgName,
    required this.accentColor,
    required this.currentUid,
    required this.currentEmail,
  });

  final String sdgLabel;
  final String sdgName;
  final Color accentColor;
  final String currentUid;
  final String currentEmail;

  @override
  State<SdgStoryViewer> createState() => _SdgStoryViewerState();
}

class _SdgStoryViewerState extends State<SdgStoryViewer> {
  final _api = ApiService();
  late List<ResearchPost> _filteredPosts;
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Filter posts that contain this SDG tag
    _filteredPosts = MockData.researchPosts
        .where((post) => post.sdgTags.contains(widget.sdgLabel))
        .toList();

    if (_filteredPosts.isNotEmpty) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.02; // 5 seconds total (100ms * 50 steps)
        if (_progress >= 1.0) {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (_currentIndex < _filteredPosts.length - 1) {
      setState(() {
        _currentIndex++;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      _startTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      _startTimer();
    } else {
      _startTimer();
    }
  }

  Future<void> _toggleLike() async {
    final post = _filteredPosts[_currentIndex];
    // Pause timer while liking? Or just let it run.
    try {
      final updated = await _api.toggleLike(postId: post.postId, userId: widget.currentUid);
      setState(() {
        _filteredPosts[_currentIndex] = updated;
      });
    } catch (_) {}
  }

  void _viewFullThesis() {
    _timer?.cancel(); // Pause story when navigating away
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpoPostDetailPage(
          post: _filteredPosts[_currentIndex],
          currentUid: widget.currentUid,
          currentEmail: widget.currentEmail,
        ),
      ),
    ).then((_) {
      // Resume or just stay paused? Usually better to restart or keep paused.
      // We'll just restart for now.
      _startTimer(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredPosts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_outlined, color: widget.accentColor, size: 48),
              const SizedBox(height: 16),
              Text(
                'No research stories for ${widget.sdgLabel} yet.',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: GoogleFonts.poppins(color: widget.accentColor)),
              )
            ],
          ),
        ),
      );
    }

    final currentPost = _filteredPosts[_currentIndex];
    final isLiked = currentPost.likedBy.contains(widget.currentUid);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredPosts.length,
            itemBuilder: (context, index) {
              final post = _filteredPosts[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.imageUrl ?? '',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: widget.accentColor.withValues(alpha: 0.5),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: Center(
                        child: Icon(Icons.auto_awesome_mosaic_rounded,
                            color: widget.accentColor.withValues(alpha: 0.2),
                            size: 80),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.2, 0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Progress Bars
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: List.generate(_filteredPosts.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: index == _currentIndex
                              ? _progress
                              : (index < _currentIndex ? 1.0 : 0.0),
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            index == _currentIndex ? widget.accentColor : Colors.white,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.science_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.sdgLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.sdgName,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // Tap Detectors
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _prevStory,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextStory,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'STUDENT RESEARCH',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentPost.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentPost.abstract,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _viewFullThesis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'View Full Thesis',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLiked ? widget.accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isLiked ? widget.accentColor : Colors.white24),
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: isLiked ? widget.accentColor : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
