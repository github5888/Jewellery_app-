import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ipd_models.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/patient_avatar.dart';

/// Website-Aligned Bedside & Triage Vitals Entry (`+ Record Vitals`):
/// Submits live vitals (`Blood Pressure`, `Pulse`, `Temperature`, `SpO₂`, `Weight`, `Height`, `Notes`)
/// to `POST /api/ipd/:id/vitals` (IPD ward) or `POST /api/opd/:id/vitals` (OPD triage).
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
  final _bpCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prev =
        widget.ipdAdmission?.latestVital ?? widget.opdVisit?.triageVitals;
    if (prev != null) {
      if (prev.weight.isNotEmpty) _weightCtrl.text = prev.weight;
      if (prev.height.isNotEmpty) _heightCtrl.text = prev.height;
    }
  }

  @override
  void dispose() {
    _bpCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _spo2Ctrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveVitals() async {
    FocusScope.of(context).unfocus();

    final bp = _bpCtrl.text.trim();
    final pulse = _pulseCtrl.text.trim();
    final temp = _tempCtrl.text.trim();
    final spo2 = _spo2Ctrl.text.trim();
    final weight = _weightCtrl.text.trim();
    final height = _heightCtrl.text.trim();

    if (bp.isEmpty &&
        pulse.isEmpty &&
        temp.isEmpty &&
        spo2.isEmpty &&
        weight.isEmpty &&
        height.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter at least one vital sign (BP, Pulse, Temperature, SpO₂, Weight, or Height).',
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
          weight: weight,
          height: height,
          notes: _notesCtrl.text.trim(),
          recordedBy: nurse?.fullName,
          recordedById: nurse?.id,
        );
      } else if (widget.opdVisit != null) {
        await controller.api.recordOpdTriageVitals(
          opdId: widget.opdVisit!.id,
          bp: bp,
          pulse: pulse,
          temperature: temp,
          spo2: spo2,
          weight: weight,
          height: height,
          notes: _notesCtrl.text.trim(),
          recordedBy: nurse?.fullName,
          recordedById: nurse?.id,
        );
      }

      await controller.refreshWorkspace(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals & clinical observation recorded successfully.'),
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
    final patient = isIpd
        ? widget.ipdAdmission!.patient
        : widget.opdVisit!.patient;
    final badge1 = isIpd
        ? widget.ipdAdmission!.ipdNo
        : widget.opdVisit!.opdNo;
    final badge2 = isIpd
        ? 'Bed ${widget.ipdAdmission!.bed.isEmpty ? 'Unassigned' : widget.ipdAdmission!.bed}'
        : (widget.opdVisit!.caseReferenceId.isNotEmpty
            ? widget.opdVisit!.caseReferenceId
            : widget.opdVisit!.statusCategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1E3F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Record Clinical Vitals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Patient Banner Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1E3F), Color(0xFF173D7A)],
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

          // Exact 6 Website Vital Fields (2-column compact clinical form)
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
                const Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Bedside Vital Parameters',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Blood Pressure',
                        unit: 'mmHg',
                        hint: '120/80',
                        controller: _bpCtrl,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Pulse',
                        unit: 'bpm',
                        hint: '76',
                        controller: _pulseCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Temperature',
                        unit: '°F',
                        hint: '98.6',
                        controller: _tempCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'SpO₂',
                        unit: '%',
                        hint: '98',
                        controller: _spo2Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Weight',
                        unit: 'kg',
                        hint: '65',
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalLabeledInput(
                        label: 'Height',
                        unit: 'cm',
                        hint: '170',
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Clinical Notes / Observations',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Optional bedside remarks (e.g. Patient comfortable, afebrile)...',
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
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F2942),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saving ? null : _saveVitals,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 19),
          label: Text(
            _saving ? 'Saving Vitals...' : 'Save Vitals Observation',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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
  final String unit;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _VitalLabeledInput({
    required this.label,
    required this.unit,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12.5),
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' ($unit)',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: unit,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
        ),
      ],
    );
  }
}
