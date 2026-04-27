import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/models/story_post.dart';
import 'package:alitaptap_mobile/services/api_service.dart' show ApiService;

class SdgStoryViewer extends StatefulWidget {
  const SdgStoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  final List<StoryPost> stories;
  final int initialIndex;

  @override
  State<SdgStoryViewer> createState() => _SdgStoryViewerState();
}

class _SdgStoryViewerState extends State<SdgStoryViewer> {
  late final List<StoryPost> _stories;
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _stories = List<StoryPost>.from(widget.stories);
    _currentIndex = _stories.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    if (_stories.isNotEmpty) {
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
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
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

  Color _accentColorForSdg(String sdgLabel) {
    switch (sdgLabel) {
      case 'SDG 3':
        return const Color(0xFFEF5350);
      case 'SDG 12':
        return const Color(0xFFFFB300);
      case 'SDG 11':
        return const Color(0xFFAB47BC);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_stories_outlined,
                  color: Color(0xFFFFD60A), size: 48),
              const SizedBox(height: 16),
              Text(
                'No story posts available yet.',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close',
                    style: GoogleFonts.poppins(color: const Color(0xFFFFD60A))),
              )
            ],
          ),
        ),
      );
    }

    final currentStory = _stories[_currentIndex];
    final accent = _accentColorForSdg(currentStory.sdgLabel);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stories.length,
            itemBuilder: (context, index) {
              final story = _stories[index];
              final pageAccent = _accentColorForSdg(story.sdgLabel);
              return Stack(
                fit: StackFit.expand,
                children: [
                  story.imagePath.isNotEmpty
                      ? Image.network(
                          ApiService.fixImageUrl(story.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A1A),
                            child: Center(
                              child: Icon(Icons.auto_awesome_mosaic_rounded,
                                  color: pageAccent.withValues(alpha: 0.3), size: 80),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1A1A1A),
                          child: Center(
                            child: Icon(Icons.auto_awesome_mosaic_rounded,
                                color: pageAccent.withValues(alpha: 0.3), size: 80),
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
                children: List.generate(_stories.length, (index) {
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
                            index == _currentIndex ? accent : Colors.white,
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
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.science_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentStory.sdgLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          currentStory.sdgName,
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
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 28),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'STORY POST',
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
                  currentStory.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentStory.description,
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'Aligned SDG: ${currentStory.sdgLabel} - ${currentStory.sdgName}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
