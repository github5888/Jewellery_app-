import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Section 7 & 10: Nurse Duty Roster & Shifts (`GET /api/dutyroster` / `/api/duty-rosters/assignments`)
/// Matches Web Portal Screenshot 725.
class DutyRosterScreen extends StatefulWidget {
  const DutyRosterScreen({super.key});

  @override
  State<DutyRosterScreen> createState() => _DutyRosterScreenState();
}

class _DutyRosterScreenState extends State<DutyRosterScreen> {
  bool _onlyMyShifts = false;

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final list = _onlyMyShifts
        ? controller.myShifts
        : (controller.allRosterShifts.isNotEmpty
            ? controller.allRosterShifts
            : controller.myShifts);

    final morningCount = list
        .where((s) => s.shiftName.toLowerCase().contains('morn'))
        .length;
    final eveningCount = list
        .where((s) => s.shiftName.toLowerCase().contains('even'))
        .length;
    final nightCount = list
        .where((s) =>
            s.shiftName.toLowerCase().contains('night') ||
            s.shiftName.toLowerCase().contains('gen'))
        .length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Staff Duty Roster')),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshWorkspace(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: _RosterKpi(
                    label: 'Total Scheduled',
                    value: '${list.length}',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RosterKpi(
                    label: 'Morning',
                    value: '$morningCount',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RosterKpi(
                    label: 'Evening',
                    value: '$eveningCount',
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RosterKpi(
                    label: 'Night',
                    value: '$nightCount',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('All Hospital Roster'),
                  selected: !_onlyMyShifts,
                  onSelected: (_) => setState(() => _onlyMyShifts = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('My Shifts'),
                  selected: _onlyMyShifts,
                  onSelected: (_) => setState(() => _onlyMyShifts = true),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const SoftSurfaceCard(
                child: ClinicalEmptyState(
                  icon: Icons.schedule_rounded,
                  title: 'No Duty Shifts Scheduled',
                  subtitle:
                      'Assigned Morning, Evening, and Night shifts appear here from Duty Roster Setup.',
                ),
              )
            else
              ...list.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftSurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                s.staffName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            StatusBadge(label: s.shiftName),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            if (s.role.isNotEmpty)
                              Text(
                                s.role,
                                style: const TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (s.date.isNotEmpty)
                              Text(
                                'Date: ${s.date}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            if (s.timeRangeLabel.isNotEmpty)
                              Text(
                                s.timeRangeLabel,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              [
                                s.department,
                                if (s.floor.isNotEmpty) s.floor,
                              ].join(' • '),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

class _RosterKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RosterKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
