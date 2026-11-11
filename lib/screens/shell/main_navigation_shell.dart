import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../dashboard/nurse_dashboard_screen.dart';
import '../patients/my_patients_screen.dart';
import '../profile/nurse_profile_screen.dart';
import '../tasks/nursing_tasks_screen.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});

  static const List<Widget> _tabs = [
    NurseDashboardScreen(),
    MyPatientsScreen(isEmbeddedInTab: true),
    NursingTasksScreen(isEmbeddedInTab: true),
    NurseProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final selectedIndex = controller.selectedNavIndex;
    final bannerEvent = controller.latestBannerEvent;
    final pendingTasksLen = controller.pendingNursingTasks.length;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: _tabs,
          ),
          if (bannerEvent != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Material(
                  elevation: 8,
                  shadowColor: AppColors.cardShadow,
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primaryDark,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bannerEvent.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                bannerEvent.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD6E6FA),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: controller.dismissLatestBanner,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: selectedIndex == 0,
                  onTap: () => controller.setSelectedNavIndex(0),
                ),
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_alt_rounded,
                  label: 'Patients',
                  selected: selectedIndex == 1,
                  onTap: () => controller.setSelectedNavIndex(1),
                ),
                _NavItem(
                  icon: Icons.assignment_turned_in_outlined,
                  activeIcon: Icons.assignment_turned_in_rounded,
                  label: 'Tasks',
                  badgeCount: pendingTasksLen,
                  selected: selectedIndex == 2,
                  onTap: () => controller.setSelectedNavIndex(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  selected: selectedIndex == 3,
                  onTap: () => controller.setSelectedNavIndex(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, color: color, size: 25),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
