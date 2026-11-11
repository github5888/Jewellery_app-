import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ipd_models.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';

/// Screen 6 of Nurse Portal UI (`Record Vitals`):
/// Submits real bedside vitals to `POST /api/ipd/:id/vitals` (for IPD ward patients)
/// or `POST /api/opd/:id/vitals` (for OPD waiting triage patients).
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
  final _pulseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _rrCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate height/weight from last recorded vitals if present (never fake numbers!)
    final prev = widget.ipdAdmission?.latestVital ?? widget.opdVisit?.triageVitals;
    if (prev != null) {
      if (prev.weight.isNotEmpty) _weightCtrl.text = prev.weight;
      if (prev.height.isNotEmpty) _heightCtrl.text = prev.height;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _bpCtrl.dispose();
    _spo2Ctrl.dispose();
    _rrCtrl.dispose();
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

    if (bp.isEmpty && pulse.isEmpty && temp.isEmpty && spo2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter at least one vital sign (Heart Rate, Temp, BP, or SpO2).',
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
          respiratoryRate: _rrCtrl.text.trim(),
          weight: _weightCtrl.text.trim(),
          height: _heightCtrl.text.trim(),
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
          respiratoryRate: _rrCtrl.text.trim(),
          weight: _weightCtrl.text.trim(),
          height: _heightCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          recordedBy: nurse?.fullName,
          recordedById: nurse?.id,
        );
      }

      await controller.refreshWorkspace(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vital signs saved to live clinical chart.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save vitals: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = NursePortalScope.of(context).baseUrl;
    final patient =
        widget.ipdAdmission?.patient ?? widget.opdVisit!.patient;
    final subLabel = widget.ipdAdmission != null
        ? [
            if (patient.patientUniqueId.isNotEmpty) patient.patientUniqueId,
            widget.ipdAdmission!.wardAndBedLabel,
          ].join(' • ')
        : [
            if (patient.patientUniqueId.isNotEmpty) patient.patientUniqueId,
            'OPD ${widget.opdVisit!.opdNo}',
          ].join(' • ');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.ipdAdmission != null ? 'Record Vitals' : 'OPD Triage Vitals',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          // Patient Context Header Card (matching image-2.png)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                PatientAvatar(
                  name: patient.patientName,
                  imagePath: patient.image,
                  baseUrl: baseUrl,
                  radius: 25,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4 Primary Vital Input Cards (exact image-2.png order & icons)
          _VitalInputCard(
            icon: Icons.favorite_rounded,
            iconBg: AppColors.dangerSoft,
            iconColor: AppColors.danger,
            label: 'Heart Rate',
            unit: 'bpm',
            hint: 'e.g. 76',
            controller: _pulseCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          const SizedBox(height: 12),

          _VitalInputCard(
            icon: Icons.thermostat_rounded,
            iconBg: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFE53935),
            label: 'Temperature',
            unit: '°F',
            hint: 'e.g. 98.4',
            controller: _tempCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          _VitalInputCard(
            icon: Icons.water_drop_rounded,
            iconBg: AppColors.warningSoft,
            iconColor: AppColors.warning,
            label: 'Blood Pressure',
            unit: 'mmHg',
            hint: 'e.g. 120/80',
            controller: _bpCtrl,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 12),

          _VitalInputCard(
            icon: Icons.air_rounded,
            iconBg: AppColors.infoSoft,
            iconColor: AppColors.primary,
            label: 'SpO2',
            unit: '%',
            hint: 'e.g. 98',
            controller: _spo2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
          ),
          const SizedBox(height: 12),

          // Additional Bedside Parameters (`respiratory_rate`, `weight`, `height`)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Clinical Parameters',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rrCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Resp. Rate',
                          suffixText: '/min',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Remarks (Optional) — matching image-2.png
          const Text(
            'Remarks (Optional)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter clinical observations (e.g. Patient calm, afebrile)...',
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: ElevatedButton(
          onPressed: _saving ? null : _saveVitals,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Record'),
        ),
      ),
    );
  }
}

class _VitalInputCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String unit;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _VitalInputCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.unit,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
