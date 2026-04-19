import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

/// Shows a branded splash while Firebase initializes, then hands off to [AlitaptapApp].
class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _SplashScreen(error: true);
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return const AlitaptapApp();
          }
          return const _SplashScreen();
        },
      ),
    );
  }
}

/// Branded splash screen with pulsing logo and loading indicator.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({this.error = false});
  final bool error;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Background glow top-left
          Positioned(
            top: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD60A)
                      .withValues(alpha: 0.06 * _pulse.value),
                ),
              ),
            ),
          ),

          // Background glow bottom-right
          Positioned(
            bottom: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD60A)
                      .withValues(alpha: 0.04 * _pulse.value),
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo icon with pulse
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: _pulse.value,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFFFFD60A)
                              .withValues(alpha: 0.5 * _pulse.value),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD60A)
                                .withValues(alpha: 0.2 * _pulse.value),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Color(0xFFFFD60A),
                        size: 44,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // App name
                AnimatedBuilder(
                  animation: _fade,
                  builder: (_, __) => Opacity(
                    opacity: _fade.value,
                    child: Text(
                      'ALITAPTAP',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFFFD60A),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Community · Research · Impact',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator or error
                if (!widget.error)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.7),
                    ),
                  )
                else
                  Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Color(0xFFFFD60A), size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to connect. Check your network.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9E9E9E),
                          fontSize: 12,
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
