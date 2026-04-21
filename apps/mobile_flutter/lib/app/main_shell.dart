import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import '../features/civic_intelligence/presentation/issue_map_page.dart';
import '../features/expo/presentation/expo_feed_page.dart';
import '../features/home/presentation/community_home_page.dart';

const _amber = Color(0xFFFFA726);
const _dark = Color(0xFF1A1A1A);

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onToggleTheme});
  final VoidCallback? onToggleTheme;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      const StudentHomePage(),
      IssueMapPage(onToggleTheme: widget.onToggleTheme),
      const ExpoFeedPage(),
      _ProfilePage(onToggleTheme: widget.onToggleTheme),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _BottomNav(
        index: _index,
        isDark: isDark,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final bool isDark;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.map_rounded, label: 'Map'),
    (icon: Icons.lightbulb_rounded, label: 'Expo'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? _amber.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: selected
                              ? _amber
                              : isDark
                                  ? const Color(0xFF616161)
                                  : const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? _amber
                              : isDark
                                  ? const Color(0xFF616161)
                                  : const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({this.onToggleTheme});

  final VoidCallback? onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = AppTheme.of(context).themeMode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF141414) : const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _dark,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _amber.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _dark, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.email ?? 'Guest',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF757575),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _DarkModeTile(
                isDarkMode: themeMode == ThemeMode.dark,
                isDark: isDark,
                onChanged: (_) => onToggleTheme?.call(),
              ),
              const SizedBox(height: 12),
              _ProfileTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isDark: isDark,
                onTap: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModeTile extends StatelessWidget {
  const _DarkModeTile({
    required this.isDarkMode,
    required this.isDark,
    required this.onChanged,
  });

  final bool isDarkMode;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.dark_mode_rounded, color: _amber, size: 20),
          const SizedBox(width: 14),
          Text(
            'Dark Mode',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : _dark,
            ),
          ),
          const Spacer(),
          Switch.adaptive(
            value: isDarkMode,
            activeColor: _amber,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _amber.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _amber, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _dark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark
                  ? const Color(0xFF616161)
                  : const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }
}
