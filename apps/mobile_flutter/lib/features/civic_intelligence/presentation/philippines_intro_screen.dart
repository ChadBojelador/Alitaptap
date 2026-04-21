import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'issue_map_page.dart';

const _bg = Color(0xFF080C14);
const _green = Color(0xFFFFD60A);
const _yellow = Color(0xFFFFD60A);
const _muted = Color(0xFF6B7280);

class PhilippinesIntroScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const PhilippinesIntroScreen({super.key, this.onToggleTheme});

  @override
  State<PhilippinesIntroScreen> createState() => _PhilippinesIntroScreenState();
}

class _PhilippinesIntroScreenState extends State<PhilippinesIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _teleport = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool _teleporting = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), _doTeleport);
  }

  Future<void> _doTeleport() async {
    if (!mounted) return;
    setState(() => _teleporting = true);
    await _teleport.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            IssueMapPage(onToggleTheme: widget.onToggleTheme),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _pulse.dispose();
    _scan.dispose();
    _teleport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = Tween<double>(begin: 1.0, end: 4.0)
        .animate(CurvedAnimation(parent: _teleport, curve: Curves.easeIn));
    final fadeOut = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _teleport, curve: Curves.easeIn));

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeIn, _pulse, _scan, _teleport]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _fadeIn,
            child: Transform.scale(
              scale: _teleporting ? zoom.value : 1.0,
              child: Opacity(
                opacity: _teleporting ? fadeOut.value : 1.0,
                child: Stack(
                  children: [
                    // Scanline overlay
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _ScanPainter(_scan.value),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Philippines map
                          SizedBox(
                            width: 220,
                            height: 320,
                            child: CustomPaint(
                              painter: _PhilippinesPainter(
                                glowIntensity: _pulse.value,
                                scanProgress: _scan.value,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Label
                          Text(
                            'PHILIPPINES',
                            style: GoogleFonts.robotoMono(
                              color: _green,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'CIVIC INTELLIGENCE NETWORK',
                            style: GoogleFonts.robotoMono(
                              color: _muted,
                              fontSize: 9,
                              letterSpacing: 2.4,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Status
                          if (!_teleporting)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    color: _green,
                                    strokeWidth: 1.5,
                                    value: null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'INITIALIZING MAP...',
                                  style: GoogleFonts.robotoMono(
                                    color: _muted,
                                    fontSize: 9,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'TELEPORTING >>>',
                              style: GoogleFonts.robotoMono(
                                color: _yellow,
                                fontSize: 9,
                                letterSpacing: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Scanline painter ──────────────────────────────────────────────────────────

class _ScanPainter extends CustomPainter {
  final double progress;
  _ScanPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _green.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final sweepY = size.height * progress;
    canvas.drawLine(
      Offset(0, sweepY),
      Offset(size.width, sweepY),
      Paint()
        ..color = _green.withValues(alpha: 0.10)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.progress != progress;
}

// ── Philippines outline painter ───────────────────────────────────────────────
//
// Simplified polygon approximation of the Philippine archipelago's major
// islands (Luzon, Visayas, Mindanao) scaled to fit the canvas.

class _PhilippinesPainter extends CustomPainter {
  final double glowIntensity;
  final double scanProgress;

  _PhilippinesPainter({
    required this.glowIntensity,
    required this.scanProgress,
  });

  // Normalised (0–1) outline points for the major island groups.
  // x: 0=west, 1=east  |  y: 0=north, 1=south
  static const _luzon = [
    Offset(0.42, 0.00),
    Offset(0.55, 0.02),
    Offset(0.62, 0.06),
    Offset(0.68, 0.12),
    Offset(0.72, 0.18),
    Offset(0.70, 0.24),
    Offset(0.65, 0.28),
    Offset(0.72, 0.32),
    Offset(0.75, 0.38),
    Offset(0.70, 0.42),
    Offset(0.62, 0.44),
    Offset(0.55, 0.46),
    Offset(0.48, 0.48),
    Offset(0.40, 0.46),
    Offset(0.32, 0.42),
    Offset(0.28, 0.36),
    Offset(0.30, 0.28),
    Offset(0.35, 0.22),
    Offset(0.32, 0.14),
    Offset(0.36, 0.06),
  ];

  static const _visayas = [
    Offset(0.30, 0.52),
    Offset(0.40, 0.50),
    Offset(0.52, 0.52),
    Offset(0.60, 0.54),
    Offset(0.68, 0.56),
    Offset(0.72, 0.60),
    Offset(0.65, 0.64),
    Offset(0.55, 0.62),
    Offset(0.45, 0.64),
    Offset(0.35, 0.62),
    Offset(0.28, 0.58),
  ];

  static const _mindanao = [
    Offset(0.28, 0.68),
    Offset(0.38, 0.66),
    Offset(0.50, 0.66),
    Offset(0.62, 0.68),
    Offset(0.72, 0.72),
    Offset(0.76, 0.78),
    Offset(0.72, 0.86),
    Offset(0.62, 0.92),
    Offset(0.50, 0.96),
    Offset(0.38, 0.96),
    Offset(0.28, 0.90),
    Offset(0.22, 0.82),
    Offset(0.22, 0.74),
  ];

  Path _buildPath(List<Offset> pts, Size size) {
    final path = Path();
    path.moveTo(pts[0].dx * size.width, pts[0].dy * size.height);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final glow = 0.15 + 0.15 * glowIntensity;

    final fillPaint = Paint()
      ..color = _green.withValues(alpha: 0.08 + 0.06 * glowIntensity)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _green.withValues(alpha: 0.7 + 0.3 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 4 + 4 * glowIntensity);

    final dotPaint = Paint()
      ..color = _green.withValues(alpha: 0.5 + 0.5 * glowIntensity)
      ..style = PaintingStyle.fill;

    for (final pts in [_luzon, _visayas, _mindanao]) {
      final path = _buildPath(pts, size);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Scan sweep highlight
    final sweepY = size.height * scanProgress;
    final sweepPaint = Paint()
      ..color = _green.withValues(alpha: 0.18)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY), sweepPaint);

    // Dot markers on major cities
    final cities = [
      Offset(0.50 * size.width, 0.20 * size.height), // Manila
      Offset(0.55 * size.width, 0.55 * size.height), // Cebu
      Offset(0.48 * size.width, 0.80 * size.height), // Davao
    ];
    for (final city in cities) {
      canvas.drawCircle(city, 3.5, dotPaint);
      canvas.drawCircle(
        city,
        6 + 3 * glowIntensity,
        Paint()
          ..color = _green.withValues(alpha: glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = _green.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (var x = 0.0; x <= size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Corner brackets
    final bracketPaint = Paint()
      ..color = _yellow.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const bl = 14.0;
    for (final corner in [
      [Offset.zero, Offset(bl, 0), Offset(0, bl)],
      [
        Offset(size.width, 0),
        Offset(size.width - bl, 0),
        Offset(size.width, bl)
      ],
      [
        Offset(0, size.height),
        Offset(bl, size.height),
        Offset(0, size.height - bl)
      ],
      [
        Offset(size.width, size.height),
        Offset(size.width - bl, size.height),
        Offset(size.width, size.height - bl)
      ],
    ]) {
      final p = Path()
        ..moveTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(p, bracketPaint);
    }
  }

  @override
  bool shouldRepaint(_PhilippinesPainter old) =>
      old.glowIntensity != glowIntensity || old.scanProgress != scanProgress;
}
