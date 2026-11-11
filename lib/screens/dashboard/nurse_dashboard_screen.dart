import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/status_badge.dart';
import '../beds/bed_status_screen.dart';
import '../medications/medications_mar_screen.dart';
import '../modules/annual_calendar_screen.dart';
import '../modules/blood_bank_screen.dart';
import '../modules/notifications_screen.dart';
import '../notes/nursing_notes_screen.dart';
import '../opd/opd_triage_screen.dart';
import '../patients/ipd_patient_detail_screen.dart';
import '../patients/my_patients_screen.dart';
import '../patients/patient_directory_screen.dart';
import '../reports/reports_screen.dart';
import '../roster/duty_roster_screen.dart';
import '../vitals/record_vitals_screen.dart';

class NurseDashboardScreen extends StatelessWidget {
  const NurseDashboardScreen({super.key});

  void _openMoreClinicalHub(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hospital Clinical Modules',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All Nurse Station modules synced live with Smart Hospital HMS',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _QuickActionTile(
                      icon: Icons.bed_rounded,
                      iconBg: AppColors.infoSoft,
                      iconColor: AppColors.primary,
                      label: 'Bed Status',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BedStatusScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.medical_information_rounded,
                      iconBg: AppColors.tealSoft,
                      iconColor: AppColors.teal,
                      label: 'OPD Triage',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OpdTriageScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.schedule_rounded,
                      iconBg: AppColors.purpleSoft,
                      iconColor: AppColors.purple,
                      label: 'Duty Roster',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DutyRosterScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.perm_contact_calendar_rounded,
                      iconBg: AppColors.skySurface,
                      iconColor: AppColors.primaryDark,
                      label: 'All Patients',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PatientDirectoryScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.water_drop_rounded,
                      iconBg: AppColors.dangerSoft,
                      iconColor: AppColors.danger,
                      label: 'Blood Bank',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BloodBankScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionTile(
                      icon: Icons.calendar_month_rounded,
                      iconBg: AppColors.warningSoft,
                      iconColor: AppColors.warning,
                      label: 'Calendar',
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnnualCalendarScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openQuickVitalsSelector(
    BuildContext context,
    List<IpdAdmission> admitted,
  ) {
    if (admitted.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OpdTriageScreen()),
      );
      return;
    }
    if (admitted.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordVitalsScreen(ipdAdmission: admitted.first),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final baseUrl = NursePortalScope.read(context).baseUrl;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Patient to Record Vitals',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: admitted.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final p = admitted[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: PatientAvatar(
                          name: p.patient.patientName,
                          imagePath: p.patient.image,
                          baseUrl: baseUrl,
                          radius: 21,
                        ),
                        title: Text(
                          p.patient.patientName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${p.patient.patientUniqueId} • ${p.wardAndBedLabel}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordVitalsScreen(ipdAdmission: p),
                            ),
                          );
                        },
                      );
                    },
                  ),
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
    final nurse = controller.currentUser;
    final dash = controller.dashboard;
    final admitted = controller.admittedPatients;

    // Determine primary ward label dynamically from bedGroups or admitted patients
    String wardLabel = 'All Hospital Wards';
    if (controller.bedGroups.isNotEmpty) {
      wardLabel = controller.bedGroups.map((g) => g.name).take(2).join(' • ');
    } else if (admitted.isNotEmpty && admitted.first.bedGroup.isNotEmpty) {
      wardLabel = admitted.first.bedGroup;
    }

    // Determine Today's Schedule summary from real duty roster + OPD queue
    final shifts = controller.myShifts.isNotEmpty
        ? controller.myShifts
        : controller.allRosterShifts;
    final opdWaitingCount = controller.opdQueue
        .where((o) => o.status.toLowerCase().contains('wait'))
        .length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => controller.refreshWorkspace(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Curved Royal Blue Top Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      78,
                    ),
                    decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppFormatters.greetingForNow(),
                                style: const TextStyle(
                                  color: Color(0xFFD6E8FF),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${nurse?.fullName ?? 'Duty Nurse'} 👋',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Nurse Dashboard',
                                    style: TextStyle(
                                      color: Color(0xFFD2E5FE),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x29FFFFFF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6.5,
                                          height: 6.5,
                                          decoration: BoxDecoration(
                                            color: controller.socketConnected
                                                ? const Color(0xFF4ADE80)
                                                : const Color(0xFFFBBF24),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          controller.socketConnected
                                              ? 'Live Sync'
                                              : 'Online',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Notification Bell with Unread Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0x26FFFFFF),
                              ),
                              icon: const Icon(
                                Icons.notifications_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                            if (controller.unreadAlertsCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
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
                                    '${controller.unreadAlertsCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => controller.setSelectedNavIndex(3),
                          child: PatientAvatar(
                            name: nurse?.fullName ?? 'Nurse',
                            imagePath: nurse?.image,
                            baseUrl: controller.baseUrl,
                            radius: 23,
                            backgroundColor: Colors.white,
                            textColor: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3 Overlapping Top Summary Cards (matching image-2.png)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: -44,
                    child: Row(
                      children: [
                        Expanded(
                          child: _TopKpiCard(
                            icon: Icons.people_alt_rounded,
                            iconBg: AppColors.infoSoft,
                            iconColor: AppColors.primary,
                            value: '${controller.activePatientsCount}',
                            label: 'My Patients',
                            onTap: () => controller.setSelectedNavIndex(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TopKpiCard(
                            icon: Icons.event_note_rounded,
                            iconBg: AppColors.warningSoft,
                            iconColor: AppColors.warning,
                            value: '${controller.pendingVitalsCount}',
                            label: 'Vitals Due',
                            onTap: () =>
                                _openQuickVitalsSelector(context, admitted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TopKpiCard(
                            icon: Icons.medication_rounded,
                            iconBg: AppColors.successSoft,
                            iconColor: AppColors.success,
                            value: '${controller.medicationsDueCount}',
                            label: 'Medications',
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
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 62, 18, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (controller.isLoadingWorkspace && dash == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: LinearProgressIndicator(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),

                  if (controller.workspaceError != null &&
                      dash == null &&
                      admitted.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SoftSurfaceCard(
                        child: ClinicalErrorState(
                          message: controller.workspaceError!,
                          onRetry: () => controller.refreshWorkspace(),
                        ),
                      ),
                    ),

                  // Quick Actions Section (6-Grid matching image-2.png)
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.04,
                    children: [
                      _QuickActionTile(
                        icon: Icons.groups_rounded,
                        iconBg: AppColors.infoSoft,
                        iconColor: AppColors.primary,
                        label: 'My Patients',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyPatientsScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.monitor_heart_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF0277BD),
                        label: 'Vitals',
                        onTap: () =>
                            _openQuickVitalsSelector(context, admitted),
                      ),
                      _QuickActionTile(
                        icon: Icons.medication_liquid_rounded,
                        iconBg: AppColors.successSoft,
                        iconColor: AppColors.success,
                        label: 'Medications',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MedicationsMarScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.note_add_rounded,
                        iconBg: AppColors.tealSoft,
                        iconColor: AppColors.teal,
                        label: 'Nursing Notes',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NursingNotesScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.biotech_rounded,
                        iconBg: AppColors.purpleSoft,
                        iconColor: AppColors.purple,
                        label: 'Reports',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReportsScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionTile(
                        icon: Icons.more_horiz_rounded,
                        iconBg: AppColors.skySurface,
                        iconColor: AppColors.primaryDark,
                        label: 'More',
                        onTap: () => _openMoreClinicalHub(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ward Overview Card with Circular Occupancy Ring (matching image-2.png)
                  SoftSurfaceCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BedStatusScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ward Overview',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                wardLabel,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Bed Occupancy',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${controller.bedOccupancyPercent}%',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${controller.occupiedBedsCount}/${controller.totalBedsCount} Occupied • ${controller.availableBedsCount} Vacant',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        WardOccupancyRing(
                          ratio: controller.bedOccupancyRatio,
                          size: 68,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Today's Schedule / Duty & OPD Triage Strip (matching image-2.png)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Schedule',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DutyRosterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'View All →',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SoftSurfaceCard(
                    onTap: () {
                      if (opdWaitingCount > 0) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OpdTriageScreen(),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DutyRosterScreen(),
                          ),
                        );
                      }
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: shifts.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${shifts.first.shiftName} • ${shifts.first.department}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (shifts.first.timeRangeLabel.isNotEmpty)
                                          shifts.first.timeRangeLabel,
                                        if (opdWaitingCount > 0)
                                          '$opdWaitingCount OPD Waiting for Vitals',
                                      ].join(' • '),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opdWaitingCount > 0
                                          ? '$opdWaitingCount OPD Consultations Waiting'
                                          : AppFormatters.formatFullDayDate(
                                              DateTime.now(),
                                            ),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opdWaitingCount > 0
                                          ? 'Tap to record OPD pre-consultation triage vitals'
                                          : 'Tap to inspect hospital duty roster & shift schedule',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Currently Admitted Ward Patients Live Census (matching Web Screenshot 720)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Currently Admitted Ward Patients',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (admitted.isNotEmpty)
                        TextButton(
                          onPressed: () => controller.setSelectedNavIndex(1),
                          child: const Text('View All →'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (admitted.isEmpty && !controller.isLoadingWorkspace)
                    const SoftSurfaceCard(
                      child: ClinicalEmptyState(
                        icon: Icons.hotel_rounded,
                        title: 'No Admitted IPD Patients',
                        subtitle:
                            'Ward census is currently clear. New admissions appear here in real time.',
                      ),
                    )
                  else
                    ...admitted.take(4).map(
                          (ipd) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AdmittedCensusRow(ipd: ipd),
                          ),
                        ),

                  // Recent Clinical Activity Live Feed (from GET /api/dashboard `recentActivity`)
                  if (dash != null && dash.recentActivity.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Recent Patient Clinical Activity',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SoftSurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Column(
                        children: dash.recentActivity
                            .take(5)
                            .map(
                              (act) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: const BoxDecoration(
                                        color: AppColors.skySurface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.history_edu_rounded,
                                        color: AppColors.primary,
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
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _TopKpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdmittedCensusRow extends StatelessWidget {
  final IpdAdmission ipd;

  const _AdmittedCensusRow({required this.ipd});

  @override
  Widget build(BuildContext context) {
    final baseUrl = NursePortalScope.read(context).baseUrl;
    return SoftSurfaceCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IpdPatientDetailScreen(
              ipdId: ipd.id,
              initialAdmission: ipd,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              PatientAvatar(
                name: ipd.patient.patientName,
                imagePath: ipd.patient.image,
                baseUrl: baseUrl,
                radius: 23,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (ipd.patient.patientUniqueId.isNotEmpty)
                          ipd.patient.patientUniqueId,
                        ipd.wardAndBedLabel,
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ipd.doctor.displayName,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: ipd.clinicalStatusLabel),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniActionChip(
                icon: Icons.assignment_ind_outlined,
                label: 'Chart',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IpdPatientDetailScreen(
                        ipdId: ipd.id,
                        initialAdmission: ipd,
                      ),
                    ),
                  );
                },
              ),
              _MiniActionChip(
                icon: Icons.favorite_border_rounded,
                label: 'Vitals',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
                    ),
                  );
                },
              ),
              _MiniActionChip(
                icon: Icons.medication_outlined,
                label: 'Meds',
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
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
