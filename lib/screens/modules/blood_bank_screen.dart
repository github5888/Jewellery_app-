import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Native Mobile Blood Bank Status Screen (`GET /api/blood-bank`):
/// - Clean `MobileScreenHeader` + `[Donors]` action button
/// - Summary banner with total available blood bags across all groups
/// - Crisp 2x4 Blood Group Grid (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`)
class BloodBankScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const BloodBankScreen({
    super.key,
    this.isEmbeddedInShell = false,
  });

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen> {
  static const List<String> _standardOrder = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  bool _refreshing = false;
  String? _error;
  List<BloodBankGroupItem>? _localOverride;

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final controller = NursePortalScope.read(context);
      final items = await controller.api.fetchBloodBank();
      if (!mounted) return;
      setState(() {
        _localOverride = items;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _refreshing = false;
      });
    }
  }

  List<BloodBankGroupItem> _orderedGroups(List<BloodBankGroupItem> raw) {
    if (raw.isEmpty) return const [];
    final byGroup = <String, BloodBankGroupItem>{};
    final extras = <BloodBankGroupItem>[];
    for (final item in raw) {
      final key = item.bloodGroup.trim().toUpperCase();
      if (_standardOrder.contains(key)) {
        final existing = byGroup[key];
        if (existing == null) {
          byGroup[key] = item;
        } else {
          byGroup[key] = BloodBankGroupItem(
            id: existing.id,
            bloodGroup: key,
            availableBags: existing.availableBags + item.availableBags,
          );
        }
      } else {
        extras.add(item);
      }
    }

    final ordered = <BloodBankGroupItem>[];
    for (final g in _standardOrder) {
      if (byGroup.containsKey(g)) {
        ordered.add(byGroup[g]!);
      }
    }
    ordered.addAll(extras);
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final groups = _orderedGroups(
      _localOverride ?? controller.bloodBankGroups,
    );
    final totalBags = groups.fold<int>(0, (sum, item) => sum + item.availableBags);

    final content = RefreshIndicator(
      color: primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: 'Blood Bank',
              subtitle: 'Live blood group stock & donor registry',
              countBadge: '$totalBags Bags',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDonorDetailsModal(context),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Donors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size(140, 40),
                  ),
                  onPressed: () => _showDonorDetailsModal(context),
                  icon: const Icon(Icons.groups_rounded, size: 17),
                  label: const Text('Donor Details'),
                ),
              ),
            ),

          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          if (_error != null && groups.isEmpty)
            SoftSurfaceCard(
              child: ClinicalErrorState(
                message: _error!,
                onRetry: _refresh,
              ),
            )
          else if (groups.isEmpty)
            const SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.water_drop_outlined,
                title: 'No Blood Bank Stock Returned',
                subtitle: 'Pull down to refresh blood group inventory.',
              ),
            )
          else
            GridView.builder(
              itemCount: groups.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.32,
              ),
              itemBuilder: (context, index) {
                return _BloodGroupStockCard(item: groups[index]);
              },
            ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Blood Bank Status')),
      body: content,
    );
  }

  void _showDonorDetailsModal(BuildContext context) {
    final controller = NursePortalScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _DonorDetailsSheet(controller: controller),
    );
  }
}

class _BloodGroupStockCard extends StatelessWidget {
  final BloodBankGroupItem item;

  const _BloodGroupStockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final lowStock = item.availableBags <= 3;

    return SoftSurfaceCard(
      padding: const EdgeInsets.all(15),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.bloodGroup,
                style: const TextStyle(
                  color: Color(0xFFBE123C),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFFE11D48),
                  size: 19,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lowStock ? 'Low Stock' : 'Available Bags',
                style: TextStyle(
                  color: lowStock
                      ? const Color(0xFFD97706)
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${item.availableBags}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonorDetailsSheet extends StatefulWidget {
  final NursePortalController controller;

  const _DonorDetailsSheet({required this.controller});

  @override
  State<_DonorDetailsSheet> createState() => _DonorDetailsSheetState();
}

class _DonorDetailsSheetState extends State<_DonorDetailsSheet> {
  final _searchCtrl = TextEditingController();
  late Future<List<BloodDonorRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.api.fetchBloodDonors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: Color(0xFFE11D48)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Blood Donor Directory',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search donor name, blood group, contact...',
              prefixIcon: Icon(Icons.search_rounded, size: 19),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<BloodDonorRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ClinicalLoadingState(
                    message: 'Loading donor details...',
                  );
                }
                final donors = snapshot.data ?? const [];
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = donors.where((d) {
                  if (q.isEmpty) return true;
                  return d.donorName.toLowerCase().contains(q) ||
                      d.bloodGroup.toLowerCase().contains(q) ||
                      d.contactNo.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const ClinicalEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Donor Records Found',
                    subtitle: 'Registered blood donors appear here.',
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    return SoftSurfaceCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              d.bloodGroup.isEmpty ? '-' : d.bloodGroup,
                              style: const TextStyle(
                                color: Color(0xFFBE123C),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.donorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  [
                                    if (d.age > 0) '${d.age} Yrs',
                                    if (d.gender.isNotEmpty) d.gender,
                                    if (d.contactNo.isNotEmpty) d.contactNo,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
