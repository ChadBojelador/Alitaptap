import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../application/usecases/submit_issue_use_case.dart';
import '../data/repositories/api_issue_repository.dart';

class IssueSubmitPage extends StatefulWidget {
  const IssueSubmitPage({super.key, required this.reporterId});
  final String reporterId;

  @override
  State<IssueSubmitPage> createState() => _IssueSubmitPageState();
}

class _IssueSubmitPageState extends State<IssueSubmitPage> {
  static const _mapStyle = 'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(12.8797, 121.7740);
  static const _defaultZoom = 12.0;
  static const _userZoom = 16.0;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _issueRepository = ApiIssueRepository();

  late final SubmitIssueUseCase _submitIssueUseCase =
      SubmitIssueUseCase(_issueRepository);

  MapLibreMapController? _mapController;
  Circle? _selectedCircle;
  bool _styleLoaded = false;
  bool _cameraMovedToUser = false;
  Position? _userPosition;

  double? _lat;
  double? _lng;
  bool _submitting = false;
  bool _useLocationInput = true; // true = region/city, false = current location/map

  @override
  void initState() {
    super.initState();
    _resolveCurrentLocation();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) =>
      _mapController = controller;

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _moveCameraToUserLocation();
    await _renderSelectedPin();
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
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
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
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        _userZoom,
      ),
    );
    _cameraMovedToUser = true;
  }

  Future<void> _onMapTap(Point<double> point, LatLng latLng) async {
    setState(() {
      _lat = latLng.latitude;
      _lng = latLng.longitude;
    });
    await _renderSelectedPin();
  }

  Future<void> _renderSelectedPin() async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null) return;
    if (_selectedCircle != null) {
      await controller.removeCircle(_selectedCircle!);
      _selectedCircle = null;
    }
    if (_lat == null || _lng == null) return;
    _selectedCircle = await controller.addCircle(
      CircleOptions(
        geometry: LatLng(_lat!, _lng!),
        circleRadius: 10,
        circleColor: '#FFD60A',
        circleStrokeColor: '#1A1A1A',
        circleStrokeWidth: 2,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // If using location-based, set coordinates
    if (!_useLocationInput) {
      if (_userPosition != null && _lat == null && _lng == null) {
        _lat = _userPosition!.latitude;
        _lng = _userPosition!.longitude;
      }
    }

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a location or enable GPS.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _submitIssueUseCase(
        SubmitIssueInput(
          reporterId: widget.reporterId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          lat: _lat!,
          lng: _lng!,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem reported! Awaiting validation.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report a Problem',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFFD60A), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your report will be reviewed and pinned on the community map for researchers to discover.',
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

              // Title field
              _fieldLabel('Problem Title', textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                decoration: _inputDecoration(
                  hint: 'e.g. Recurring flooding on Main Street',
                  icon: Icons.title_rounded,
                  isDark: isDark,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // Description field
              _fieldLabel('Description', textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                decoration: _inputDecoration(
                  hint:
                      'Describe the problem in detail — who is affected, how often, what impact...',
                  icon: Icons.description_rounded,
                  isDark: isDark,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 24),

              // Location method selector
              _fieldLabel('Location Method', textColor),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useLocationInput = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useLocationInput
                              ? const Color(0xFFFFD60A)
                              : (isDark
                                  ? const Color(0xFF242424)
                                  : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _useLocationInput
                                ? const Color(0xFFFFD60A)
                                : const Color(0xFFFFD60A).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: _useLocationInput ? textColor : subtleColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Region / City',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _useLocationInput ? textColor : subtleColor,
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
                      onTap: () => setState(() => _useLocationInput = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useLocationInput
                              ? const Color(0xFFFFD60A)
                              : (isDark
                                  ? const Color(0xFF242424)
                                  : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_useLocationInput
                                ? const Color(0xFFFFD60A)
                                : const Color(0xFFFFD60A).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              color: !_useLocationInput ? textColor : subtleColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Current Location',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: !_useLocationInput ? textColor : subtleColor,
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

              // Region and City input (only show if selected)
              if (_useLocationInput) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Region',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: subtleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            style: GoogleFonts.poppins(fontSize: 12, color: textColor),
                            decoration: _inputDecoration(
                              hint: 'e.g. Calabarzon',
                              icon: Icons.public_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City / Municipality',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: subtleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            style: GoogleFonts.poppins(fontSize: 12, color: textColor),
                            decoration: _inputDecoration(
                              hint: 'e.g. Cavite City',
                              icon: Icons.location_city_rounded,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Map section (only show if current location is selected)
                _fieldLabel('Pin the Location', textColor),
                const SizedBox(height: 4),
                Text(
                  'Tap the map to mark exactly where the problem is, or use the current location button.',
                  style: GoogleFonts.poppins(fontSize: 11, color: subtleColor),
                ),
                const SizedBox(height: 10),
                if (_lat != null && _lng != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Color(0xFFFFD60A), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              _lat = null;
                              _lng = null;
                            });
                            await _renderSelectedPin();
                          },
                          child: Icon(Icons.close_rounded,
                              size: 16, color: subtleColor),
                        ),
                      ],
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Stack(
                      children: [
                        MapLibreMap(
                          styleString: _mapStyle,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _lat ?? _defaultCenter.latitude,
                              _lng ?? _defaultCenter.longitude,
                            ),
                            zoom: _defaultZoom,
                          ),
                          onMapCreated: _onMapCreated,
                          onStyleLoadedCallback: _onStyleLoaded,
                          onMapClick: _onMapTap,
                          compassEnabled: false,
                          myLocationEnabled: false,
                          attributionButtonMargins: const Point(-100, -100),
                          logoViewMargins: const Point(-100, -100),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () async {
                              await _resolveCurrentLocation();
                              if (_userPosition != null) {
                                setState(() {
                                  _lat = _userPosition!.latitude;
                                  _lng = _userPosition!.longitude;
                                });
                                await _renderSelectedPin();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A)
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFFD60A)
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Icon(Icons.my_location_rounded,
                                  color: Color(0xFFFFD60A), size: 18),
                            ),
                          ),
                        ),
                        if (_lat == null)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A)
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFFD60A)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.touch_app_rounded,
                                      color: Color(0xFFFFD60A), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tap to pin location',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFF0F0F0),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_lat != null)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Location pinned!')),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD60A),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD60A)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF1A1A1A), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Location Confirmed',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF1A1A1A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Submit button
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _submitting
                        ? const Color(0xFFFFD60A).withValues(alpha: 0.5)
                        : const Color(0xFFFFD60A),
                    borderRadius: BorderRadius.circular(16),
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
                      if (_submitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        )
                      else
                        const Icon(Icons.send_rounded,
                            color: Color(0xFF1A1A1A), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _submitting ? 'Submitting...' : 'Submit Report',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1A1A1A),
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
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: isDark ? const Color(0xFF616161) : const Color(0xFF9E9E9E),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFFFFD60A), size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFFD60A), width: 1.5),
      ),
    );
  }
}

Widget _fieldLabel(String label, Color color) {
  return Text(
    label,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  );
}
