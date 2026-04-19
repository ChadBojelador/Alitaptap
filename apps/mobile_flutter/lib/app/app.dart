import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/app_role.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/civic_intelligence/presentation/issue_map_page.dart';
import '../features/home/presentation/admin_home_page.dart';
import '../features/home/presentation/community_home_page.dart';
import '../services/auth_service.dart';

/// Root application widget.
/// Bootstraps Firebase Auth, resolves the user role, and routes to the
/// appropriate home screen (community / student / admin).
class AlitaptapApp extends StatefulWidget {
  const AlitaptapApp({super.key});

  @override
  State<AlitaptapApp> createState() => _AlitaptapAppState();
}

class _AlitaptapAppState extends State<AlitaptapApp> {
  final _authService = AuthService();
  AppRole? _role;

  Future<void> _bootstrapRole() async {
    try {
      await _authService.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final hint = switch (e.code) {
        'operation-not-allowed' =>
          'Enable Anonymous sign-in in Firebase Authentication.',
        'api-key-not-valid' =>
          'Check Firebase web API key and app configuration.',
        'app-not-authorized' =>
          'Add localhost/127.0.0.1 to Firebase Auth authorized domains.',
        _ => 'Check Firebase Auth setup, API key restrictions, and network.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth setup issue: $hint')),
      );
    } catch (_) {
      // Continue with role lookup; unauthenticated lookup defaults to student.
    }

    final role = await _authService.getCurrentUserRole();
    if (!mounted) return;
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    // Poppins is applied globally via textTheme.
    // Primary accent: #FFD60A (yellow). Surface: dark charcoal.
    final poppins = GoogleFonts.poppinsTextTheme();
    final theme = ThemeData(
      useMaterial3: true,
      textTheme: poppins,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFD60A),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFFFD60A),
        onPrimary: const Color(0xFF1C1C1E),
        surface: const Color(0xFF1C1C1E),
        onSurface: const Color(0xFFF5F5F5),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      // AppBar is hidden on the map screen; kept transparent for other screens.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFFFD60A),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFFFFD60A),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF2C2C2E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C2C2E),
        contentTextStyle: GoogleFonts.poppins(color: const Color(0xFFF5F5F5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return MaterialApp(
      title: 'ALITAPTAP',
      theme: theme,
      home: _role == null
          ? SignInPage(onContinue: _bootstrapRole)
          : switch (_role!) {
              AppRole.community => const CommunityHomePage(),
              AppRole.student => IssueMapPage(
                  showIdeaDock: true,
                  studentId: FirebaseAuth.instance.currentUser?.uid ?? 'anon',
                ),
              AppRole.admin => const AdminHomePage(),
            },
    );
  }
}
