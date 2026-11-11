import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/global_search_sheet.dart';
import '../../widgets/status_badge.dart';
import '../beds/bed_status_screen.dart';
import '../medications/medications_mar_screen.dart';
import '../patients/ipd_patient_detail_screen.dart';
import '../vitals/record_vitals_screen.dart';

/// Nurse Dashboard Screen matching `https://hospital.hrpocket.in` (image-4 & image-5) 1-to-1:
/// - Greeting (`Good morning/afternoon/evening, Sunita`) + `Nursing Desk — In-Patient Care, Vitals & Ward Management`
/// - Search box (`Search patients, appointments, doctors...`)
/// - Date chip + `In-Patient Nursing & Ward Desk` • `Online & Ready`
/// - Burgundy `Inpatient Nursing & Ward Clinical Workspace` Hero Banner (`WARD DUTY ACTIVE` + `All Patients`, `In-Patients (IPD)`, `Bed Status`)
/// - All 8 Live KPI Cards (`Total Patients`, `Currently Admitted`, `OPD Patients`, `Discharged Patients`, `Pending Nursing Tasks`, `Medications Due`, `Pending Vitals`, `Ward Bed Occupancy`)
/// - `Currently Admitted Ward Patients` with `[Chart]`, `[Vitals]`, `[Meds]`
/// - `Recent Patient Clinical Activity` (`No recent vitals or nursing notes recorded today yet.`)
/// - `Quick Nursing Operations` (`All Patients`, `In-Patients (IPD)`, `Bed Status`, `Duty Roster`)
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

    return RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
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

          // Pending ABHA Scan & Share Banner (shown when > 0, matching Screenshot 717)
          if (controller.pendingAbhaCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => controller.setSelectedNavIndex(NurseNavIndex.opd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFFB45309),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${controller.pendingAbhaCount} pending ABHA Scan & Share check-ins',
                          style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Text(
                        'Open Queue →',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Greeting Header (matching image-4)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${AppFormatters.greetingForNow()}, $firstName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.medical_information_rounded,
                          color: Color(0xFF0A4D78),
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Nursing Desk — In-Patient Care, Vitals & Ward Management',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Box (`Search patients, appointments, doctors...` — image-4)
          GestureDetector(
            onTap: () => showGlobalHospitalSearchSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search patients, appointments, doctors...',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Date Chip & Online Status Row (image-4)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppFormatters.formatFullDayDate(DateTime.now()),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online & Ready',
                      style: TextStyle(
                        color: Color(0xFF15803D),
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

          // Burgundy Clinical Workspace Hero Banner (image-4)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF231526), Color(0xFF6A163E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x226A163E),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D68),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hotel_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Inpatient Nursing & Ward Clinical Workspace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D68),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '• WARD DUTY ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nurse Station • Vitals Monitoring, Medication Dose Administration & Ward Bed Management',
                            style: TextStyle(
                              color: Color(0xFFE2CBD5),
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$firstName (${nurse?.roleName ?? "Nurse"}) • Clinical Inpatient Care • Vitals & Rounds Monitoring',
                            style: const TextStyle(
                              color: Color(0xFFF9A8D4),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroButton(
                      icon: Icons.groups_rounded,
                      label: 'All Patients',
                      filled: true,
                      onTap: () =>
                          controller.setSelectedNavIndex(NurseNavIndex.patients),
                    ),
                    _HeroButton(
                      icon: Icons.hotel_rounded,
                      label: 'In-Patients (IPD)',
                      filled: false,
                      onTap: () =>
                          controller.setSelectedNavIndex(NurseNavIndex.ipd),
                    ),
                    _HeroButton(
                      icon: Icons.bed_rounded,
                      label: 'Bed Status',
                      filled: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BedStatusScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // THE 8 EXACT WEBSITE KPI CARDS (image-4 & image-5)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.42,
            children: [
              _WebsiteKpiCard(
                icon: Icons.groups_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0369A1),
                title: 'Total Patients',
                value: '${controller.totalPatientsCount}',
                badgeText: '→ View',
                badgeBg: const Color(0xFFDCFCE7),
                badgeFg: const Color(0xFF15803D),
                subtitle: 'All registered hospital patients',
                onTap: () =>
                    controller.setSelectedNavIndex(NurseNavIndex.patients),
              ),
              _WebsiteKpiCard(
                icon: Icons.hotel_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                title: 'Currently Admitted',
                value: '${controller.activePatientsCount}',
                badgeText: 'Active',
                badgeBg: const Color(0xFFDCFCE7),
                badgeFg: const Color(0xFF15803D),
                subtitle: 'Admitted in-patients in wards',
                onTap: () => controller.openIpdSection(showDischarged: false),
              ),
              _WebsiteKpiCard(
                icon: Icons.medical_information_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'OPD Patients',
                value: '${controller.opdPatientsCount}',
                badgeText: '→ View',
                badgeBg: const Color(0xFFDCFCE7),
                badgeFg: const Color(0xFF15803D),
                subtitle: 'Outpatient clinic consultations',
                onTap: () => controller.setSelectedNavIndex(NurseNavIndex.opd),
              ),
              _WebsiteKpiCard(
                icon: Icons.logout_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                title: 'Discharged Patients',
                value: '${controller.dischargedPatientsCount}',
                badgeText: 'History',
                badgeBg: const Color(0xFFFEF3C7),
                badgeFg: const Color(0xFFB45309),
                subtitle: 'Completed hospital discharges',
                onTap: () => controller.openIpdSection(showDischarged: true),
              ),
              _WebsiteKpiCard(
                icon: Icons.checklist_rounded,
                iconBg: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFDB2777),
                title: 'Pending Nursing Tasks',
                value: '${controller.pendingNursingTasksCount}',
                badgeText: 'Today',
                badgeBg: const Color(0xFFFCE7F3),
                badgeFg: const Color(0xFFBE185D),
                subtitle: 'Care tasks & nurse notes due',
                onTap: () => controller.openIpdSection(showDischarged: false),
              ),
              _WebsiteKpiCard(
                icon: Icons.medical_services_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7E22CE),
                title: 'Medications Due',
                value: '${controller.medicationsDueCount}',
                badgeText: 'Active',
                badgeBg: const Color(0xFFF3E8FF),
                badgeFg: const Color(0xFF7E22CE),
                subtitle: 'Prescriptions requiring administration',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MedicationsMarScreen(),
                    ),
                  );
                },
              ),
              _WebsiteKpiCard(
                icon: Icons.monitor_heart_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                title: 'Pending Vitals',
                value: '${controller.pendingVitalsCount}',
                badgeText: controller.pendingVitalsCount > 0
                    ? 'Required'
                    : 'Clear',
                badgeBg: controller.pendingVitalsCount > 0
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFDCFCE7),
                badgeFg: controller.pendingVitalsCount > 0
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF15803D),
                subtitle: 'Admitted patients due for vitals',
                onTap: () {
                  if (admitted.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecordVitalsScreen(ipdAdmission: admitted.first),
                      ),
                    );
                  } else {
                    controller.setSelectedNavIndex(NurseNavIndex.opd);
                  }
                },
              ),
              _WebsiteKpiCard(
                icon: Icons.bed_rounded,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF334155),
                title: 'Ward Bed Occupancy',
                value:
                    '${controller.occupiedBedsCount} / ${controller.totalBedsCount}',
                badgeText: '${controller.bedOccupancyPercent}% Full',
                badgeBg: const Color(0xFFF1F5F9),
                badgeFg: const Color(0xFF334155),
                subtitle: '${controller.availableBedsCount} Available Beds',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BedStatusScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Currently Admitted Ward Patients Card (image-5 & Screenshot 721)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.hotel_rounded,
                        color: Color(0xFF15803D),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currently Admitted Ward Patients',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Live patient census in hospital beds',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE0F2FE),
                        foregroundColor: const Color(0xFF0369A1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          controller.openIpdSection(showDischarged: false),
                      child: const Text(
                        'View All Admitted →',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (admitted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No currently admitted ward patients.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  ...admitted.map(
                    (ipd) => _AdmittedPatientRow(ipd: ipd),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Recent Patient Clinical Activity (image-5)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFFDB2777),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Recent Patient Clinical Activity',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      'Live Stream',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'No recent vitals or nursing notes recorded today yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ...activities.take(6).map(
                        (act) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
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
                      ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quick Nursing Operations (4 tiles matching Screenshot 721)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Nursing Operations',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.35,
                  children: [
                    _QuickOperationBox(
                      icon: Icons.groups_rounded,
                      label: 'All Patients',
                      bg: const Color(0xFFEFF6FF),
                      fg: const Color(0xFF1D4ED8),
                      onTap: () => controller
                          .setSelectedNavIndex(NurseNavIndex.patients),
                    ),
                    _QuickOperationBox(
                      icon: Icons.hotel_rounded,
                      label: 'In-Patients (IPD)',
                      bg: const Color(0xFFECFDF5),
                      fg: const Color(0xFF047857),
                      onTap: () =>
                          controller.openIpdSection(showDischarged: false),
                    ),
                    _QuickOperationBox(
                      icon: Icons.bed_rounded,
                      label: 'Bed Status',
                      bg: const Color(0xFFFFF1F2),
                      fg: const Color(0xFFBE123C),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BedStatusScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickOperationBox(
                      icon: Icons.schedule_rounded,
                      label: 'Duty Roster',
                      bg: const Color(0xFFF5F3FF),
                      fg: const Color(0xFF6D28D9),
                      onTap: () => controller
                          .setSelectedNavIndex(NurseNavIndex.dutyRoster),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? Colors.white : const Color(0x28FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? Colors.white : const Color(0x45FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: filled ? const Color(0xFF0A4D78) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebsiteKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final String subtitle;
  final VoidCallback onTap;

  const _WebsiteKpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdmittedPatientRow extends StatelessWidget {
  final IpdAdmission ipd;

  const _AdmittedPatientRow({required this.ipd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (ipd.patient.patientUniqueId.isNotEmpty)
                          StatusBadge(label: ipd.patient.patientUniqueId),
                        Text(
                          [
                            if (ipd.patient.age > 0) '${ipd.patient.age} Yrs',
                            ipd.patient.gender,
                          ].join(' • '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hotel_rounded,
                        size: 14,
                        color: Color(0xFF0A4D78),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ipd.wardAndBedLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppFormatters.formatSlashDate(ipd.admissionDate),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              ipd.doctor.displayName,
              if (ipd.department.isNotEmpty) ipd.department,
            ].join(' • '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionOutlineBtn(
                  icon: Icons.medical_information_outlined,
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionOutlineBtn(
                  icon: Icons.favorite_rounded,
                  label: 'Vitals',
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
                child: _ActionOutlineBtn(
                  icon: Icons.medical_services_rounded,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionOutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionOutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: const Color(0xFF0A4D78)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _QuickOperationBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _QuickOperationBox({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
