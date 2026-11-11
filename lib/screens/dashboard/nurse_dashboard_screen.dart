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

/// Executive Clinical Nurse Dashboard ("Aura Clinical Luxe")
/// - Zero clunky top header above `Good Afternoon, Sunita`
/// - Studio-lit ambient canvas + sculptural multi-stop Command Vault Hero Card
/// - Gradient-badged Shift Priorities, OneMedical-style Bedside Patient Passes,
///   2x2 Hospital Workspace Bento Grid, and Connected Clinical Activity Timeline
/// - 100% live data from `https://hospital.hrpocket.in`
class NurseDashboardScreen extends StatelessWidget {
  const NurseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final nurse = controller.currentUser;
    final firstName = (nurse?.name.trim().isNotEmpty ?? false)
        ? nurse!.name.trim()
        : (nurse?.fullName.split(' ').first ?? 'Nurse');
    final roleSubtitle = [
      if (nurse != null && nurse.designation.trim().isNotEmpty)
        nurse.designation.trim()
      else if (nurse != null && nurse.roleName.trim().isNotEmpty)
        nurse.roleName.trim(),
      if (nurse != null && nurse.department.trim().isNotEmpty)
        '${nurse.department.trim()} Dept',
    ].join('  •  ');

    final admitted = controller.admittedPatients;
    final activities = controller.todayClinicalActivity;
    final themePreset = controller.personalTheme;
    final primary = themePreset.primaryColor;
    final totalBloodBags = controller.bloodBankGroups.fold<int>(
      0,
      (sum, item) => sum + item.availableBags,
    );

    return PremiumScreenBackground(
      accentColor: primary,
      child: SafeArea(
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

              // 1. EXECUTIVE EDITORIAL GREETING HEADER (Nothing above Greeting)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(225),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'WARD DUTY  •  ${AppFormatters.formatDateShort(DateTime.now()).toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.65,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppFormatters.greetingForNow()}, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        if (roleSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            roleSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Glass Notification Bell
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                                width: 8.5,
                                height: 8.5,
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Gradient Halo Profile Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NurseProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2.2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primary, primary.withAlpha(130)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withAlpha(45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: PatientAvatar(
                          name: nurse?.fullName ?? 'Nurse',
                          imagePath: nurse?.image,
                          baseUrl: controller.baseUrl,
                          radius: 18.5,
                          backgroundColor: primary.withAlpha(20),
                          textColor: primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. TACTILE COMMAND SEARCH BAR
              GestureDetector(
                onTap: () => showGlobalHospitalSearchSheet(context),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primary.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Text(
                          'Search patient, UHID, mobile or doctor...',
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
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Find',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. ARCHITECTURAL CLINICAL COMMAND VAULT HERO CARD
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

              // 4. 3-UP SCULPTED SHIFT NURSING PRIORITIES
              Row(
                children: [
                  Expanded(
                    child: _ShiftPriorityTile(
                      icon: Icons.monitor_heart_rounded,
                      gradientColors: controller.pendingVitalsCount > 0
                          ? const [Color(0xFFF43F5E), Color(0xFFBE123C)]
                          : const [Color(0xFF10B981), Color(0xFF047857)],
                      value: '${controller.pendingVitalsCount}',
                      label: 'Pending Vitals',
                      cue: 'Record ›',
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
                      icon: Icons.assignment_turned_in_rounded,
                      gradientColors: [primary, primary.withAlpha(200)],
                      value: '${controller.pendingNursingTasksCount}',
                      label: 'Care Tasks',
                      cue: 'In-Ward ›',
                      onTap: () =>
                          controller.openIpdSection(showDischarged: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShiftPriorityTile(
                      icon: Icons.medication_rounded,
                      gradientColors: const [
                        Color(0xFF8B5CF6),
                        Color(0xFF6D28D9),
                      ],
                      value: '${controller.medicationsDueCount}',
                      label: 'Meds Due',
                      cue: 'MAR Chart ›',
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

              const SizedBox(height: 24),

              // 5. ADMITTED WARD PATIENTS SECTION
              _ExecutiveSectionHeader(
                title: 'Admitted Ward Patients',
                accentColor: primary,
                trailingText: 'Ward (${admitted.length})',
                onTapTrailing: () =>
                    controller.openIpdSection(showDischarged: false),
              ),
              const SizedBox(height: 12),

              if (admitted.isEmpty)
                SoftSurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      GradientIconBadge(
                        icon: Icons.hotel_rounded,
                        colors: [primary, primary.withAlpha(180)],
                        size: 42,
                        iconSize: 20,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Active Ward Admissions',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Currently admitted IPD patients appear here automatically.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...admitted.take(4).map(
                      (ipd) => _PremiumBedsidePatientCard(
                        ipd: ipd,
                        primaryColor: primary,
                      ),
                    ),

              const SizedBox(height: 22),

              // 6. HOSPITAL WORKSPACE 2x2 BENTO GRID
              _ExecutiveSectionHeader(
                title: 'Hospital Workspace',
                accentColor: primary,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.42,
                children: [
                  _BentoModuleCard(
                    icon: Icons.medical_services_rounded,
                    gradientColors: const [
                      Color(0xFF0EA5E9),
                      Color(0xFF0369A1),
                    ],
                    title: 'OPD Queue',
                    metricBadge: '${controller.opdPatientsCount} Visits',
                    subtitle: 'Out-patient triage & vitals',
                    onTap: () =>
                        controller.setSelectedNavIndex(NurseNavIndex.opd),
                  ),
                  _BentoModuleCard(
                    icon: Icons.water_drop_rounded,
                    gradientColors: const [
                      Color(0xFFF43F5E),
                      Color(0xFFBE123C),
                    ],
                    title: 'Blood Bank',
                    metricBadge: '$totalBloodBags Units',
                    subtitle: '${controller.bloodBankGroups.length} Blood groups',
                    onTap: () =>
                        controller.setSelectedNavIndex(NurseNavIndex.bloodBank),
                  ),
                  _BentoModuleCard(
                    icon: Icons.badge_rounded,
                    gradientColors: const [
                      Color(0xFFF59E0B),
                      Color(0xFFD97706),
                    ],
                    title: 'Duty Roster',
                    metricBadge: '${controller.allRosterShifts.length} Shifts',
                    subtitle: 'Staff duty allocation',
                    onTap: () => controller.setSelectedNavIndex(
                      NurseNavIndex.dutyRoster,
                    ),
                  ),
                  _BentoModuleCard(
                    icon: Icons.calendar_month_rounded,
                    gradientColors: const [
                      Color(0xFF10B981),
                      Color(0xFF047857),
                    ],
                    title: 'Calendar',
                    metricBadge: '${controller.holidays.length} Events',
                    subtitle: 'Hospital annual holidays',
                    onTap: () => controller.setSelectedNavIndex(
                      NurseNavIndex.annualCalendar,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 7. CONNECTED CLINICAL ACTIVITY TIMELINE
              _ExecutiveSectionHeader(
                title: 'Live Clinical Activity',
                accentColor: primary,
              ),
              const SizedBox(height: 12),
              SoftSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: activities.isEmpty
                    ? Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primary.withAlpha(16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.timeline_rounded,
                              color: primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No vitals or bedside nursing logs recorded in this shift yet.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: List.generate(
                          activities.take(6).length,
                          (index) {
                            final slice = activities.take(6).toList();
                            final act = slice[index];
                            final isLast = index == slice.length - 1;
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 11,
                                          height: 11,
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: primary.withAlpha(70),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 1.5,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              color: AppColors.border,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isLast ? 0 : 14,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  act.title,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                                if (act.description
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    act.description,
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              AppFormatters.timeAgo(
                                                act.timestamp,
                                              ),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExecutiveSectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final String? trailingText;
  final VoidCallback? onTapTrailing;

  const _ExecutiveSectionHeader({
    required this.title,
    required this.accentColor,
    this.trailingText,
    this.onTapTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (trailingText != null && onTapTrailing != null)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTapTrailing,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailingText!,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Architectural Dark-Jewel Gradient Ward Command Vault Card with Subtle Orbital Arcs
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
        ? const [Color(0xFF082F49), Color(0xFF0369A1), Color(0xFF0284C7)]
        : themePreset.bannerGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(70),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: CustomPaint(
          painter: const _VaultOrbitalPainter(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Capsule Strip inside Vault Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(32)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 13,
                            color: Color(0xFF34D399),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'INPATIENT WARD CENSUS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.75,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onTapBedStatus,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(24),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bed Matrix',
                              style: TextStyle(
                                color: Color(0xFFE0F2FE),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: Color(0xFFE0F2FE),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Center Split: Giant Admitted Count + Glowing Occupancy Gauge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onTapAdmitted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$admittedCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                    height: 1.0,
                                    fontFeatures: AppTheme.tabularNums,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                const Flexible(
                                  child: Text(
                                    'Active Inpatients',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x3310B981),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0x6634D399),
                                    ),
                                  ),
                                  child: Text(
                                    '$availableBeds Vacant',
                                    style: const TextStyle(
                                      color: Color(0xFF6EE7B7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$occupiedBeds / $totalBeds Beds Occupied',
                                  style: const TextStyle(
                                    color: Color(0xFFD6E8FA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onTapBedStatus,
                      child: WardOccupancyRing(
                        ratio: occupancyRatio,
                        size: 78,
                        trackColor: const Color(0x2EFFFFFF),
                        progressColor: const Color(0xFF34D399),
                        centerChild: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$occupancyPercent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                fontFeatures: AppTheme.tabularNums,
                              ),
                            ),
                            const Text(
                              'BEDS',
                              style: TextStyle(
                                color: Color(0xFFBAE6FD),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Frosted Glass Telemetry Dock (Total Patients | OPD | Discharged)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x30FFFFFF)),
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
                        height: 28,
                        color: const Color(0x30FFFFFF),
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
                        height: 28,
                        color: const Color(0x30FFFFFF),
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
          ),
        ),
      ),
    );
  }
}

class _VaultOrbitalPainter extends CustomPainter {
  const _VaultOrbitalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.12),
      95,
      arcPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.12),
      145,
      arcPaint,
    );

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(26),
          Colors.white.withAlpha(0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, 0),
          radius: 150,
        ),
      );
    canvas.drawCircle(Offset(size.width * 0.88, 0), 150, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFeatures: AppTheme.tabularNums,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD6E8FA),
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
  final List<Color> gradientColors;
  final String value;
  final String label;
  final String cue;
  final VoidCallback onTap;

  const _ShiftPriorityTile({
    required this.icon,
    required this.gradientColors,
    required this.value,
    required this.label,
    required this.cue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GradientIconBadge(
                icon: icon,
                colors: gradientColors,
                size: 35,
                iconSize: 17,
                radius: 11,
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  fontFeatures: AppTheme.tabularNums,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cue,
            style: TextStyle(
              color: gradientColors.last,
              fontSize: 10.5,
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
  final List<Color> gradientColors;
  final String title;
  final String metricBadge;
  final String subtitle;
  final VoidCallback onTap;

  const _BentoModuleCard({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.metricBadge,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -10,
            child: Icon(
              icon,
              size: 62,
              color: gradientColors.last.withAlpha(12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GradientIconBadge(
                    icon: icon,
                    colors: gradientColors,
                    size: 38,
                    iconSize: 19,
                    radius: 12,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: gradientColors.last.withAlpha(18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      metricBadge,
                      style: TextStyle(
                        color: gradientColors.last,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        fontFeatures: AppTheme.tabularNums,
                      ),
                    ),
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
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
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withAlpha(32),
                        primaryColor.withAlpha(14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withAlpha(40)),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5.5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: primaryColor.withAlpha(38)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hotel_rounded,
                        size: 13.5,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ipd.wardAndBedLabel,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_information_rounded,
                    size: 15,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 7),
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
                    AppFormatters.formatSlashDate(ipd.admissionDate),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                    icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                    label: const Text(
                      'Open Chart',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _TintedActionBtn(
                    icon: Icons.favorite_rounded,
                    label: 'Vitals',
                    fg: const Color(0xFFE11D48),
                    bg: const Color(0xFFFFF1F2),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _TintedActionBtn(
                    icon: Icons.medication_rounded,
                    label: 'Meds',
                    fg: const Color(0xFF6D28D9),
                    bg: const Color(0xFFF5F3FF),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MedicationsMarScreen(
                            filterIpdId: ipd.id,
                            patientTitle: ipd.patient.patientName,
                          ),
                        ),
                      );
                    },
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

class _TintedActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  const _TintedActionBtn({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
