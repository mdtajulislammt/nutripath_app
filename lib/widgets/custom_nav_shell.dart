import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/history/diet_history_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

class CustomNavShell extends StatefulWidget {
  const CustomNavShell({super.key});

  @override
  State<CustomNavShell> createState() => _CustomNavShellState();
}

class _CustomNavShellState extends State<CustomNavShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DietHistoryScreen(),
    AiChatScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enforceAccessGuard());
  }

  void _enforceAccessGuard() {
    if (!mounted) return;
    final state = context.read<AppStateProvider>();
    if (!state.isAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } else if (!state.isOnboarded) {
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    if (!state.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    if (!state.isOnboarded) {
      return const OnboardingScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.slate700 : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavBarItem(
                    icon: LucideIcons.layoutGrid,
                    label: 'Today',
                    isSelected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: LucideIcons.calendarDays,
                    label: 'History',
                    isSelected: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: LucideIcons.bot,
                    label: 'AI Chat',
                    isSelected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: LucideIcons.chartColumn,
                    label: 'Analytics',
                    isSelected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: LucideIcons.user,
                    label: 'Profile',
                    isSelected: _currentIndex == 4,
                    onTap: () => setState(() => _currentIndex = 4),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFE7F7F2);
    final activeColor = isDark ? AppColors.emeraldAccent : const Color(0xFF10B981);
    final inactiveColor = isDark ? AppColors.slate400 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: isSelected
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 2.5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
