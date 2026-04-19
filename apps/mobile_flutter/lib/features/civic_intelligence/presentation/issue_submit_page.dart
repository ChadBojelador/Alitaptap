import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../services/api_service.dart';

/// Full-screen form for community members to report a local problem.
class IssueSubmitPage extends StatefulWidget {
  const IssueSubmitPage({super.key, required this.reporterId});

  final String reporterId;

  @override
  State<IssueSubmitPage> createState() => _IssueSubmitPageState();
}

class _IssueSubmitPageState extends State<IssueSubmitPage> {
  static const _openFreeMapStyle = 'https://tiles.openfreemap.org/styles/liberty';

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _api = ApiService();

  MapLibreMapController? _mapController;
  Circle? _selectedCircle;
  bool _styleLoaded = false;

  double? _lat;
  double? _lng;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _renderSelectedPin();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _api.submitIssue(
        reporterId: widget.reporterId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        lat: _lat!,
        lng: _lng!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem reported! Awaiting admin validation.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        circleRadius: 7,
        circleColor: '#D32F2F',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Icon(Icons.report_problem_rounded,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                'What problem do you see in your community?',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // --- Title ---
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Problem Title',
                  hintText: 'e.g. Recurring flooding on Main Street',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the problem in detail...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // --- Location Picker ---
              Text('Location', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_lat != null && _lng != null)
                Chip(
                  avatar: const Icon(Icons.location_on, size: 18),
                  label: Text(
                    '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                  ),
                  onDeleted: () async {
                    setState(() {
                      _lat = null;
                      _lng = null;
                    });
                    await _renderSelectedPin();
                  },
                ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: MapLibreMap(
                  styleString: _openFreeMapStyle,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_lat ?? 14.6, _lng ?? 121.0),
                    zoom: 12,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  onMapClick: _onMapTap,
                  compassEnabled: true,
                  myLocationEnabled: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the map to select the problem location',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // --- Submit ---
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Submitting...' : 'Submit Report'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
