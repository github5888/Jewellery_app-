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

/// IPD - In Patient Management Screen (`https://hospital.hrpocket.in/ipd` — matches image-8 1-to-1):
/// - Top 4 KPI Cards: `ACTIVE INPATIENTS`, `OCCUPIED BEDS`, `AVAILABLE BEDS`, `OUTSTANDING DUES`
/// - `IPD In-Patient Management` + `Antenatal: N` badge + `[Discharged Patients]` toggle + `[Bed Status]`
/// - Search box: `Search by name, UHID, bed, doctor...`
/// - Admission Cards: `IPDN408751`, `CASE408747`, `Manish yadav`, `PAT-1003 • Male (22y)`, `6392036589`,
///   `21/10/2026 • 16:01`, `Planned`, `VIP / BED-002`, `Dr. Ajay Verma`, `[Chart]`, `[Vitals]`, `[Meds]`
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

    final body = RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          // Top 4 KPI Cards (matching image-8)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _IpdTopStatCard(
                topColor: const Color(0xFF0284C7),
                label: 'ACTIVE INPATIENTS',
                value: '${controller.activePatientsCount}',
                subtitle: 'Currently admitted',
                icon: Icons.hotel_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconFg: const Color(0xFF0284C7),
              ),
              _IpdTopStatCard(
                topColor: const Color(0xFF9333EA),
                label: 'OCCUPIED BEDS',
                value: '${controller.occupiedBedsCount}',
                subtitle: 'Allocated beds',
                icon: Icons.bed_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconFg: const Color(0xFF9333EA),
              ),
              _IpdTopStatCard(
                topColor: const Color(0xFF16A34A),
                label: 'AVAILABLE BEDS',
                value: '${controller.availableBedsCount}',
                subtitle: 'From Bed Setup',
                icon: Icons.check_circle_outline_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconFg: const Color(0xFF16A34A),
              ),
              _IpdTopStatCard(
                topColor: const Color(0xFFE11D48),
                label: 'OUTSTANDING DUES',
                value: AppFormatters.formatCurrencyInr(
                  controller.ipdOutstandingDues,
                ),
                subtitle: 'Unpaid inpatient bills',
                icon: Icons.credit_card_rounded,
                iconBg: const Color(0xFFFFE4E6),
                iconFg: const Color(0xFFE11D48),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main IPD Management Container Card (matching image-8)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A4D78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.hotel_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                showDischarged
                                    ? 'Discharged IPD Patients'
                                    : 'IPD In-Patient Management',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE7F3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '♥ Antenatal: ${controller.ipdAntenatalCount}',
                                  style: const TextStyle(
                                    color: Color(0xFFBE185D),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Patient admission, bed allocation, inpatient treatment, billing, transfer & discharge workflow',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Toggle buttons (`Discharged Patients` / `Active Admissions` + `Bed Status`)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: showDischarged
                            ? Colors.white
                            : AppColors.textPrimary,
                        backgroundColor: showDischarged
                            ? const Color(0xFF0A4D78)
                            : Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () =>
                          controller.setIpdShowDischarged(!showDischarged),
                      icon: Icon(
                        Icons.list_rounded,
                        size: 16,
                        color: showDischarged
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      label: Text(
                        showDischarged
                            ? 'Active Inpatients (${controller.activePatientsCount})'
                            : 'Discharged Patients (${controller.dischargedPatientsCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0A4D78),
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BedStatusScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bed_rounded, size: 16),
                      label: const Text(
                        'Bed Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Search Box (`Search by name, UHID, bed, doctor...` — image-8)
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name, UHID, bed, doctor...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
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
                  ClinicalEmptyState(
                    icon: Icons.hotel_outlined,
                    title: showDischarged
                        ? 'No Discharged IPD Records'
                        : 'No Active IPD Admissions',
                    subtitle: _searchCtrl.text.isNotEmpty
                        ? 'No IPD records matched your search query.'
                        : 'Records from /api/ipd will appear here.',
                  )
                else
                  ...filtered.map(
                    (ipd) => _IpdAdmissionDetailCard(ipd: ipd),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('IPD - In Patient')),
      body: body,
    );
  }
}

class _IpdTopStatCard extends StatelessWidget {
  final Color topColor;
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

  const _IpdTopStatCard({
    required this.topColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 3.5, color: topColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: topColor == const Color(0xFF16A34A)
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconFg, size: 19),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IpdAdmissionDetailCard extends StatelessWidget {
  final IpdAdmission ipd;

  const _IpdAdmissionDetailCard({required this.ipd});

  @override
  Widget build(BuildContext context) {
    final timeStr = AppFormatters.formatTime24h(ipd.admissionDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ADMISSION & PATIENT (matching image-8)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADMISSION',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hotel_rounded,
                            size: 13,
                            color: Color(0xFF3730A3),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              ipd.ipdNo,
                              style: const TextStyle(
                                color: Color(0xFF3730A3),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ipd.caseReferenceId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📁 ${ipd.caseReferenceId}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PATIENT',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ipd.patient.patientName,
                      style: const TextStyle(
                        color: Color(0xFF0A4D78),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (ipd.patient.patientUniqueId.isNotEmpty)
                          ipd.patient.patientUniqueId,
                        '${ipd.patient.gender}${ipd.patient.age > 0 ? " (${ipd.patient.age}y)" : ""}',
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11.5,
                      ),
                    ),
                    if (ipd.patient.mobileNo.isNotEmpty)
                      Text(
                        '📞 ${ipd.patient.mobileNo}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Row 2: ADMITTED, TYPE, WARD/BED, DOCTOR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADMITTED',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppFormatters.formatSlashDate(ipd.admissionDate),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TYPE & BED',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ipd.admissionType,
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ipd.wardAndBedLabel,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Attending: ${ipd.doctor.displayName}${ipd.department.isNotEmpty ? " (${ipd.department})" : ""}',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons (`Chart`, `Vitals`, `Meds`)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4D78),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A4D78),
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_rounded, size: 15),
                    label:
                        const Text('Vitals', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A4D78),
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    icon: const Icon(Icons.medical_services_rounded, size: 15),
                    label: const Text('Meds', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
