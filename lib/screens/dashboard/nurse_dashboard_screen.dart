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
import '../profile/nurse_profile_screen.dart';
import '../vitals/record_vitals_screen.dart';

/// Nurse Dashboard Screen:
/// - Starts directly at the top (`SafeArea`) with the sky-blue `Good Afternoon, Sunita`
///   Hospital Hero Card (nothing above it).
/// - Styled in the clean modern mobile card layout of `image-16.png` while displaying
///   ONLY 100% real features & live API data from `https://hospital.hrpocket.in`.
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

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: themePreset.primaryColor,
        onRefresh: () => controller.refreshWorkspace(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (controller.isLoadingWorkspace && controller.dashboard == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
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

            // 1. TOP SKY-BLUE HOSPITAL GREETING BANNER (Very top of screen — nothing above it!)
            _GreetingHospitalHeroCard(
              greeting: '${_titleCaseGreeting()},',
              firstName: firstName,
            ),

            const SizedBox(height: 12),

            // 2. DATE PILL + NAVY `Bed Status >` PILL (matching image-16 pill row with real website Bed Status)
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2ECF9)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A0B3B78),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: themePreset.primaryColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            AppFormatters.formatFullDayDate(DateTime.now()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 12,
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
                  flex: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BedStatusScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A3977), Color(0xFF1354A4)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x220A3977),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bed_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Bed Status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. WEBSITE GLOBAL SEARCH BAR (`Search patients, appointments, doctors...` + `Online & Ready`)
            GestureDetector(
              onTap: () => showGlobalHospitalSearchSheet(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2ECF9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0B3B78),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: themePreset.primaryColor,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Search patients, appointments, doctors...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF8A9BB5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Online',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 10.5,
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

            const SizedBox(height: 14),

            // 4. PRIMARY 2x2 KPI GRID (image-16 visual design with real website counts)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.92,
              children: [
                _SoftModernKpiCard(
                  icon: Icons.groups_rounded,
                  iconBg: const Color(0xFFE8F1FF),
                  iconFg: const Color(0xFF155EEF),
                  value: '${controller.totalPatientsCount}',
                  label: 'Total Patients',
                  pillText: 'View →',
                  pillBg: const Color(0xFFEBF3FF),
                  pillFg: const Color(0xFF155EEF),
                  onTap: () =>
                      controller.setSelectedNavIndex(NurseNavIndex.patients),
                ),
                _SoftModernKpiCard(
                  icon: Icons.hotel_rounded,
                  iconBg: const Color(0xFFE6F7EF),
                  iconFg: const Color(0xFF129A56),
                  value: '${controller.activePatientsCount}',
                  label: 'Currently Admitted',
                  pillText: 'View →',
                  pillBg: const Color(0xFFE6F7EF),
                  pillFg: const Color(0xFF129A56),
                  onTap: () => controller.openIpdSection(showDischarged: false),
                ),
                _SoftModernKpiCard(
                  icon: Icons.medical_services_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  iconFg: const Color(0xFF7C3AED),
                  value: '${controller.opdPatientsCount}',
                  label: 'OPD Patients',
                  pillText: 'View →',
                  pillBg: const Color(0xFFF3E8FF),
                  pillFg: const Color(0xFF7C3AED),
                  onTap: () =>
                      controller.setSelectedNavIndex(NurseNavIndex.opd),
                ),
                _SoftModernKpiCard(
                  icon: Icons.logout_rounded,
                  iconBg: const Color(0xFFFFF2E2),
                  iconFg: const Color(0xFFEA7A18),
                  value: '${controller.dischargedPatientsCount}',
                  label: 'Discharged Patients',
                  pillText: 'View →',
                  pillBg: const Color(0xFFFFF2E2),
                  pillFg: const Color(0xFFD96B0C),
                  onTap: () => controller.openIpdSection(showDischarged: true),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 5. WARD CLINICAL KPI GRID (Remaining 4 real website KPIs from image-4 in same design)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.92,
              children: [
                _SoftModernKpiCard(
                  icon: Icons.checklist_rounded,
                  iconBg: const Color(0xFFFDEBF3),
                  iconFg: const Color(0xFFDB2777),
                  value: '${controller.pendingNursingTasksCount}',
                  label: 'Pending Tasks',
                  pillText: 'Today',
                  pillBg: const Color(0xFFFDEBF3),
                  pillFg: const Color(0xFFBE185D),
                  onTap: () => controller.openIpdSection(showDischarged: false),
                ),
                _SoftModernKpiCard(
                  icon: Icons.medication_rounded,
                  iconBg: const Color(0xFFEDE9FE),
                  iconFg: const Color(0xFF6D28D9),
                  value: '${controller.medicationsDueCount}',
                  label: 'Medications Due',
                  pillText: 'Active',
                  pillBg: const Color(0xFFEDE9FE),
                  pillFg: const Color(0xFF6D28D9),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MedicationsMarScreen(),
                      ),
                    );
                  },
                ),
                _SoftModernKpiCard(
                  icon: Icons.monitor_heart_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                  iconFg: const Color(0xFFDC2626),
                  value: '${controller.pendingVitalsCount}',
                  label: 'Pending Vitals',
                  pillText: controller.pendingVitalsCount > 0
                      ? 'Required'
                      : 'Clear',
                  pillBg: controller.pendingVitalsCount > 0
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFE6F7EF),
                  pillFg: controller.pendingVitalsCount > 0
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF129A56),
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
                _SoftModernKpiCard(
                  icon: Icons.bed_rounded,
                  iconBg: const Color(0xFFE6F4FE),
                  iconFg: const Color(0xFF0284C7),
                  value:
                      '${controller.occupiedBedsCount}/${controller.totalBedsCount}',
                  label: '${controller.availableBedsCount} Beds Free',
                  pillText: '${controller.bedOccupancyPercent}%',
                  pillBg: const Color(0xFFE6F4FE),
                  pillFg: const Color(0xFF0369A1),
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

            const SizedBox(height: 16),

            // 6. DUAL-LAYER NAVY + WHITE `In-Patient Nursing & Ward Clinical Workspace` CARD (exact image-16 style!)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF072D5B), Color(0xFF0D4B92)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22072D5B),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.hotel_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 9),
                            const Expanded(
                              child: Text(
                                'In-Patient Nursing & Ward Clinical Workspace',
                                maxLines: 2,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F6E),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '• WARD DUTY ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Nurse Station • Vitals Monitoring • Medication Dose Administration',
                          style: TextStyle(
                            color: Color(0xFFC7DCF7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Inner White Elevated Surface (exact image-16 overlapping white box)
                  Container(
                    margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // 3-item Clinical Info Strip (`Sunita (Nurse)` | `Vitals & Rounds` | `Ward Management`)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F9FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NurseProfileScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.person_rounded,
                                        size: 15,
                                        color: Color(0xFFF43F6E),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '$firstName (${nurse?.roleName ?? "Nurse"})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 14,
                                color: const Color(0xFFDCE6F5),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => controller
                                      .setSelectedNavIndex(NurseNavIndex.opd),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.favorite_rounded,
                                        size: 14,
                                        color: Color(0xFFF43F6E),
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Vitals & Rounds',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 14,
                                color: const Color(0xFFDCE6F5),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => controller
                                      .openIpdSection(showDischarged: false),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bar_chart_rounded,
                                        size: 15,
                                        color: Color(0xFF155EEF),
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Ward Care',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 11,
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
                        ),

                        const SizedBox(height: 10),

                        // 3 Website Action Pills (`All Patients`, `In-Patients (IPD)`, `Bed Status`)
                        Row(
                          children: [
                            Expanded(
                              child: _WorkspaceActionPill(
                                icon: Icons.groups_rounded,
                                label: 'All Patients',
                                primary: true,
                                onTap: () => controller.setSelectedNavIndex(
                                  NurseNavIndex.patients,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: _WorkspaceActionPill(
                                icon: Icons.hotel_rounded,
                                label: 'In-Patients (IPD)',
                                primary: false,
                                onTap: () => controller.openIpdSection(
                                  showDischarged: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: _WorkspaceActionPill(
                                icon: Icons.bed_rounded,
                                label: 'Bed Status',
                                primary: false,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BedStatusScreen(),
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 7. CURRENTLY ADMITTED WARD PATIENTS (Website Real Census)
            SoftSurfaceCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7EF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.hotel_rounded,
                          color: Color(0xFF129A56),
                          size: 17,
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
                                color: Color(0xFF0F2544),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Live patient census in hospital beds',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            controller.openIpdSection(showDischarged: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'View All →',
                            style: TextStyle(
                              color: Color(0xFF155EEF),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (admitted.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'No currently admitted ward patients.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF566B88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ...admitted.map((ipd) => _AdmittedPatientRow(ipd: ipd)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 8. RECENT PATIENT CLINICAL ACTIVITY (exact image-16 card with `• Live Stream` & ECG wave)
            SoftSurfaceCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: Color(0xFF0A3977),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recent Patient Clinical Activity',
                          style: TextStyle(
                            color: Color(0xFF0F2544),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDEBF3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF43F6E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Live Stream',
                              style: TextStyle(
                                color: Color(0xFFBE185D),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (activities.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD6E6FC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.monitor_heart_rounded,
                              color: Color(0xFF155EEF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No recent vitals or nursing notes recorded today yet.',
                              style: TextStyle(
                                color: Color(0xFF334E6F),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 58,
                            height: 34,
                            child: CustomPaint(
                              painter: _SubtleCardEcgPainter(),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...activities.take(6).map(
                          (act) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD6E6FC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.monitor_heart_rounded,
                                    color: Color(0xFF155EEF),
                                    size: 16,
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

            // 9. QUICK NURSING OPERATIONS (exact image-16 4-column pastel tiles mapped strictly to website features!)
            SoftSurfaceCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xFF0A3977),
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Quick Nursing Operations',
                          style: TextStyle(
                            color: Color(0xFF0F2544),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => controller
                            .setSelectedNavIndex(NurseNavIndex.annualCalendar),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Calendar',
                                style: TextStyle(
                                  color: Color(0xFF155EEF),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: Color(0xFF155EEF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PastelOperationTile(
                          icon: Icons.favorite_rounded,
                          label: 'Vitals',
                          bg: const Color(0xFFEAF3FF),
                          fg: const Color(0xFF155EEF),
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
                              controller
                                  .setSelectedNavIndex(NurseNavIndex.opd);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PastelOperationTile(
                          icon: Icons.medication_rounded,
                          label: 'Meds',
                          bg: const Color(0xFFE8F8F0),
                          fg: const Color(0xFF129A56),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MedicationsMarScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PastelOperationTile(
                          icon: Icons.water_drop_rounded,
                          label: 'Blood Bank',
                          bg: const Color(0xFFF3ECFF),
                          fg: const Color(0xFF7C3AED),
                          onTap: () => controller
                              .setSelectedNavIndex(NurseNavIndex.bloodBank),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PastelOperationTile(
                          icon: Icons.calendar_month_rounded,
                          label: 'Duty Roster',
                          bg: const Color(0xFFFFF3E4),
                          fg: const Color(0xFFD97706),
                          onTap: () => controller
                              .setSelectedNavIndex(NurseNavIndex.dutyRoster),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _titleCaseGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/// Top Sky-Blue Hospital Greeting Banner matching `image-16.png`
class _GreetingHospitalHeroCard extends StatelessWidget {
  final String greeting;
  final String firstName;

  const _GreetingHospitalHeroCard({
    required this.greeting,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC3DCFB), Color(0xFFE7F1FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A3977),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Right-side 3D Hospital Building Illustration
          Positioned(
            right: -4,
            top: 8,
            bottom: 0,
            width: 158,
            child: CustomPaint(
              painter: _DashboardHospitalArtPainter(),
            ),
          ),

          // Left-side Greeting Typography
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 132, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0C2D57),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0C2D57),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0x330C2D57),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.medical_information_rounded,
                        size: 16,
                        color: Color(0xFF0C2D57),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Nursing Desk – In-Patient Care, Vitals & Ward Management',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF284B7A),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

/// Architectural multi-wing Hospital Building artwork on the right of the Greeting card
class _DashboardHospitalArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft clouds
    final cloudPaint = Paint()..color = const Color(0x66FFFFFF);
    canvas.drawCircle(Offset(w * 0.25, h * 0.22), 18, cloudPaint);
    canvas.drawCircle(Offset(w * 0.38, h * 0.18), 22, cloudPaint);

    // Left wing
    final leftWing = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.42, w * 0.30, h * 0.56),
      const Radius.circular(5),
    );
    canvas.drawRRect(leftWing, Paint()..color = const Color(0xFFD6E6FA));

    // Right wing
    final rightWing = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.66, h * 0.36, w * 0.30, h * 0.62),
      const Radius.circular(5),
    );
    canvas.drawRRect(rightWing, Paint()..color = const Color(0xFFCEE0F8));

    // Center main hospital tower
    final mainTower = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.14, w * 0.44, h * 0.84),
      const Radius.circular(6),
    );
    canvas.drawRRect(mainTower, Paint()..color = const Color(0xFFF6FAFF));
    canvas.drawRRect(
      mainTower,
      Paint()
        ..color = const Color(0xFFB3CEF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Roof cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.12, w * 0.48, h * 0.05),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8AB4EC),
    );

    // Medical Cross Emblem on main tower
    final crossBg = Paint()..color = const Color(0xFFE1EEFE);
    canvas.drawCircle(Offset(w * 0.50, h * 0.28), 10, crossBg);
    final crossPaint = Paint()..color = const Color(0xFF1D68C4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.28),
          width: 4,
          height: 11,
        ),
        const Radius.circular(1),
      ),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.28),
          width: 11,
          height: 4,
        ),
        const Radius.circular(1),
      ),
      crossPaint,
    );

    // Windows on center tower & wings
    final winPaint = Paint()..color = const Color(0xFF7BA9E6);
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * (0.34 + col * 0.11),
              h * (0.42 + row * 0.13),
              w * 0.08,
              h * 0.08,
            ),
            const Radius.circular(2),
          ),
          winPaint,
        );
      }
    }
    for (int row = 0; row < 2; row++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * 0.12,
            h * (0.52 + row * 0.15),
            w * 0.12,
            h * 0.08,
          ),
          const Radius.circular(2),
        ),
        winPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * 0.75,
            h * (0.48 + row * 0.15),
            w * 0.13,
            h * 0.08,
          ),
          const Radius.circular(2),
        ),
        winPaint,
      );
    }

    // Entrance doors
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.41, h * 0.82, w * 0.18, h * 0.16),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1D68C4),
    );

    // Soft green trees at the base
    final treePaint = Paint()..color = const Color(0xFF5FA87A);
    canvas.drawCircle(Offset(w * 0.22, h * 0.90), 8, treePaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.89), 9, treePaint);
    canvas.drawCircle(Offset(w * 0.84, h * 0.92), 7, treePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SubtleCardEcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final y = h * 0.55;
    final paint = Paint()
      ..color = const Color(0xFFB8D1F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, y)
      ..lineTo(w * 0.22, y)
      ..lineTo(w * 0.30, y - 5)
      ..lineTo(w * 0.38, y + 9)
      ..lineTo(w * 0.48, y - 16)
      ..lineTo(w * 0.58, y + 12)
      ..lineTo(w * 0.67, y - 4)
      ..lineTo(w * 0.76, y)
      ..lineTo(w, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clean `image-16.png` KPI Card: Pastel Left Icon + Big Count/Label + Right Pill
class _SoftModernKpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String value;
  final String label;
  final String pillText;
  final Color pillBg;
  final Color pillFg;
  final VoidCallback onTap;

  const _SoftModernKpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.value,
    required this.label,
    required this.pillText,
    required this.pillBg,
    required this.pillFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4EEFA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0B3B78),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconFg, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F2544),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pillText,
                          style: TextStyle(
                            color: pillFg,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _WorkspaceActionPill({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF0A356A) : const Color(0xFFEEF4FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: primary ? Colors.white : const Color(0xFF0A356A),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary ? Colors.white : const Color(0xFF0F2544),
                  fontSize: 10.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastelOperationTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _PastelOperationTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
        color: const Color(0xFFF6F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2ECF9)),
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
                        fontSize: 14.5,
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
                            fontSize: 11.5,
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
                        color: Color(0xFF0A3977),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ipd.wardAndBedLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatSlashDate(ipd.admissionDate),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
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
                  icon: Icons.medication_rounded,
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
        foregroundColor: const Color(0xFF0F2544),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFDCE7F5)),
        minimumSize: const Size(0, 35),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: const Color(0xFF155EEF)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}
