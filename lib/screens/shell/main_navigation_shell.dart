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

/// Main Nurse Portal App Shell matching `https://hospital.hrpocket.in` (image-4 & image-5):
/// - Top Royal-Navy Hospital Header with Global Search (`Search Name / Mobile / UHID...`),
///   Bed Status shortcut, Live Alerts, and Nurse Profile
/// - Exact 7-Item Nurse Sidebar Drawer (`Dashboard`, `Patient`, `OPD - Out Patient`,
///   `IPD - In Patient`, `Blood Bank`, `Duty Roster`, `Annual Calendar`)
/// - Fast Mobile Bottom Navigation Bar
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

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final currentIndex = controller.selectedNavIndex.clamp(0, _pages.length - 1);
    final banner = controller.latestBannerEvent;
    final user = controller.currentUser;

    // Map 7 sidebar pages onto 5 bottom bar items (0..3 direct, 4..6 -> More menu index 4)
    final bottomIndex = currentIndex <= 3 ? currentIndex : 4;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldBg,
      drawer: _NurseWebsiteSidebarDrawer(
        currentIndex: currentIndex,
        onSelectIndex: (idx) {
          Navigator.of(context).pop();
          controller.setSelectedNavIndex(idx);
        },
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A4D78),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Nurse Menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  ),
                  // Tap-to-Search Global Search Pill (matching image-4 top bar)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showGlobalHospitalSearchSheet(context),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
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
                                  fontSize: 12.5,
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
                  IconButton(
                    tooltip: 'Bed Status',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BedStatusScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.bed_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Live Alerts',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      if (controller.unreadAlertsCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${controller.unreadAlertsCount > 9 ? "9+" : controller.unreadAlertsCount}',
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
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NurseProfileScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PatientAvatar(
                        name: user?.fullName ?? 'Nurse',
                        imagePath: user?.image,
                        baseUrl: controller.baseUrl,
                        radius: 16,
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF0A4D78),
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

          // Live Socket.IO Floating Clinical Event Banner
          if (banner != null)
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF0D2E5C),
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
                                  color: Color(0xFFD0E3FF),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: bottomIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF0A4D78),
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11.5,
          unselectedFontSize: 11.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          onTap: (idx) {
            if (idx <= 3) {
              controller.setSelectedNavIndex(idx);
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.desktop_windows_outlined),
              activeIcon: Icon(Icons.desktop_windows_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Patient',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services_rounded),
              label: 'OPD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hotel_outlined),
              activeIcon: Icon(Icons.hotel_rounded),
              label: 'IPD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_rounded),
              activeIcon: Icon(Icons.apps_rounded),
              label: 'Modules',
            ),
          ],
        ),
      ),
    );
  }
}

/// Exact 7-Item Nurse Sidebar from `https://hospital.hrpocket.in` (image-5):
/// Dashboard, Patient, OPD - Out Patient, IPD - In Patient, Blood Bank, Duty Roster, Annual Calendar
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

    const items = <(int, IconData, String)>[
      (NurseNavIndex.dashboard, Icons.desktop_windows_rounded, 'Dashboard'),
      (NurseNavIndex.patients, Icons.person_rounded, 'Patient'),
      (NurseNavIndex.opd, Icons.medical_information_rounded, 'OPD - Out Patient'),
      (NurseNavIndex.ipd, Icons.hotel_rounded, 'IPD - In Patient'),
      (NurseNavIndex.bloodBank, Icons.water_drop_rounded, 'Blood Bank'),
      (NurseNavIndex.dutyRoster, Icons.schedule_rounded, 'Duty Roster'),
      (NurseNavIndex.annualCalendar, Icons.calendar_month_rounded, 'Annual Calendar'),
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0A4D78),
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
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF0A4D78),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Nurse Clinical Portal',
                          style: TextStyle(
                            color: Color(0xFFCCE4F7),
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
                            ? const Color(0xFF0A4D78)
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
                                : const Color(0xFF0A4D78),
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
                    leading: const Icon(
                      Icons.bed_rounded,
                      size: 20,
                      color: Color(0xFF0A4D78),
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
                user?.roleName ?? 'Nurse',
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
