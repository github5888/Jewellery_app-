import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

enum _MarFilter { active, given, pending }

/// Screen 7 of Nurse Portal UI (`Medications` / MAR):
/// Logs medication administration via `POST /api/ipd/:id/prescriptions/:prescriptionId/administer`.
class MedicationsMarScreen extends StatefulWidget {
  final String? filterIpdId;
  final String? patientTitle;

  const MedicationsMarScreen({
    super.key,
    this.filterIpdId,
    this.patientTitle,
  });

  @override
  State<MedicationsMarScreen> createState() => _MedicationsMarScreenState();
}

class _MedicationsMarScreenState extends State<MedicationsMarScreen> {
  _MarFilter _filter = _MarFilter.active;
  final Set<String> _selectedKeys = <String>{};
  bool _submitting = false;

  String _keyFor(MedicationPrescription rx) => '${rx.ipdId}::${rx.id}';

  Future<void> _openAdministerDialog(
    List<MedicationPrescription> selectedItems,
  ) async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap one or more pending medications to administer.'),
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
              padding: EdgeInsets.fromLTRB(20, 16, 20, inset + 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Medication Administration (MAR)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recording ${selectedItems.length} medication dose(s)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: ['Given', 'Held', 'Refused', 'Missed'].map((st) {
                      final active = chosenStatus == st;
                      return ChoiceChip(
                        label: Text(st),
                        selected: active,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : AppColors.textPrimary,
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
                      hintText: 'e.g. Administered IV push after meals',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Confirm • Mark as $chosenStatus'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final controller = NursePortalScope.read(context);
    final nurse = controller.currentUser;

    try {
      for (final rx in selectedItems) {
        if (rx.ipdId.isEmpty || rx.id.isEmpty) continue;
        await controller.api.administerMedication(
          ipdId: rx.ipdId,
          prescriptionId: rx.id,
          status: chosenStatus,
          remarks: remarksCtrl.text.trim(),
          administeredBy: nurse?.fullName,
          administeredById: nurse?.id,
        );
      }
      _selectedKeys.clear();
      await controller.refreshWorkspace();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medication status updated to "$chosenStatus".'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MAR update failed: $e'),
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
    final all = controller.wardPrescriptions.where((rx) {
      if (widget.filterIpdId != null && widget.filterIpdId!.isNotEmpty) {
        return rx.ipdId == widget.filterIpdId;
      }
      return true;
    }).toList();

    final visible = all.where((rx) {
      switch (_filter) {
        case _MarFilter.active:
          return true;
        case _MarFilter.given:
          return rx.isGiven;
        case _MarFilter.pending:
          return rx.isPending;
      }
    }).toList();

    final selectedItems = visible
        .where((rx) => _selectedKeys.contains(_keyFor(rx)))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.patientTitle != null
              ? 'Medications • ${widget.patientTitle}'
              : 'Medications',
        ),
      ),
      body: Column(
        children: [
          // Segmented Filter Pills (`Active`, `Given`, `Pending` — matching image-2.png)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3ECF8),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  _SegmentPill(
                    label: 'Active',
                    selected: _filter == _MarFilter.active,
                    onTap: () => setState(() => _filter = _MarFilter.active),
                  ),
                  _SegmentPill(
                    label: 'Given',
                    selected: _filter == _MarFilter.given,
                    onTap: () => setState(() => _filter = _MarFilter.given),
                  ),
                  _SegmentPill(
                    label: 'Pending',
                    selected: _filter == _MarFilter.pending,
                    onTap: () => setState(() => _filter = _MarFilter.pending),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.refreshWorkspace(),
              child: visible.isEmpty
                  ? ListView(
                      children: [
                        ClinicalEmptyState(
                          icon: Icons.medication_outlined,
                          title: 'No Medications in This Tab',
                          subtitle:
                              'Active IPD prescriptions ordered by doctors appear here in real time.',
                          actionLabel: 'Refresh MAR',
                          onAction: () => controller.refreshWorkspace(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) {
                        final rx = visible[idx];
                        final key = _keyFor(rx);
                        final isSelected = _selectedKeys.contains(key);

                        return SoftSurfaceCard(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedKeys.remove(key);
                              } else {
                                _selectedKeys.add(key);
                              }
                            });
                          },
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  rx.isGiven
                                      ? Icons.check_circle_rounded
                                      : (isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_unchecked_rounded),
                                  color: rx.isGiven
                                      ? AppColors.success
                                      : (isSelected
                                          ? AppColors.primary
                                          : AppColors.textMuted),
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
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
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (rx.dose.isNotEmpty) rx.dose,
                                        if (rx.frequency.isNotEmpty)
                                          rx.frequency,
                                      ].join(' – '),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (rx.patientName.isNotEmpty &&
                                        widget.filterIpdId == null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        '${rx.patientName} • ${rx.bedLabel}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 3),
                                    Text(
                                      rx.administeredAt != null
                                          ? 'Logged ${AppFormatters.formatDateTimeShort(rx.administeredAt)}'
                                          : (rx.instruction.isNotEmpty
                                              ? rx.instruction
                                              : AppFormatters.formatTime12h(
                                                  rx.orderedDate,
                                                )),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: visible.isEmpty
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
                onPressed: _submitting
                    ? null
                    : () => _openAdministerDialog(
                          selectedItems.isNotEmpty
                              ? selectedItems
                              : visible.where((r) => r.isPending).take(1).toList(),
                        ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        selectedItems.isNotEmpty
                            ? 'Mark as Given (${selectedItems.length})'
                            : 'Mark as Given',
                      ),
              ),
            ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
