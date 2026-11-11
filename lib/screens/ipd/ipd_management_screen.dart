import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../beds/bed_status_screen.dart';
import '../medications/medications_mar_screen.dart';
import '../patients/ipd_patient_detail_screen.dart';
import '../vitals/record_vitals_screen.dart';

/// Native Mobile IPD In-Patient Management Screen (`GET /api/ipd`):
/// - Clean `MobileScreenHeader` + `Bed Status` shortcut
/// - 4-Card Inpatient KPI Summary (`Active`, `Occupied Beds`, `Free Beds`, `Dues`)
/// - Segmented toggle (`Active Inpatients` / `Discharged`) + `Antenatal: N` pill
/// - Search (`Search by name, UHID, bed, doctor...`)
/// - Floating white Inpatient Cards with `Chart`, `Vitals`, `Meds`.
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
              subtitle: 'Inpatient care, bedside chart, vitals & MAR',
              countBadge: '${controller.activePatientsCount} Active',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BedStatusScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bed_rounded, size: 16, color: primary),
                      const SizedBox(width: 5),
                      const Text(
                        'Beds',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4-Metric IPD Summary Strip
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
                  label: 'Free Beds',
                  accent: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IpdMetricBox(
                  value: AppFormatters.formatCurrencyInr(
                    controller.ipdOutstandingDues,
                  ),
                  label: 'Dues',
                  accent: const Color(0xFFE11D48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Segmented Active / Discharged Toggle + Antenatal Pill
          Row(
            children: [
              _SegmentPill(
                label: 'Active (${controller.activePatientsCount})',
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
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '♥ Antenatal: ${controller.ipdAntenatalCount}',
                  style: const TextStyle(
                    color: Color(0xFFBE123C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, UHID, bed, doctor...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 14),

          if (filtered.isEmpty)
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.hotel_outlined,
                title: showDischarged
                    ? 'No Discharged IPD Records'
                    : 'No Active IPD Admissions',
                subtitle: _searchCtrl.text.isNotEmpty
                    ? 'No IPD records matched your search.'
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
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('IPD - In Patient')),
      body: content,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
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
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ipd.ipdNo,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (ipd.caseReferenceId.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    ipd.caseReferenceId,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ipd.wardAndBedLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatSlashDate(ipd.admissionDate),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        '$timeStr • ${ipd.admissionType}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              'Consultant: ${ipd.doctor.displayName}${ipd.department.isNotEmpty ? " (${ipd.department})" : ""}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
                    label: const Text('Chart', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                if (!ipd.isDischarged) ...[
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
                            builder: (_) =>
                                RecordVitalsScreen(ipdAdmission: ipd),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.favorite_border_rounded,
                        size: 15,
                        color: primaryColor,
                      ),
                      label:
                          const Text('Vitals', style: TextStyle(fontSize: 12.5)),
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
                      label:
                          const Text('Meds', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
