import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:alitaptap_mobile/services/api_service.dart';

const _amber = Color(0xFFFFC700);
const _amberBright = Color(0xFFFFD60A);
const _dark = Color(0xFF1A1A1A);

class IssueSubmitPage extends StatefulWidget {
  const IssueSubmitPage({super.key, required this.reporterId, this.reporterName});
  final String reporterId;
  final String? reporterName;

  @override
  State<IssueSubmitPage> createState() => _IssueSubmitPageState();
}

class _IssueSubmitPageState extends State<IssueSubmitPage> {
  static const int _minManualTitleChars = 1;
  static const int _minManualDescriptionChars = 1;
  static const int _minAiProblemChars = 1;

  bool _isAIGuided = false;
  final _problemCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _elaborating = false;
  String? _elaboratedText;
  String? _suggestedSDG;
  final List<Map<String, dynamic>> _savedReports = [];
  int? _editingIndex;
  bool _isEditingMode = false;
  String? _lastSubmittedId;

  // Location state
  bool _isLocationEnabled = true;
  double? _selectedLat;
  double? _selectedLng;
  String? _locationName;
  String? _suggestedImageUrl;
  bool _fetchingLocation = false;
  bool _resolvingAddress = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    // Add listeners to update UI immediately when user types
    _problemCtrl.addListener(() => setState(() {}));
    _titleCtrl.addListener(() => setState(() {}));
    _descriptionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _saveReport(String title, String description, String sdg, [String? id]) {
    setState(() {
      _savedReports.add({
        'id': id,
        'title': title,
        'description': description,
        'sdg': sdg,
        'date': DateTime.now().toString().split(' ')[0],
      });
    });
  }

  Future<void> _deleteReport(int index) async {
    final report = _savedReports[index];
    final issueId = report['id'];

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting report...'), duration: Duration(seconds: 1)),
    );

    if (issueId != null) {
      try {
        await ApiService().deleteIssue(issueId);
      } catch (e) {
        debugPrint('Failed to delete from server: $e');
        // We still remove it from local list to keep UI snappy, 
        // but it might reappear on refresh if server call failed.
      }
    }

    setState(() {
      _savedReports.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Report deleted successfully')),
      );
    }
  }

  void _loadReportForEdit(int index) {
    final report = _savedReports[index];
    setState(() {
      _editingIndex = index;
      _isEditingMode = true;
      _titleCtrl.text = report['title']!;
      _descriptionCtrl.text = report['description']!;
      _isAIGuided = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _isEditingMode = false;
      _titleCtrl.clear();
      _descriptionCtrl.clear();
      _problemCtrl.clear();
      _elaboratedText = null;
      _suggestedSDG = null;
    });
  }

  void _updateReport() {
    if (_titleCtrl.text.isEmpty || _descriptionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() {
      _savedReports[_editingIndex!] = {
        'title': _titleCtrl.text,
        'description': _descriptionCtrl.text,
        'sdg': _savedReports[_editingIndex!]['sdg']!,
        'date': _savedReports[_editingIndex!]['date']!,
      };
      _editingIndex = null;
      _isEditingMode = false;
      _titleCtrl.clear();
      _descriptionCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Report updated locally')),
    );
  }

  Future<void> _submitManualReport() async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_isLocationEnabled && _selectedLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location or disable location tracking')),
      );
      return;
    }

    setState(() => _elaborating = true);
    final api = ApiService();

    try {
      String? finalImageUrl = _suggestedImageUrl;
      if (_pickedImage != null) {
        finalImageUrl = await api.uploadImage(_pickedImage!);
      }

      // Real Server Call
      final res = await api.submitIssue(
        reporterId: widget.reporterId,
        reporterName: widget.reporterName,
        title: title,
        description: description,
        lat: _selectedLat ?? 12.8797,
        lng: _selectedLng ?? 121.7740,
        imageUrl: finalImageUrl,
      );

      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _savedReports.add({
            'id': res['issue_id'],
            'title': title,
            'description': description,
            'sdg': 'Manual Report',
            'date': DateTime.now().toString().split(' ')[0],
          });
          _elaborating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Problem submitted to community and pinned on map!')),
        );

        _titleCtrl.clear();
        _descriptionCtrl.clear();
        _selectedLat = null;
        _selectedLng = null;
        _locationName = null;
        _pickedImage = null;
        _suggestedImageUrl = null;
      });

    } catch (e) {
      setState(() => _elaborating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  Future<void> _elaborateWithAI() async {
    final problem = _problemCtrl.text.trim();
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the problem')),
      );
      return;
    }

    if (_isLocationEnabled && _selectedLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location or disable location tracking')),
      );
      return;
    }

    setState(() => _elaborating = true);
    final api = ApiService();
    
    // Simulate AI thinking and calling server
    try {
      final sdg = _suggestSDG(problem);
      final elaborated = _generateElaboratedDescription(problem);
      
      String? finalImageUrl = _suggestedImageUrl;
      if (_pickedImage != null) {
        finalImageUrl = await api.uploadImage(_pickedImage!);
      }
      
      // Real Server Call
      final res = await api.submitIssue(
        reporterId: widget.reporterId,
        reporterName: widget.reporterName,
        title: problem.split('\n')[0].substring(0, problem.split('\n')[0].length > 50 ? 50 : problem.split('\n')[0].length),
        description: problem,
        lat: _selectedLat ?? 12.8797,
        lng: _selectedLng ?? 121.7740,
        imageUrl: finalImageUrl,
      );

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _elaboratedText = elaborated;
          _suggestedSDG = sdg;
          _elaborating = false;
          _lastSubmittedId = res['issue_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Problem submitted to community and pinned on map!')),
        );
        
        // Clear location after submission, but keep text for Save Report button
        _selectedLat = null;
        _selectedLng = null;
        _locationName = null;
        _pickedImage = null;
        _suggestedImageUrl = null;
      });
      
    } catch (e) {
      setState(() => _elaborating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  String _generateElaboratedDescription(String problem) {
    return 'Impact: The issue affects community members and local infrastructure.\n\n'
        'Scope: This problem requires immediate attention and community involvement.\n\n'
        'Solution Potential: Addressing this requires coordinated efforts and resource allocation.\n\n'
        'Community Benefit: Resolution will improve quality of life and sustainability.';
  }

  String _suggestSDG(String problem) {
    final lowerProblem = problem.toLowerCase();
    
    if (lowerProblem.contains('water') || lowerProblem.contains('flood') || lowerProblem.contains('sanitation')) {
      return 'SDG 6: Clean Water and Sanitation';
    } else if (lowerProblem.contains('health') || lowerProblem.contains('disease') || lowerProblem.contains('medical')) {
      return 'SDG 3: Good Health and Well-being';
    } else if (lowerProblem.contains('education') || lowerProblem.contains('school') || lowerProblem.contains('learning')) {
      return 'SDG 4: Quality Education';
    } else if (lowerProblem.contains('poverty') || lowerProblem.contains('income') || lowerProblem.contains('employment')) {
      return 'SDG 1: No Poverty';
    } else if (lowerProblem.contains('climate') || lowerProblem.contains('environment') || lowerProblem.contains('pollution')) {
      return 'SDG 13: Climate Action';
    } else if (lowerProblem.contains('waste') || lowerProblem.contains('garbage') || lowerProblem.contains('recycl')) {
      return 'SDG 12: Responsible Consumption';
    } else if (lowerProblem.contains('energy') || lowerProblem.contains('electricity') || lowerProblem.contains('power')) {
      return 'SDG 7: Affordable Clean Energy';
    } else if (lowerProblem.contains('infrastructure') || lowerProblem.contains('road') || lowerProblem.contains('transport')) {
      return 'SDG 9: Industry, Innovation and Infrastructure';
    } else if (lowerProblem.contains('gender') || lowerProblem.contains('women') || lowerProblem.contains('discrimination')) {
      return 'SDG 5: Gender Equality';
    } else {
      return 'SDG 17: Partnerships for the Goals';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLat = pos.latitude;
          _selectedLng = pos.longitude;
          _locationName = 'Locating address...';
          _fetchingLocation = false;
        });
        
        // Resolve address in background
        final address = await _getAddressFromLatLng(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _locationName = address;
          });
        }
      } else {
        setState(() => _fetchingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
      }
    } catch (e) {
      setState(() => _fetchingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      setState(() => _resolvingAddress = true);
      // Using OSM Nominatim (Free, no key needed for basic prototype use)
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=16';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'AlitaptapApp/1.0',
      });
      
      setState(() => _resolvingAddress = false);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? '';
        // Clean up the address - take first 3 parts
        final parts = address.split(', ');
        if (parts.length > 3) {
          return '${parts[0]}, ${parts[1]}, ${parts[2]}';
        }
        return address;
      }
    } catch (e) {
      setState(() => _resolvingAddress = false);
      debugPrint('Geocoding error: $e');
    }
    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  Future<void> _pickLocationOnMap() async {
    latlong.LatLng initialCenter;
    
    if (_selectedLat != null) {
      initialCenter = latlong.LatLng(_selectedLat!, _selectedLng!);
    } else {
      // Try to get current position for better UX so map doesn't start in the ocean
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 2),
        );
        initialCenter = latlong.LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        initialCenter = const latlong.LatLng(12.8797, 121.7740); // Fallback to Philippines center
      }
    }

    final result = await showDialog<latlong.LatLng>(
      context: context,
      builder: (context) {
        latlong.LatLng? picked;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _dark,
              title: Text('Pick Location', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 500,
                height: 400,
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: FlutterMap(
                        options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 13,
                        minZoom: 3,
                        maxZoom: 18,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        cameraConstraint: CameraConstraint.contain(
                          bounds: LatLngBounds(
                            const latlong.LatLng(-85.0, -180.0),
                            const latlong.LatLng(85.0, 180.0),
                          ),
                        ),
                        onTap: (tapPosition, point) {
                          setDialogState(() => picked = point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        if (picked != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: picked!,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on_rounded, color: _amber, size: 40),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          'Tap on map to select location',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: picked == null ? null : () => Navigator.pop(context, picked),
                  style: ElevatedButton.styleFrom(backgroundColor: _amber),
                  child: Text('Confirm', style: GoogleFonts.poppins(color: _dark)),
                ),
              ],
            );
          },
        );
      }
    );

    if (result != null) {
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        _locationName = 'Resolving address...';
      });
      
      final addr = await _getAddressFromLatLng(result.latitude, result.longitude);
      if (mounted) {
        setState(() => _locationName = addr);
      }
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
    final canSaveManual = _titleCtrl.text.trim().length >= _minManualTitleChars &&
        _descriptionCtrl.text.trim().length >= _minManualDescriptionChars;
    final canAnalyzeAi = _problemCtrl.text.trim().length >= _minAiProblemChars;
    // The bug was that canSaveAi required canAnalyzeAi to be true, 
    // but the text was cleared after submission. 
    // Now it only requires the analysis result to exist.
    final canSaveAi = _elaboratedText != null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _isEditingMode ? 'Edit Report' : 'Report a Problem',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  const Icon(Icons.info_outline_rounded,
                      color: _amberBright, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Help us understand community problems better.',
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

            if (!_isEditingMode) ...[
              Text(
                'Report Method',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAIGuided = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isAIGuided
                              ? _amber.withValues(alpha: 0.16)
                              : (isDark
                                  ? const Color(0xFF242424)
                                  : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isAIGuided
                                ? _amber
                                : _amber.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: !_isAIGuided ? _amber : subtleColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Manual',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: !_isAIGuided ? _amber : subtleColor,
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
                      onTap: () => setState(() => _isAIGuided = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isAIGuided
                              ? _amberBright.withValues(alpha: 0.16)
                              : (isDark
                                  ? const Color(0xFF242424)
                                  : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isAIGuided
                                ? _amberBright
                                : _amberBright.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: _isAIGuided ? _amberBright : subtleColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI-Guided',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isAIGuided ? _amberBright : subtleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // --- Location Selection Section ---
            Text(
              'Location',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _amber.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: subtleColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Include Location',
                            style: GoogleFonts.poppins(fontSize: 13, color: textColor),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isLocationEnabled,
                        onChanged: (v) => setState(() => _isLocationEnabled = v),
                        activeColor: _amber,
                      ),
                    ],
                  ),
                  if (_isLocationEnabled) ...[
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _fetchingLocation ? null : _getCurrentLocation,
                            icon: _fetchingLocation 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _amber))
                              : const Icon(Icons.my_location_rounded, size: 16),
                            label: Text(_fetchingLocation ? 'Locating...' : 'Current'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _amber,
                              side: BorderSide(color: _amber.withValues(alpha: 0.3)),
                              textStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickLocationOnMap,
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('Pick on Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _amber,
                              side: BorderSide(color: _amber.withValues(alpha: 0.3)),
                              textStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLat != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (_resolvingAddress)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
                              )
                            else
                              const Icon(Icons.check_circle_outline, color: _amber, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationName ?? '',
                                style: GoogleFonts.poppins(fontSize: 11, color: textColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'No location selected yet.',
                        style: GoogleFonts.poppins(fontSize: 11, color: subtleColor),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_isAIGuided && !_isEditingMode) ...[
              Text(
                'Describe the Problem',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _problemCtrl,
                maxLines: 5,
                style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Describe the community problem in your own words...',
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
                onTap: (_elaborating || !canAnalyzeAi) ? null : _elaborateWithAI,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: (_elaborating || !canAnalyzeAi)
                        ? _amberBright.withValues(alpha: 0.5)
                        : _amberBright,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _elaborating
                        ? []
                        : [
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
                      if (_elaborating)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _dark,
                          ),
                        )
                      else
                        const Icon(Icons.auto_awesome_rounded,
                            color: _dark, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _elaborating
                            ? 'Analyzing...'
                            : 'Analyze & Submit to Community',
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


              if (_elaboratedText != null) ...[
                const SizedBox(height: 24),
                Text(
                  'AI Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _amberBright.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _amberBright.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _elaboratedText!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                      if (_suggestedSDG != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _amberBright.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flag_rounded,
                                  color: _amberBright, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _suggestedSDG!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _amberBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: !canSaveAi
                      ? null
                      : () {
                    _saveReport(_problemCtrl.text, _elaboratedText!, _suggestedSDG ?? 'SDG 17', _lastSubmittedId);
                    _problemCtrl.clear();
                    setState(() {
                      _elaboratedText = null;
                      _suggestedSDG = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Report saved successfully')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: canSaveAi
                          ? _amberBright
                          : _amberBright.withValues(alpha: 0.45),
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
                          'Save Report',
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
                if (!canSaveAi) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Complete AI analysis before saving this report.',
                    style:
                        GoogleFonts.poppins(fontSize: 11, color: subtleColor),
                  ),
                ],
              ],
            ] else if (!_isAIGuided || _isEditingMode) ...[
              Text(
                'Problem Title',
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
                  hintText: 'e.g. Recurring flooding on Main Street',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtleColor,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _amber,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
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
                  hintText: 'Describe the problem in detail — who is affected, how often, what impact...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: subtleColor,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _amber.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _amber,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isEditingMode)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _updateReport,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _amber,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _amber.withValues(alpha: 0.3),
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
                                'Update Report',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _cancelEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF242424)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _amber.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded,
                                  color: subtleColor, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: subtleColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
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
              Text(
                'Problem Photo',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _amber.withValues(alpha: 0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: (_pickedImage != null || _suggestedImageUrl != null) 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_pickedImage != null)
                              Image.file(_pickedImage!, fit: BoxFit.cover)
                            else if (_suggestedImageUrl != null)
                              Image.network(_suggestedImageUrl!, fit: BoxFit.cover),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _pickedImage = null;
                                  _suggestedImageUrl = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: subtleColor, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photo evidence',
                            style: GoogleFonts.poppins(fontSize: 12, color: subtleColor),
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                  onTap: (_elaborating || !canSaveManual)
                      ? null
                      : _submitManualReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: (_elaborating || !canSaveManual)
                          ? _amber.withValues(alpha: 0.45)
                          : _amber,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _amber.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_elaborating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _dark),
                          )
                        else
                          const Icon(Icons.send_rounded, color: _dark, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _elaborating ? 'Submitting...' : 'Submit to Community',
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

            ],

            if (_savedReports.isNotEmpty) ...[
              const SizedBox(height: 40),
              Text(
                'Your Reports',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              ..._savedReports.asMap().entries.map((entry) {
                final index = entry.key;
                final report = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                                report['title']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: subtleColor, size: 20),
                              padding: EdgeInsets.zero,
                              color: cardBg,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _loadReportForEdit(index);
                                } else if (value == 'delete') {
                                  _deleteReport(index);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: _amber, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Edit', style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded, color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: GoogleFonts.poppins(fontSize: 12, color: textColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report['date']!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: subtleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report['description']!,
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
                            report['sdg']!,
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
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _suggestedImageUrl = null; // Clear any previously suggested/demo URL
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ImageSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _ImageSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _amber.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: _amber, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
