import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/bed_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Section 5: Beds & Ward Status Screen (`GET /api/beds` & `GET /api/beds/groups`)
class BedStatusScreen extends StatefulWidget {
  const BedStatusScreen({super.key});

  @override
  State<BedStatusScreen> createState() => _BedStatusScreenState();
}

class _BedStatusScreenState extends State<BedStatusScreen> {
  String _selectedGroup = 'All';
  String _availabilityFilter = 'All'; // All | Vacant | Occupied

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
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

    final totalCount = beds.isNotEmpty ? beds.length : controller.totalBedsCount;
    final occCount =
        beds.isNotEmpty ? beds.where((b) => b.isOccupied).length : controller.occupiedBedsCount;
    final vacCount =
        beds.isNotEmpty ? beds.where((b) => !b.isOccupied).length : controller.availableBedsCount;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Bed Status & Wards')),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshWorkspace(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            // Top Summary Counters
            Row(
              children: [
                Expanded(
                  child: _BedStatTile(
                    label: 'Total Beds',
                    value: '$totalCount',
                    bg: AppColors.infoSoft,
                    fg: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BedStatTile(
                    label: 'Available',
                    value: '$vacCount',
                    bg: AppColors.successSoft,
                    fg: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BedStatTile(
                    label: 'Occupied',
                    value: '$occCount',
                    bg: AppColors.dangerSoft,
                    fg: AppColors.danger,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ward Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: groupNames.map((g) {
                  final active = _selectedGroup == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: active,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _selectedGroup = g),
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
                  child: FilterChip(
                    label: Text(f),
                    selected: active,
                    onSelected: (_) =>
                        setState(() => _availabilityFilter = f),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            if (filtered.isEmpty)
              const SoftSurfaceCard(
                child: ClinicalEmptyState(
                  icon: Icons.bed_outlined,
                  title: 'No Beds Found',
                  subtitle:
                      'No hospital beds matched your current ward/status filter.',
                ),
              )
            else
              ...filtered.map(
                (HospitalBed b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftSurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: b.isOccupied
                                ? AppColors.dangerSoft
                                : AppColors.successSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bed_rounded,
                            color: b.isOccupied
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
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
                                  fontSize: 12.5,
                                ),
                              ),
                              if (b.currentPatientName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Patient: ${b.currentPatientName}${b.currentPatientUhid.isNotEmpty ? " (${b.currentPatientUhid})" : ""}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
    );
  }
}

class _BedStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  const _BedStatTile({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.bed_rounded, color: fg, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
