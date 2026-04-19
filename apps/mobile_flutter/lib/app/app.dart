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
/// Supports light and dark mode toggle, with Poppins as the global font
/// and #FFD60A yellow as the primary accent color.
class AlitaptapApp extends StatefulWidget {
  const AlitaptapApp({super.key});

  @override
  State<AlitaptapApp> createState() => _AlitaptapAppState();
}

class _AlitaptapAppState extends State<AlitaptapApp> {
  final _authService = AuthService();
  AppRole? _role;
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() =>
      setState(() => _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

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
    } catch (_) {}

    final role = await _authService.getCurrentUserRole();
    if (!mounted) return;
    setState(() => _role = role);
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final poppins = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: poppins,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFD60A),
        brightness: brightness,
      ).copyWith(
        primary: const Color(0xFFFFD60A),
        onPrimary: const Color(0xFF1C1C1E),
        surface: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F5E9),
        onSurface: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E),
      ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF141414) : const Color(0xFFF5F0E0),
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
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFDE7),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFDE7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFDE7),
        contentTextStyle: GoogleFonts.poppins(
          color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALITAPTAP',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: _role == null
          ? SignInPage(onContinue: _bootstrapRole)
          : switch (_role!) {
              AppRole.community => const CommunityHomePage(),
              AppRole.student => IssueMapPage(
                  showIdeaDock: true,
                  studentId:
                      FirebaseAuth.instance.currentUser?.uid ?? 'anon',
                  onToggleTheme: toggleTheme,
                  themeMode: _themeMode,
                ),
              AppRole.admin => const AdminHomePage(),
            },
    );
  }
}
