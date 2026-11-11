import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/bed_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Executive Ward Bed Matrix Screen (`GET /api/beds` & `GET /api/beds/groups`)
class BedStatusScreen extends StatefulWidget {
  const BedStatusScreen({super.key});

  @override
  State<BedStatusScreen> createState() => _BedStatusScreenState();
}

class _BedStatusScreenState extends State<BedStatusScreen> {
  String _selectedGroup = 'All';
  String _availabilityFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final beds = controller.beds;

    final groupNames = <String>{
      'All',
      ...controller.bedGroups.map((g) => g.name),
      ...beds.map((b) => b.bedGroupName),
    }.where((n) => n.trim().isNotEmpty).toList();

    if (!groupNames.contains(_selectedGroup)) {
      _selectedGroup = 'All';
    }

    final filtered = beds.where((b) {
      if (_selectedGroup != 'All' && b.bedGroupName != _selectedGroup) {
        return false;
      }
      if (_availabilityFilter == 'Vacant' && b.isOccupied) return false;
      if (_availabilityFilter == 'Occupied' && !b.isOccupied) return false;
      return true;
    }).toList();

    final totalCount =
        beds.isNotEmpty ? beds.length : controller.totalBedsCount;
    final occCount = beds.isNotEmpty
        ? beds.where((b) => b.isOccupied).length
        : controller.occupiedBedsCount;
    final vacCount = beds.isNotEmpty
        ? beds.where((b) => !b.isOccupied).length
        : controller.availableBedsCount;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Ward Bed Matrix')),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: RefreshIndicator(
          color: primary,
          onRefresh: () => controller.refreshWorkspace(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              // 3-Up Sculpted Bed Telemetry Strip
              Row(
                children: [
                  Expanded(
                    child: _BedStatTile(
                      label: 'Total Beds',
                      value: '$totalCount',
                      colors: [primary, primary.withAlpha(200)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BedStatTile(
                      label: 'Vacant',
                      value: '$vacCount',
                      colors: const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BedStatTile(
                      label: 'Occupied',
                      value: '$occCount',
                      colors: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ward Filter Capsule Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: groupNames.map((g) {
                    final active = _selectedGroup == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _selectedGroup = g),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active ? primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color:
                                  active ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: ['All', 'Vacant', 'Occupied'].map((f) {
                  final active = _availabilityFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _availabilityFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6.5,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? primary.withAlpha(20)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: active ? primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              if (filtered.isEmpty)
                const SoftSurfaceCard(
                  child: ClinicalEmptyState(
                    icon: Icons.bed_outlined,
                    title: 'No Beds Matched Filter',
                    subtitle:
                        'No hospital beds matched your current ward/status selection.',
                  ),
                )
              else
                ...filtered.map(
                  (HospitalBed b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftSurfaceCard(
                      padding: const EdgeInsets.all(15),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          GradientIconBadge(
                            icon: Icons.hotel_rounded,
                            colors: b.isOccupied
                                ? const [Color(0xFFF43F5E), Color(0xFFBE123C)]
                                : const [Color(0xFF10B981), Color(0xFF047857)],
                            size: 42,
                            iconSize: 20,
                            radius: 13,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    b.bedGroupName,
                                    if (b.bedType.isNotEmpty) b.bedType,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (b.currentPatientName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Patient: ${b.currentPatientName}${b.currentPatientUhid.isNotEmpty ? " (${b.currentPatientUhid})" : ""}',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: b.isOccupied ? 'Occupied' : 'Available',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BedStatTile extends StatelessWidget {
  final String label;
  final String value;
  final List<Color> colors;

  const _BedStatTile({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GradientIconBadge(
                icon: Icons.hotel_rounded,
                colors: colors,
                size: 32,
                iconSize: 16,
                radius: 10,
              ),
              Text(
                value,
                style: TextStyle(
                  color: colors.last,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  fontFeatures: AppTheme.tabularNums,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
