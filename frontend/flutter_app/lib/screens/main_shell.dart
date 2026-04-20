import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import '../services/app_store.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'patients_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _idx = 0;

  static const _navItems = [
    (icon: Icons.dashboard_outlined,        activeIcon: Icons.dashboard_rounded,      label: 'Dashboard'),
    (icon: Icons.document_scanner_outlined, activeIcon: Icons.document_scanner,       label: 'Scan'),
    (icon: Icons.people_outline,            activeIcon: Icons.people_rounded,         label: 'Patients'),
    (icon: Icons.bar_chart_outlined,        activeIcon: Icons.bar_chart_rounded,      label: 'Reports'),
  ];

  final _screens = const [
    DashboardScreen(), ScanScreen(), PatientsScreen(), ReportsScreen(),
  ];

  void _switchTab(int i) {
    if (i == _idx) return;
    setState(() => _idx = i);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: C.err.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: C.err, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Sign Out', style: GoogleFonts.plusJakartaSans(
                color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Are you sure you want to sign out\nof NeuroScan AI?',
                style: GoogleFonts.plusJakartaSans(
                    color: C.t2, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: C.surface, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.divider)),
                  child: Center(child: Text('Cancel',
                      style: GoogleFonts.plusJakartaSans(
                          color: C.t2, fontSize: 14, fontWeight: FontWeight.w600))),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () async {
                  await AuthService().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: a, child: child),
                    ),
                    (_) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: C.err.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.err.withOpacity(0.3))),
                  child: Center(child: Text('Sign Out',
                      style: GoogleFonts.plusJakartaSans(
                          color: C.err, fontSize: 14, fontWeight: FontWeight.w700))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showProfile() {
    final user = AuthService().currentUser;
    final name = user?['name'] ?? 'User';
    final email = user?['email'] ?? '';
    final role = user?['role'] ?? '';
    final hospital = user?['hospital'] ?? '';
    final initials = name.split(' ').map((e) => e[0]).take(2).join();
    final store = AppStore();

    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 24, right: 24, top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: C.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(gradient: C.tealGrad, shape: BoxShape.circle),
            child: Center(child: Text(initials, style: GoogleFonts.plusJakartaSans(
                color: C.bg, fontSize: 26, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(height: 14),
          Text(name, style: GoogleFonts.plusJakartaSans(
              color: C.t1, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email, style: GoogleFonts.spaceMono(color: C.t3, fontSize: 11)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (role.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: C.tealGlow, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.tealBorder)),
              child: Text(role, style: GoogleFonts.plusJakartaSans(
                  color: C.teal, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            if (hospital.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(child: Text(hospital, style: GoogleFonts.plusJakartaSans(
                  color: C.t3, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ]),

          const SizedBox(height: 24),

          // Session stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.divider)),
            child: Row(children: [
              _statItem('Scans', '${store.totalScans}', C.teal),
              _divider(),
              _statItem('Positive', '${store.positiveScans}', C.err),
              _divider(),
              _statItem('Patients', '${store.patients.length}', C.ok),
            ]),
          ),

          const SizedBox(height: 20),

          // Menu items
          _profileMenuItem(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Profile editing coming soon'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          _profileMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.pop(context),
          ),
          _profileMenuItem(
            icon: Icons.security_outlined,
            label: 'Privacy & Security',
            onTap: () => Navigator.pop(context),
          ),
          _profileMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => Navigator.pop(context),
          ),

          const SizedBox(height: 8),

          // Logout button
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              _logout();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: C.err.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.err.withOpacity(0.25)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout_rounded, color: C.err, size: 18),
                const SizedBox(width: 10),
                Text('Sign Out', style: GoogleFonts.plusJakartaSans(
                    color: C.err, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) => Expanded(child: Column(children: [
    Text(value, style: GoogleFonts.plusJakartaSans(
        color: color, fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: GoogleFonts.plusJakartaSans(color: C.t3, fontSize: 11)),
  ]));

  Widget _divider() => Container(width: 1, height: 32, color: C.divider);

  Widget _profileMenuItem({required IconData icon, required String label, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.divider)),
        child: Row(children: [
          Icon(icon, color: C.teal, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.plusJakartaSans(
              color: C.t1, fontSize: 14, fontWeight: FontWeight.w500))),
          const Icon(Icons.arrow_forward_ios_rounded, color: C.t3, size: 14),
        ]),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final name = user?['name'] ?? 'User';
    final initials = name.split(' ').map((e) => e[0]).take(2).join();

    return Scaffold(
      backgroundColor: C.bg,
      // Profile button injected into each screen via a floating overlay
      body: Stack(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          child: KeyedSubtree(key: ValueKey(_idx), child: _screens[_idx]),
        ),

        // Profile avatar — top right, accessible from any screen
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: GestureDetector(
            onTap: _showProfile,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  gradient: C.tealGrad, borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(initials, style: GoogleFonts.plusJakartaSans(
                  color: C.bg, fontSize: 13, fontWeight: FontWeight.w700))),
            ),
          ),
        ),
      ]),

      bottomNavigationBar: _BottomNav(
        selected: _idx, onSelect: _switchTab, items: _navItems,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final List<({IconData icon, IconData activeIcon, String label})> items;
  const _BottomNav({required this.selected, required this.onSelect, required this.items});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom + 6,
      top: 10, left: 12, right: 12,
    ),
    decoration: BoxDecoration(
      color: C.surface,
      border: const Border(top: BorderSide(color: C.divider, width: .5)),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, -6))],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final active = selected == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active ? C.tealGlow : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(active ? item.activeIcon : item.icon,
                  color: active ? C.teal : C.t3, size: 22),
              const SizedBox(height: 3),
              Text(item.label, style: GoogleFonts.plusJakartaSans(
                  color: active ? C.teal : C.t3, fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            ]),
          ),
        );
      }),
    ),
  );
}
