import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Blood Bank Inventory (`GET /api/blood-bank` / `/api/bloodbank` — from Web Screenshot 718)
class BloodBankScreen extends StatefulWidget {
  const BloodBankScreen({super.key});

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen> {
  List<BloodBankGroupItem> _items = const [];
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
    try {
      final list = await NursePortalScope.read(context).api.fetchBloodBank();
      if (mounted) {
        setState(() {
          _items = list;
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
      appBar: AppBar(title: const Text('Blood Bank Availability')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ClinicalErrorState(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? ClinicalEmptyState(
                      icon: Icons.water_drop_outlined,
                      title: 'No Blood Bank Inventory Records',
                      subtitle:
                          'Blood group stock from Hospital Blood Bank appears here.',
                      actionLabel: 'Refresh',
                      onAction: _load,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, idx) {
                          final item = _items[idx];
                          return SoftSurfaceCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: AppColors.dangerSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    item.bloodGroup,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Group ${item.bloodGroup}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${item.componentType} • ${item.availableBags} Bags',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(label: item.status),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
