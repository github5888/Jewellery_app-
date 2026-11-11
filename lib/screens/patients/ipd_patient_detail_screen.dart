import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/clinical_report_model.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/status_badge.dart';
import '../clinical_actions/bed_transfer_sheet.dart';
import '../clinical_actions/nursing_charge_sheet.dart';
import '../notes/nursing_notes_screen.dart';
import '../reports/report_viewer_screen.dart';
import '../vitals/record_vitals_screen.dart';

/// Full Bedside IPD Clinical Chart (`GET /api/ipd/:id`)
/// Matches the 5-tab website modal (`Admission Overview`, `Vitals & Findings`,
/// `Treatment & Orders`, `Bed & Nursing`, `Discharge Checklist`) with 100% live API integration.
class IpdPatientDetailScreen extends StatefulWidget {
  final String ipdId;
  final IpdAdmission? initialAdmission;
  final int initialTabIndex;
  final int initialOrderSubTab;

  const IpdPatientDetailScreen({
    super.key,
    required this.ipdId,
    this.initialAdmission,
    this.initialTabIndex = 0,
    this.initialOrderSubTab = 0,
  });

  @override
  State<IpdPatientDetailScreen> createState() => _IpdPatientDetailScreenState();
}

class _IpdPatientDetailScreenState extends State<IpdPatientDetailScreen> {
  IpdAdmission? _admission;
  bool _loading = true;
  String? _error;

  late int _activeTab;
  late int _activeOrderSubTab;

  // Inline Discharge Checklist state (Tab 4)
  late DischargeChecklist _draftChecklist;
  late TextEditingController _checklistNotesCtrl;
  bool _savingChecklist = false;
  bool _checklistDirty = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex.clamp(0, 4);
    _activeOrderSubTab = widget.initialOrderSubTab.clamp(0, 3);
    _admission = widget.initialAdmission;
    _draftChecklist =
        widget.initialAdmission?.dischargeChecklist ?? const DischargeChecklist();
    _checklistNotesCtrl = TextEditingController(
      text: _draftChecklist.checklistNotes,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  @override
  void dispose() {
    _checklistNotesCtrl.dispose();
    super.dispose();
  }

  void _syncChecklistFromAdmission(IpdAdmission fresh) {
    if (_checklistDirty) return;
    _draftChecklist = fresh.dischargeChecklist;
    _checklistNotesCtrl.text = fresh.dischargeChecklist.checklistNotes;
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = NursePortalScope.read(context).api;
      final fresh = await api.fetchIpdPatientDetail(widget.ipdId);
      if (mounted) {
        setState(() {
          _admission = fresh;
          _syncChecklistFromAdmission(fresh);
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

  Future<void> _refreshAll() async {
    _checklistDirty = false;
    await _loadDetail();
    if (!mounted) return;
    await NursePortalScope.read(context).refreshWorkspace(silent: true);
  }

  Future<void> _openRecordVitals(IpdAdmission ipd) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
      ),
    );
    if (saved == true && mounted) {
      await _refreshAll();
    }
  }

  Future<void> _openAddNurseNote(IpdAdmission ipd) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NursingNotesScreen(preselectedAdmission: ipd),
      ),
    );
    if (saved == true && mounted) {
      await _refreshAll();
    }
  }

  Future<void> _openTransferBed(IpdAdmission ipd) async {
    final shifted = await showBedTransferSheet(context, ipd);
    if (shifted == true && mounted) {
      await _refreshAll();
    }
  }

  Future<void> _openAddCharge(IpdAdmission ipd) async {
    final added = await showNursingChargeSheet(context, ipd);
    if (added == true && mounted) {
      await _refreshAll();
    }
  }

  Future<void> _administerSingleMedication(
    IpdAdmission ipd,
    MedicationPrescription rx,
  ) async {
    if (rx.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription ID unavailable for MAR logging.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    String chosenStatus = 'Given';
    final remarksCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final inset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, inset + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Log Medication Administration',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rx.medicineName}${rx.dose.isNotEmpty ? ' • ${rx.dose}' : ''}${rx.frequency.isNotEmpty ? ' • ${rx.frequency}' : ''}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Given', 'Held', 'Refused', 'Missed'].map((st) {
                      final selected = chosenStatus == st;
                      return ChoiceChip(
                        label: Text(st),
                        selected: selected,
                        selectedColor: const Color(0xFF0F2942),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) =>
                            setModalState(() => chosenStatus = st),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Administration Remarks (Optional)',
                      hintText: 'e.g. Dose administered after meals, tolerated well',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2942),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text('Confirm • Mark as $chosenStatus'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final controller = NursePortalScope.read(context);
    final nurse = controller.currentUser;
    try {
      await controller.api.administerMedication(
        ipdId: ipd.id,
        prescriptionId: rx.id,
        status: chosenStatus,
        remarks: remarksCtrl.text.trim(),
        administeredBy: nurse?.fullName,
        administeredById: nurse?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${rx.medicineName} marked as "$chosenStatus".'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log medication dose: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _saveDischargeChecklist(IpdAdmission ipd) async {
    FocusScope.of(context).unfocus();
    setState(() => _savingChecklist = true);
    final updated = _draftChecklist.copyWith(
      checklistNotes: _checklistNotesCtrl.text.trim(),
    );
    try {
      final controller = NursePortalScope.read(context);
      await controller.api.updateDischargeChecklist(
        ipdId: ipd.id,
        checklist: updated,
      );
      _checklistDirty = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nursing discharge handover checklist saved.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save discharge checklist: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingChecklist = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ipd = _admission;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: ipd == null
          ? SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const ClinicalLoadingState(
                            message: 'Loading patient clinical chart...',
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: ClinicalErrorState(
                              message:
                                  _error ?? 'Unable to load IPD clinical chart.',
                              onRetry: _loadDetail,
                            ),
                          ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _WebsiteChartBanner(
                  ipd: ipd,
                  loading: _loading,
                  onBack: () => Navigator.of(context).pop(),
                  onRefresh: _loadDetail,
                ),
                _ClinicalTabStrip(
                  activeIndex: _activeTab,
                  onSelect: (idx) => setState(() => _activeTab = idx),
                ),
                if (_loading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF1D4ED8),
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF1D4ED8),
                    onRefresh: _refreshAll,
                    child: _buildActiveTabBody(ipd),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActiveTabBody(IpdAdmission ipd) {
    switch (_activeTab) {
      case 0:
        return _buildAdmissionOverviewTab(ipd);
      case 1:
        return _buildVitalsAndFindingsTab(ipd);
      case 2:
        return _buildTreatmentAndOrdersTab(ipd);
      case 3:
        return _buildBedAndNursingTab(ipd);
      case 4:
        return _buildDischargeChecklistTab(ipd);
      default:
        return _buildAdmissionOverviewTab(ipd);
    }
  }

  // ===========================================================================
  // TAB 0: ADMISSION OVERVIEW (Screenshot 748 & 749)
  // ===========================================================================

  Widget _buildAdmissionOverviewTab(IpdAdmission ipd) {
    final pat = ipd.patient;
    final genderAge = [
      if (pat.gender.isNotEmpty) pat.gender,
      if (pat.ageLabel.isNotEmpty && pat.ageLabel != '—') pat.ageLabel,
    ].join(' / ');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Card 1: Patient Information
        _ChartSectionCard(
          icon: Icons.person_outline_rounded,
          iconColor: const Color(0xFF2563EB),
          title: 'Patient Information',
          child: Column(
            children: [
              _OverviewKeyValueRow(
                label: 'Full Name:',
                value: pat.patientName,
                valueWeight: FontWeight.w800,
              ),
              _OverviewKeyValueRow(
                label: 'UHID:',
                value: pat.patientUniqueId.isEmpty ? '-' : pat.patientUniqueId,
                valueWeight: FontWeight.w700,
              ),
              _OverviewKeyValueRow(
                label: 'Gender / Age:',
                value: genderAge.isEmpty ? '-' : genderAge,
              ),
              _OverviewKeyValueRow(
                label: 'Blood Group:',
                value: pat.bloodGroup.isEmpty ? 'Not Specified' : pat.bloodGroup,
                valueColor: pat.bloodGroup.isEmpty
                    ? AppColors.textSecondary
                    : const Color(0xFFDC2626),
                valueWeight:
                    pat.bloodGroup.isEmpty ? FontWeight.w600 : FontWeight.w800,
              ),
              _OverviewKeyValueRow(
                label: 'Phone Number:',
                value: pat.phone.isEmpty ? '-' : pat.phone,
              ),
              _OverviewKeyValueRow(
                label: 'Guardian:',
                value: pat.guardianName.isEmpty ? '-' : pat.guardianName,
              ),
              _OverviewKeyValueRow(
                label: 'Address:',
                value: pat.address.isEmpty ? '-' : pat.address,
              ),
              _OverviewKeyValueRow(
                label: 'Known Allergies:',
                value: pat.knownAllergies.isEmpty
                    ? 'None recorded'
                    : pat.knownAllergies,
                valueColor: pat.knownAllergies.isEmpty
                    ? AppColors.textSecondary
                    : const Color(0xFFDC2626),
                valueWeight: pat.knownAllergies.isEmpty
                    ? FontWeight.w500
                    : FontWeight.w700,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 2: Clinical Admission Details
        _ChartSectionCard(
          icon: Icons.medical_information_outlined,
          iconColor: const Color(0xFF2563EB),
          title: 'Clinical Admission Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OverviewKeyValueRow(
                label: 'Admission No:',
                value: ipd.ipdNo,
                valueColor: const Color(0xFF2563EB),
                valueWeight: FontWeight.w800,
              ),
              _OverviewKeyValueRow(
                label: 'Case ID:',
                value: ipd.caseReferenceId.isEmpty ? '-' : ipd.caseReferenceId,
                valueWeight: FontWeight.w700,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Admission Type:',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: ipd.admissionType.toLowerCase() == 'emergency'
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ipd.admissionType.isEmpty ? 'Planned' : ipd.admissionType,
                        style: TextStyle(
                          color: ipd.admissionType.toLowerCase() == 'emergency'
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF1D4ED8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _OverviewKeyValueRow(
                label: 'Department:',
                value: ipd.department.isEmpty ? '-' : ipd.department,
                valueWeight: FontWeight.w700,
              ),
              _OverviewKeyValueRow(
                label: 'Consultant Doctor:',
                value: ipd.doctor.displayName,
                valueWeight: FontWeight.w800,
              ),
              _OverviewKeyValueRow(
                label: 'Referring Doctor:',
                value: ipd.referringDoctor.isEmpty
                    ? 'Self / Hospital OPD'
                    : ipd.referringDoctor,
              ),
              _OverviewKeyValueRow(
                label: 'Casualty:',
                value: ipd.isCasualty ? 'Yes' : 'No',
                valueColor: ipd.isCasualty
                    ? const Color(0xFFDC2626)
                    : AppColors.textPrimary,
              ),
              _OverviewKeyValueRow(
                label: 'Antenatal:',
                value: ipd.isAntenatal ? 'Yes' : 'No',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              const Text(
                'Provisional Diagnosis:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  ipd.provisionalDiagnosis.isEmpty
                      ? 'No provisional diagnosis specified at admission'
                      : ipd.provisionalDiagnosis,
                  style: TextStyle(
                    color: ipd.provisionalDiagnosis.isEmpty
                        ? const Color(0xFF64748B)
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: ipd.provisionalDiagnosis.isEmpty
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Presenting Complaint / Reason:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  ipd.presentingComplaint.isEmpty
                      ? 'No presenting complaint recorded'
                      : ipd.presentingComplaint,
                  style: TextStyle(
                    color: ipd.presentingComplaint.isEmpty
                        ? const Color(0xFF64748B)
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: ipd.presentingComplaint.isEmpty
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 3: Ward, Attendant & Payer
        _ChartSectionCard(
          icon: Icons.bed_rounded,
          iconColor: const Color(0xFF2563EB),
          title: 'Ward, Attendant & Payer',
          child: Column(
            children: [
              _OverviewKeyValueRow(
                label: 'Current Bed:',
                value: ipd.bed.isEmpty ? 'Unassigned' : ipd.bed,
                valueColor: const Color(0xFF059669),
                valueWeight: FontWeight.w800,
              ),
              _OverviewKeyValueRow(
                label: 'Ward / Bed Group:',
                value: ipd.bedGroup.isEmpty ? '-' : ipd.bedGroup,
                valueWeight: FontWeight.w700,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              _OverviewKeyValueRow(
                label: 'Attendant Name:',
                value: ipd.attendantName.isEmpty ? '-' : ipd.attendantName,
              ),
              _OverviewKeyValueRow(
                label: 'Relationship:',
                value:
                    ipd.attendantRelation.isEmpty ? '-' : ipd.attendantRelation,
              ),
              _OverviewKeyValueRow(
                label: 'Attendant Phone:',
                value: ipd.attendantPhone.isEmpty ? '-' : ipd.attendantPhone,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              _OverviewKeyValueRow(
                label: 'Payer Type:',
                value: ipd.payerType.isEmpty ? 'Self-pay' : ipd.payerType,
                valueWeight: FontWeight.w700,
              ),
              _OverviewKeyValueRow(
                label: 'TPA / Insurance:',
                value: ipd.tpaInsurance.isEmpty ? 'None' : ipd.tpaInsurance,
              ),
              _OverviewKeyValueRow(
                label: 'Credit Limit:',
                value: AppFormatters.formatCurrencyInr(ipd.creditLimit),
                valueWeight: FontWeight.w800,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: VITALS & FINDINGS (Screenshot 750)
  // ===========================================================================

  Widget _buildVitalsAndFindingsTab(IpdAdmission ipd) {
    final latest = ipd.latestVital;
    final sortedVitals = List<VitalSignRecord>.from(ipd.vitals)
      ..sort((a, b) {
        final da = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // 6 Website Latest Vital Cards (2x3 Grid on mobile)
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.08,
          children: [
            _WebsiteVitalStatBox(
              label: 'Blood Pressure',
              value: latest != null && latest.bp.isNotEmpty ? latest.bp : '-',
              unit: 'mmHg',
            ),
            _WebsiteVitalStatBox(
              label: 'Pulse',
              value:
                  latest != null && latest.pulse.isNotEmpty ? latest.pulse : '-',
              unit: 'bpm',
            ),
            _WebsiteVitalStatBox(
              label: 'Temperature',
              value: latest != null && latest.temperature.isNotEmpty
                  ? latest.temperature
                  : '-',
              unit: '°F',
            ),
            _WebsiteVitalStatBox(
              label: 'SpO₂',
              value:
                  latest != null && latest.spo2.isNotEmpty ? latest.spo2 : '-',
              unit: '%',
            ),
            _WebsiteVitalStatBox(
              label: 'Weight',
              value: latest != null && latest.weight.isNotEmpty
                  ? latest.weight
                  : '-',
              unit: 'kg',
            ),
            _WebsiteVitalStatBox(
              label: 'Height',
              value: latest != null && latest.height.isNotEmpty
                  ? latest.height
                  : '-',
              unit: 'cm',
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Timeline Header + `+ Record Vitals` Button
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'Vitals & Clinical Observations Timeline',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2942),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openRecordVitals(ipd),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Record Vitals',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Vitals Timeline Table / Cards
        if (sortedVitals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 10),
                Text(
                  'No vitals recorded yet. Click "+ Record Vitals" above to add the first observation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else
          ...sortedVitals.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: v.hasCriticalReading
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              AppFormatters.formatSlashDateTimeWithSeconds(
                                v.date,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        if (v.recordedBy.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'By ${v.recordedBy}',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniVitalChip(
                          label: 'BP',
                          value: v.bp.isEmpty ? '-' : '${v.bp} mmHg',
                        ),
                        _MiniVitalChip(
                          label: 'PULSE',
                          value: v.pulse.isEmpty ? '-' : '${v.pulse} bpm',
                        ),
                        _MiniVitalChip(
                          label: 'TEMP',
                          value: v.temperature.isEmpty
                              ? '-'
                              : '${v.temperature} °F',
                        ),
                        _MiniVitalChip(
                          label: 'SPO₂',
                          value: v.spo2.isEmpty ? '-' : '${v.spo2}%',
                        ),
                        _MiniVitalChip(
                          label: 'WEIGHT',
                          value: v.weight.isEmpty ? '-' : '${v.weight} kg',
                        ),
                        if (v.height.isNotEmpty)
                          _MiniVitalChip(
                            label: 'HEIGHT',
                            value: '${v.height} cm',
                          ),
                      ],
                    ),
                    if (v.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Notes: ${v.notes}',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: TREATMENT & ORDERS (Screenshot 751 & 754)
  // ===========================================================================

  Widget _buildTreatmentAndOrdersTab(IpdAdmission ipd) {
    final subTabs = <({IconData icon, String label, int count})>[
      (
        icon: Icons.medication_outlined,
        label: 'Medications',
        count: ipd.prescriptions.length,
      ),
      (
        icon: Icons.science_outlined,
        label: 'Investigations',
        count: ipd.investigations.length,
      ),
      (
        icon: Icons.medical_services_outlined,
        label: 'Doctor Round Notes',
        count: ipd.consultantRegister.length,
      ),
      (
        icon: Icons.assignment_outlined,
        label: 'Nurse Notes',
        count: ipd.nurseNotes.length,
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // 4 Sub-Tab Pill Selector (matches Screenshot 751)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withAlpha(166),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(subTabs.length, (i) {
                final item = subTabs[i];
                final active = _activeOrderSubTab == i;
                return Padding(
                  padding: EdgeInsets.only(right: i == subTabs.length - 1 ? 0 : 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => _activeOrderSubTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 15,
                            color: active
                                ? const Color(0xFF0F2942)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.label} (${item.count})',
                            style: TextStyle(
                              color: active
                                  ? const Color(0xFF0F2942)
                                  : const Color(0xFF64748B),
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_activeOrderSubTab == 0) _buildMedicationsSubTab(ipd),
        if (_activeOrderSubTab == 1) _buildInvestigationsSubTab(ipd),
        if (_activeOrderSubTab == 2) _buildDoctorRoundsSubTab(ipd),
        if (_activeOrderSubTab == 3) _buildNurseNotesSubTab(ipd),
      ],
    );
  }

  Widget _buildMedicationsSubTab(IpdAdmission ipd) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Text(
              'Prescribed Inpatient Medications',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (ipd.prescriptions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              child: Center(
                child: Text(
                  'No active medications prescribed yet.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: ipd.prescriptions.map((rx) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                    rx.medicineName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _RxMetaChip(
                                        label: 'DOSE',
                                        value: rx.dose.isEmpty ? '-' : rx.dose,
                                      ),
                                      _RxMetaChip(
                                        label: 'FREQUENCY',
                                        value: rx.frequency.isEmpty
                                            ? '-'
                                            : rx.frequency,
                                      ),
                                      _RxMetaChip(
                                        label: 'DURATION',
                                        value: rx.duration.isEmpty
                                            ? '-'
                                            : rx.duration,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(label: rx.status),
                          ],
                        ),
                        if (rx.instruction.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Instruction: ${rx.instruction}',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                [
                                  if (rx.orderedBy.isNotEmpty)
                                    'Ordered by: ${rx.orderedBy}',
                                  if (rx.orderedDate != null)
                                    AppFormatters.formatSlashDate(
                                      rx.orderedDate,
                                    ),
                                ].join(' • '),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (!ipd.isDischarged)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F2942),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () =>
                                    _administerSingleMedication(ipd, rx),
                                icon: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  rx.isAdministered
                                      ? 'Log Next Dose'
                                      : 'Administer',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (rx.administeredAt != null ||
                            rx.administeredBy.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Last MAR: ${rx.status}'
                              '${rx.administeredBy.isNotEmpty ? ' by ${rx.administeredBy}' : ''}'
                              '${rx.administeredAt != null ? ' • ${AppFormatters.formatDateTimeShort(rx.administeredAt)}' : ''}',
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvestigationsSubTab(IpdAdmission ipd) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Text(
              'Ordered Diagnostic Investigations',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (ipd.investigations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              child: Center(
                child: Text(
                  'No diagnostic investigations ordered yet.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: ipd.investigations.map((inv) {
                  final hasPdf =
                      inv.reportPdf != null && inv.reportPdf!.trim().isNotEmpty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                inv.category.toLowerCase().contains('rad')
                                    ? Icons.biotech_rounded
                                    : Icons.science_rounded,
                                size: 17,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.testName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      inv.category,
                                      if (inv.orderedAt != null)
                                        AppFormatters.formatSlashDate(
                                          inv.orderedAt,
                                        ),
                                    ].join(' • '),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(label: inv.status),
                          ],
                        ),
                        if (inv.resultSummary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Finding: ${inv.resultSummary}',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (hasPdf) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final report = ClinicalReportRecord(
                                  id: inv.id,
                                  billNo: ipd.ipdNo,
                                  title: inv.testName,
                                  category: inv.category
                                          .toLowerCase()
                                          .contains('rad')
                                      ? ClinicalReportCategory.radiology
                                      : ClinicalReportCategory.lab,
                                  patientName: ipd.patient.patientName,
                                  patientUniqueId: ipd.patient.patientUniqueId,
                                  doctorName: ipd.doctor.displayName,
                                  date: inv.orderedAt,
                                  status: inv.status,
                                  resultSummary: inv.resultSummary,
                                  reportPdf: inv.reportPdf,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportViewerScreen(report: report),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 15,
                              ),
                              label: const Text('View Report'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorRoundsSubTab(IpdAdmission ipd) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Text(
              'Consultant Round Register & Instructions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (ipd.consultantRegister.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              child: Center(
                child: Text(
                  'No doctor round notes recorded yet.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: ipd.consultantRegister.map((round) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              round.doctorName.isEmpty
                                  ? ipd.doctor.displayName
                                  : round.doctorName,
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              AppFormatters.formatDateTimeShort(round.date),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          round.instruction,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (round.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            round.notes,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNurseNotesSubTab(IpdAdmission ipd) {
    final sortedNotes = List<NurseProgressNote>.from(ipd.nurseNotes)
      ..sort((a, b) {
        final da = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nursing Shift Progress Notes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2942),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: () => _openAddNurseNote(ipd),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Nurse Note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (sortedNotes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 34),
              child: Center(
                child: Text(
                  'No nurse progress notes recorded yet.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: sortedNotes.map((n) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              n.nurseName,
                              style: const TextStyle(
                                color: Color(0xFF0F2942),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              AppFormatters.formatDateTimeShort(n.date),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.note,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        if (n.comment.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Handover: ${n.comment}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: BED & NURSING (Screenshot 752)
  // ===========================================================================

  Widget _buildBedAndNursingTab(IpdAdmission ipd) {
    final currentBedText = ipd.bed.isEmpty ? 'Unassigned' : ipd.bed;
    final currentWardText = ipd.bedGroup.isEmpty ? 'General' : ipd.bedGroup;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Card 1: Current Bed Allocation
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bed_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Current Bed Allocation',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                currentBedText,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ward Group: $currentWardText',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!ipd.isDischarged) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2942),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: () => _openTransferBed(ipd),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text(
                      'Transfer to Another Bed',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 2: Bed Transfer History
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Bed Transfer History',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (ipd.bedTransferHistory.isEmpty)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(text: 'Initial bed allocated: '),
                      TextSpan(
                        text: currentBedText,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: ' on admission.'),
                    ],
                  ),
                )
              else
                Column(
                  children: ipd.bedTransferHistory.map((h) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                h.fromBed.isNotEmpty
                                    ? '${h.fromBed} → ${h.toBed}'
                                    : h.toBed,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (h.date != null)
                                Text(
                                  AppFormatters.formatDateTimeShort(h.date),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.5,
                                  ),
                                ),
                            ],
                          ),
                          if (h.reason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${h.reason}',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bedside Nursing Procedures & Ward Charges
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bedside Nursing Procedures (${ipd.charges.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!ipd.isDischarged)
                    TextButton.icon(
                      onPressed: () => _openAddCharge(ipd),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Log Procedure'),
                    ),
                ],
              ),
              if (ipd.charges.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'No bedside nursing procedure charges logged yet.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                )
              else ...[
                const SizedBox(height: 8),
                ...ipd.charges.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c.chargeName} (×${c.qty})',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrencyInr(c.totalAmount),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: DISCHARGE CHECKLIST (Screenshot 753)
  // ===========================================================================

  Widget _buildDischargeChecklistTab(IpdAdmission ipd) {
    final c = _draftChecklist;

    void updateChecklist(DischargeChecklist next) {
      setState(() {
        _draftChecklist = next;
        _checklistDirty = true;
      });
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 20,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nursing Discharge Handover Checklist',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Verify essential nursing discharge criteria and clinical handover tasks before patient departure. Final clinical discharge authorization is performed by the attending doctor.',
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nurse Protocol Sky-Blue Info Alert (exact match to Screenshot 753)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 12,
                            height: 1.45,
                          ),
                          children: [
                            TextSpan(
                              text: 'Nurse Protocol: ',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text:
                                  'Confirm peripheral line removal, catheter care, patient education, and stable vitals before saving. Final discharge authorization is strictly restricted to attending physicians.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Exact 9 Checklist Items from Screenshot 753
              _WebsiteChecklistCard(
                title: 'Nursing Handover Completed',
                subtitle:
                    'Clinical handover communicated to receiving nurse or patient guardian',
                checked: c.handoverCompleted,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(handoverCompleted: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Peripheral IV Line Removed',
                subtitle: 'Cannula / IV line removed safely and pressure applied',
                checked: c.ivCannulaRemoved,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(ivCannulaRemoved: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Catheter / Drains Removed',
                subtitle:
                    'Urinary catheter and temporary drainage tubes removed if indicated',
                checked: c.catheterRemoved,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(catheterRemoved: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Surgical Packing Removed',
                subtitle:
                    'All temporary surgical packs or tubes removed and checked',
                checked: c.drainRemoved,
                onChanged: (v) => updateChecklist(c.copyWith(drainRemoved: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Wound Dressing Clean & Dry',
                subtitle:
                    'Wound inspected, intact and covered with fresh sterile dressing',
                checked: c.woundDressingClean,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(woundDressingClean: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Medications & Dosage Explained',
                subtitle:
                    'Post-discharge medicines, frequency and food timing explained to patient',
                checked: c.medicationsExplained,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(medicationsExplained: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Patient Belongings Returned',
                subtitle:
                    'Personal valuables, reports and outside films returned',
                checked: c.belongingsReturned,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(belongingsReturned: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Pre-Discharge Vitals Stable',
                subtitle:
                    'Final BP, Pulse, SpO2 and Temperature verified within safe limits',
                checked: c.vitalSignsStable,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(vitalSignsStable: v)),
              ),
              _WebsiteChecklistCard(
                title: 'Discharge Summary Slip Handed',
                subtitle:
                    'Printed discharge summary & follow-up schedule explained',
                checked: c.dischargeSlipHandedOver,
                onChanged: (v) =>
                    updateChecklist(c.copyWith(dischargeSlipHandedOver: v)),
              ),

              const SizedBox(height: 8),
              TextField(
                controller: _checklistNotesCtrl,
                maxLines: 2,
                onChanged: (_) => _checklistDirty = true,
                decoration: const InputDecoration(
                  labelText: 'Checklist Handover Notes (Optional)',
                  hintText: 'Any nursing remarks prior to patient departure...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2942),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _savingChecklist
                      ? null
                      : () => _saveDischargeChecklist(ipd),
                  icon: _savingChecklist
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _savingChecklist
                        ? 'Saving Handover Checklist...'
                        : 'Save Discharge Checklist (${c.completedItemsCount}/9)',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// WEBSITE-ALIGNED CHART HEADER BANNER & COMPONENTS
// =============================================================================

class _WebsiteChartBanner extends StatelessWidget {
  final IpdAdmission ipd;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _WebsiteChartBanner({
    required this.ipd,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pat = ipd.patient;
    final bedBadge = ipd.isDischarged
        ? 'Discharged'
        : 'Admitted: Bed ${ipd.bed.isEmpty ? 'Unassigned' : ipd.bed}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0B1E3F),
            Color(0xFF132F63),
            Color(0xFF193E7E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: Back + Title + Refresh
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PatientAvatar(
                    name: pat.patientName,
                    baseUrl: NursePortalScope.of(context).baseUrl,
                    imagePath: pat.photo,
                    radius: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pat.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            if (pat.patientUniqueId.isNotEmpty)
                              _BannerPill(
                                text: pat.patientUniqueId,
                                bg: Colors.white.withAlpha(36),
                                fg: Colors.white,
                              ),
                            _BannerPill(
                              text: ipd.ipdNo,
                              bg: Colors.white.withAlpha(36),
                              fg: Colors.white,
                            ),
                            _BannerPill(
                              text: bedBadge,
                              bg: ipd.isDischarged
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFDCFCE7),
                              fg: ipd.isDischarged
                                  ? const Color(0xFF334155)
                                  : const Color(0xFF15803D),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh Chart',
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              // Metadata strip: Gender, Age, Phone, Doctor, Admitted Date/Time
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withAlpha(26),
                  ),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    _BannerMetaText(
                      label: 'Gender:',
                      value: pat.gender.isEmpty ? '-' : pat.gender,
                    ),
                    _BannerMetaText(
                      label: 'Age:',
                      value: pat.ageLabel,
                    ),
                    if (pat.phone.isNotEmpty)
                      _BannerMetaText(
                        label: 'Phone:',
                        value: pat.phone,
                      ),
                    _BannerMetaText(
                      label: 'Doctor:',
                      value: ipd.doctor.displayName,
                    ),
                    _BannerMetaText(
                      label: 'Admitted:',
                      value: AppFormatters.formatSlashDateTimeWithSeconds(
                        ipd.admissionDate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _BannerPill({
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BannerMetaText extends StatelessWidget {
  final String label;
  final String value;

  const _BannerMetaText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11.5),
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              color: Colors.white.withAlpha(175),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalTabStrip extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _ClinicalTabStrip({
    required this.activeIndex,
    required this.onSelect,
  });

  static const List<({IconData icon, String label})> _tabs = [
    (icon: Icons.info_outline_rounded, label: 'Admission Overview'),
    (icon: Icons.monitor_heart_outlined, label: 'Vitals & Findings'),
    (icon: Icons.medical_services_outlined, label: 'Treatment & Orders'),
    (icon: Icons.bed_outlined, label: 'Bed & Nursing'),
    (icon: Icons.fact_check_outlined, label: 'Discharge Checklist'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final item = _tabs[i];
            final active = activeIndex == i;
            return Padding(
              padding: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 15,
                        color: active
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF475569),
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ChartSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _ChartSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _OverviewKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight valueWeight;
  final bool isLast;

  const _OverviewKeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight = FontWeight.w600,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.5, bottom: isLast ? 2 : 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight: valueWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteVitalStatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _WebsiteVitalStatBox({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniVitalChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniVitalChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RxMetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _RxMetaChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WebsiteChecklistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _WebsiteChecklistCard({
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: checked
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: checked,
                  activeColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
