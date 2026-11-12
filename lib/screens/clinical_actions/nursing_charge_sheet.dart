import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';

/// Section 9: Nursing Procedures / Charges (`POST /api/ipd/:id/charges`)
Future<bool?> showNursingChargeSheet(
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
    builder: (_) => _NursingChargeSheetBody(admission: admission),
  );
}

class _NursingChargeSheetBody extends StatefulWidget {
  final IpdAdmission admission;

  const _NursingChargeSheetBody({required this.admission});

  @override
  State<_NursingChargeSheetBody> createState() =>
      _NursingChargeSheetBodyState();
}

class _NursingChargeSheetBodyState extends State<_NursingChargeSheetBody> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Nursing Charges');
  final _qtyCtrl = TextEditingController(text: '1');
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<ChargeMasterItem> _catalog = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final items =
        await NursePortalScope.read(context).api.fetchChargeMaster();
    if (mounted && items.isNotEmpty) {
      setState(() => _catalog = items);
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter procedure name and valid applied charge.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final controller = NursePortalScope.read(context);
    try {
      await controller.api.addNursingProcedureCharge(
        ipdId: widget.admission.id,
        chargeName: name,
        chargeCategory: _categoryCtrl.text.trim().isEmpty
            ? 'Nursing Charges'
            : _categoryCtrl.text.trim(),
        qty: qty < 1 ? 1 : qty,
        appliedCharge: amount,
        note: _noteCtrl.text.trim(),
        addedBy: controller.currentUser?.fullName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nursing procedure logged to patient IPD bill.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log procedure charge: $e'),
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
      child: SingleChildScrollView(
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
              'Log Nursing Procedure • ${widget.admission.patient.patientName}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_catalog.isNotEmpty) ...[
              DropdownButtonFormField<ChargeMasterItem>(
                decoration: const InputDecoration(
                  labelText: 'Select from Hospital Charge Master (Optional)',
                  prefixIcon: Icon(Icons.list_alt_rounded),
                ),
                items: _catalog
                    .take(40)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.name} (${AppFormatters.formatCurrencyInr(c.standardCharge)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (c) {
                  if (c == null) return;
                  _nameCtrl.text = c.name;
                  _categoryCtrl.text = c.chargeCategory;
                  _amountCtrl.text = c.standardCharge.toStringAsFixed(0);
                },
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Procedure Name *',
                hintText: 'e.g. IV Cannulation & Dressing / Nebulization',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fee (₹) *',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Procedure Clinical Note',
                hintText: 'e.g. Left arm 20G IV cannula inserted',
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Procedure Charge'),
            ),
          ],
        ),
      ),
    );
  }
}
