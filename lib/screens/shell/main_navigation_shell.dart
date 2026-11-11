import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/global_search_sheet.dart';
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

/// Main Nurse Portal App Shell:
/// - On Dashboard (`Home`), `appBar` is completely hidden so NOTHING appears above
///   the `Good Afternoon, Sunita` hero banner!
/// - On inner website modules (`Patient`, `OPD`, `IPD`, `Blood Bank`, `Duty Roster`, `Annual Calendar`),
///   shows a clean compact hospital header with Global Search & Profile access.
/// - Clean `image-16.png` style Bottom Bar (`Home`, `Patients`, Center Navy `IPD` button, `OPD`, `More •••`).
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
          'Your active ward session will be disconnected safely.',
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

  void _showMoreModulesSheet(BuildContext context) {
    final controller = NursePortalScope.read(context);
    final user = controller.currentUser;
    final themePreset = controller.personalTheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Widget tile({
          required IconData icon,
          required Color bg,
          required Color fg,
          required String title,
          required String subtitle,
          required VoidCallback onTap,
        }) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fg, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F2544),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
            onTap: onTap,
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE7F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Nurse Profile Card (`My Profile` — Edit, Password, Professional Info, My Theme)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openProfileTab(context, 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE7F5)),
                    ),
                    child: Row(
                      children: [
                        PatientAvatar(
                          name: user?.fullName ?? 'Nurse',
                          imagePath: user?.image,
                          baseUrl: controller.baseUrl,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Duty Nurse',
                                style: const TextStyle(
                                  color: Color(0xFF0F2544),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${user?.roleName ?? "Nurse"}${user != null && user.staffCode.isNotEmpty ? " • ID: ${user.staffCode}" : ""} • My Profile & Theme',
                                style: TextStyle(
                                  color: themePreset.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 4),
                  child: Text(
                    'HOSPITAL NURSE MODULES',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                tile(
                  icon: Icons.water_drop_rounded,
                  bg: const Color(0xFFFFE4E6),
                  fg: const Color(0xFFE11D48),
                  title: 'Blood Bank Status',
                  subtitle: 'Available blood bags & donor details',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.setSelectedNavIndex(NurseNavIndex.bloodBank);
                  },
                ),
                tile(
                  icon: Icons.schedule_rounded,
                  bg: const Color(0xFFFEF3C7),
                  fg: const Color(0xFFD97706),
                  title: 'Duty Roster',
                  subtitle: 'Staff duty shifts & department schedule',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.setSelectedNavIndex(NurseNavIndex.dutyRoster);
                  },
                ),
                tile(
                  icon: Icons.calendar_month_rounded,
                  bg: const Color(0xFFE0F2FE),
                  fg: const Color(0xFF0284C7),
                  title: 'Annual Calendar',
                  subtitle: 'Hospital holidays & important dates',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller
                        .setSelectedNavIndex(NurseNavIndex.annualCalendar);
                  },
                ),
                tile(
                  icon: Icons.bed_rounded,
                  bg: const Color(0xFFE6F7EF),
                  fg: const Color(0xFF129A56),
                  title: 'Bed Status',
                  subtitle: 'Live ward bed occupancy & allocation',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BedStatusScreen(),
                      ),
                    );
                  },
                ),
                tile(
                  icon: Icons.notifications_active_outlined,
                  bg: const Color(0xFFF3E8FF),
                  fg: const Color(0xFF7C3AED),
                  title: 'Live Clinical Alerts',
                  subtitle: 'Ward notifications & real-time updates',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                tile(
                  icon: Icons.brush_rounded,
                  bg: const Color(0xFFEBF3FF),
                  fg: const Color(0xFF155EEF),
                  title: 'My Theme',
                  subtitle: 'Switch personal hospital portal theme',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openProfileTab(context, 3);
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
    final user = controller.currentUser;
    final themePreset = controller.personalTheme;
    final appBarFg = themePreset.appBarForeground;
    final isDashboard = currentIndex == NurseNavIndex.dashboard;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: themePreset.scaffoldColor,
      drawer: _NurseWebsiteSidebarDrawer(
        currentIndex: currentIndex,
        onSelectIndex: (idx) {
          Navigator.of(context).pop();
          controller.setSelectedNavIndex(idx);
        },
      ),
      // NO AppBar on Dashboard so nothing sits above `Good Afternoon, Sunita`!
      appBar: isDashboard
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                decoration: BoxDecoration(
                  color: themePreset.appBarColor,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Nurse Menu',
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          icon: Icon(Icons.menu_rounded, color: appBarFg),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showGlobalHospitalSearchSheet(context),
                            child: Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 11),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: themePreset.id == 'glacier_blue'
                                    ? Border.all(color: AppColors.border)
                                    : null,
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 17,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Search Name / Mobile / UHID...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _openProfileTab(context, 0),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8, left: 4),
                            child: PatientAvatar(
                              name: user?.fullName ?? 'Nurse',
                              imagePath: user?.image,
                              baseUrl: controller.baseUrl,
                              radius: 15,
                              backgroundColor: Colors.white,
                              textColor: themePreset.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _pages,
          ),

          if (banner != null)
            Positioned(
              top: isDashboard ? 42 : 10,
              left: 14,
              right: 14,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                color: themePreset.primaryColor,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
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
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
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
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                banner.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
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
      bottomNavigationBar: _ModernNurseBottomBar(
        currentIndex: currentIndex,
        unreadAlerts: controller.unreadAlertsCount,
        primaryColor: themePreset.primaryColor,
        onSelectIndex: controller.setSelectedNavIndex,
        onTapMore: () => _showMoreModulesSheet(context),
      ),
    );
  }
}

/// Clean `image-16.png` Bottom Navigation Bar with elevated center IPD Ward button
class _ModernNurseBottomBar extends StatelessWidget {
  final int currentIndex;
  final int unreadAlerts;
  final Color primaryColor;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onTapMore;

  const _ModernNurseBottomBar({
    required this.currentIndex,
    required this.unreadAlerts,
    required this.primaryColor,
    required this.onSelectIndex,
    required this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    final isMoreSelected = currentIndex >= NurseNavIndex.bloodBank;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140A3977),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              Expanded(
                child: _BottomNavSlot(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == NurseNavIndex.dashboard,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.dashboard),
                ),
              ),
              Expanded(
                child: _BottomNavSlot(
                  icon: Icons.groups_rounded,
                  label: 'Patients',
                  selected: currentIndex == NurseNavIndex.patients,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.patients),
                ),
              ),
              // Prominent Center Navy Circle Button (IPD In-Patient Ward)
              SizedBox(
                width: 68,
                child: Center(
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onSelectIndex(NurseNavIndex.ipd),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentIndex == NurseNavIndex.ipd
                              ? [primaryColor, primaryColor]
                              : const [Color(0xFF0A3977), Color(0xFF155EEF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x330A3977),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.hotel_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BottomNavSlot(
                  icon: Icons.medical_services_rounded,
                  label: 'OPD',
                  selected: currentIndex == NurseNavIndex.opd,
                  activeColor: primaryColor,
                  onTap: () => onSelectIndex(NurseNavIndex.opd),
                ),
              ),
              Expanded(
                child: _BottomNavSlot(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  selected: isMoreSelected,
                  badgeCount: unreadAlerts,
                  activeColor: primaryColor,
                  onTap: onTapMore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final Color activeColor;
  final VoidCallback onTap;

  const _BottomNavSlot({
    required this.icon,
    required this.label,
    required this.selected,
    this.badgeCount = 0,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : const Color(0xFF7B8CA6);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 23),
              if (badgeCount > 0)
                Positioned(
                  right: -7,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
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
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 22 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Exact 7-Item Nurse Sidebar from `https://hospital.hrpocket.in` (image-5)
class _NurseWebsiteSidebarDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectIndex;

  const _NurseWebsiteSidebarDrawer({
    required this.currentIndex,
    required this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final user = controller.currentUser;
    final hospital = controller.hospitalInfo;
    final themePreset = controller.personalTheme;

    const items = <(int, IconData, String)>[
      (NurseNavIndex.dashboard, Icons.desktop_windows_rounded, 'Dashboard'),
      (NurseNavIndex.patients, Icons.person_rounded, 'Patient'),
      (
        NurseNavIndex.opd,
        Icons.medical_information_rounded,
        'OPD - Out Patient',
      ),
      (NurseNavIndex.ipd, Icons.hotel_rounded, 'IPD - In Patient'),
      (NurseNavIndex.bloodBank, Icons.water_drop_rounded, 'Blood Bank'),
      (NurseNavIndex.dutyRoster, Icons.schedule_rounded, 'Duty Roster'),
      (
        NurseNavIndex.annualCalendar,
        Icons.calendar_month_rounded,
        'Annual Calendar',
      ),
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: themePreset.appBarColor,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: themePreset.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: themePreset.appBarForeground,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nurse Clinical Portal',
                          style: TextStyle(
                            color: themePreset.id == 'glacier_blue'
                                ? const Color(0xFF475569)
                                : const Color(0xFFCCE4F7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: currentIndex == item.$1
                            ? themePreset.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(
                            item.$2,
                            size: 20,
                            color: currentIndex == item.$1
                                ? Colors.white
                                : themePreset.primaryColor,
                          ),
                          title: Text(
                            item.$3,
                            style: TextStyle(
                              color: currentIndex == item.$1
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => onSelectIndex(item.$1),
                        ),
                      ),
                    ),
                  const Divider(height: 24),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      Icons.bed_rounded,
                      size: 20,
                      color: themePreset.primaryColor,
                    ),
                    title: const Text(
                      'Bed Status',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BedStatusScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NurseProfileScreen(),
                  ),
                );
              },
              leading: PatientAvatar(
                name: user?.fullName ?? 'Nurse',
                imagePath: user?.image,
                baseUrl: controller.baseUrl,
                radius: 19,
              ),
              title: Text(
                user?.fullName ?? 'Nurse',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                'My Profile • ${user?.roleName ?? "Nurse"}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
