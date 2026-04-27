import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import '../services/session_service.dart';
import '../features/civic_intelligence/presentation/civic_explore_dashboard.dart';
import '../features/expo/presentation/expo_feed_page.dart';
import '../features/home/presentation/create_page.dart';
import '../features/civic_intelligence/presentation/issue_submit_page.dart';
import '../features/expo/presentation/chat_inbox_page.dart';

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

  Future<void> _openActionSheet(String uid) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subtle =
        isDark ? const Color(0xFFBDBDBD) : const Color(0xFF666666);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final canCreate = widget.role != 'admin';
        final canReport = widget.role != 'admin';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to do?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _dark,
                  ),
                ),
                const SizedBox(height: 12),
                if (canReport)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_location_alt_rounded,
                        color: _amber),
                    title: Text('Report a Problem',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('Submit a local issue for validation',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: subtle)),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IssueSubmitPage(reporterId: uid),
                        ),
                      );
                    },
                  ),
                if (canCreate)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.edit_note_rounded, color: _amber),
                    title: Text('Create a Project',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text('Start a research project post',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: subtle)),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreatePage(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = SessionService.uid;

    final pages = [
      const ExpoFeedPage(),
      CivicExploreDashboard(uid: uid),
      ChatInboxPage(
        currentUid: uid,
      ),
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
        onActionTap: () => _openActionSheet(uid),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.isDark,
    required this.onTap,
    required this.onActionTap,
  });

  final int index;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onActionTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.explore_rounded, label: 'Explore'),
    (icon: Icons.notifications_rounded, label: 'Inbox'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE0E0E0);

    return SizedBox(
      height: 78,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: border, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        Expanded(child: _NavItem(item: _items[0], selected: index == 0, isDark: isDark, onTap: () => onTap(0))),
                        Expanded(child: _NavItem(item: _items[1], selected: index == 1, isDark: isDark, onTap: () => onTap(1))),
                        const SizedBox(width: 64),
                        Expanded(child: _NavItem(item: _items[2], selected: index == 2, isDark: isDark, onTap: () => onTap(2))),
                        Expanded(child: _NavItem(item: _items[3], selected: index == 3, isDark: isDark, onTap: () => onTap(3))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -24,
            child: GestureDetector(
              onTap: onActionTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _amber.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.add_rounded, color: _dark, size: 30),
              ),
            ),
          ),
        ],
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
    final user = SessionService.email;

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
                  user.isEmpty ? 'Anonymous' : user,
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
                  await SessionService.clear();
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final ({IconData icon, String label}) item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    selected ? _amber.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                size: 21,
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
  }
}

String _roleDisplayName(String role) {
  switch (role) {
    case 'student': return 'Student / Researcher';
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
