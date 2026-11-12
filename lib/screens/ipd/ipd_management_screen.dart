import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../beds/bed_status_screen.dart';
import '../patients/ipd_patient_detail_screen.dart';
import '../patients/patient_detail_screen.dart';
import 'discharge_card_preview_modal.dart';

/// Executive Mobile IPD In-Patient Ward Screen (`GET /api/ipd`):
/// - Studio-lit `PremiumScreenBackground` + `MobileScreenHeader` + `Bed Matrix` capsule
/// - 4-Card Sculpted Inpatient Telemetry Strip (`Admitted`, `Occupied`, `Vacant`, `Ward Dues`)
/// - Capsule Segmented Toggle (`Active Ward` / `Discharged`) + `Antenatal` ruby badge
/// - `PremiumSearchField` + OneMedical-style Inpatient Pass Cards (`Open Chart`, `Vitals`, `Meds`).
class IpdManagementScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const IpdManagementScreen({
    super.key,
    this.isEmbeddedInShell = false,
  });

  @override
  State<IpdManagementScreen> createState() => _IpdManagementScreenState();
}

class _IpdManagementScreenState extends State<IpdManagementScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final showDischarged = controller.ipdShowDischarged;
    final sourceList = showDischarged
        ? controller.dischargedPatients
        : controller.admittedPatients;

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = sourceList.where((ipd) {
      if (q.isEmpty) return true;
      return ipd.patient.patientName.toLowerCase().contains(q) ||
          ipd.patient.patientUniqueId.toLowerCase().contains(q) ||
          ipd.patient.mobileNo.toLowerCase().contains(q) ||
          ipd.ipdNo.toLowerCase().contains(q) ||
          ipd.caseReferenceId.toLowerCase().contains(q) ||
          ipd.bed.toLowerCase().contains(q) ||
          ipd.bedGroup.toLowerCase().contains(q) ||
          ipd.doctor.displayName.toLowerCase().contains(q);
    }).toList();

    final content = RefreshIndicator(
      color: primary,
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: 'IPD Ward',
              subtitle: 'Inpatient care, bedside charts, vitals & MAR',
              countBadge: '${controller.activePatientsCount} Active',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(14),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_view_rounded, size: 15, color: primary),
                      const SizedBox(width: 5),
                      const Text(
                        'Beds',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4-Metric Sculpted IPD Summary Strip
          Row(
            children: [
              Expanded(
                child: _IpdMetricBox(
                  value: '${controller.activePatientsCount}',
                  label: 'Admitted',
                  accent: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IpdMetricBox(
                  value: '${controller.occupiedBedsCount}',
                  label: 'Occupied',
                  accent: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IpdMetricBox(
                  value: '${controller.availableBedsCount}',
                  label: 'Vacant',
                  accent: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IpdMetricBox(
                  value: AppFormatters.formatCurrencyInr(
                    controller.ipdOutstandingDues,
                  ),
                  label: 'Ward Dues',
                  accent: const Color(0xFFE11D48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Segmented Active / Discharged Toggle + Antenatal Pill
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SegmentPill(
                  label: 'Active Ward (${controller.activePatientsCount})',
                  selected: !showDischarged,
                  primary: primary,
                  onTap: () => controller.setIpdShowDischarged(false),
                ),
                const SizedBox(width: 8),
                _SegmentPill(
                  label: 'Discharged (${controller.dischargedPatientsCount})',
                  selected: showDischarged,
                  primary: primary,
                  onTap: () => controller.setIpdShowDischarged(true),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Text(
                    '♥ Antenatal: ${controller.ipdAntenatalCount}',
                    style: const TextStyle(
                      color: Color(0xFFBE123C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Elevated Pill Search Box
          PremiumSearchField(
            controller: _searchCtrl,
            accentColor: primary,
            hintText: 'Search patient, UHID, ward bed or doctor...',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.hotel_outlined,
                title: showDischarged
                    ? 'No Discharged IPD Records'
                    : 'No Active IPD Admissions',
                subtitle: _searchCtrl.text.isNotEmpty
                    ? 'No IPD records matched your search query.'
                    : 'Inpatient records from /api/ipd appear here.',
              ),
            )
          else
            ...filtered.map(
              (ipd) => _IpdAdmissionDetailCard(
                ipd: ipd,
                primaryColor: primary,
              ),
            ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return PremiumScreenBackground(
        accentColor: primary,
        child: SafeArea(bottom: false, child: content),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('IPD - In Patient')),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: content,
      ),
    );
  }
}

class _IpdMetricBox extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _IpdMetricBox({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFeatures: AppTheme.tabularNums,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primary : AppColors.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withAlpha(55),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IpdAdmissionDetailCard extends StatelessWidget {
  final IpdAdmission ipd;
  final Color primaryColor;

  const _IpdAdmissionDetailCard({
    required this.ipd,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = AppFormatters.formatTime24h(ipd.admissionDate);
    final initials = AppFormatters.initials(ipd.patient.patientName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          ipd.ipdNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFeatures: AppTheme.tabularNums,
                          ),
                        ),
                      ),
                      if (ipd.caseReferenceId.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Case #${ipd.caseReferenceId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withAlpha(36)),
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
                        Flexible(
                          child: Text(
                            ipd.wardAndBedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        primaryColor.withAlpha(30),
                        primaryColor.withAlpha(12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (ipd.patient.patientUniqueId.isNotEmpty)
                            ipd.patient.patientUniqueId,
                          '${ipd.patient.gender}${ipd.patient.age > 0 ? " (${ipd.patient.age}y)" : ""}',
                          if (ipd.patient.mobileNo.isNotEmpty)
                            ipd.patient.mobileNo,
                        ].join('  •  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
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
                      '${ipd.doctor.displayName}${ipd.department.isNotEmpty ? " • ${ipd.department}" : ""}',
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
                    '${AppFormatters.formatSlashDate(ipd.admissionDate)}${timeStr.isNotEmpty ? " • $timeStr" : ""}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (ipd.isDischarged)
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                              initialTabIndex: 0,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                      label: const Text(
                        'Open Chart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: _IpdQuickPillBtn(
                      icon: Icons.print_outlined,
                      label: 'Print Card',
                      fg: const Color(0xFF035C7A),
                      bg: const Color(0xFFE0F2FE),
                      onTap: () => showDischargeCardPreviewModal(
                        context,
                        admission: ipd,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _IpdQuickPillBtn(
                      icon: Icons.person_outline_rounded,
                      label: 'Details',
                      fg: const Color(0xFF059669),
                      bg: AppColors.successSoft,
                      onTap: () => _openFullPatientProfile(context, ipd),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                              initialTabIndex: 0,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                      label: const Text(
                        'Open Chart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _IpdQuickPillBtn(
                      icon: Icons.favorite_rounded,
                      label: 'Vitals',
                      fg: const Color(0xFFE11D48),
                      bg: const Color(0xFFFFF1F2),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IpdPatientDetailScreen(
                              ipdId: ipd.id,
                              initialAdmission: ipd,
                              initialTabIndex: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _IpdQuickPillBtn(
                      icon: Icons.medication_rounded,
                      label: 'Meds',
                      fg: const Color(0xFF6D28D9),
                      bg: const Color(0xFFF5F3FF),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IpdPatientDetailScreen(
                              ipdId: ipd.id,
                              initialAdmission: ipd,
                              initialTabIndex: 2,
                              initialOrderSubTab: 0,
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

  void _openFullPatientProfile(BuildContext context, IpdAdmission ipd) {
    final ctrl = NursePortalScope.read(context);
    final pat = ipd.patient;
    PatientDirectoryRecord? match;
    for (final item in ctrl.patientDirectory) {
      if ((pat.id.isNotEmpty && item.id == pat.id) ||
          (pat.patientUniqueId.isNotEmpty &&
              item.patientUniqueId.toLowerCase() ==
                  pat.patientUniqueId.toLowerCase())) {
        match = item;
        break;
      }
    }
    final record = match ??
        PatientDirectoryRecord(
          id: pat.id,
          patientUniqueId: pat.patientUniqueId,
          patientName: pat.patientName,
          age: pat.age,
          dob: pat.dob,
          gender: pat.gender,
          bloodGroup: pat.bloodGroup,
          phone: pat.mobileNo,
          address: pat.address,
          guardianName: pat.guardianName,
          knownAllergies: pat.knownAllergies,
          abhaNumber: pat.abhaNumber,
          abhaAddress: pat.abhaAddress,
          dueBalance: ipd.outstandingDue,
          image: pat.image,
        );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(initialPatient: record),
      ),
    );
  }
}

class _IpdQuickPillBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  const _IpdQuickPillBtn({
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
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
