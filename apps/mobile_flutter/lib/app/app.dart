import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/presentation/welcome_page.dart';
import 'main_shell.dart';

/// Provides [themeMode] and [toggleTheme] to the entire widget tree so any
/// page can toggle the theme without prop drilling.
class AppTheme extends InheritedWidget {
  const AppTheme({
    super.key,
    required this.themeMode,
    required this.toggleTheme,
    required super.child,
  });

  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  static AppTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTheme>()!;

  @override
  bool updateShouldNotify(AppTheme old) => old.themeMode != themeMode;
}

/// Root application widget.
class AlitaptapApp extends StatefulWidget {
  const AlitaptapApp({super.key});

  @override
  State<AlitaptapApp> createState() => _AlitaptapAppState();
}

class _AlitaptapAppState extends State<AlitaptapApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final _navigatorKey = GlobalKey<NavigatorState>();

  void toggleTheme() => setState(() => _themeMode =
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  // Brand colors matching the clean travel-app UI reference
  static const _amber = Color(0xFFFFA726);   // warm amber — primary accent
  static const _dark = Color(0xFF1A1A1A);
  static const _white = Color(0xFFFFFFFF);
  static const _bgLight = Color(0xFFF7F8FA);
  static const _bgDark = Color(0xFF141414);
  static const _cardDark = Color(0xFF242424);
  static const _mutedLight = Color(0xFF757575);
  static const _mutedDark = Color(0xFF9E9E9E);

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
        seedColor: _amber,
        brightness: brightness,
      ).copyWith(
        primary: _amber,
        onPrimary: _dark,
        surface: isDark ? const Color(0xFF1E1E1E) : _white,
        onSurface: isDark ? const Color(0xFFF0F0F0) : _dark,
        surfaceContainerHighest:
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
      ),
      scaffoldBackgroundColor: isDark ? _bgDark : _bgLight,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? _white : _dark,
        titleTextStyle: GoogleFonts.poppins(
          color: isDark ? _white : _dark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _cardDark : _white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _cardDark : const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _amber, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? _cardDark : _dark,
        contentTextStyle: GoogleFonts.poppins(
          color: isDark ? const Color(0xFFF0F0F0) : _white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? _cardDark : _white,
        selectedItemColor: _amber,
        unselectedItemColor: isDark ? _mutedDark : _mutedLight,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      themeMode: _themeMode,
      toggleTheme: toggleTheme,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'ALITAPTAP',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: _RootRouter(toggleTheme: toggleTheme),
      ),
    );
  }
}

/// Checks if the user has seen the welcome screen and routes accordingly.
class _RootRouter extends StatefulWidget {
  const _RootRouter({required this.toggleTheme});
  final VoidCallback toggleTheme;

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          // Brief blank while prefs load
          return const Scaffold(
            backgroundColor: Color(0xFFF7F8FA),
          );
        }
        final seen = snap.data!.getBool('seen_welcome') ?? false;
        if (seen) {
          return MainShell(onToggleTheme: widget.toggleTheme);
        }
        return WelcomePage(onToggleTheme: widget.toggleTheme);
      },
    );
  }
}
