import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/bed_models.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';

/// Patient Bed Shifting (`POST /api/ipd/:id/transfer-bed`)
/// Fetches live vacant beds via `GET /api/beds?is_occupied=false`.
Future<bool?> showBedTransferSheet(
  BuildContext context,
  IpdAdmission admission,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BedTransferSheetBody(admission: admission),
  );
}

class _BedTransferSheetBody extends StatefulWidget {
  final IpdAdmission admission;

  const _BedTransferSheetBody({required this.admission});

  @override
  State<_BedTransferSheetBody> createState() => _BedTransferSheetBodyState();
}

class _BedTransferSheetBodyState extends State<_BedTransferSheetBody> {
  final _reasonCtrl = TextEditingController();
  List<HospitalBed> _vacantBeds = const [];
  String? _selectedBedId;
  bool _loadingBeds = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVacantBeds());
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVacantBeds() async {
    setState(() {
      _loadingBeds = true;
      _error = null;
    });
    try {
      final beds = await NursePortalScope.read(context)
          .api
          .fetchBeds(isOccupied: false);
      final available = beds.where((b) => !b.isOccupied).toList();
      if (mounted) {
        setState(() {
          _vacantBeds = available;
          if (available.isNotEmpty) {
            _selectedBedId = available.first.id;
          }
          _loadingBeds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingBeds = false;
        });
      }
    }
  }

  Future<void> _submitTransfer() async {
    if (_selectedBedId == null || _selectedBedId!.isEmpty) return;
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the clinical reason for bed shifting.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await NursePortalScope.read(context).api.transferPatientBed(
            ipdId: widget.admission.id,
            bedId: _selectedBedId!,
            transferReason: _reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient bed transfer completed successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bed transfer failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, inset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Shift Bed • ${widget.admission.patient.patientName}',
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current Bed: ${widget.admission.wardAndBedLabel}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_loadingBeds)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger))
          else if (_vacantBeds.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No vacant beds are currently available in Bed Setup.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedBedId,
              decoration: const InputDecoration(
                labelText: 'Select Target Vacant Bed',
                prefixIcon: Icon(Icons.bed_rounded),
              ),
              items: _vacantBeds
                  .map(
                    (b) => DropdownMenuItem<String>(
                      value: b.id,
                      child: Text(
                        '${b.bedGroupName} • ${b.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedBedId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Transfer Reason *',
                hintText: 'e.g. Shifted from ICU to General Ward',
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _submitting ? null : _submitTransfer,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm Bed Transfer'),
            ),
          ],
        ],
      ),
    );
  }
}
