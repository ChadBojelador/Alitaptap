import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/civic_intelligence/presentation/issue_map_page.dart';

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
  ThemeMode _themeMode = ThemeMode.dark;
  final _navigatorKey = GlobalKey<NavigatorState>();

  void toggleTheme() => setState(() => _themeMode =
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

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
        fillColor: isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        home: IssueMapPage(onToggleTheme: toggleTheme),
      ),
    );
  }
}
