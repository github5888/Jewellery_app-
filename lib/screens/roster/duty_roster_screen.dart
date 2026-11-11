import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/duty_roster_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Staff Duty Roster Screen (`https://hospital.hrpocket.in/duty-roster` — matches image-10 1-to-1):
/// - Header: `Staff Duty Roster` + `N Scheduled` + `Sunita Rao • Read-Only`
/// - 4 KPI Cards: `Total Staff on Duty`, `Morning Shift Staff`, `Evening Shift Staff`, `General & Night Staff`
/// - View Tabs: `Today` (default), `Date-wise`, `Monthly`, `All Records`
/// - Filters: `All Departments`, `All Shifts`, `All Roles`, `All Staff`
/// - Search box: `Search staff, ID, department...`
/// - Roster Card: Initials, `Dr. Ajay Verma`, `#9002 • Doctor`, `2026-11-11`,
///   `morning • 08:00 AM - 02:00 PM`, `6.00 Hrs`, `Cardiology`, `Ground Floor`
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
  String _viewMode = 'today'; // today | date | monthly | all
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
    final nurseName = controller.currentUser?.fullName ?? 'Nurse';
    final allRoster = controller.allRosterShifts;
    final now = DateTime.now();
    final todayIso = AppFormatters.formatIsoDate(now);

    // Dynamic filter options built strictly from real API records
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

    // Ensure selected dropdown value remains valid on refresh
    final activeDept =
        departments.contains(_selectedDepartment) ? _selectedDepartment : 'All Departments';
    final activeShift =
        shifts.contains(_selectedShift) ? _selectedShift : 'All Shifts';
    final activeRole =
        roles.contains(_selectedRole) ? _selectedRole : 'All Roles';
    final activeStaff =
        staffNames.contains(_selectedStaff) ? _selectedStaff : 'All Staff';

    final selectedIso = AppFormatters.formatIsoDate(_selectedDate);

    // 1. Apply view-mode filter (`Today`, `Date-wise`, `Monthly`, `All Records`)
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

    // 2. Apply dropdown + search filters
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

    // Compute the 4 KPI counts on the active view (`image-10.png`)
    final totalOnDuty = filtered.length;
    final morningCount =
        filtered.where((e) => e.shiftCategory == 'morning').length;
    final eveningCount =
        filtered.where((e) => e.shiftCategory == 'evening').length;
    final nightGeneralCount =
        filtered.where((e) => e.shiftCategory == 'night_general').length;

    final body = RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          // Header Card (matching image-10)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A4D78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Staff Duty Roster',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalOnDuty Scheduled',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Hospital-wide Shift Allocation, Department Coverage & Live Duty Schedule',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        nurseName,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Read-Only',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4 KPI Cards (`Total Staff on Duty`, `Morning Shift Staff`, `Evening Shift Staff`, `General & Night Staff` — image-10)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _RosterStatCard(
                label: 'Total Staff on Duty',
                value: '$totalOnDuty',
                subtitle: 'Active shift assignments',
                icon: Icons.groups_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconFg: const Color(0xFF0284C7),
              ),
              _RosterStatCard(
                label: 'Morning Shift Staff',
                value: '$morningCount',
                subtitle: 'Daycare & OPD coverage',
                icon: Icons.wb_sunny_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconFg: const Color(0xFFD97706),
              ),
              _RosterStatCard(
                label: 'Evening Shift Staff',
                value: '$eveningCount',
                subtitle: 'Afternoon & ward handoff',
                icon: Icons.wb_twilight_rounded,
                iconBg: const Color(0xFFFFEDD5),
                iconFg: const Color(0xFFEA580C),
              ),
              _RosterStatCard(
                label: 'General & Night Staff',
                value: '$nightGeneralCount',
                subtitle: '24x7 emergency & ICU',
                icon: Icons.nights_stay_outlined,
                iconBg: const Color(0xFFEDE9FE),
                iconFg: const Color(0xFF7C3AED),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Roster Controls & Table Card (matching image-10)
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // View Tabs (`Today`, `Date-wise`, `Monthly`, `All Records`)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ViewTabBtn(
                        label: 'Today',
                        selected: _viewMode == 'today',
                        onTap: () => setState(() => _viewMode = 'today'),
                      ),
                      const SizedBox(width: 6),
                      _ViewTabBtn(
                        label: 'Date-wise',
                        selected: _viewMode == 'date',
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
                        onTap: () => setState(() => _viewMode = 'monthly'),
                      ),
                      const SizedBox(width: 6),
                      _ViewTabBtn(
                        label: 'All Records',
                        selected: _viewMode == 'all',
                        onTap: () => setState(() => _viewMode = 'all'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Dropdown Filters (`All Departments`, `All Shifts`, `All Roles`, `All Staff` — image-10)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _RosterDropdown(
                        value: activeDept,
                        options: departments,
                        onChanged: (v) =>
                            setState(() => _selectedDepartment = v),
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

                const SizedBox(height: 10),

                // Search Box (`Search staff, ID, department...` — image-10)
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search staff, ID, department...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
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

                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  ClinicalEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No Duty Roster Entries Found',
                    subtitle: _viewMode == 'today'
                        ? 'Switch to "All Records" or another date to view other shifts.'
                        : 'Try clearing filters or search terms.',
                  )
                else
                  ...filtered.map((entry) => _DutyRosterCard(entry: entry)),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Staff Duty Roster')),
      body: body,
    );
  }
}

class _RosterStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

  const _RosterStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconFg, size: 19),
          ),
        ],
      ),
    );
  }
}

class _ViewTabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewTabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A4D78) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w800,
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
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 11.5,
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

  const _DutyRosterCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Text(
                  entry.initials,
                  style: const TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.staffName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (entry.staffCode.isNotEmpty) '#${entry.staffCode}',
                        if (entry.role.isNotEmpty) entry.role,
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Date pill (`2026-11-11` — image-10)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  entry.date.isNotEmpty ? entry.date : '—',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Shift Badge (`☀ morning` — image-10)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '☀ ${entry.shiftName}',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (entry.timeRangeLabel.isNotEmpty)
                Text(
                  entry.timeRangeLabel,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (entry.shiftHour.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.shiftHour,
                    style: const TextStyle(
                      color: Color(0xFF0369A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (entry.department.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.department,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (entry.floor.isNotEmpty) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.location_on_outlined,
                  size: 13.5,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 3),
                Text(
                  entry.floor,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
