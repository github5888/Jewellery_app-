import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Executive Mobile Blood Bank Status Screen (`GET /api/blood-bank`):
/// - Studio-lit `PremiumScreenBackground` + `MobileScreenHeader`
/// - Crimson Executive Reserve Banner (`Total Available Units`, `8 Blood Groups`, `Donor Registry`)
/// - 2x4 Sculpted Blood Group Stock Grid (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`) with stock level bars.
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
    if (raw.isEmpty) {
      return BloodBankGroupItem.websiteBaselineStock();
    }
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
      ordered.add(
        byGroup[g] ?? BloodBankGroupItem(id: g, bloodGroup: g, availableBags: 0),
      );
    }
    ordered.addAll(extras);
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final groups = _orderedGroups(
      _localOverride ?? controller.bloodBankGroups,
    );
    final totalBags = groups.fold<int>(
      0,
      (sum, item) => sum + item.availableBags,
    );
    final lowGroups = groups.where((g) => g.availableBags <= 3).length;

    final content = RefreshIndicator(
      color: const Color(0xFFBE123C),
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: 'Blood Bank',
              subtitle: 'Live blood reserve inventory & donor registry',
              countBadge: '$totalBags Units',
            ),

          // Crimson Executive Reserve Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4C0519),
                  Color(0xFF9F1239),
                  Color(0xFFE11D48),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x36881337),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL BLOOD RESERVE',
                        style: TextStyle(
                          color: Color(0xFFFECDD3),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$totalBags',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              fontFeatures: AppTheme.tabularNums,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Bags Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${groups.length} Blood Groups  •  $lowGroups Low Reserve',
                        style: const TextStyle(
                          color: Color(0xFFFFE4E6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showDonorDetailsModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 17,
                          color: Color(0xFFBE123C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Donor Details',
                          style: TextStyle(
                            color: Color(0xFFBE123C),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                subtitle: 'Pull down to sync blood group inventory.',
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
                mainAxisExtent: 128,
              ),
              itemBuilder: (context, index) {
                return _BloodGroupStockCard(item: groups[index]);
              },
            ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return PremiumScreenBackground(
        accentColor: const Color(0xFFBE123C),
        child: SafeArea(bottom: false, child: content),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Blood Bank Status')),
      body: PremiumScreenBackground(
        accentColor: const Color(0xFFBE123C),
        child: content,
      ),
    );
  }

  void _showDonorDetailsModal(BuildContext context) {
    final controller = NursePortalScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final fillRatio = (item.availableBags / 20.0).clamp(0.08, 1.0);

    return SoftSurfaceCard(
      padding: const EdgeInsets.all(15),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(
                  item.bloodGroup,
                  style: const TextStyle(
                    color: Color(0xFFBE123C),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const GradientIconBadge(
                icon: Icons.water_drop_rounded,
                colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
                size: 34,
                iconSize: 17,
                radius: 11,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lowStock ? 'Low Reserve' : 'In Stock',
                    style: TextStyle(
                      color: lowStock
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${item.availableBags} Bags',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFeatures: AppTheme.tabularNums,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fillRatio,
                  minHeight: 5.5,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    lowStock
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE11D48),
                  ),
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
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const GradientIconBadge(
                icon: Icons.water_drop_rounded,
                colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
                size: 38,
                iconSize: 19,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Donor Registry',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Registered hospital blood bank donors',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumSearchField(
            controller: _searchCtrl,
            accentColor: const Color(0xFFBE123C),
            hintText: 'Search donor name, blood group, contact...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<BloodDonorRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ClinicalLoadingState(
                    message: 'Loading donor registry...',
                  );
                }
                final donors = snapshot.data ?? const [];
                final q = _searchCtrl.text.trim().toLowerCase();
                final filtered = donors.where((d) {
                  if (q.isEmpty) return true;
                  return d.donorName.toLowerCase().contains(q) ||
                      d.bloodGroup.toLowerCase().contains(q) ||
                      d.contactNo.toLowerCase().contains(q) ||
                      d.fatherName.toLowerCase().contains(q) ||
                      d.address.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const ClinicalEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No data available in table',
                    subtitle: 'Registered blood bank donors appear here.',
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    return SoftSurfaceCard(
                      padding: const EdgeInsets.all(13),
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFFECDD3),
                              ),
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
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (d.dateOfBirth != null)
                                      'DOB: ${AppFormatters.formatSlashDate(d.dateOfBirth)}'
                                    else if (d.age > 0)
                                      '${d.age} Yrs',
                                    if (d.gender.isNotEmpty) d.gender,
                                    if (d.contactNo.isNotEmpty) d.contactNo,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (d.fatherName.isNotEmpty ||
                                    d.address.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (d.fatherName.isNotEmpty)
                                        'Father: ${d.fatherName}',
                                      if (d.address.isNotEmpty) d.address,
                                    ].join(' • '),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
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
