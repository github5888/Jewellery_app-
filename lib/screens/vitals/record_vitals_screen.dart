import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ipd_models.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/patient_avatar.dart';

/// Website-Aligned Triage & Bedside Vitals Form (`image-35.png`):
/// - `Blood Pressure (BP)`: `Systolic` / `Diastolic`
/// - `Pulse (bpm)`
/// - `SpO₂ (%)`
/// - `Temperature (°F)`
/// - `Respiration (/min)`
/// - `Weight (kg)` & `Height (cm)`
/// - `Patient Chief Complaints / Symptoms` (OPD — pre-filled with `opdVisit.symptoms`)
///   or `Clinical Notes / Observations` (IPD)
/// Submits live to `POST /api/opd/:id/vitals` (+ `PUT /api/opd/:id`) or `POST /api/ipd/:id/vitals`.
class RecordVitalsScreen extends StatefulWidget {
  final IpdAdmission? ipdAdmission;
  final OpdVisitRecord? opdVisit;

  const RecordVitalsScreen({
    super.key,
    this.ipdAdmission,
    this.opdVisit,
  }) : assert(ipdAdmission != null || opdVisit != null);

  @override
  State<RecordVitalsScreen> createState() => _RecordVitalsScreenState();
}

class _RecordVitalsScreenState extends State<RecordVitalsScreen> {
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _notesOrSymptomsCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final isOpd = widget.opdVisit != null;
    final prev =
        isOpd ? widget.opdVisit!.triageVitals : widget.ipdAdmission?.latestVital;

    if (prev != null) {
      if (prev.weight.isNotEmpty) _weightCtrl.text = prev.weight;
      if (prev.height.isNotEmpty) _heightCtrl.text = prev.height;

      // Pre-populate existing OPD triage vitals when editing/re-opening
      if (isOpd) {
        if (prev.bp.isNotEmpty) {
          final parts = prev.bp.split('/');
          _systolicCtrl.text = parts.first.trim();
          if (parts.length > 1) {
            _diastolicCtrl.text = parts.sublist(1).join('/').trim();
          }
        }
        if (prev.pulse.isNotEmpty) _pulseCtrl.text = prev.pulse;
        if (prev.spo2.isNotEmpty) _spo2Ctrl.text = prev.spo2;
        if (prev.temperature.isNotEmpty) _tempCtrl.text = prev.temperature;
        if (prev.respiratoryRate.isNotEmpty) {
          _respCtrl.text = prev.respiratoryRate;
        }
      }
    }

    if (isOpd) {
      final sym = widget.opdVisit!.symptoms.trim();
      if (sym.isNotEmpty) {
        _notesOrSymptomsCtrl.text = sym;
      } else if (prev != null && prev.notes.trim().isNotEmpty) {
        _notesOrSymptomsCtrl.text = prev.notes.trim();
      }
    }
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _spo2Ctrl.dispose();
    _tempCtrl.dispose();
    _respCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _notesOrSymptomsCtrl.dispose();
    super.dispose();
  }

  String _composeBp() {
    final sys = _systolicCtrl.text.trim();
    final dia = _diastolicCtrl.text.trim();
    if (sys.isNotEmpty && dia.isNotEmpty) return '$sys/$dia';
    if (sys.isNotEmpty) return sys;
    if (dia.isNotEmpty) return dia;
    return '';
  }

  Future<void> _saveVitals() async {
    FocusScope.of(context).unfocus();

    final sys = _systolicCtrl.text.trim();
    final dia = _diastolicCtrl.text.trim();
    final bp = _composeBp();
    final pulse = _pulseCtrl.text.trim();
    final spo2 = _spo2Ctrl.text.trim();
    final temp = _tempCtrl.text.trim();
    final resp = _respCtrl.text.trim();
    final weight = _weightCtrl.text.trim();
    final height = _heightCtrl.text.trim();
    final textRemarks = _notesOrSymptomsCtrl.text.trim();

    if (bp.isEmpty &&
        pulse.isEmpty &&
        spo2.isEmpty &&
        temp.isEmpty &&
        resp.isEmpty &&
        weight.isEmpty &&
        height.isEmpty &&
        (widget.opdVisit == null || textRemarks.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter at least one vital sign (BP, Pulse, SpO₂, Temperature, Respiration, Weight, or Height).',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final controller = NursePortalScope.read(context);
    final nurse = controller.currentUser;

    try {
      if (widget.ipdAdmission != null) {
        await controller.api.recordIpdVitals(
          ipdId: widget.ipdAdmission!.id,
          bp: bp,
          pulse: pulse,
          temperature: temp,
          spo2: spo2,
          respiratoryRate: resp,
          weight: weight,
          height: height,
          notes: textRemarks,
          recordedBy: nurse?.fullName,
          recordedById: nurse?.id,
        );
      } else if (widget.opdVisit != null) {
        await controller.api.recordOpdTriageVitals(
          opdId: widget.opdVisit!.id,
          bp: bp,
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          temperature: temp,
          spo2: spo2,
          respiratoryRate: resp,
          weight: weight,
          height: height,
          symptoms: textRemarks,
          notes: textRemarks,
          recordedBy: nurse?.fullName,
          recordedById: nurse?.id,
        );
      }

      await controller.refreshWorkspace(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals saved and synced successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save vitals: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIpd = widget.ipdAdmission != null;
    final patient =
        isIpd ? widget.ipdAdmission!.patient : widget.opdVisit!.patient;
    final badge1 =
        isIpd ? widget.ipdAdmission!.ipdNo : widget.opdVisit!.opdNo;
    final badge2 = isIpd
        ? 'Bed ${widget.ipdAdmission!.bed.isEmpty ? 'Unassigned' : widget.ipdAdmission!.bed}'
        : (widget.opdVisit!.caseReferenceId.isNotEmpty
            ? widget.opdVisit!.caseReferenceId
            : widget.opdVisit!.statusCategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF034C6A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isIpd ? 'Record Bedside Vitals' : 'OPD Triage Vitals',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Patient Context Banner
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF034C6A), Color(0xFF026789)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                PatientAvatar(
                  name: patient.patientName,
                  baseUrl: NursePortalScope.of(context).baseUrl,
                  imagePath: patient.photo,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (patient.patientUniqueId.isNotEmpty)
                            _SmallHeaderChip(text: patient.patientUniqueId),
                          if (badge1.isNotEmpty) _SmallHeaderChip(text: badge1),
                          _SmallHeaderChip(
                            text: badge2,
                            bg: const Color(0xFFDCFCE7),
                            fg: const Color(0xFF15803D),
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

          // Exact Website Vitals Form Card (`image-35.png`)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Blood Pressure (Systolic / Diastolic) + Pulse (bpm)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bpField = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldTitle('Blood Pressure (BP)'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _systolicCtrl,
                                keyboardType: TextInputType.number,
                                style: _fieldTextStyle,
                                decoration: _boxDecoration('Systolic'),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 7),
                              child: Text(
                                '/',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _diastolicCtrl,
                                keyboardType: TextInputType.number,
                                style: _fieldTextStyle,
                                decoration: _boxDecoration('Diastolic'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

                    final pulseField = _VitalLabeledInput(
                      label: 'Pulse (bpm)',
                      hint: 'e.g. 72',
                      controller: _pulseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                    );

                    if (constraints.maxWidth >= 430) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: bpField),
                          const SizedBox(width: 12),
                          Expanded(child: pulseField),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        bpField,
                        const SizedBox(height: 12),
                        pulseField,
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Row 2: SpO2 (%) full width (exact layout in image-35)
                _VitalLabeledInput(
                  label: 'SpO₂ (%)',
                  hint: 'Enter oxygen saturation...',
                  controller: _spo2Ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                ),

                const SizedBox(height: 12),

                // Row 3: Temperature (°F) + Respiration (/min)
                Row(
                  children: [
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Temperature (°F)',
                        hint: 'e.g. 98.6',
                        controller: _tempCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Respiration (/min)',
                        hint: 'e.g. 18',
                        controller: _respCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 4: Weight (kg) + Height (cm)
                Row(
                  children: [
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Weight (kg)',
                        hint: 'e.g. 65',
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Height (cm)',
                        hint: 'e.g. 172',
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Row 5: Patient Chief Complaints / Symptoms (image-35)
                _FieldTitle(
                  isIpd
                      ? 'Clinical Notes / Observations'
                      : 'Patient Chief Complaints / Symptoms',
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesOrSymptomsCtrl,
                  maxLines: 3,
                  style: _fieldTextStyle,
                  decoration: _boxDecoration(
                    isIpd
                        ? 'Optional bedside remarks (e.g. Patient comfortable, afebrile)...'
                        : 'Enter presenting symptoms / chief complaints (e.g. high fever)...',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 7,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF026789),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: _saving ? null : _saveVitals,
                icon: _saving
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
                  _saving ? 'Saving...' : 'Save Vitals',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _fieldTextStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static InputDecoration _boxDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD5DFEC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF026789), width: 1.5),
      ),
    );
  }
}

class _FieldTitle extends StatelessWidget {
  final String text;

  const _FieldTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SmallHeaderChip extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;

  const _SmallHeaderChip({
    required this.text,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg ?? Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VitalLabeledInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _VitalLabeledInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldTitle(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: _RecordVitalsScreenState._fieldTextStyle,
          decoration: _RecordVitalsScreenState._boxDecoration(hint),
        ),
      ],
    );
  }
}
