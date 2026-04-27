import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../app/app.dart' show AppTheme;
import '../../../core/models/issue.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';
import '../application/usecases/get_validated_issues_use_case.dart';
import '../data/repositories/api_issue_repository.dart';
import 'issue_detail_page.dart';
import 'issue_submit_page.dart';

const _leafletBg = Color(0xFF0A0E17);
const _leafletPanel = Color(0xFF0D1320);
const _leafletYellow = Color(0xFFFFD60A);
const _leafletRed = Color(0xFFFF2D55);
const _leafletText = Color(0xFFE0FFF8);
const _leafletMuted = Color(0xFF8A7340);

class LeafletIssueMapPage extends StatefulWidget {
  const LeafletIssueMapPage({
    super.key,
    this.showIdeaDock = false,
    this.studentId,
    this.onToggleTheme,
    this.themeMode = ThemeMode.dark,
    this.initialIdeaText,
    this.autoRun = false,
  });

  final bool showIdeaDock;
  final String? studentId;
  final VoidCallback? onToggleTheme;
  final ThemeMode themeMode;
  final String? initialIdeaText;
  final bool autoRun;

  @override
  State<LeafletIssueMapPage> createState() => _LeafletIssueMapPageState();
}

class _LeafletIssueMapPageState extends State<LeafletIssueMapPage> {
  static const _defaultCenter = latlng.LatLng(12.8797, 121.7740);
  static const _defaultZoom = 6.0;
  static const _focusZoom = 15.5;
  static const _tapThreshold = 0.004;

  final _issueRepository = ApiIssueRepository();
  final _mapController = MapController();
  final _ideaController = TextEditingController();

  late final GetValidatedIssuesUseCase _getValidatedIssues =
      GetValidatedIssuesUseCase(_issueRepository);

  List<Issue> _issues = [];
  Position? _userPosition;

  bool _loading = true;
  bool _sidebarOpen = false;
  bool _matchingIdea = false;
  bool _resolvingLocation = false;

  String? _errorMessage;
  double _zoom = _defaultZoom;

  String get _effectiveUserId {
    final studentId = widget.studentId?.trim();
    if (studentId == null || studentId.isEmpty) {
      return 'anon';
    }
    return studentId;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialIdeaText != null) {
      _ideaController.text = widget.initialIdeaText!;
    }

    _loadIssues();
    _resolveCurrentLocation();

    if (widget.autoRun && (widget.initialIdeaText?.length ?? 0) >= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitIdea());
    }
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _getValidatedIssues();
      if (!mounted) return;
      setState(() {
        _issues = issues;
        _errorMessage = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _resolveCurrentLocation() async {
    if (_resolvingLocation) return;

    setState(() => _resolvingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() => _userPosition = position);
      _focusUserLocation();
    } catch (_) {
      // Intentionally silent for now to match existing UX behavior.
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  void _focusUserLocation() {
    final position = _userPosition;
    if (position == null) return;

    final zoomToUse = _zoom.isFinite ? (_zoom < _focusZoom ? _focusZoom : _zoom) : _focusZoom;
    if (position.latitude.isFinite && position.longitude.isFinite) {
      _mapController.move(
        latlng.LatLng(position.latitude, position.longitude),
        zoomToUse,
      );
    }
  }

  void _onMapTap(latlng.LatLng latLng) {
    for (final issue in _issues) {
      if ((issue.lat - latLng.latitude).abs() <= _tapThreshold &&
          (issue.lng - latLng.longitude).abs() <= _tapThreshold) {
        _openIssue(issue);
        return;
      }
    }
  }

  void _openIssue(Issue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueDetailPage(issueId: issue.issueId),
      ),
    );
  }

  Future<void> _submitIdea() async {
    final idea = _ideaController.text.trim();
    if (idea.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least 5 characters.')),
      );
      return;
    }

    setState(() => _matchingIdea = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IdeaMatchPage(
          studentId: _effectiveUserId,
          initialIdeaText: idea,
          autoRun: true,
        ),
      ),
    );
    if (mounted) setState(() => _matchingIdea = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = AppTheme.of(context).themeMode;
    final isDark = currentTheme == ThemeMode.dark;

    return Scaffold(
      backgroundColor: _leafletBg,
      body: Stack(
        children: [
          SizedBox.expand(
            child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const latlng.LatLng(-85.0, -180.0),
                  const latlng.LatLng(85.0, 180.0),
                ),
              ),
              onTap: (_, point) => _onMapTap(point),
              onPositionChanged: (position, _) {
                if (position.zoom.isFinite) {
                  _zoom = position.zoom;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.alitaptap.mobile',
                maxNativeZoom: 19,
                tileDisplay: const TileDisplay.fadeIn(),
                keepBuffer: 1,
                panBuffer: 1,
              ),
              MarkerLayer(markers: _buildIssueMarkers()),
              if (_userPosition != null && _userPosition!.latitude.isFinite && _userPosition!.longitude.isFinite)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latlng.LatLng(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      ),
                      width: 140,
                      height: 80,
                      child: const _UserLocationMarker(),
                    ),
                  ],
                ),
            ],
          ),
        ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _leafletBg.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _LeafletTopBar(
                  issueCount: _issues.length,
                  isDark: isDark,
                  sidebarOpen: _sidebarOpen,
                  onToggleSidebar: () {
                    setState(() => _sidebarOpen = !_sidebarOpen);
                  },
                  onLocate: _resolvingLocation ? null : _resolveCurrentLocation,
                  onRefresh: () {
                    setState(() {
                      _loading = true;
                      _errorMessage = null;
                    });
                    _loadIssues();
                  },
                  onAddPin: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            IssueSubmitPage(reporterId: _effectiveUserId),
                      ),
                    );
                  },
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).pop()
                      : null,
                ),
              ),
            ),
          ),
          if (_sidebarOpen)
            Positioned(
              top: 74,
              left: 12,
              bottom: widget.showIdeaDock ? 144 : 16,
              child: _LeafletIssueSidebar(
                issues: _issues,
                onTapIssue: _openIssue,
              ),
            ),
          if (!_loading)
            Positioned(
              left: 16,
              bottom: widget.showIdeaDock ? 134 : 24,
              child: _LeafletFabCluster(
                onReport: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          IssueSubmitPage(reporterId: _effectiveUserId),
                    ),
                  );
                },
                onResearch: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IdeaMatchPage(
                        studentId: _effectiveUserId,
                        initialIdeaText: '',
                        autoRun: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.showIdeaDock)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _LeafletIdeaDock(
                controller: _ideaController,
                matching: _matchingIdea,
                onSubmit: _submitIdea,
              ),
            ),
          if (_loading)
            Container(
              color: _leafletBg.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        color: _leafletYellow,
                        strokeWidth: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'LOADING CIVIC INTELLIGENCE...',
                      style: GoogleFonts.robotoMono(
                        color: _leafletYellow,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null && !_loading)
            Positioned(
              left: 16,
              right: 16,
              top: 94,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _leafletPanel.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _leafletRed.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.robotoMono(
                      color: _leafletText,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildIssueMarkers() {
    return _issues
        .where((issue) => issue.lat.isFinite && issue.lng.isFinite)
        .map(
          (issue) => Marker(
            point: latlng.LatLng(issue.lat, issue.lng),
            width: 120, // Wider for the bubble
            height: 60, // Taller for the bubble
            child: GestureDetector(
              onTap: () => _openIssue(issue),
              child: _IssuePinMarker(issue: issue),
            ),
          ),
        )
        .toList(growable: false);
  }
}

class _LeafletTopBar extends StatelessWidget {
  const _LeafletTopBar({
    required this.issueCount,
    required this.isDark,
    required this.sidebarOpen,
    required this.onToggleSidebar,
    required this.onLocate,
    required this.onRefresh,
    required this.onAddPin,
    required this.onBack,
  });

  final int issueCount;
  final bool isDark;
  final bool sidebarOpen;
  final VoidCallback onToggleSidebar;
  final VoidCallback? onLocate;
  final VoidCallback onRefresh;
  final VoidCallback onAddPin;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _leafletPanel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _leafletYellow.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: onBack == null ? _leafletMuted : _leafletYellow,
            ),
          ),
          IconButton(
            onPressed: onToggleSidebar,
            icon: Icon(
              sidebarOpen ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: _leafletYellow,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CIVIC MAP',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: _leafletYellow,
                  ),
                ),
                Text(
                  '$issueCount issues indexed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark
                        ? _leafletText.withValues(alpha: 0.84)
                        : _leafletMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onLocate,
            icon: Icon(
              Icons.my_location_rounded,
              color: onLocate == null ? _leafletMuted : _leafletYellow,
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: _leafletYellow),
          ),
          IconButton(
            onPressed: onAddPin,
            icon: const Icon(Icons.add_location_alt_rounded,
                color: _leafletYellow),
          ),
        ],
      ),
    );
  }
}

class _LeafletIssueSidebar extends StatelessWidget {
  const _LeafletIssueSidebar({
    required this.issues,
    required this.onTapIssue,
  });

  final List<Issue> issues;
  final ValueChanged<Issue> onTapIssue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      decoration: BoxDecoration(
        color: _leafletPanel.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _leafletYellow.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, color: _leafletYellow, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Issue Feed',
                  style: GoogleFonts.robotoMono(
                    color: _leafletYellow,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x33FFD60A)),
          Expanded(
            child: issues.isEmpty
                ? Center(
                    child: Text(
                      'No validated issues yet.',
                      style: GoogleFonts.poppins(
                        color: _leafletText.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (_, index) {
                      final issue = issues[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onTapIssue(issue),
                        child: Ink(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _leafletYellow.withValues(alpha: 0.15),
                            ),
                            color: const Color(0xFF111C30),
                          ),
                          child: Row(
                            children: [
                              if (issue.imageUrl != null && issue.imageUrl!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      issue.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48, height: 48, color: const Color(0xFF2C2C2E),
                                        child: const Icon(Icons.broken_image_rounded, size: 16, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      issue.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: _leafletText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      issue.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: _leafletText.withValues(alpha: 0.75),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: issues.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeafletFabCluster extends StatelessWidget {
  const _LeafletFabCluster({
    required this.onReport,
    required this.onResearch,
  });

  final VoidCallback onReport;
  final VoidCallback onResearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LeafletFabWithTooltip(
          heroTag: 'leaflet-report',
          icon: Icons.add_location_alt_rounded,
          tooltip: 'Report a local problem',
          isFilled: true,
          onPressed: onReport,
          delay: const Duration(milliseconds: 800),
        ),
        const SizedBox(height: 10),
        _LeafletFabWithTooltip(
          heroTag: 'leaflet-research',
          icon: Icons.psychology_alt_rounded,
          tooltip: 'Match idea to problems',
          isFilled: false,
          onPressed: onResearch,
          delay: const Duration(milliseconds: 1400),
        ),
      ],
    );
  }
}

class _LeafletFabWithTooltip extends StatefulWidget {
  const _LeafletFabWithTooltip({
    required this.heroTag,
    required this.icon,
    required this.tooltip,
    required this.isFilled,
    required this.onPressed,
    this.delay = Duration.zero,
  });

  final String heroTag;
  final IconData icon;
  final String tooltip;
  final bool isFilled;
  final VoidCallback onPressed;
  final Duration delay;

  @override
  State<_LeafletFabWithTooltip> createState() => _LeafletFabWithTooltipState();
}

class _LeafletFabWithTooltipState extends State<_LeafletFabWithTooltip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    Future.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
      _ctrl.forward();
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted) return;
        _ctrl.reverse().then((_) {
          if (mounted) setState(() => _visible = false);
        });
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FloatingActionButton.small(
          heroTag: widget.heroTag,
          backgroundColor:
              widget.isFilled ? _leafletYellow : _leafletPanel,
          foregroundColor:
              widget.isFilled ? const Color(0xFF171100) : _leafletYellow,
          onPressed: widget.onPressed,
          child: Icon(widget.icon),
        ),
        if (_visible)
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              return Opacity(
                opacity: _anim.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(6 * (1 - _anim.value), 0),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _leafletPanel.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _leafletYellow.withValues(alpha: 0.30),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _leafletYellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.tooltip,
                    style: GoogleFonts.robotoMono(
                      color: _leafletYellow.withValues(alpha: 0.9),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LeafletIdeaDock extends StatelessWidget {
  const _LeafletIdeaDock({
    required this.controller,
    required this.matching,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool matching;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _leafletPanel.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _leafletYellow.withValues(alpha: 0.34)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.robotoMono(
                color: _leafletText,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Type idea, then match with mapped problems...',
                hintStyle: GoogleFonts.robotoMono(
                  color: _leafletText.withValues(alpha: 0.44),
                  fontSize: 11,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: matching ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _leafletYellow,
              foregroundColor: const Color(0xFF120E00),
            ),
            icon: matching
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8),
                  )
                : const Icon(Icons.search_rounded, size: 16),
            label: Text(
              matching ? 'Matching' : 'Match',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuePinMarker extends StatelessWidget {
  const _IssuePinMarker({required this.issue});
  final Issue issue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _leafletBg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _leafletYellow.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            issue.aiSdgTag ?? issue.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoMono(
              color: _leafletYellow,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // The Pin
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _leafletYellow.withValues(alpha: 0.93),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _leafletYellow.withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.priority_high_rounded,
              color: Color(0xFF171100),
              size: 18,
              weight: 800,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _bubbleCtrl;
  late final Animation<double> _bubbleAnim;
  bool _showBubble = false;

  @override
  void initState() {
    super.initState();

    // Continuous pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeOut,
    );

    // "You're here" bubble
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bubbleAnim = CurvedAnimation(
      parent: _bubbleCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _showBubble = true);
      _bubbleCtrl.forward();
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        _bubbleCtrl.reverse().then((_) {
          if (mounted) setState(() => _showBubble = false);
        });
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "You're here" bubble
        if (_showBubble)
          AnimatedBuilder(
            animation: _bubbleAnim,
            builder: (context, child) {
              return Opacity(
                opacity: _bubbleAnim.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 4 * (1 - _bubbleAnim.value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _leafletPanel.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _leafletYellow.withValues(alpha: 0.45),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _leafletYellow.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.near_me_rounded,
                    color: _leafletYellow,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "You're here",
                    style: GoogleFonts.robotoMono(
                      color: _leafletYellow,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 26),

        // Animated pin
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            final t = _pulseAnim.value;
            return SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Container(
                    width: 22 + (30 * t),
                    height: 22 + (30 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _leafletYellow
                            .withValues(alpha: 0.45 * (1 - t)),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Glow halo
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _leafletYellow.withValues(alpha: 0.12),
                    ),
                  ),
                  // Core dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _leafletYellow,
                      border:
                          Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _leafletYellow
                              .withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
