import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/models/app_role.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/home/presentation/admin_home_page.dart';
import '../features/home/presentation/community_home_page.dart';
import '../features/home/presentation/student_home_page.dart';

/// Root application widget.
///
/// ## Theme
/// - Uses Poppins font globally via [GoogleFonts].
/// - Primary accent: #FFD60A (yellow). Supports light and dark mode toggle.
/// - Dark: deep charcoal surfaces. Light: clean white surfaces.
///
/// ## Role Routing (BYPASSED — see note below)
/// Originally, this widget bootstrapped Firebase Auth anonymously, then read
/// the user's role from Firestore (`users/{uid}.role`) to decide which home
/// screen to show. That flow was removed because:
///
///   1. Firestore security rules were not yet configured, causing
///      "permission-denied" errors on every launch.
///   2. The `_bootstrapRole` method and `FirebaseAuthException` handling
///      were deleted to unblock development.
///
/// CURRENT BEHAVIOUR: [SignInPage] collects the role from the user directly
/// and calls [_onRoleSelected], which pushes the correct home page onto the
/// navigator stack. The role is NOT persisted — every app launch shows the
/// sign-in screen again.
///
/// TO RESTORE PERSISTENCE:
///   1. Set Firestore rules to allow authenticated users to read/write their
///      own `users/{uid}` document (see docs/00-governance/firebase-setup.md).
///   2. Re-enable `AuthService.setRole()` call in [SignInPage._proceed].
///   3. Re-add `_bootstrapRole()` here to read the role on launch and skip
///      the sign-in screen for returning users.
class AlitaptapApp extends StatefulWidget {
  const AlitaptapApp({super.key});

  @override
  State<AlitaptapApp> createState() => _AlitaptapAppState();
}

class _AlitaptapAppState extends State<AlitaptapApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  final _navigatorKey = GlobalKey<NavigatorState>();

  void toggleTheme() =>
      setState(() => _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  // TODO: remove once Firestore rules are configured and role is persisted.
  // Role is passed directly from SignInPage to bypass Firestore permission.
  void _onRoleSelected(String role) {
    final page = switch (AppRoleX.fromString(role)) {
      AppRole.community => const CommunityHomePage(),
      AppRole.student => const StudentHomePage(),
      AppRole.admin => const AdminHomePage(),
    };
    Navigator.of(
      _navigatorKey.currentContext!,
    ).push(MaterialPageRoute(builder: (_) => page));
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
        // Light: clean white surface with dark text for strong contrast.
        // Dark: deep charcoal surface with light text.
        surface: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        onSurface: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
        surfaceContainerHighest:
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
      ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF141414) : const Color(0xFFF0F0F0),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        // Light mode: dark text on light bg for readability.
        foregroundColor:
            isDark ? const Color(0xFFFFD60A) : const Color(0xFF1A1A1A),
        titleTextStyle: GoogleFonts.poppins(
          color: isDark ? const Color(0xFFFFD60A) : const Color(0xFF1A1A1A),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF242424) : const Color(0xFF1A1A1A),
        contentTextStyle: GoogleFonts.poppins(
          color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFFFFFFFF),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ALITAPTAP',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: SignInPage(onRoleSelected: _onRoleSelected),
    );
  }
}
