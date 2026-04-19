import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/models/app_role.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/civic_intelligence/presentation/issue_map_page.dart';
import '../features/home/presentation/admin_home_page.dart';
import '../features/home/presentation/community_home_page.dart';
import '../services/auth_service.dart';

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
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A84FF),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1C1E),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.78),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
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
