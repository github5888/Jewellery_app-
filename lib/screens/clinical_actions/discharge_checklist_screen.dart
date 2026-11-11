import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Section 4: Nursing Pre-Discharge Checklist (`PUT /api/ipd/:id/discharge-checklist`)
class DischargeChecklistScreen extends StatefulWidget {
  final IpdAdmission admission;

  const DischargeChecklistScreen({super.key, required this.admission});

  @override
  State<DischargeChecklistScreen> createState() =>
      _DischargeChecklistScreenState();
}

class _DischargeChecklistScreenState extends State<DischargeChecklistScreen> {
  late bool _handoverCompleted;
  late bool _ivCannulaRemoved;
  late bool _catheterRemoved;
  late bool _drainRemoved;
  late bool _woundDressingClean;
  late bool _medicationsExplained;
  late bool _belongingsReturned;
  late bool _vitalSignsStable;
  late bool _dischargeSlipHandedOver;
  late final TextEditingController _notesCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.admission.dischargeChecklist;
    _handoverCompleted = c.handoverCompleted;
    _ivCannulaRemoved = c.ivCannulaRemoved;
    _catheterRemoved = c.catheterRemoved;
    _drainRemoved = c.drainRemoved;
    _woundDressingClean = c.woundDressingClean;
    _medicationsExplained = c.medicationsExplained;
    _belongingsReturned = c.belongingsReturned;
    _vitalSignsStable = c.vitalSignsStable;
    _dischargeSlipHandedOver = c.dischargeSlipHandedOver;
    _notesCtrl = TextEditingController(text: c.checklistNotes);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  DischargeChecklist _buildChecklist() {
    return DischargeChecklist(
      handoverCompleted: _handoverCompleted,
      ivCannulaRemoved: _ivCannulaRemoved,
      catheterRemoved: _catheterRemoved,
      drainRemoved: _drainRemoved,
      woundDressingClean: _woundDressingClean,
      medicationsExplained: _medicationsExplained,
      belongingsReturned: _belongingsReturned,
      vitalSignsStable: _vitalSignsStable,
      dischargeSlipHandedOver: _dischargeSlipHandedOver,
      checklistNotes: _notesCtrl.text.trim(),
    );
  }

  Future<void> _saveChecklist() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await NursePortalScope.read(context).api.updateDischargeChecklist(
            ipdId: widget.admission.id,
            checklist: _buildChecklist(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pre-discharge nursing checklist updated.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update checklist: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _buildChecklist();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Pre-Discharge Checklist')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          SoftSurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.successSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${current.completedItemsCount}/9',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.admission.patient.patientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.admission.ipdNo} • ${widget.admission.wardAndBedLabel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SoftSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              children: [
                _CheckItem(
                  title: 'Handover Completed',
                  subtitle: 'Shift / attendant clinical handover completed',
                  value: _handoverCompleted,
                  onChanged: (v) => setState(() => _handoverCompleted = v),
                ),
                _CheckItem(
                  title: 'IV Cannula Removed',
                  subtitle: 'Peripheral IV drip cannula safely removed',
                  value: _ivCannulaRemoved,
                  onChanged: (v) => setState(() => _ivCannulaRemoved = v),
                ),
                _CheckItem(
                  title: 'Foley\'s Catheter Removed',
                  subtitle: 'Urinary catheter safely removed (or N/A verified)',
                  value: _catheterRemoved,
                  onChanged: (v) => setState(() => _catheterRemoved = v),
                ),
                _CheckItem(
                  title: 'Surgical Drain Removed',
                  subtitle: 'Drain tube removed & site inspected',
                  value: _drainRemoved,
                  onChanged: (v) => setState(() => _drainRemoved = v),
                ),
                _CheckItem(
                  title: 'Wound Dressing Clean',
                  subtitle: 'Fresh sterile wound dressing completed',
                  value: _woundDressingClean,
                  onChanged: (v) => setState(() => _woundDressingClean = v),
                ),
                _CheckItem(
                  title: 'Discharge Medications Explained',
                  subtitle: 'Home dosage & schedule explained to attendant',
                  value: _medicationsExplained,
                  onChanged: (v) => setState(() => _medicationsExplained = v),
                ),
                _CheckItem(
                  title: 'Belongings & Reports Returned',
                  subtitle: 'Patient personal belongings & prior reports handed over',
                  value: _belongingsReturned,
                  onChanged: (v) => setState(() => _belongingsReturned = v),
                ),
                _CheckItem(
                  title: 'Vital Signs Stable',
                  subtitle: 'BP, Pulse, Temp & SpO2 stable at checkout',
                  value: _vitalSignsStable,
                  onChanged: (v) => setState(() => _vitalSignsStable = v),
                ),
                _CheckItem(
                  title: 'Discharge Slip Handed Over',
                  subtitle: 'Signed discharge summary provided to family',
                  value: _dischargeSlipHandedOver,
                  onChanged: (v) =>
                      setState(() => _dischargeSlipHandedOver = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Final Nursing Checkout Remarks',
              hintText:
                  'e.g. All lines removed, discharge medication handed over to attendant',
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
          onPressed: _saving ? null : _saveChecklist,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Discharge Checklist'),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      activeColor: AppColors.primary,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
