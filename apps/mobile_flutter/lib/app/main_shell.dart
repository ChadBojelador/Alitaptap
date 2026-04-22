import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import '../features/expo/presentation/expo_feed_page.dart';
import '../features/home/presentation/analytics_page.dart';
import '../features/home/presentation/community_home_page.dart';
import '../features/home/presentation/admin_home_page.dart';
import '../features/home/presentation/dashboard_page.dart';
import '../features/home/presentation/create_page.dart';
import '../features/civic_intelligence/presentation/issue_submit_page.dart';
import '../core/models/app_role.dart';

const _amber = Color(0xFFFFC700);
const _dark = Color(0xFF1A1A1A);

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.role, this.onToggleTheme, this.onSignOut});
  final String role;
  final VoidCallback? onToggleTheme;
  // DEMO BYPASS: onSignOut resets role in _RootRouter so user can switch roles.
  final VoidCallback? onSignOut;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final pages = widget.role == 'community'
        ? [
            const ExpoFeedPage(),
            IssueSubmitPage(reporterId: uid),
            DashboardPage(role: AppRole.community),
            _ProfilePage(
                onToggleTheme: widget.onToggleTheme,
                onSignOut: widget.onSignOut,
                role: widget.role),
          ]
        : widget.role == 'student'
            ? [
                const ExpoFeedPage(),
                const CreatePage(),
                IssueSubmitPage(reporterId: uid),
                DashboardPage(role: AppRole.student),
                _ProfilePage(
                    onToggleTheme: widget.onToggleTheme,
                    onSignOut: widget.onSignOut,
                    role: widget.role),
              ]
            : [
                const ExpoFeedPage(),
                const CreatePage(),
                const AdminHomePage(),
                _ProfilePage(
                    onToggleTheme: widget.onToggleTheme,
                    onSignOut: widget.onSignOut,
                    role: widget.role),
              ];

    final safeIndex = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        index: safeIndex,
        isDark: isDark,
        onTap: (i) => setState(() => _index = i),
        role: widget.role,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.isDark,
    required this.onTap,
    required this.role,
  });

  final int index;
  final bool isDark;
  final ValueChanged<int> onTap;
  final String role;

  static const _adminItems = [
    (icon: Icons.lightbulb_rounded, label: 'Expo'),
    (icon: Icons.edit_note_rounded, label: 'Create'),
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  static const _studentItems = [
    (icon: Icons.lightbulb_rounded, label: 'Expo'),
    (icon: Icons.edit_note_rounded, label: 'Create'),
    (icon: Icons.add_location_alt_rounded, label: 'Report'),
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  static const _communityItems = [
    (icon: Icons.lightbulb_rounded, label: 'Expo'),
    (icon: Icons.add_location_alt_rounded, label: 'Report'),
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  List<({IconData icon, String label})> _getItems() {
    if (role == 'community') return _communityItems;
    if (role == 'student') return _studentItems;
    return _adminItems;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);

    return SizedBox(
      height: 72,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_getItems().length, (i) {
                final item = _getItems()[i];
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
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
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
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({this.onToggleTheme, this.onSignOut, required this.role});

  final VoidCallback? onToggleTheme;
  final VoidCallback? onSignOut;
  final String role;

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
                  child: ClipOval(
                    child: Image.asset(
                      'assets/branding/logo_source.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _roleDisplayName(role),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _dark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user?.email ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  onSignOut?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _roleDisplayName(String role) {
  switch (role) {
    case 'student': return 'Student / Researcher';
    case 'community': return 'Community Member';
    case 'admin': return 'Administrator';
    default: return role;
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
            activeThumbColor: _amber,
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
