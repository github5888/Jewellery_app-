import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Pharmacy Medicine Stock & Ward Consumables Inventory
/// (`GET https://hospital.hrpocket.in/api/pharmacy/medicines` & `/api/inventory`)
class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() =>
      _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  bool _showInventory = false;
  List<PharmacyMedicineItem> _medicines = const [];
  List<InventoryStockItem> _supplies = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = NursePortalScope.read(context).api;
    try {
      final results = await Future.wait<dynamic>([
        api.fetchPharmacyStock().catchError((_) => <PharmacyMedicineItem>[]),
        api.fetchWardInventory().catchError((_) => <InventoryStockItem>[]),
      ]);
      if (mounted) {
        setState(() {
          _medicines = results[0] as List<PharmacyMedicineItem>;
          _supplies = results[1] as List<InventoryStockItem>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Pharmacy & Ward Supplies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Pharmacy (${_medicines.length})'),
                  selected: !_showInventory,
                  onSelected: (_) => setState(() => _showInventory = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Ward Inventory (${_supplies.length})'),
                  selected: _showInventory,
                  onSelected: (_) => setState(() => _showInventory = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ClinicalErrorState(message: _error!, onRetry: _load)
                    : (!_showInventory ? _medicines.isEmpty : _supplies.isEmpty)
                        ? ClinicalEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Stock Items Found',
                            subtitle: _showInventory
                                ? 'Ward consumables from /api/inventory appear here.'
                                : 'Pharmacy medicines from /api/pharmacy appear here.',
                            actionLabel: 'Refresh',
                            onAction: _load,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: !_showInventory
                                ? ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      18,
                                      24,
                                    ),
                                    itemCount: _medicines.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, idx) {
                                      final m = _medicines[idx];
                                      return SoftSurfaceCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.medication_liquid_rounded,
                                              color: AppColors.teal,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    m.medicineName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14.5,
                                                    ),
                                                  ),
                                                  Text(
                                                    [
                                                      m.category,
                                                      if (m.company.isNotEmpty)
                                                        m.company,
                                                      if (m.salePrice > 0)
                                                        AppFormatters
                                                            .formatCurrencyInr(
                                                          m.salePrice,
                                                        ),
                                                    ].join(' • '),
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            StatusBadge(
                                              label: m.availableQty > 0
                                                  ? '${m.availableQty} in Stock'
                                                  : 'Available',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      4,
                                      18,
                                      24,
                                    ),
                                    itemCount: _supplies.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, idx) {
                                      final s = _supplies[idx];
                                      return SoftSurfaceCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.medical_services_outlined,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    s.itemName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14.5,
                                                    ),
                                                  ),
                                                  Text(
                                                    [
                                                      s.category,
                                                      if (s.supplier.isNotEmpty)
                                                        s.supplier,
                                                    ].join(' • '),
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            StatusBadge(
                                              label: 'Qty: ${s.quantity}',
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
    );
  }
}
