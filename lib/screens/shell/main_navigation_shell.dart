import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../beds/bed_status_screen.dart';
import '../dashboard/nurse_dashboard_screen.dart';
import '../ipd/ipd_management_screen.dart';
import '../modules/annual_calendar_screen.dart';
import '../modules/blood_bank_screen.dart';
import '../modules/notifications_screen.dart';
import '../opd/opd_triage_screen.dart';
import '../patients/patient_directory_screen.dart';
import '../profile/nurse_profile_screen.dart';
import '../roster/duty_roster_screen.dart';

/// Executive Native Mobile Shell:
/// - Zero clunky web AppBars — every module renders inside a luminous studio-lit SafeArea layout.
/// - Floating Capsule Bottom Navigation Dock (`Home`, `Patients`, `IPD Ward`, `OPD`, `Hub`).
/// - Executive Hospital Hub Sheet with Nurse Identity Pass, 1-Tap Personal Theme Switcher,
///   2x2 Clinical Module Bento (`Blood Bank`, `Duty Roster`, `Annual Calendar`, `Bed Matrix`),
///   `Clinical Alerts`, and `Sign Out`.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  static const List<Widget> _pages = <Widget>[
    NurseDashboardScreen(),
    PatientDirectoryScreen(isEmbeddedInShell: true),
    OpdTriageScreen(isEmbeddedInShell: true),
    IpdManagementScreen(isEmbeddedInShell: true),
    BloodBankScreen(isEmbeddedInShell: true),
    DutyRosterScreen(isEmbeddedInShell: true),
    AnnualCalendarScreen(isEmbeddedInShell: true),
  ];

  void _openProfileTab(BuildContext context, int tabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NurseProfileScreen(initialTabIndex: tabIndex),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    NursePortalController controller,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Sign Out of Nurse Portal?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Your active clinical ward session will be closed safely.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(108, 42),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.logout();
    }
  }

  void _showNurseMenuSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final controller = NursePortalScope.of(ctx);
        final user = controller.currentUser;
        final themePreset = controller.personalTheme;
        final primary = themePreset.primaryColor;
        final currentIndex = controller.selectedNavIndex;
        final totalBloodBags = controller.bloodBankGroups.fold<int>(
          0,
          (sum, g) => sum + g.availableBags,
        );

        final heroColors = themePreset.id == 'glacier_blue'
            ? const [Color(0xFF0C4A6E), Color(0xFF0284C7)]
            : themePreset.bannerGradient;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Executive Nurse Identity Pass Card
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openProfileTab(context, 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: heroColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: heroColors.first.withAlpha(55),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(160),
                                width: 1.5,
                              ),
                            ),
                            child: PatientAvatar(
                              name: user?.fullName ?? 'Nurse',
                              imagePath: user?.image,
                              baseUrl: controller.baseUrl,
                              radius: 23,
                              backgroundColor: Colors.white,
                              textColor: primary,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Duty Nurse',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    user?.roleName ?? 'Nurse',
                                    if (user != null &&
                                        user.staffCode.isNotEmpty)
                                      'ID: ${user.staffCode}',
                                    if (user != null &&
                                        user.department.isNotEmpty)
                                      user.department,
                                  ].join('  •  '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFD6E8FA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Profile ›',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Instant Live Personal Theme Studio Strip
                  SoftSurfaceCard(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PERSONAL WORKSPACE THEME',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _openProfileTab(context, 3);
                              },
                              child: Text(
                                themePreset.name,
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: NursePersonalTheme.presets.map((preset) {
                            final selected = preset.id == themePreset.id;
                            final orbColor = preset.primaryColor;
                            return GestureDetector(
                              onTap: () => controller.setPersonalTheme(preset.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 38,
                                height: 38,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? orbColor
                                        : AppColors.border,
                                    width: selected ? 2.2 : 1,
                                  ),
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: orbColor,
                                  ),
                                  child: selected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'HOSPITAL MODULES',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // 3. 2x2 Sculpted Module Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _HubModuleTile(
                        icon: Icons.water_drop_rounded,
                        colors: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
                        title: 'Blood Bank',
                        subtitle: '$totalBloodBags Bags in Stock',
                        selected: currentIndex == NurseNavIndex.bloodBank,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          controller.setSelectedNavIndex(
                            NurseNavIndex.bloodBank,
                          );
                        },
                      ),
                      _HubModuleTile(
                        icon: Icons.badge_rounded,
                        colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                        title: 'Duty Roster',
                        subtitle:
                            '${controller.allRosterShifts.length} Staff Shifts',
                        selected: currentIndex == NurseNavIndex.dutyRoster,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          controller.setSelectedNavIndex(
                            NurseNavIndex.dutyRoster,
                          );
                        },
                      ),
                      _HubModuleTile(
                        icon: Icons.calendar_month_rounded,
                        colors: const [Color(0xFF10B981), Color(0xFF047857)],
                        title: 'Calendar',
                        subtitle: '${controller.holidays.length} Holidays',
                        selected: currentIndex == NurseNavIndex.annualCalendar,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          controller.setSelectedNavIndex(
                            NurseNavIndex.annualCalendar,
                          );
                        },
                      ),
                      _HubModuleTile(
                        icon: Icons.grid_view_rounded,
                        colors: [primary, primary.withAlpha(200)],
                        title: 'Bed Matrix',
                        subtitle:
                            '${controller.availableBedsCount} Beds Vacant',
                        selected: false,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BedStatusScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4. Alerts & Sign Out Row
                  Row(
                    children: [
                      Expanded(
                        child: SoftSurfaceCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 18,
                                color: primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  controller.unreadAlertsCount > 0
                                      ? 'Alerts (${controller.unreadAlertsCount})'
                                      : 'Clinical Alerts',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SoftSurfaceCard(
                          color: const Color(0xFFFFF1F2),
                          borderColor: const Color(0xFFFECDD3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _confirmLogout(context, controller);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final selectedIndex = controller.selectedNavIndex.clamp(
      0,
      _pages.length - 1,
    );
    final bannerEvent = controller.latestBannerEvent;
    final themePreset = controller.personalTheme;
    final primary = themePreset.primaryColor;

    final isSecondaryModuleActive = selectedIndex >= NurseNavIndex.bloodBank;

    return PopScope(
      canPop: selectedIndex == NurseNavIndex.dashboard,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selectedIndex != NurseNavIndex.dashboard) {
          controller.setSelectedNavIndex(NurseNavIndex.dashboard);
        }
      },
      child: Scaffold(
        backgroundColor: themePreset.scaffoldColor,
        extendBody: false,
        body: Column(
          children: [
            if (bannerEvent != null)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x220F172A),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(24),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFF34D399),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${bannerEvent.title}: ${bannerEvent.subtitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: controller.dismissLatestBanner,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: _pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _ExecutiveFloatingDock(
          currentIndex: selectedIndex,
          isMenuSelected: isSecondaryModuleActive,
          primaryColor: primary,
          admittedCount: controller.activePatientsCount,
          unreadAlerts: controller.unreadAlertsCount,
          onSelectIndex: (idx) => controller.setSelectedNavIndex(idx),
          onTapMenu: () => _showNurseMenuSheet(context),
        ),
      ),
    );
  }
}

class _HubModuleTile extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _HubModuleTile({
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(18),
      borderColor: selected ? colors.last : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GradientIconBadge(
                icon: icon,
                colors: colors,
                size: 34,
                iconSize: 17,
                radius: 11,
              ),
              const Icon(
                Icons.north_east_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutiveFloatingDock extends StatelessWidget {
  final int currentIndex;
  final bool isMenuSelected;
  final Color primaryColor;
  final int admittedCount;
  final int unreadAlerts;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onTapMenu;

  const _ExecutiveFloatingDock({
    required this.currentIndex,
    required this.isMenuSelected,
    required this.primaryColor,
    required this.admittedCount,
    required this.unreadAlerts,
    required this.onSelectIndex,
    required this.onTapMenu,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _DockCapsuleItem(
                  icon: Icons.space_dashboard_outlined,
                  activeIcon: Icons.space_dashboard_rounded,
                  label: 'Home',
                  selected: currentIndex == NurseNavIndex.dashboard,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.dashboard),
                ),
              ),
              Expanded(
                child: _DockCapsuleItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Patients',
                  selected: currentIndex == NurseNavIndex.patients,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.patients),
                ),
              ),
              Expanded(
                child: _DockCapsuleItem(
                  icon: Icons.hotel_outlined,
                  activeIcon: Icons.hotel_rounded,
                  label: 'IPD Ward',
                  badgeCount: admittedCount,
                  badgeColor: primaryColor,
                  selected: currentIndex == NurseNavIndex.ipd,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.ipd),
                ),
              ),
              Expanded(
                child: _DockCapsuleItem(
                  icon: Icons.medical_services_outlined,
                  activeIcon: Icons.medical_services_rounded,
                  label: 'OPD',
                  selected: currentIndex == NurseNavIndex.opd,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.opd),
                ),
              ),
              Expanded(
                child: _DockCapsuleItem(
                  icon: Icons.apps_rounded,
                  activeIcon: Icons.apps_rounded,
                  label: 'Hub',
                  badgeCount: unreadAlerts,
                  badgeColor: AppColors.danger,
                  selected: isMenuSelected,
                  activeColor: primaryColor,
                  onTap: onTapMenu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockCapsuleItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final Color? badgeColor;
  final Color activeColor;
  final VoidCallback onTap;

  const _DockCapsuleItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    this.badgeCount = 0,
    this.badgeColor,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : const Color(0xFF64748B);
    final labelFg = selected ? activeColor : const Color(0xFF64748B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [activeColor, activeColor.withAlpha(210)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: activeColor.withAlpha(65),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  color: fg,
                  size: 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF10B981)
                            : (badgeColor ?? AppColors.danger),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3.5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelFg,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
