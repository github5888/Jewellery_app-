import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/duty_roster_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Native Mobile Staff Duty Roster Screen (`GET /api/dutyroster`):
/// - Clean `MobileScreenHeader` + `Read-Only` pill
/// - 4-Column Shift Summary Strip (`Total`, `Morning`, `Evening`, `Night`)
/// - View Pills (`Today` default, `Date-wise`, `Monthly`, `All Records`)
/// - Dropdown Filters (`All Departments`, `All Shifts`, `All Roles`, `All Staff`)
/// - Search (`Search staff, ID, department...`) + Floating white Roster Cards.
class DutyRosterScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const DutyRosterScreen({
    super.key,
    this.isEmbeddedInShell = false,
  });

  @override
  State<DutyRosterScreen> createState() => _DutyRosterScreenState();
}

class _DutyRosterScreenState extends State<DutyRosterScreen> {
  final _searchCtrl = TextEditingController();
  String _viewMode = 'today';
  DateTime _selectedDate = DateTime.now();

  String _selectedDepartment = 'All Departments';
  String _selectedShift = 'All Shifts';
  String _selectedRole = 'All Roles';
  String _selectedStaff = 'All Staff';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    final l = a.toLocal();
    return l.year == b.year && l.month == b.month && l.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final allRoster = controller.allRosterShifts;
    final now = DateTime.now();
    final todayIso = AppFormatters.formatIsoDate(now);

    final departments = <String>{
      'All Departments',
      ...allRoster
          .map((e) => e.department.trim())
          .where((s) => s.isNotEmpty),
    }.toList();
    final shifts = <String>{
      'All Shifts',
      ...allRoster
          .map((e) => e.shiftName.trim())
          .where((s) => s.isNotEmpty),
    }.toList();
    final roles = <String>{
      'All Roles',
      ...allRoster.map((e) => e.role.trim()).where((s) => s.isNotEmpty),
    }.toList();
    final staffNames = <String>{
      'All Staff',
      ...allRoster
          .map((e) => e.staffName.trim())
          .where((s) => s.isNotEmpty),
    }.toList();

    final activeDept = departments.contains(_selectedDepartment)
        ? _selectedDepartment
        : 'All Departments';
    final activeShift =
        shifts.contains(_selectedShift) ? _selectedShift : 'All Shifts';
    final activeRole =
        roles.contains(_selectedRole) ? _selectedRole : 'All Roles';
    final activeStaff =
        staffNames.contains(_selectedStaff) ? _selectedStaff : 'All Staff';

    final selectedIso = AppFormatters.formatIsoDate(_selectedDate);

    final viewFiltered = allRoster.where((entry) {
      switch (_viewMode) {
        case 'today':
          return entry.date == todayIso || _sameDay(entry.parsedDate, now);
        case 'date':
          return entry.date == selectedIso ||
              _sameDay(entry.parsedDate, _selectedDate);
        case 'monthly':
          if (entry.parsedDate != null) {
            final d = entry.parsedDate!.toLocal();
            return d.year == _selectedDate.year &&
                d.month == _selectedDate.month;
          }
          final ym =
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, "0")}';
          return entry.date.startsWith(ym);
        case 'all':
        default:
          return true;
      }
    }).toList();

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = viewFiltered.where((entry) {
      if (activeDept != 'All Departments' &&
          entry.department.trim().toLowerCase() != activeDept.toLowerCase()) {
        return false;
      }
      if (activeShift != 'All Shifts' &&
          entry.shiftName.trim().toLowerCase() != activeShift.toLowerCase()) {
        return false;
      }
      if (activeRole != 'All Roles' &&
          entry.role.trim().toLowerCase() != activeRole.toLowerCase()) {
        return false;
      }
      if (activeStaff != 'All Staff' &&
          entry.staffName.trim().toLowerCase() != activeStaff.toLowerCase()) {
        return false;
      }
      if (q.isNotEmpty) {
        return entry.staffName.toLowerCase().contains(q) ||
            entry.staffCode.toLowerCase().contains(q) ||
            entry.department.toLowerCase().contains(q) ||
            entry.role.toLowerCase().contains(q) ||
            entry.floor.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final totalOnDuty = filtered.length;
    final morningCount =
        filtered.where((e) => e.shiftCategory == 'morning').length;
    final eveningCount =
        filtered.where((e) => e.shiftCategory == 'evening').length;
    final nightGeneralCount =
        filtered.where((e) => e.shiftCategory == 'night_general').length;

    final content = RefreshIndicator(
      color: primary,
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: 'Duty Roster',
              subtitle: 'Hospital shift allocation & staff schedule',
              countBadge: '$totalOnDuty On Duty',
              trailingAction: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Read-Only',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          // 4-Column Shift Summary Strip
          Row(
            children: [
              Expanded(
                child: _RosterMiniStat(
                  value: '$totalOnDuty',
                  label: 'Total',
                  accent: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RosterMiniStat(
                  value: '$morningCount',
                  label: 'Morning',
                  accent: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RosterMiniStat(
                  value: '$eveningCount',
                  label: 'Evening',
                  accent: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RosterMiniStat(
                  value: '$nightGeneralCount',
                  label: 'Night',
                  accent: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // View Mode Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ViewTabBtn(
                  label: 'Today',
                  selected: _viewMode == 'today',
                  primary: primary,
                  onTap: () => setState(() => _viewMode = 'today'),
                ),
                const SizedBox(width: 6),
                _ViewTabBtn(
                  label: 'Date-wise',
                  selected: _viewMode == 'date',
                  primary: primary,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    setState(() {
                      _viewMode = 'date';
                      if (picked != null) _selectedDate = picked;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _ViewTabBtn(
                  label: 'Monthly',
                  selected: _viewMode == 'monthly',
                  primary: primary,
                  onTap: () => setState(() => _viewMode = 'monthly'),
                ),
                const SizedBox(width: 6),
                _ViewTabBtn(
                  label: 'All Records',
                  selected: _viewMode == 'all',
                  primary: primary,
                  onTap: () => setState(() => _viewMode = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search staff, ID, department...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 10),

          // Filter Dropdowns
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RosterDropdown(
                  value: activeDept,
                  options: departments,
                  onChanged: (v) => setState(() => _selectedDepartment = v),
                ),
                const SizedBox(width: 8),
                _RosterDropdown(
                  value: activeShift,
                  options: shifts,
                  onChanged: (v) => setState(() => _selectedShift = v),
                ),
                const SizedBox(width: 8),
                _RosterDropdown(
                  value: activeRole,
                  options: roles,
                  onChanged: (v) => setState(() => _selectedRole = v),
                ),
                const SizedBox(width: 8),
                _RosterDropdown(
                  value: activeStaff,
                  options: staffNames,
                  onChanged: (v) => setState(() => _selectedStaff = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (filtered.isEmpty)
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No Duty Roster Entries',
                subtitle: _viewMode == 'today'
                    ? 'Switch to "All Records" or another date to view shifts.'
                    : 'Try clearing filters or search terms.',
              ),
            )
          else
            ...filtered.map(
              (entry) => _DutyRosterCard(entry: entry, primaryColor: primary),
            ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Staff Duty Roster')),
      body: content,
    );
  }
}

class _RosterMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _RosterMiniStat({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewTabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _ViewTabBtn({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RosterDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _RosterDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: options
              .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _DutyRosterCard extends StatelessWidget {
  final DutyShiftAssignment entry;
  final Color primaryColor;

  const _DutyRosterCard({
    required this.entry,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    entry.initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.staffName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (entry.staffCode.isNotEmpty) '#${entry.staffCode}',
                          if (entry.role.isNotEmpty) entry.role,
                        ].join('  •  '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.date.isNotEmpty ? entry.date : '—',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '☀ ${entry.shiftName}',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (entry.timeRangeLabel.isNotEmpty)
                    Text(
                      entry.timeRangeLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (entry.shiftHour.isNotEmpty)
                    Text(
                      '•  ${entry.shiftHour}',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            if (entry.department.isNotEmpty || entry.floor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (entry.department.isNotEmpty)
                    Text(
                      entry.department,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (entry.floor.isNotEmpty) ...[
                    const Spacer(),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      entry.floor,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
