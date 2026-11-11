import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Daily Shift Nurse Progress Notes (`POST /api/ipd/:id/nurse-notes`)
class NursingNotesScreen extends StatefulWidget {
  final IpdAdmission? preselectedAdmission;

  const NursingNotesScreen({
    super.key,
    this.preselectedAdmission,
  });

  @override
  State<NursingNotesScreen> createState() => _NursingNotesScreenState();
}

class _NursingNotesScreenState extends State<NursingNotesScreen> {
  String? _selectedIpdId;
  final _noteCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  final _attachmentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedIpdId = widget.preselectedAdmission?.id;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _commentCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    FocusScope.of(context).unfocus();
    final ipdId = _selectedIpdId;
    if (ipdId == null || ipdId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an admitted patient first.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_noteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your nursing observation note.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final controller = NursePortalScope.read(context);
    try {
      await controller.api.addNurseProgressNote(
        ipdId: ipdId,
        note: _noteCtrl.text.trim(),
        comment: _commentCtrl.text.trim(),
        nurseName: controller.currentUser?.fullName,
        attachment: _attachmentCtrl.text.trim(),
      );
      _noteCtrl.clear();
      _commentCtrl.clear();
      _attachmentCtrl.clear();
      await controller.refreshWorkspace();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nursing care note saved to patient chart.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.preselectedAdmission != null) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save nursing note: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final admitted = controller.admittedPatients;

    if ((_selectedIpdId == null || _selectedIpdId!.isEmpty) &&
        admitted.isNotEmpty) {
      _selectedIpdId = admitted.first.id;
    }

    final currentAdmission = admitted
            .where((a) => a.id == _selectedIpdId)
            .firstOrNull ??
        widget.preselectedAdmission;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Nursing Care Notes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          if (admitted.isEmpty && widget.preselectedAdmission == null)
            const SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.note_alt_outlined,
                title: 'No Admitted Ward Patients',
                subtitle:
                    'Admitted IPD patients are required before logging bedside shift notes.',
              ),
            )
          else ...[
            SoftSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Shift Observation Note',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.preselectedAdmission == null)
                    DropdownButtonFormField<String>(
                      value: _selectedIpdId,
                      decoration: const InputDecoration(
                        labelText: 'Ward Patient',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      items: admitted
                          .map(
                            (a) => DropdownMenuItem<String>(
                              value: a.id,
                              child: Text(
                                '${a.patient.patientName} (${a.wardAndBedLabel})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedIpdId = v),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.skySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.preselectedAdmission!.patient.patientName} • ${widget.preselectedAdmission!.wardAndBedLabel}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Daily Nursing Observation *',
                      hintText:
                          'e.g. Morning IV antibiotics administered. IV cannula site clean, no swelling.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Shift Handover Comment / Remarks',
                      hintText: 'e.g. Patient slept well during night shift.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _attachmentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Optional Attachment URL / Chart Reference',
                      hintText: 'e.g. /uploads/chart-photo.jpg',
                      prefixIcon: Icon(Icons.attach_file_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submitNote,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Nursing Note'),
                  ),
                ],
              ),
            ),

            if (currentAdmission != null) ...[
              const SizedBox(height: 20),
              Text(
                'Previous Shift Notes (${currentAdmission.nurseNotes.length})',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (currentAdmission.nurseNotes.isEmpty)
                const SoftSurfaceCard(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'No previous shift notes recorded for this patient yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...currentAdmission.nurseNotes.map(
                  (n) => Padding(
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
                                n.nurseName,
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                AppFormatters.formatDateTimeShort(n.date),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (n.comment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Handover: ${n.comment}',
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
            ],
          ],
        ],
      ),
    );
  }
}
