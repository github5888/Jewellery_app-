import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Blood Bank Status Screen (`https://hospital.hrpocket.in/admin/bloodbankstatus` — matches image-9 1-to-1):
/// - Header: `Blood Bank Status` + `[Donor Details]` button
/// - 8 Blood Group Stock Cards (`A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`)
///   displaying `Blood Group` and `Available Bags` directly from `/api/blood-bank`.
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
    final groups = _orderedGroups(
      _localOverride ?? controller.bloodBankGroups,
    );

    final body = RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          SoftSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (`Blood Bank Status` + `[Donor Details]` — image-9)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Blood Bank Status',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showDonorDetailsModal(context),
                      icon: const Icon(Icons.groups_rounded, size: 16),
                      label: const Text(
                        'Donor Details',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_refreshing)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 16),

                if (_error != null && groups.isEmpty)
                  ClinicalErrorState(
                    message: _error!,
                    onRetry: _refresh,
                  )
                else if (groups.isEmpty)
                  const ClinicalEmptyState(
                    icon: Icons.water_drop_outlined,
                    title: 'No Blood Bank Stock Returned',
                    subtitle:
                        'Pull down to refresh blood group inventory from /api/blood-bank.',
                  )
                else
                  GridView.builder(
                    itemCount: groups.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25,
                    ),
                    itemBuilder: (context, index) {
                      final item = groups[index];
                      return _BloodGroupStockCard(item: item);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Blood Bank Status')),
      body: body,
    );
  }

  void _showDonorDetailsModal(BuildContext context) {
    final controller = NursePortalScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DonorDetailsSheet(controller: controller);
      },
    );
  }
}

class _BloodGroupStockCard extends StatelessWidget {
  final BloodBankGroupItem item;

  const _BloodGroupStockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Group',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.bloodGroup,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFFE11D48),
                  size: 20,
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Bags',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${item.availableBags}',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: Color(0xFFE11D48),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Blood Donor Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
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
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              d.bloodGroup.isEmpty ? '-' : d.bloodGroup,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
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
