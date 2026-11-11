import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/global_search_sheet.dart';
import '../../widgets/patient_avatar.dart';
import '../beds/bed_status_screen.dart';
import '../medications/medications_mar_screen.dart';
import '../modules/notifications_screen.dart';
import '../patients/ipd_patient_detail_screen.dart';
import '../profile/nurse_profile_screen.dart';
import '../vitals/record_vitals_screen.dart';

/// Flagship Modern Clinical Nurse Dashboard
/// Designed with Apple-Health / Practo-Pro visual hierarchy, generous whitespace,
/// cohesive typography, and 100% live data from `https://hospital.hrpocket.in`.
class NurseDashboardScreen extends StatelessWidget {
  const NurseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final nurse = controller.currentUser;
    final firstName = (nurse?.name.trim().isNotEmpty ?? false)
        ? nurse!.name.trim()
        : (nurse?.fullName.split(' ').first ?? 'Nurse');
    final admitted = controller.admittedPatients;
    final activities = controller.todayClinicalActivity;
    final themePreset = controller.personalTheme;
    final primary = themePreset.primaryColor;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: primary,
        onRefresh: () => controller.refreshWorkspace(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            if (controller.isLoadingWorkspace && controller.dashboard == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),

            if (controller.workspaceError != null &&
                controller.dashboard == null &&
                admitted.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SoftSurfaceCard(
                  child: ClinicalErrorState(
                    message: controller.workspaceError!,
                    onRetry: () => controller.refreshWorkspace(),
                  ),
                ),
              ),

            // 1. NATIVE EDITORIAL TOP GREETING ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'WARD DUTY ACTIVE  •  ${AppFormatters.formatDateShort(DateTime.now()).toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppFormatters.greetingForNow()}, $firstName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Notifications Bell
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                          size: 21,
                        ),
                        if (controller.unreadAlertsCount > 0)
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nurse Profile Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NurseProfileScreen(),
                      ),
                    );
                  },
                  child: PatientAvatar(
                    name: nurse?.fullName ?? 'Nurse',
                    imagePath: nurse?.image,
                    baseUrl: controller.baseUrl,
                    radius: 21,
                    backgroundColor: Colors.white,
                    textColor: primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. SLEEK SEARCH PILL
            GestureDetector(
              onTap: () => showGlobalHospitalSearchSheet(context),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Search patients, UHID, mobile, doctors...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 3. SIGNATURE WARD COMMAND & BED OCCUPANCY HERO CARD
            _WardCommandHeroCard(
              themePreset: themePreset,
              admittedCount: controller.activePatientsCount,
              totalPatientsCount: controller.totalPatientsCount,
              opdCount: controller.opdPatientsCount,
              dischargedCount: controller.dischargedPatientsCount,
              occupiedBeds: controller.occupiedBedsCount,
              totalBeds: controller.totalBedsCount,
              availableBeds: controller.availableBedsCount,
              occupancyRatio: controller.bedOccupancyRatio,
              occupancyPercent: controller.bedOccupancyPercent,
              onTapPatients: () =>
                  controller.setSelectedNavIndex(NurseNavIndex.patients),
              onTapAdmitted: () =>
                  controller.openIpdSection(showDischarged: false),
              onTapOpd: () =>
                  controller.setSelectedNavIndex(NurseNavIndex.opd),
              onTapDischarged: () =>
                  controller.openIpdSection(showDischarged: true),
              onTapBedStatus: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BedStatusScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 4. SHIFT NURSING PRIORITIES (3-Up Crisp Clinical Strip)
            Row(
              children: [
                Expanded(
                  child: _ShiftPriorityTile(
                    icon: Icons.monitor_heart_outlined,
                    accent: controller.pendingVitalsCount > 0
                        ? const Color(0xFFE11D48)
                        : AppColors.success,
                    tint: controller.pendingVitalsCount > 0
                        ? const Color(0xFFFFF1F2)
                        : AppColors.successSoft,
                    value: '${controller.pendingVitalsCount}',
                    label: 'Pending Vitals',
                    onTap: () {
                      if (admitted.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecordVitalsScreen(
                              ipdAdmission: admitted.first,
                            ),
                          ),
                        );
                      } else {
                        controller.setSelectedNavIndex(NurseNavIndex.opd);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShiftPriorityTile(
                    icon: Icons.assignment_turned_in_outlined,
                    accent: primary,
                    tint: const Color(0xFFEFF6FF),
                    value: '${controller.pendingNursingTasksCount}',
                    label: 'Care Tasks',
                    onTap: () =>
                        controller.openIpdSection(showDischarged: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShiftPriorityTile(
                    icon: Icons.medication_outlined,
                    accent: const Color(0xFF7C3AED),
                    tint: const Color(0xFFF5F3FF),
                    value: '${controller.medicationsDueCount}',
                    label: 'Meds Due',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MedicationsMarScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 5. ADMITTED WARD PATIENTS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Admitted Ward Patients',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => controller.openIpdSection(showDischarged: false),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'See all (${admitted.length}) →',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (admitted.isEmpty)
              const SoftSurfaceCard(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Row(
                  children: [
                    Icon(
                      Icons.hotel_outlined,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No active inpatients admitted in wards right now.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...admitted.map(
                (ipd) => _PremiumBedsidePatientCard(
                  ipd: ipd,
                  primaryColor: primary,
                ),
              ),

            const SizedBox(height: 18),

            // 6. HOSPITAL WORKSPACE BENTO GRID (2x2 Direct Access to Website Modules)
            const Text(
              'Hospital Workspace',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _BentoModuleCard(
                  icon: Icons.medical_services_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconFg: const Color(0xFF2563EB),
                  title: 'OPD Queue',
                  subtitle: '${controller.opdPatientsCount} consultations',
                  onTap: () =>
                      controller.setSelectedNavIndex(NurseNavIndex.opd),
                ),
                _BentoModuleCard(
                  icon: Icons.water_drop_rounded,
                  iconBg: const Color(0xFFFFF1F2),
                  iconFg: const Color(0xFFE11D48),
                  title: 'Blood Bank',
                  subtitle:
                      '${controller.bloodBankGroups.length} blood groups',
                  onTap: () =>
                      controller.setSelectedNavIndex(NurseNavIndex.bloodBank),
                ),
                _BentoModuleCard(
                  icon: Icons.schedule_rounded,
                  iconBg: const Color(0xFFFFFBEB),
                  iconFg: const Color(0xFFD97706),
                  title: 'Duty Roster',
                  subtitle: '${controller.allRosterShifts.length} shifts',
                  onTap: () =>
                      controller.setSelectedNavIndex(NurseNavIndex.dutyRoster),
                ),
                _BentoModuleCard(
                  icon: Icons.calendar_month_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconFg: const Color(0xFF059669),
                  title: 'Annual Calendar',
                  subtitle: '${controller.holidays.length} holidays',
                  onTap: () => controller
                      .setSelectedNavIndex(NurseNavIndex.annualCalendar),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 7. TODAY'S CLINICAL STREAM
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Clinical Activity',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Live Stream',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SoftSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: activities.isEmpty
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.timeline_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No recent vitals or nursing notes recorded today yet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: activities
                          .take(6)
                          .map(
                            (act) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.skySurface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.bolt_rounded,
                                      color: primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          act.title,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (act.description.isNotEmpty)
                                          Text(
                                            act.description,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.timeAgo(act.timestamp),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Luxury Dark-Gradient Ward Command & Bed Occupancy Hero Card
class _WardCommandHeroCard extends StatelessWidget {
  final NursePersonalTheme themePreset;
  final int admittedCount;
  final int totalPatientsCount;
  final int opdCount;
  final int dischargedCount;
  final int occupiedBeds;
  final int totalBeds;
  final int availableBeds;
  final double occupancyRatio;
  final int occupancyPercent;
  final VoidCallback onTapPatients;
  final VoidCallback onTapAdmitted;
  final VoidCallback onTapOpd;
  final VoidCallback onTapDischarged;
  final VoidCallback onTapBedStatus;

  const _WardCommandHeroCard({
    required this.themePreset,
    required this.admittedCount,
    required this.totalPatientsCount,
    required this.opdCount,
    required this.dischargedCount,
    required this.occupiedBeds,
    required this.totalBeds,
    required this.availableBeds,
    required this.occupancyRatio,
    required this.occupancyPercent,
    required this.onTapPatients,
    required this.onTapAdmitted,
    required this.onTapOpd,
    required this.onTapDischarged,
    required this.onTapBedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = themePreset.id == 'glacier_blue'
        ? const [Color(0xFF0C4A6E), Color(0xFF0284C7)]
        : themePreset.bannerGradient;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Inpatient Census + Circular Bed Occupancy Gauge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INPATIENT WARD CENSUS',
                      style: TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onTapAdmitted,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$admittedCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Currently Admitted',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$availableBeds Available Beds  •  $occupiedBeds/$totalBeds Occupied',
                      style: const TextStyle(
                        color: Color(0xFFD6E8FA),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onTapBedStatus,
                child: Column(
                  children: [
                    WardOccupancyRing(
                      ratio: occupancyRatio,
                      size: 68,
                      trackColor: const Color(0x2EFFFFFF),
                      progressColor: const Color(0xFF34D399),
                      centerChild: Text(
                        '$occupancyPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bed Status ›',
                      style: TextStyle(
                        color: Color(0xFFBAE6FD),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Bottom Integrated 3-Stat Glass Bar (Total Patients | OPD | Discharged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x29FFFFFF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStatColumn(
                    value: '$totalPatientsCount',
                    label: 'Total Patients',
                    onTap: onTapPatients,
                  ),
                ),
                Container(
                  width: 1,
                  height: 26,
                  color: const Color(0x2EFFFFFF),
                ),
                Expanded(
                  child: _HeroStatColumn(
                    value: '$opdCount',
                    label: 'OPD Visits',
                    onTap: onTapOpd,
                  ),
                ),
                Container(
                  width: 1,
                  height: 26,
                  color: const Color(0x2EFFFFFF),
                ),
                Expanded(
                  child: _HeroStatColumn(
                    value: '$dischargedCount',
                    label: 'Discharged',
                    onTap: onTapDischarged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatColumn extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;

  const _HeroStatColumn({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCCE3F8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftPriorityTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color tint;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _ShiftPriorityTile({
    required this.icon,
    required this.accent,
    required this.tint,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BentoModuleCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconFg, size: 19),
              ),
              const Icon(
                Icons.north_east_rounded,
                size: 16,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumBedsidePatientCard extends StatelessWidget {
  final IpdAdmission ipd;
  final Color primaryColor;

  const _PremiumBedsidePatientCard({
    required this.ipd,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = AppFormatters.initials(ipd.patient.patientName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ipd.patient.patientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (ipd.patient.patientUniqueId.isNotEmpty)
                            ipd.patient.patientUniqueId,
                          if (ipd.patient.age > 0) '${ipd.patient.age} Yrs',
                          ipd.patient.gender,
                        ].join('  •  '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hotel_rounded,
                        size: 13,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ipd.wardAndBedLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_information_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ipd.doctor.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Admitted ${AppFormatters.formatSlashDate(ipd.admissionDate)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IpdPatientDetailScreen(
                            ipdId: ipd.id,
                            initialAdmission: ipd,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_ind_outlined, size: 15),
                    label: const Text(
                      'Chart',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.favorite_border_rounded,
                      size: 15,
                      color: primaryColor,
                    ),
                    label: const Text(
                      'Vitals',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MedicationsMarScreen(
                            filterIpdId: ipd.id,
                            patientTitle: ipd.patient.patientName,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.medication_outlined,
                      size: 15,
                      color: primaryColor,
                    ),
                    label: const Text(
                      'Meds',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
