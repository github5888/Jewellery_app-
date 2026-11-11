import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
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

/// Flagship Native Mobile Shell:
/// - Zero clunky web AppBars — every module renders a clean native SafeArea mobile layout.
/// - Tactile modern pill-indicator Bottom Dock (`Home`, `Patients`, `IPD`, `OPD`, `Menu`).
/// - Sleek Apple-style Bottom Sheet for `Blood Bank`, `Duty Roster`, `Annual Calendar`,
///   `Bed Status`, `My Profile & Theme`, `Notifications`, and `Logout`.
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
        title: const Text('Logout from Nurse Portal?'),
        content: const Text(
          'Your active ward session will be closed safely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 42),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.logout();
    }
  }

  void _showNurseMenuSheet(BuildContext context) {
    final controller = NursePortalScope.read(context);
    final user = controller.currentUser;
    final themePreset = controller.personalTheme;
    final currentIndex = controller.selectedNavIndex;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        Widget moduleTile({
          required IconData icon,
          required Color bg,
          required Color fg,
          required String title,
          required String subtitle,
          bool active = false,
          required VoidCallback onTap,
        }) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: active ? const Color(0xFFF1F5F9) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: fg, size: 20),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onTap: onTap,
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nurse Profile Card -> Opens My Profile
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openProfileTab(context, 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: themePreset.id == 'glacier_blue'
                            ? const [Color(0xFFF1F5F9), Color(0xFFE0F2FE)]
                            : themePreset.bannerGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        PatientAvatar(
                          name: user?.fullName ?? 'Nurse',
                          imagePath: user?.image,
                          baseUrl: controller.baseUrl,
                          radius: 22,
                          backgroundColor: Colors.white,
                          textColor: themePreset.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Duty Nurse',
                                style: TextStyle(
                                  color: themePreset.id == 'glacier_blue'
                                      ? AppColors.textPrimary
                                      : Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user?.roleName ?? "Nurse"}${user != null && user.staffCode.isNotEmpty ? " • ID: ${user.staffCode}" : ""} • My Profile',
                                style: TextStyle(
                                  color: themePreset.id == 'glacier_blue'
                                      ? AppColors.textSecondary
                                      : const Color(0xFFD6E6F7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: themePreset.id == 'glacier_blue'
                              ? AppColors.textSecondary
                              : Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 8),
                  child: Text(
                    'HOSPITAL MODULES',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                moduleTile(
                  icon: Icons.water_drop_rounded,
                  bg: const Color(0xFFFFF1F2),
                  fg: const Color(0xFFE11D48),
                  title: 'Blood Bank Status',
                  subtitle: 'Blood group bag stock & donor directory',
                  active: currentIndex == NurseNavIndex.bloodBank,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.setSelectedNavIndex(NurseNavIndex.bloodBank);
                  },
                ),
                moduleTile(
                  icon: Icons.schedule_rounded,
                  bg: const Color(0xFFFFFBEB),
                  fg: const Color(0xFFD97706),
                  title: 'Duty Roster',
                  subtitle: 'Shift allocation & department coverage',
                  active: currentIndex == NurseNavIndex.dutyRoster,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.setSelectedNavIndex(NurseNavIndex.dutyRoster);
                  },
                ),
                moduleTile(
                  icon: Icons.calendar_month_rounded,
                  bg: const Color(0xFFEFF6FF),
                  fg: const Color(0xFF2563EB),
                  title: 'Annual Calendar',
                  subtitle: 'Hospital holidays & important dates',
                  active: currentIndex == NurseNavIndex.annualCalendar,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller
                        .setSelectedNavIndex(NurseNavIndex.annualCalendar);
                  },
                ),
                moduleTile(
                  icon: Icons.bed_rounded,
                  bg: const Color(0xFFECFDF5),
                  fg: const Color(0xFF059669),
                  title: 'Ward Bed Status',
                  subtitle: 'Real-time bed occupancy & free beds',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BedStatusScreen(),
                      ),
                    );
                  },
                ),
                moduleTile(
                  icon: Icons.notifications_none_rounded,
                  bg: const Color(0xFFF5F3FF),
                  fg: const Color(0xFF7C3AED),
                  title: 'Clinical Notifications',
                  subtitle: 'Real-time ward & patient alerts',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                moduleTile(
                  icon: Icons.palette_outlined,
                  bg: const Color(0xFFF0FDFA),
                  fg: const Color(0xFF0D9488),
                  title: 'Personal Theme',
                  subtitle: 'Switch between 6 hospital portal themes',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openProfileTab(context, 3);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),

                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Close active nurse portal session',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmLogout(context, controller);
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
    final controller = NursePortalScope.of(context);
    final currentIndex =
        controller.selectedNavIndex.clamp(0, _pages.length - 1);
    final banner = controller.latestBannerEvent;
    final themePreset = controller.personalTheme;

    return Scaffold(
      backgroundColor: themePreset.scaffoldColor,
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _pages,
          ),

          if (banner != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                shadowColor: const Color(0x330F172A),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.textPrimary,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    controller.dismissLatestBanner();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: themePreset.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                banner.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: controller.dismissLatestBanner,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
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
      bottomNavigationBar: _SleekBottomDock(
        currentIndex: currentIndex,
        admittedCount: controller.activePatientsCount,
        unreadAlerts: controller.unreadAlertsCount,
        primaryColor: themePreset.primaryColor,
        onSelectIndex: controller.setSelectedNavIndex,
        onTapMenu: () => _showNurseMenuSheet(context),
      ),
    );
  }
}

class _SleekBottomDock extends StatelessWidget {
  final int currentIndex;
  final int admittedCount;
  final int unreadAlerts;
  final Color primaryColor;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onTapMenu;

  const _SleekBottomDock({
    required this.currentIndex,
    required this.admittedCount,
    required this.unreadAlerts,
    required this.primaryColor,
    required this.onSelectIndex,
    required this.onTapMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isMenuSelected = currentIndex >= NurseNavIndex.bloodBank;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _DockTabItem(
                  icon: Icons.grid_view_rounded,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Home',
                  selected: currentIndex == NurseNavIndex.dashboard,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.dashboard),
                ),
              ),
              Expanded(
                child: _DockTabItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Patients',
                  selected: currentIndex == NurseNavIndex.patients,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.patients),
                ),
              ),
              Expanded(
                child: _DockTabItem(
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
                child: _DockTabItem(
                  icon: Icons.medical_services_outlined,
                  activeIcon: Icons.medical_services_rounded,
                  label: 'OPD',
                  selected: currentIndex == NurseNavIndex.opd,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.opd),
                ),
              ),
              Expanded(
                child: _DockTabItem(
                  icon: Icons.widgets_outlined,
                  activeIcon: Icons.widgets_rounded,
                  label: 'Modules',
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

class _DockTabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final Color? badgeColor;
  final Color activeColor;
  final VoidCallback onTap;

  const _DockTabItem({
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
    final fg = selected ? activeColor : const Color(0xFF64748B);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withAlpha(24)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? activeIcon : icon,
                    color: fg,
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -9,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
