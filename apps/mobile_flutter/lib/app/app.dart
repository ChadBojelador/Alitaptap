import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/presentation/sign_in_page.dart';
import '../features/home/presentation/onboarding_carousel_page.dart';
import '../features/home/presentation/welcome_page.dart';
import '../services/session_service.dart';
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
  static const _themeModePrefKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_themeModePrefKey);
    final mode = storedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  void toggleTheme() {
    final nextMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = nextMode);
    _persistThemeMode(nextMode);
  }

  Future<void> _persistThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModePrefKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  // Brand colors matching the clean travel-app UI reference
  static const _amber = Color(0xFFFFC700); // logo yellow — primary accent
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

/// Routes first-time users through welcome + onboarding before entering the app.
class _RootRouter extends StatefulWidget {
  const _RootRouter({required this.toggleTheme});
  final VoidCallback toggleTheme;

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _sessionLoaded = false;
  bool _isLoggedIn = false;
  String _role = 'student';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    await SessionService.load();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = SessionService.isLoggedIn;
      _role = SessionService.role.isNotEmpty ? SessionService.role : 'student';
      _sessionLoaded = true;
    });
  }

  void _onRoleSelected(String role) {
    setState(() {
      _isLoggedIn = true;
      _role = role;
    });
  }

  void _onSignOut() {
    setState(() {
      _isLoggedIn = false;
      _role = 'student';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionLoaded) {
      return const Scaffold(backgroundColor: Color(0xFF141414));
    }

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(backgroundColor: Color(0xFF141414));
        }
        final prefs = snap.data!;
        final seenWelcome = prefs.getBool('seen_welcome') ?? false;
        final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

        if (!seenWelcome) {
          return WelcomePage(onToggleTheme: widget.toggleTheme);
        }
        if (!seenOnboarding) {
          return OnboardingCarouselPage(onToggleTheme: widget.toggleTheme);
        }

        if (!_isLoggedIn) {
          return SignInPage(onRoleSelected: _onRoleSelected);
        }

        return MainShell(
          role: _role,
          onToggleTheme: widget.toggleTheme,
          onSignOut: _onSignOut,
        );
      },
    );
  }
}
