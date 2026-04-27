import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/core/models/issue.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';
import 'package:alitaptap_mobile/features/civic_intelligence/application/map_engine_rollout.dart';
import 'package:alitaptap_mobile/features/civic_intelligence/presentation/issue_map_page_leaflet.dart';
import 'package:alitaptap_mobile/features/expo/presentation/expo_post_detail_page.dart';
import 'package:alitaptap_mobile/services/api_service.dart';

class CivicExploreDashboard extends StatefulWidget {
  const CivicExploreDashboard({super.key, required this.uid});
  final String uid;

  @override
  State<CivicExploreDashboard> createState() => _CivicExploreDashboardState();
}

class _CivicExploreDashboardState extends State<CivicExploreDashboard> {
  static const _amber = Color(0xFFFFC700);
  final _apiService = ApiService();
  List<Issue> _liveIssues = [];
  List<ResearchPost> _livePosts = [];
  bool _loadingIssues = true;
  bool _loadingPosts = true;

  @override
  void initState() {
    super.initState();
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    _loadLiveIssues();
    _loadLivePosts();
  }

  Future<void> _loadLiveIssues() async {
    try {
      final issues = await _apiService.getIssues(status: 'validated');
      if (mounted) {
        setState(() {
          _liveIssues = issues;
          _loadingIssues = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingIssues = false);
    }
  }

  Future<void> _loadLivePosts() async {
    try {
      final posts = await _apiService.getPosts();
      if (mounted) {
        setState(() {
          _livePosts = posts;
          _loadingPosts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapEngine = MapEngineRollout.resolveForUser(widget.uid);
    final effectiveMapEngine =
        (kIsWeb && MapEngineRollout.isAutoMode) ? MapEngine.leaflet : mapEngine;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtle = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Explore Intelligence',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      isDark ? Colors.black : const Color(0xFFF0F0F0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Mini Map Card ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeafletIssueMapPage(studentId: widget.uid),
                  ),
                ),
                child: Hero(
                  tag: 'mini_map',
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: cardBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: _amber.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Map Representation: Live Snapshot
                        AbsorbPointer(
                          child: effectiveMapEngine == MapEngine.leaflet
                              ? FlutterMap(
                                  options: const MapOptions(
                                    initialCenter:
                                        latlng.LatLng(12.8797, 121.7740),
                                    initialZoom: 4.5,
                                    interactionOptions:
                                        InteractionOptions(flags: 0),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                      userAgentPackageName:
                                          'com.alitaptap.mobile',
                                    ),
                                  ],
                                )
                              : MapLibreMap(
                                  styleString:
                                      '{"version":8,"sources":{"osm":{"type":"raster","tiles":["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],"tileSize":256}},"layers":[{"id":"osm","type":"raster","source":"osm"}]}',
                                  initialCameraPosition: const CameraPosition(
                                    target: LatLng(12.8797, 121.7740),
                                    zoom: 4.5,
                                  ),
                                  annotationOrder: const [],
                                  annotationConsumeTapEvents: const [
                                    AnnotationType.circle
                                  ],
                                ),
                        ),
                        // Dark Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.map_rounded,
                                    color: Color(0xFF1A1A1A)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Live Intelligence Map',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Tap to explore real-world problems',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Pulse Animation indicator
                        const Positioned(
                          top: 20,
                          right: 20,
                          child: _LivePulse(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Opportunity Heatmap ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opportunity Heatmap',
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Priority SDG Intelligence',
                            style: GoogleFonts.poppins(
                              color: subtle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LIVE DATA',
                          style: GoogleFonts.robotoMono(
                            color: _amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SDGGridMatrix(isDark: isDark, issues: _liveIssues),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'LOW PRIORITY',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 6,
                        children: List.generate(5, (i) {
                          final color = Color.lerp(
                            const Color(0xFFFFC700).withValues(alpha: 0.2),
                            const Color(0xFFFFC700),
                            i / 4,
                          )!;
                          return Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'HIGH PRIORITY',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: const Color(0xFFFFC700),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Section Title: Top Research Projects ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Research Projects',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'View Expo',
                    style: GoogleFonts.poppins(
                      color: _amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Research Projects List ─────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (_livePosts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        _loadingPosts ? 'Loading projects...' : 'No research projects found.',
                        style: GoogleFonts.poppins(color: subtle),
                      ),
                    ),
                  );
                }
                final post = _livePosts[index % _livePosts.length];
                return _ResearchListItem(
                  post: post,
                  isDark: isDark,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpoPostDetailPage(
                        post: post,
                        currentUid: widget.uid,
                        currentEmail: '', // Optional
                      ),
                    ),
                  ),
                );
              },
              childCount: _livePosts.isEmpty ? 1 : _livePosts.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ResearchListItem extends StatelessWidget {
  const _ResearchListItem({
    required this.post,
    required this.isDark,
    required this.onTap,
  });

  final ResearchPost post;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final amber = const Color(0xFFFFC700);
    final progress = (post.fundingRaised / post.fundingGoal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: amber.withValues(alpha: 0.1)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon or Image
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      image: post.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(post.imageUrl!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: post.imageUrl == null
                        ? Icon(Icons.science_rounded, color: amber, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Title and Tags
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: post.sdgTags
                              .take(3)
                              .map((sdg) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: amber.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sdg,
                                      style: GoogleFonts.robotoMono(
                                        color: amber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Funding Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Funding Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: amber.withValues(alpha: 0.1),
                  color: amber,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2 + (0.5 * _anim.value)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SDGGridMatrix extends StatelessWidget {
  const _SDGGridMatrix({required this.isDark, required this.issues});
  final bool isDark;
  final List<Issue> issues;

  @override
  Widget build(BuildContext context) {
    final Map<int, String> sdgNames = {
      1: 'No Poverty',
      2: 'Zero Hunger',
      3: 'Good Health',
      4: 'Quality Education',
      5: 'Gender Equality',
      6: 'Clean Water',
      7: 'Clean Energy',
      8: 'Decent Work',
      9: 'Innovation',
      10: 'Reduced Inequality',
      11: 'Sustainable Cities',
      12: 'Consumption',
      13: 'Climate Action',
      14: 'Life Below Water',
      15: 'Life on Land',
      16: 'Peace & Justice',
      17: 'Partnerships',
    };

    // Calculate SDG counts from live issues
    final Map<int, int> counts = {};
    for (var i = 1; i <= 17; i++) {
      counts[i] = 0;
    }

    for (final issue in issues) {
      final tag = issue.aiSdgTag ?? '';
      if (tag.startsWith('SDG ')) {
        final numStr = tag.replaceAll('SDG ', '');
        final num = int.tryParse(numStr);
        if (num != null && num >= 1 && num <= 17) {
          counts[num] = (counts[num] ?? 0) + 1;
        }
      }
    }

    final activeSdgs = List.generate(17, (i) => i + 1);
    final values = counts.values.toList();
    final maxCount = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b).clamp(1, 100);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: activeSdgs.length,
      itemBuilder: (context, index) {
        final sdgNum = activeSdgs[index];
        final count = counts[sdgNum] ?? 0;
        final intensity = (count / maxCount).clamp(0.05, 1.0);

        final Color color;
        if (count == 0) {
          color = isDark ? const Color(0xFF222222) : Colors.blueGrey.shade50;
        } else {
          color = Color.lerp(
            const Color(0xFFFFC700).withValues(alpha: 0.15),
            const Color(0xFFFFC700),
            intensity,
          )!;
        }

        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SDG $sdgNum',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: intensity > 0.6
                      ? Colors.black
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sdgNames[sdgNum] ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: intensity > 0.6
                      ? Colors.black.withValues(alpha: 0.6)
                      : (isDark ? Colors.white38 : Colors.black45),
                  height: 1.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
