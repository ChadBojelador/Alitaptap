import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../../../services/api_service.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';
import '../../../app/app.dart' show AppTheme;
import 'issue_detail_page.dart';



/// Full-screen map page showing validated community issues as pins.
///
/// Always uses OpenFreeMap 'liberty' style so 3D buildings are visible in
/// both light and dark mode. In dark mode a semi-transparent dark tint is
/// layered over the map to reduce brightness without hiding buildings or labels.
///
/// UI overlays adapt to the current [ThemeMode] using [Theme.of(context)] so
/// colors stay harmonious across both modes.
class IssueMapPage extends StatefulWidget {
  const IssueMapPage({
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

  /// Pre-fill the idea dock and auto-run matching on open.
  final String? initialIdeaText;
  final bool autoRun;

  @override
  State<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends State<IssueMapPage> {
  // Liberty style base — fetched and patched at runtime with theme colors.
  static const _mapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(12.8797, 121.7740);
  static const _defaultZoom = 6.0;
  static const _userZoom = 16.5;
  static final _philippinesBounds = LatLngBounds(
    southwest: LatLng(4.5, 116.0),
    northeast: LatLng(21.5, 127.0),
  );

  final _api = ApiService();
  final _ideaController = TextEditingController();

  List<Issue> _issues = [];
  String? _errorMessage;
  Position? _userPosition;

  bool _loading = true;
  bool _styleLoaded = false;
  bool _cameraMovedToUser = false;
  bool _matchingIdea = false;
  MapLibreMapController? _mapController;
  Circle? _userLocationCircle;
  Offset? _userScreenPosition;
  double _bearing = 0.0;
  String? _patchedStyle;

  bool _isDarkMode = true; // default, updated in didChangeDependencies
  bool get _isDark => _isDarkMode;

  ThemeMode? _lastThemeMode;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdeaText != null) {
      _ideaController.text = widget.initialIdeaText!;
    }
    _resolveCurrentLocation();
    _loadIssues();
    if (widget.autoRun && (widget.initialIdeaText?.length ?? 0) >= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitIdea());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMode = AppTheme.of(context).themeMode;
    _isDarkMode = currentMode == ThemeMode.dark;
    if (_lastThemeMode != currentMode) {
      _styleLoaded = false;
      _patchedStyle = null;
      _loadPatchedStyle(dark: _isDarkMode);
      _lastThemeMode = currentMode;
    }
  }

  /// Fetches the liberty style JSON and patches layer colors.
  /// Dark mode: deep navy + yellow roads + electric blue water.
  /// Light mode: warm parchment + yellow roads + sky blue water.
  Future<void> _loadPatchedStyle({required bool dark}) async {
    try {
      final res = await http.get(Uri.parse(_mapStyleUrl));
      if (res.statusCode != 200) return;
      final style = jsonDecode(res.body) as Map<String, dynamic>;
      final layers = style['layers'] as List<dynamic>;

      final idPatches = dark
          ? <String, String>{
              // Dark: deep navy land
              'background':                     '#0D1B2A',
              'park':                           '#0F2A1E',
              'landuse_residential':            '#111D2E',
              'landcover_wood':                 '#0A2218',
              'landcover_grass':                '#0D2318',
              'landcover_wetland':              '#0A1F2A',
              'landcover_sand':                 '#1A2A1A',
              'landcover_ice':                  '#1A2A3A',
              'landuse_cemetery':               '#0F1F2F',
              'landuse_hospital':               '#0F1F2F',
              'landuse_school':                 '#0F1F2F',
              'landuse_pitch':                  '#0A2218',
              'landuse_track':                  '#0A2218',
              'aeroway_fill':                   '#0D1B2A',
              'water':                          '#1565C0',
              'waterway_river':                 '#1976D2',
              'waterway_other':                 '#1565C0',
              'waterway_tunnel':                '#0D47A1',
              'road_motorway':                  '#FFD60A',
              'road_motorway_casing':           '#B8960A',
              'road_motorway_link':             '#FFD60A',
              'road_motorway_link_casing':      '#B8960A',
              'road_trunk_primary':             '#F5C842',
              'road_trunk_primary_casing':      '#A88A20',
              'road_secondary_tertiary':        '#C8A020',
              'road_secondary_tertiary_casing': '#7A6010',
              'road_minor':                     '#1E3A5F',
              'road_minor_casing':              '#152A45',
              'road_link':                      '#C8A020',
              'road_link_casing':               '#7A6010',
              'road_service_track':             '#1A3050',
              'road_service_track_casing':      '#0F1F35',
              'road_path_pedestrian':           '#1A3050',
              'bridge_motorway':                '#FFD60A',
              'bridge_motorway_casing':         '#B8960A',
              'bridge_trunk_primary':           '#F5C842',
              'bridge_trunk_primary_casing':    '#A88A20',
              'bridge_secondary_tertiary':      '#C8A020',
              'bridge_street':                  '#1E3A5F',
              'bridge_motorway_link':           '#FFD60A',
              'bridge_link':                    '#C8A020',
              'bridge_service_track':           '#1A3050',
              'bridge_path_pedestrian':         '#1A3050',
              'tunnel_motorway':                '#B8960A',
              'tunnel_trunk_primary':           '#A88A20',
              'tunnel_secondary_tertiary':      '#7A6010',
              'tunnel_minor':                   '#152A45',
              'building':                       '#1A2E4A',
              'road_major_rail':                '#2A4A6A',
              'road_transit_rail':              '#2A4A6A',
              'bridge_major_rail':              '#2A4A6A',
              'bridge_transit_rail':            '#2A4A6A',
              'boundary_2':                     '#FFD60A',
              'boundary_3':                     '#C8A020',
            }
          : <String, String>{
              // Light: warm parchment land
              'background':                     '#F5EFD6',
              'park':                           '#C8DBA0',
              'landuse_residential':            '#EDE8D0',
              'landcover_wood':                 '#A8C878',
              'landcover_grass':                '#C8DBA0',
              'landcover_wetland':              '#B0D4C0',
              'landcover_sand':                 '#E8DFC0',
              'landcover_ice':                  '#E0EEF5',
              'landuse_cemetery':               '#D4CCA8',
              'landuse_hospital':               '#F0E8D0',
              'landuse_school':                 '#EAE0C0',
              'landuse_pitch':                  '#B8D898',
              'landuse_track':                  '#C8D8A0',
              'aeroway_fill':                   '#E8E0C8',
              'water':                          '#7AB8D4',
              'waterway_river':                 '#5AA8C8',
              'waterway_other':                 '#7AB8D4',
              'waterway_tunnel':                '#A8D0E8',
              'road_motorway':                  '#FFD60A',
              'road_motorway_casing':           '#C8A000',
              'road_motorway_link':             '#FFD60A',
              'road_motorway_link_casing':      '#C8A000',
              'road_trunk_primary':             '#F5C842',
              'road_trunk_primary_casing':      '#C8A020',
              'road_secondary_tertiary':        '#E8D080',
              'road_secondary_tertiary_casing': '#C0A840',
              'road_minor':                     '#E8E0C0',
              'road_minor_casing':              '#C8C0A0',
              'road_link':                      '#E8D080',
              'road_link_casing':               '#C0A840',
              'road_service_track':             '#EAE4CC',
              'road_service_track_casing':      '#C8C0A8',
              'road_path_pedestrian':           '#D4C890',
              'bridge_motorway':                '#FFD60A',
              'bridge_motorway_casing':         '#C8A000',
              'bridge_trunk_primary':           '#F5C842',
              'bridge_trunk_primary_casing':    '#C8A020',
              'bridge_secondary_tertiary':      '#E8D080',
              'bridge_street':                  '#E8E0C0',
              'bridge_motorway_link':           '#FFD60A',
              'bridge_link':                    '#E8D080',
              'bridge_service_track':           '#EAE4CC',
              'bridge_path_pedestrian':         '#D4C890',
              'tunnel_motorway':                '#E8C000',
              'tunnel_trunk_primary':           '#D8B030',
              'tunnel_secondary_tertiary':      '#C8A040',
              'tunnel_minor':                   '#D8D0B0',
              'building':                       '#D4C8A0',
              'road_major_rail':                '#B0A888',
              'road_transit_rail':              '#B0A888',
              'bridge_major_rail':              '#B0A888',
              'bridge_transit_rail':            '#B0A888',
              'boundary_2':                     '#C8A020',
              'boundary_3':                     '#D4B840',
            };

      for (final layer in layers) {
        final map = layer as Map<String, dynamic>;
        final id = map['id'] as String? ?? '';
        final type = map['type'] as String? ?? '';
        final paint = Map<String, dynamic>.from(
            map['paint'] as Map<String, dynamic>? ?? {});

        if (idPatches.containsKey(id)) {
          final color = idPatches[id]!;
          if (type == 'background') {
            paint['background-color'] = color;
          } else if (type == 'fill') {
            paint['fill-color'] = color;
            paint['fill-opacity'] = 1.0;
          } else if (type == 'line') {
            paint['line-color'] = color;
          }
          map['paint'] = paint;
        }
      }

      if (mounted) setState(() => _patchedStyle = jsonEncode(style));
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController?.removeListener(_onCameraMove);
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _api.getIssues(status: 'validated');
      if (mounted) {
        setState(() {
          _issues = issues;
          _errorMessage = null;
          _loading = false;
        });
        await _renderIssuePins();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.addListener(_onCameraMove);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    final controller = _mapController;
    if (controller != null) {
      // Exact layer IDs from the liberty style.
      // Keep: place names, road names, water labels.
      // Hide: all POI layers (gas stations, cafes, shops, etc).
      const keepLayers = {
        'label_other',
        'label_village',
        'label_town',
        'label_state',
        'label_city',
        'label_city_capital',
        'label_country_1',
        'label_country_2',
        'label_country_3',
        'highway-name-path',
        'highway-name-minor',
        'highway-name-major',
        'highway-shield-non-us',
        'highway-shield-us-interstate',
        'road_shield_us',
        'waterway_line_label',
        'water_name_point_label',
        'water_name_line_label',
        'road_one_way_arrow',
        'road_one_way_arrow_opposite',
      };

      // Keep default black colors for readability, just increase sizes
      // per hierarchy. Poppins only applies to Flutter UI, not map tiles.
      const labelSizes = {
        'label_country_1': 22.0,
        'label_country_2': 20.0,
        'label_country_3': 18.0,
        'label_state':     15.0,
        'label_city_capital': 14.0,
        'label_city':      13.0,
        'label_town':      12.0,
        'label_village':   11.0,
        'label_other':     10.0,
      };

      for (final entry in labelSizes.entries) {
        try {
          await controller.setLayerProperties(
            entry.key,
            SymbolLayerProperties(
              textColor: _isDark ? '#FFD60A' : '#1A1A1A',
              textSize: entry.value,
              textHaloColor: _isDark ? '#0D1B2A' : '#F5EFD6',
              textHaloWidth: 1.5,
              textHaloBlur: 0,
            ),
          );
        } catch (_) {}
      }

      // Hide all symbol layers not in the keep list.
      const hideLayers = [
        'poi_r20', 'poi_r7', 'poi_r1', 'poi_transit', 'airport',
      ];
      for (final layer in hideLayers) {
        try {
          await controller.setLayerVisibility(layer, false);
        } catch (_) {}
      }
    }
    await _moveCameraToUserLocation();
    await _renderIssuePins();
  }

  Future<void> _updateUserScreenPosition() async {
    final controller = _mapController;
    final pos = _userPosition;
    if (controller == null || pos == null) return;
    final point = await controller.toScreenLocation(
      LatLng(pos.latitude, pos.longitude),
    );
    if (mounted) {
      setState(() => _userScreenPosition =
          Offset(point.x.toDouble(), point.y.toDouble()));
    }
  }

  void _onCameraMove() {
    _updateUserScreenPosition();
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if (mounted) setState(() => _bearing = bearing);
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() => _userPosition = position);
      await _moveCameraToUserLocation(force: true);
    } catch (_) {}
  }

  Future<void> _moveCameraToUserLocation({bool force = false}) async {
    if (!force && _cameraMovedToUser) return;
    final controller = _mapController;
    final pos = _userPosition;
    if (!_styleLoaded || controller == null || pos == null) return;

    final userLatLng = LatLng(pos.latitude, pos.longitude);

    if (_userLocationCircle != null) {
      await controller.removeCircle(_userLocationCircle!);
      _userLocationCircle = null;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: _userZoom, tilt: 60),
      ),
    );

    await _updateUserScreenPosition();
    _cameraMovedToUser = true;
  }

  Future<void> _renderIssuePins() async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null) return;
    await controller.clearCircles();
    for (final issue in _issues) {
      await controller.addCircle(
        CircleOptions(
          geometry: LatLng(issue.lat, issue.lng),
          circleRadius: 7,
          circleColor: '#E53935',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
  }

  void _onMapTap(Point<double> point, LatLng latLng) {
    const threshold = 0.006;
    for (final candidate in _issues) {
      if ((candidate.lat - latLng.latitude).abs() <= threshold &&
          (candidate.lng - latLng.longitude).abs() <= threshold) {
        _onPinTapped(candidate);
        return;
      }
    }
  }

  void _onPinTapped(Issue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IssueDetailPage(issueId: issue.issueId)),
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
    final studentId = widget.studentId;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student session not found. Please sign in again.')),
      );
      return;
    }
    setState(() => _matchingIdea = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IdeaMatchPage(
          studentId: studentId,
          initialIdeaText: idea,
          autoRun: true,
        ),
      ),
    );
    if (mounted) setState(() => _matchingIdea = false);
  }

  // ---------------------------------------------------------------------------
  // Theme helpers — all overlay colors derived from these so they stay in sync.
  // ---------------------------------------------------------------------------

  /// Panel background: dark charcoal in dark mode, clean white in light mode.
  Color get _panelBg => _isDark
      ? const Color(0xFF1C1C1E).withValues(alpha: 0.78)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.88);

  /// Text color on panels.
  Color get _textColor =>
      _isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);

  /// Subtle text / hint color.
  Color get _subtleText =>
      _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);

  /// Card background inside the bottom sheet.
  Color get _cardBg => _isDark
      ? const Color(0xFF242424).withValues(alpha: 0.95)
      : const Color(0xFFF5F5F5).withValues(alpha: 0.95);

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: Stack(
        children: [
          // ── Map (liberty style — 3D buildings always on) ──────────────────
          MapLibreMap(
            styleString: _patchedStyle ?? _mapStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: _defaultZoom,
              tilt: 60,
            ),
            cameraTargetBounds: CameraTargetBounds(_philippinesBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(5.5, 20.0),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapTap,
            compassEnabled: false,
            myLocationEnabled: false,
            attributionButtonMargins: const Point(-100, -100),
            logoViewMargins: const Point(-100, -100),
          ),

          // ── Dark mode tint removed — map is already dark themed ─────────

          // ── You're Here marker ────────────────────────────────────────────
          if (_userScreenPosition != null)
            Positioned(
              left: _userScreenPosition!.dx - 40,
              top: _userScreenPosition!.dy - 72,
              child: const _YouAreHereMarker(),
            ),

          // ── Floating header ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _yellow.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (Navigator.of(context).canPop()) ...[
                            _HeaderBtn(
                              icon: Icons.arrow_back_ios_rounded,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 4),
                          ],
                          const Icon(Icons.map_rounded,
                              color: _yellow, size: 17),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Community Problems Map',
                              style: GoogleFonts.poppins(
                                color: _textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _HeaderBtn(
                            icon: Icons.my_location_rounded,
                            onPressed: () async {
                              await _resolveCurrentLocation();
                              await _moveCameraToUserLocation(force: true);
                            },
                          ),
                          const SizedBox(width: 8),
                          _HeaderBtn(
                            icon: _isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            onPressed: AppTheme.of(context).toggleTheme,
                          ),
                          const SizedBox(width: 8),
                          _HeaderBtn(
                            icon: Icons.refresh_rounded,
                            onPressed: () => setState(() {
                              _loading = true;
                              _errorMessage = null;
                              _loadIssues();
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_loading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: _yellow),
              ),
            ),

          // ── Issue count badge ─────────────────────────────────────────────
          if (!_loading)
            Positioned(
              bottom: 16,
              right: 16,
              child: _MapCompass(
                bearing: _bearing,
                onTap: () => _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _mapController?.cameraPosition?.target ??
                          _defaultCenter,
                      zoom: _mapController?.cameraPosition?.zoom ?? _defaultZoom,
                      tilt: _mapController?.cameraPosition?.tilt ?? 60,
                      bearing: 0,
                    ),
                  ),
                ),
              ),
            ),

          // ── Issue count badge ─────────────────────────────────────────────
          if (!_loading)
            Positioned(
              bottom: 16,
              left: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _panelBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _yellow.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin_drop,
                            size: 16, color: _yellow),
                        const SizedBox(width: 6),
                        Text(
                          '${_issues.length} validated issues',
                          style: GoogleFonts.poppins(
                            color: _textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Issue list sheet ──────────────────────────────────────────────
          if (!_loading && _issues.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _IssueListSheet(
                issues: _issues,
                onTap: _onPinTapped,
                panelBg: _panelBg,
                cardBg: _cardBg,
                textColor: _textColor,
                subtleText: _subtleText,
              ),
            ),

          // ── Idea dock ─────────────────────────────────────────────────────
          if (widget.showIdeaDock)
            Positioned(
              left: 16,
              right: 16,
              bottom: _issues.isNotEmpty ? 120 : 16,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _yellow.withValues(alpha: 0.4),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _yellow.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search, color: _yellow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ideaController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _submitIdea(),
                              style: GoogleFonts.poppins(
                                color: _textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Match your ideas',
                                hintStyle: GoogleFonts.poppins(
                                  color: _subtleText,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: _yellow,
                                foregroundColor: const Color(0xFF1C1C1E),
                              ),
                              onPressed: _matchingIdea ? null : _submitIdea,
                              icon: _matchingIdea
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1C1C1E),
                                      ),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded),
                              tooltip: 'Match idea',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small icon button used in the floating header.
class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, color: const Color(0xFFFFD60A), size: 18),
    );
  }
}

/// Glowing yellow "You're here" location pin overlay with pulse animation.
class _YouAreHereMarker extends StatefulWidget {
  const _YouAreHereMarker();

  @override
  State<_YouAreHereMarker> createState() => _YouAreHereMarkerState();
}

class _YouAreHereMarkerState extends State<_YouAreHereMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.65)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              "You're here",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFFD60A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36 * _pulse.value,
                  height: 36 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD60A)
                        .withValues(alpha: 0.22 * _pulse.value),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD60A),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.65),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on,
                      size: 12, color: Color(0xFF1C1C1E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small compass rose that rotates with the map bearing.
/// Tapping it snaps the map back to north.
class _MapCompass extends StatelessWidget {
  const _MapCompass({required this.bearing, required this.onTap});
  final double bearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1C1C1E),
          border: Border.all(
            color: const Color(0xFFFFD60A),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -bearing * (3.141592653589793 / 180),
          child: CustomPaint(painter: _CompassPainter()),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32;

    // North — bright yellow
    final northPaint = Paint()..color = const Color(0xFFFFD60A);
    final northPath = Path()
      ..moveTo(cx, cy - r * 1.5)
      ..lineTo(cx - r * 0.55, cy + r * 0.2)
      ..lineTo(cx + r * 0.55, cy + r * 0.2)
      ..close();
    canvas.drawPath(northPath, northPaint);

    // South — white
    final southPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final southPath = Path()
      ..moveTo(cx, cy + r * 1.5)
      ..lineTo(cx - r * 0.55, cy - r * 0.2)
      ..lineTo(cx + r * 0.55, cy - r * 0.2)
      ..close();
    canvas.drawPath(southPath, southPaint);

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.3,
      Paint()..color = Colors.white,
    );

    // N label
    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - r * 1.5 + 2),
    );
  }

  @override
  bool shouldRepaint(_CompassPainter old) => false;
}

/// Draggable bottom sheet listing issues for quick browsing.
/// Colors are passed in from [_IssueMapPageState] so they adapt to theme mode.
class _IssueListSheet extends StatelessWidget {
  const _IssueListSheet({
    required this.issues,
    required this.onTap,
    required this.panelBg,
    required this.cardBg,
    required this.textColor,
    required this.subtleText,
  });

  final List<Issue> issues;
  final ValueChanged<Issue> onTap;
  final Color panelBg;
  final Color cardBg;
  final Color textColor;
  final Color subtleText;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.08,
      maxChildSize: 0.55,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.25)),
              ),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: issues.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD60A)
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Reported Issues',
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }
                  final issue = issues[index - 1];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFD60A)
                              .withValues(alpha: 0.15)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFFFFD60A).withValues(alpha: 0.18),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFFFD60A)),
                      ),
                      title: Text(issue.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                      subtitle: Text(issue.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: subtleText, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFFFFD60A)),
                      onTap: () => onTap(issue),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
