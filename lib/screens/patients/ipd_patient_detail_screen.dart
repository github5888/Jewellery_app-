import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/status_badge.dart';
import '../clinical_actions/bed_transfer_sheet.dart';
import '../clinical_actions/discharge_checklist_screen.dart';
import '../clinical_actions/nursing_charge_sheet.dart';
import '../medications/medications_mar_screen.dart';
import '../notes/nursing_notes_screen.dart';
import '../vitals/record_vitals_screen.dart';
import '../vitals/vitals_history_screen.dart';

class IpdPatientDetailScreen extends StatefulWidget {
  final String ipdId;
  final IpdAdmission? initialAdmission;

  const IpdPatientDetailScreen({
    super.key,
    required this.ipdId,
    this.initialAdmission,
  });

  @override
  State<IpdPatientDetailScreen> createState() => _IpdPatientDetailScreenState();
}

class _IpdPatientDetailScreenState extends State<IpdPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  IpdAdmission? _admission;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _admission = widget.initialAdmission;
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    if (widget.ipdId.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await NursePortalScope.read(context)
          .api
          .fetchIpdPatientDetail(widget.ipdId);
      if (mounted) {
        setState(() {
          _admission = fresh;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openAddNoteModal() async {
    final ipd = _admission;
    if (ipd == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NursingNotesScreen(preselectedAdmission: ipd),
      ),
    );
    if (changed == true) {
      await _fetchDetail();
      if (mounted) {
        NursePortalScope.read(context).refreshWorkspace(silent: true);
      }
    }
  }

  Future<void> _onMenuAction(String value) async {
    final ipd = _admission;
    if (ipd == null) return;

    if (value == 'vitals') {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
        ),
      );
      if (ok == true) await _fetchDetail();
    } else if (value == 'transfer') {
      final ok = await showBedTransferSheet(context, ipd);
      if (ok == true) {
        await _fetchDetail();
        if (mounted) {
          NursePortalScope.read(context).refreshWorkspace(silent: true);
        }
      }
    } else if (value == 'charges') {
      final ok = await showNursingChargeSheet(context, ipd);
      if (ok == true) await _fetchDetail();
    } else if (value == 'checklist') {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DischargeChecklistScreen(admission: ipd),
        ),
      );
      if (ok == true) await _fetchDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final ipd = _admission;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Patient Details'),
        actions: [
          if (ipd != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: _onMenuAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'vitals',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.monitor_heart_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text('Record Bedside Vitals'),
                  ),
                ),
                PopupMenuItem(
                  value: 'transfer',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.teal,
                    ),
                    title: Text('Shift / Transfer Bed'),
                  ),
                ),
                PopupMenuItem(
                  value: 'charges',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.purple,
                    ),
                    title: Text('Log Nursing Procedure'),
                  ),
                ),
                PopupMenuItem(
                  value: 'checklist',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.fact_check_rounded,
                      color: AppColors.success,
                    ),
                    title: Text('Pre-Discharge Checklist'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ipd == null
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : ClinicalErrorState(
                  message: _error ?? 'Patient record could not be loaded.',
                  onRetry: _fetchDetail,
                ))
          : Column(
              children: [
                if (_loading)
                  const LinearProgressIndicator(minHeight: 2.5),

                // Patient Header Profile Card (matching image-2.png)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Column(
                    children: [
                      PatientAvatar(
                        name: ipd.patient.patientName,
                        imagePath: ipd.patient.image,
                        baseUrl: controller.baseUrl,
                        radius: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ipd.patient.patientName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.skySurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              ipd.patient.patientUniqueId.isNotEmpty
                                  ? ipd.patient.patientUniqueId
                                  : ipd.ipdNo,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label: ipd.clinicalStatusLabel,
                            showDot: true,
                          ),
                          if (ipd.patient.bloodGroup.isNotEmpty)
                            StatusBadge(
                              label: 'Blood: ${ipd.patient.bloodGroup}',
                            ),
                        ],
                      ),
                      if (ipd.patient.hasAllergyAlert) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF5B7BA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.danger,
                                size: 17,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Allergy Alert: ${ipd.patient.knownAllergies}',
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tabs (`Overview`, `Medical History`, `Prescriptions` — matching image-2.png)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.8,
                    labelStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Medical History'),
                      Tab(text: 'Prescriptions'),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(
                        ipd: ipd,
                        onRefresh: _fetchDetail,
                      ),
                      _MedicalHistoryTab(
                        ipd: ipd,
                        onAddNote: _openAddNoteModal,
                      ),
                      _PrescriptionsTab(
                        ipd: ipd,
                        onRefresh: _fetchDetail,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: ipd == null
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: ElevatedButton(
                onPressed: _openAddNoteModal,
                child: const Text('Add Nursing Note'),
              ),
            ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final IpdAdmission ipd;
  final Future<void> Function() onRefresh;

  const _OverviewTab({required this.ipd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final latestVital = ipd.latestVital;
    final shortBed = ipd.bed.replaceAll(RegExp(r'^Bed\s*', caseSensitive: false), '');

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          // 3 Demographic Boxes (`Age`, `Gender`, `Bed No.` — matching image-2.png)
          Row(
            children: [
              Expanded(
                child: _DemographicBox(
                  label: 'Age',
                  value: ipd.patient.age > 0 ? '${ipd.patient.age} Yrs' : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DemographicBox(
                  label: 'Gender',
                  value: ipd.patient.gender,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DemographicBox(
                  label: 'Bed No.',
                  value: shortBed.isNotEmpty ? shortBed : (ipd.bed.isNotEmpty ? ipd.bed : '—'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Vitals (Latest) Section (matching image-2.png)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vitals (Latest)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
                        ),
                      );
                      if (ok == true) await onRefresh();
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                    label: const Text('Record'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VitalsHistoryScreen(admission: ipd),
                        ),
                      );
                    },
                    child: const Text(
                      'View All →',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SoftSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: latestVital == null
                ? Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No bedside vitals recorded yet for this admission.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecordVitalsScreen(ipdAdmission: ipd),
                            ),
                          );
                          if (ok == true) await onRefresh();
                        },
                        child: const Text('Log Now'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _VitalMetricPill(
                            icon: Icons.favorite_rounded,
                            iconBg: AppColors.dangerSoft,
                            iconColor: AppColors.danger,
                            value: latestVital.pulse.isNotEmpty
                                ? latestVital.pulse
                                : '—',
                            unit: 'bpm',
                          ),
                          _VitalMetricPill(
                            icon: Icons.thermostat_rounded,
                            iconBg: AppColors.infoSoft,
                            iconColor: AppColors.primary,
                            value: latestVital.temperature.isNotEmpty
                                ? '${latestVital.temperature}°F'
                                : '—',
                            unit: 'Temp',
                          ),
                          _VitalMetricPill(
                            icon: Icons.bloodtype_rounded,
                            iconBg: AppColors.successSoft,
                            iconColor: AppColors.success,
                            value: latestVital.bp.isNotEmpty
                                ? latestVital.bp
                                : '—',
                            unit: 'mmHg',
                          ),
                        ],
                      ),
                      if (latestVital.spo2.isNotEmpty ||
                          latestVital.respiratoryRate.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SpO2: ${latestVital.spo2.isNotEmpty ? "${latestVital.spo2}%" : "—"}   •   RR: ${latestVital.respiratoryRate.isNotEmpty ? "${latestVital.respiratoryRate}/min" : "—"}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppFormatters.formatDateTimeShort(latestVital.date),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 18),

          // Current Treatment (Active Prescriptions — matching image-2.png)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Treatment',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (ipd.prescriptions.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MedicationsMarScreen(
                          filterIpdId: ipd.id,
                          patientTitle: ipd.patient.patientName,
                        ),
                      ),
                    );
                    await onRefresh();
                  },
                  child: const Text('Open MAR →'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (ipd.prescriptions.isEmpty)
            const SoftSurfaceCard(
              padding: EdgeInsets.all(14),
              child: Text(
                'No active prescriptions ordered by attending consultant yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ...ipd.prescriptions.take(3).map(
                  (rx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftSurfaceCard(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MedicationsMarScreen(
                              filterIpdId: ipd.id,
                              patientTitle: ipd.patient.patientName,
                            ),
                          ),
                        );
                        await onRefresh();
                      },
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.tealSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication_rounded,
                              color: AppColors.teal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rx.medicineName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (rx.dose.isNotEmpty) rx.dose,
                                    if (rx.frequency.isNotEmpty) rx.frequency,
                                    if (rx.instruction.isNotEmpty) rx.instruction,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: rx.status),
                        ],
                      ),
                    ),
                  ),
                ),

          const SizedBox(height: 10),

          // Admission & Attending Consultant Master Details
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admission & Care Team',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _DetailLine(label: 'IPD Number', value: ipd.ipdNo),
                if (ipd.caseReferenceId.isNotEmpty)
                  _DetailLine(label: 'Case Ref', value: ipd.caseReferenceId),
                _DetailLine(label: 'Ward / Bed', value: ipd.wardAndBedLabel),
                _DetailLine(
                  label: 'Attending Doctor',
                  value: ipd.doctor.displayName,
                ),
                if (ipd.department.isNotEmpty)
                  _DetailLine(label: 'Department', value: ipd.department),
                if (ipd.provisionalDiagnosis.isNotEmpty)
                  _DetailLine(
                    label: 'Diagnosis',
                    value: ipd.provisionalDiagnosis,
                  ),
                _DetailLine(
                  label: 'Admitted On',
                  value: AppFormatters.formatDateTimeShort(ipd.admissionDate),
                ),
                if (ipd.attendantName.isNotEmpty)
                  _DetailLine(
                    label: 'Attendant',
                    value: [
                      ipd.attendantName,
                      if (ipd.attendantRelation.isNotEmpty)
                        '(${ipd.attendantRelation})',
                      if (ipd.attendantPhone.isNotEmpty) ipd.attendantPhone,
                    ].join(' '),
                  ),
                if (ipd.patient.abhaNumber.isNotEmpty)
                  _DetailLine(label: 'ABHA ID', value: ipd.patient.abhaNumber),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Bedside Quick Nurse Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showBedTransferSheet(context, ipd);
                    if (ok == true) await onRefresh();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Shift Bed'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            DischargeChecklistScreen(admission: ipd),
                      ),
                    );
                    if (ok == true) await onRefresh();
                  },
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: Text(
                    'Checklist (${ipd.dischargeChecklist.completedItemsCount}/9)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicalHistoryTab extends StatelessWidget {
  final IpdAdmission ipd;
  final VoidCallback onAddNote;

  const _MedicalHistoryTab({required this.ipd, required this.onAddNote});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        if (ipd.provisionalDiagnosis.isNotEmpty) ...[
          SoftSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provisional Diagnosis',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ipd.provisionalDiagnosis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Doctor Consultant Register / Round Instructions
        const Text(
          'Doctor Rounds & Treatment Instructions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (ipd.consultantRegister.isEmpty)
          const SoftSurfaceCard(
            padding: EdgeInsets.all(14),
            child: Text(
              'No consultant round instructions logged yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...ipd.consultantRegister.map(
            (ins) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ins.doctorName.isNotEmpty
                              ? ins.doctorName
                              : ipd.doctor.displayName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDateTimeShort(ins.date),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ins.instruction,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 18),

        // Shift Nurse Progress Notes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shift Nursing Progress Notes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton.icon(
              onPressed: onAddNote,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Note'),
            ),
          ],
        ),
        if (ipd.nurseNotes.isEmpty)
          const SoftSurfaceCard(
            padding: EdgeInsets.all(14),
            child: Text(
              'No shift care notes recorded yet. Tap "Add Nursing Note" below to log observations.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...ipd.nurseNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          note.nurseName,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDateTimeShort(note.date),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.note,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (note.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remark: ${note.comment}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        if (ipd.investigations.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Ordered Investigations',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...ipd.investigations.map(
            (inv) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftSurfaceCard(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    const Icon(Icons.science_rounded, color: AppColors.purple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.testName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (inv.resultSummary.isNotEmpty)
                            Text(
                              inv.resultSummary,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(label: inv.status),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrescriptionsTab extends StatelessWidget {
  final IpdAdmission ipd;
  final Future<void> Function() onRefresh;

  const _PrescriptionsTab({required this.ipd, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (ipd.prescriptions.isEmpty) {
      return const ClinicalEmptyState(
        icon: Icons.medication_outlined,
        title: 'No Prescriptions Ordered',
        subtitle:
            'Medications prescribed by the attending doctor appear here for bedside MAR administration.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      itemCount: ipd.prescriptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final rx = ipd.prescriptions[idx];
        return SoftSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rx.medicineName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(label: rx.status),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                [
                  if (rx.prescriptionNo.isNotEmpty) rx.prescriptionNo,
                  if (rx.dose.isNotEmpty) rx.dose,
                  if (rx.frequency.isNotEmpty) rx.frequency,
                  if (rx.duration.isNotEmpty) rx.duration,
                ].join(' • '),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rx.instruction.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Instruction: ${rx.instruction}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
              if (rx.administeredAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Last logged: ${AppFormatters.formatDateTimeShort(rx.administeredAt)}'
                  '${rx.administeredBy.isNotEmpty ? " by ${rx.administeredBy}" : ""}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MedicationsMarScreen(
                          filterIpdId: ipd.id,
                          patientTitle: ipd.patient.patientName,
                        ),
                      ),
                    );
                    await onRefresh();
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                  label: Text(rx.isGiven ? 'Update MAR' : 'Administer Dose'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DemographicBox extends StatelessWidget {
  final String label;
  final String value;

  const _DemographicBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalMetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String unit;

  const _VitalMetricPill({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
