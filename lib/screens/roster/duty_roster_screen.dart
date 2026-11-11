import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/duty_roster_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Website-Aligned Executive Staff Duty Roster (`/duty-roster` — image-17..20):
/// - Live `GET /api/dutyroster` + `GET /api/staff` integration
/// - Exact 4 Website Filter Dropdowns in a crisp 2x2 mobile grid:
///   1. `All Departments` (`Administration`, `Cardiology`, `Finance`, `Front Desk`, `Nursing`, `Pathology`, `Pharmacy`, `Radiology` + live API departments)
///   2. `All Shifts` (`All Shifts`, `Morning Shift`, `Evening Shift`, `General / Night`)
///   3. `All Roles` (`All Roles`, `Doctors`, `Nurses`, `Admins`, `Pharmacists`, `Pathologists`, `Radiologists`, `Receptionists`)
///   4. `All Staff (N)` (`All Staff (9)`, `Dr. Ajay Verma (9002)`, ..., `Sunita Rao (9008)`, ..., `Prince Singh (9010)`)
/// - Date Scope Tabs (`Today`, `Date-wise`, `Monthly`, `All Records`) + `Cards` / `Month Calendar` toggle.
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
  static const List<String> _websiteBaseDepartments = [
    'Administration',
    'Cardiology',
    'Finance',
    'Front Desk',
    'Nursing',
    'Pathology',
    'Pharmacy',
    'Radiology',
  ];

  static const List<String> _websiteShifts = [
    'All Shifts',
    'Morning Shift',
    'Evening Shift',
    'General / Night',
  ];

  static const List<String> _websiteRoles = [
    'All Roles',
    'Doctors',
    'Nurses',
    'Admins',
    'Pharmacists',
    'Pathologists',
    'Radiologists',
    'Receptionists',
  ];

  final _searchCtrl = TextEditingController();
  String _viewMode = 'today'; // today | date | monthly | all
  String _displayLayout = 'cards'; // cards | calendar
  DateTime _selectedDate = DateTime.now();

  String _selectedDepartment = 'All Departments';
  String _selectedShift = 'All Shifts';
  String _selectedRole = 'All Roles';
  String _selectedStaffKey = 'ALL';

  List<StaffRosterMember> _localStaffFallback = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureStaffLoaded());
  }

  Future<void> _ensureStaffLoaded() async {
    final controller = NursePortalScope.read(context);
    if (controller.staffDirectory.isNotEmpty) return;
    final fetched = await controller.api.fetchStaffDirectory();
    if (mounted && fetched.isNotEmpty) {
      setState(() => _localStaffFallback = fetched);
    }
  }

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

  bool get _hasActiveFilters =>
      _selectedDepartment != 'All Departments' ||
      _selectedShift != 'All Shifts' ||
      _selectedRole != 'All Roles' ||
      _selectedStaffKey != 'ALL' ||
      _searchCtrl.text.trim().isNotEmpty;

  void _resetFilters() {
    setState(() {
      _selectedDepartment = 'All Departments';
      _selectedShift = 'All Shifts';
      _selectedRole = 'All Roles';
      _selectedStaffKey = 'ALL';
      _searchCtrl.clear();
    });
  }

  List<StaffRosterMember> _buildStaffPool(
    List<StaffRosterMember> apiStaff,
    List<DutyShiftAssignment> roster,
  ) {
    final byKey = <String, StaffRosterMember>{};
    for (final s in apiStaff) {
      if (s.fullName.trim().isEmpty) continue;
      byKey[s.uniqueKey] = s;
    }
    if (byKey.isEmpty) {
      for (final r in roster) {
        if (r.staffName.trim().isEmpty || r.staffName == '—') continue;
        final member = StaffRosterMember(
          id: r.staffId,
          employeeId: r.staffCode.replaceAll('#', '').trim(),
          fullName: r.staffName,
          role: r.role,
          department: r.department,
        );
        byKey[member.uniqueKey] = member;
      }
    }
    final list = byKey.values.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a.employeeId);
        final bi = int.tryParse(b.employeeId);
        if (ai != null && bi != null) return ai.compareTo(bi);
        if (a.employeeId.isNotEmpty && b.employeeId.isNotEmpty) {
          return a.employeeId.compareTo(b.employeeId);
        }
        return a.fullName.compareTo(b.fullName);
      });
    return list;
  }

  List<String> _buildDepartmentOptions(
    List<StaffRosterMember> staffPool,
    List<DutyShiftAssignment> roster,
  ) {
    final mapByLower = <String, String>{};
    for (final d in _websiteBaseDepartments) {
      mapByLower[d.toLowerCase()] = d;
    }
    for (final s in staffPool) {
      final d = s.department.trim();
      if (d.isNotEmpty) mapByLower.putIfAbsent(d.toLowerCase(), () => d);
    }
    for (final r in roster) {
      final d = r.department.trim();
      if (d.isNotEmpty) mapByLower.putIfAbsent(d.toLowerCase(), () => d);
    }
    final sorted = mapByLower.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All Departments', ...sorted];
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final nurseName = controller.currentUser?.fullName ?? 'Nurse';
    final allRoster = controller.allRosterShifts;
    final staffSource = controller.staffDirectory.isNotEmpty
        ? controller.staffDirectory
        : _localStaffFallback;
    final staffPool = _buildStaffPool(staffSource, allRoster);
    final departments = _buildDepartmentOptions(staffPool, allRoster);

    final activeDept = departments.contains(_selectedDepartment)
        ? _selectedDepartment
        : 'All Departments';
    final activeShift = _websiteShifts.contains(_selectedShift)
        ? _selectedShift
        : 'All Shifts';
    final activeRole = _websiteRoles.contains(_selectedRole)
        ? _selectedRole
        : 'All Roles';

    StaffRosterMember? selectedStaffObj;
    if (_selectedStaffKey != 'ALL') {
      for (final m in staffPool) {
        if (m.uniqueKey == _selectedStaffKey) {
          selectedStaffObj = m;
          break;
        }
      }
    }
    final activeStaffKey = selectedStaffObj != null ? _selectedStaffKey : 'ALL';

    final now = DateTime.now();
    final todayIso = AppFormatters.formatIsoDate(now);
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
      if (!entry.matchesShiftFilter(activeShift)) {
        return false;
      }
      if (!entry.matchesRoleFilter(activeRole)) {
        return false;
      }
      if (selectedStaffObj != null &&
          !entry.matchesStaffMember(selectedStaffObj)) {
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

    final allStaffLabel = staffPool.isNotEmpty
        ? 'All Staff (${staffPool.length})'
        : 'All Staff';

    final staffDropdownItems = <({String key, String label})>[
      (key: 'ALL', label: allStaffLabel),
      ...staffPool.map((m) => (key: m.uniqueKey, label: m.dropdownLabel)),
    ];

    final content = RefreshIndicator(
      color: primary,
      onRefresh: () async {
        await controller.refreshWorkspace();
        await _ensureStaffLoaded();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: 'Staff Duty Roster',
              subtitle: 'Hospital shift allocation & staff schedule',
              countBadge: '$totalOnDuty Scheduled',
              trailingAction: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${nurseName.split(" ").first} • Read-Only',
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4-Card Shift Telemetry Strip (matches Website `/duty-roster`)
          Row(
            children: [
              Expanded(
                child: _RosterMiniStat(
                  icon: Icons.assignment_ind_outlined,
                  value: '$totalOnDuty',
                  label: 'Total Duty',
                  accent: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RosterMiniStat(
                  icon: Icons.wb_sunny_outlined,
                  value: '$morningCount',
                  label: 'Morning',
                  accent: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RosterMiniStat(
                  icon: Icons.schedule_rounded,
                  value: '$eveningCount',
                  label: 'Evening',
                  accent: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RosterMiniStat(
                  icon: Icons.nights_stay_outlined,
                  value: '$nightGeneralCount',
                  label: 'Gen / Night',
                  accent: const Color(0xFFD97706),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Date Scope Pills (`Today`, `Date-wise`, `Monthly`, `All Records`)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ViewTabBtn(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  selected: _viewMode == 'today',
                  primary: primary,
                  onTap: () => setState(() => _viewMode = 'today'),
                ),
                const SizedBox(width: 7),
                _ViewTabBtn(
                  icon: Icons.event_outlined,
                  label: _viewMode == 'date'
                      ? 'Date: ${AppFormatters.formatDateShort(_selectedDate)}'
                      : 'Date-wise',
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
                const SizedBox(width: 7),
                _ViewTabBtn(
                  icon: Icons.calendar_month_outlined,
                  label: 'Monthly',
                  selected: _viewMode == 'monthly',
                  primary: primary,
                  onTap: () => setState(() => _viewMode = 'monthly'),
                ),
                const SizedBox(width: 7),
                _ViewTabBtn(
                  icon: Icons.list_alt_rounded,
                  label: 'All Records',
                  selected: _viewMode == 'all',
                  primary: primary,
                  onTap: () => setState(() => _viewMode = 'all'),
                ),
              ],
            ),
          ),

          if (_viewMode == 'monthly') ...[
            const SizedBox(height: 10),
            _MonthNavigatorBar(
              selectedMonth: _selectedDate,
              primary: primary,
              onPrev: () => setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                  1,
                );
              }),
              onNext: () => setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                  1,
                );
              }),
            ),
          ],

          const SizedBox(height: 12),

          // Exact 4 Website Filter Dropdowns in a Full-Visibility 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _WebsiteRosterSelect<String>(
                  icon: Icons.apartment_rounded,
                  value: activeDept,
                  items: departments
                      .map((d) => (value: d, label: d))
                      .toList(),
                  isFiltered: activeDept != 'All Departments',
                  primary: primary,
                  onChanged: (v) => setState(() => _selectedDepartment = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WebsiteRosterSelect<String>(
                  icon: Icons.access_time_rounded,
                  value: activeShift,
                  items: _websiteShifts
                      .map((s) => (value: s, label: s))
                      .toList(),
                  isFiltered: activeShift != 'All Shifts',
                  primary: primary,
                  onChanged: (v) => setState(() => _selectedShift = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _WebsiteRosterSelect<String>(
                  icon: Icons.badge_outlined,
                  value: activeRole,
                  items: _websiteRoles
                      .map((r) => (value: r, label: r))
                      .toList(),
                  isFiltered: activeRole != 'All Roles',
                  primary: primary,
                  onChanged: (v) => setState(() => _selectedRole = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WebsiteRosterSelect<String>(
                  icon: Icons.people_outline_rounded,
                  value: activeStaffKey,
                  items: staffDropdownItems
                      .map((s) => (value: s.key, label: s.label))
                      .toList(),
                  isFiltered: activeStaffKey != 'ALL',
                  primary: primary,
                  onChanged: (v) => setState(() => _selectedStaffKey = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search + Cards/Month Calendar Layout Toggle
          Row(
            children: [
              Expanded(
                child: PremiumSearchField(
                  controller: _searchCtrl,
                  accentColor: primary,
                  hintText: 'Search staff, ID, department...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LayoutToggleIcon(
                      icon: Icons.grid_view_rounded,
                      tooltip: 'Cards View',
                      active: _displayLayout == 'cards',
                      primary: primary,
                      onTap: () => setState(() => _displayLayout = 'cards'),
                    ),
                    const SizedBox(width: 2),
                    _LayoutToggleIcon(
                      icon: Icons.calendar_view_month_rounded,
                      tooltip: 'Month Calendar',
                      active: _displayLayout == 'calendar',
                      primary: primary,
                      onTap: () => setState(() {
                        _displayLayout = 'calendar';
                        if (_viewMode == 'today') _viewMode = 'monthly';
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_hasActiveFilters) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: primary,
                ),
                onPressed: _resetFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                label: const Text(
                  'Reset Filters',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          if (_displayLayout == 'calendar')
            _MonthCalendarRosterGrid(
              month: _selectedDate,
              entries: filtered,
              primary: primary,
              onSelectDay: (day) {
                setState(() {
                  _selectedDate = day;
                  _viewMode = 'date';
                  _displayLayout = 'cards';
                });
              },
            )
          else if (filtered.isEmpty)
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No Duty Roster Entries',
                subtitle: _hasActiveFilters
                    ? 'No shifts match the selected department, shift, role, or staff filter.'
                    : (_viewMode == 'today'
                        ? 'Switch to "All Records" or another date to view scheduled shifts.'
                        : 'No scheduled shifts found for this period.'),
                actionLabel: _hasActiveFilters ? 'Clear Filters' : null,
                onAction: _hasActiveFilters ? _resetFilters : null,
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
      return PremiumScreenBackground(
        accentColor: primary,
        child: SafeArea(bottom: false, child: content),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Staff Duty Roster')),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: content,
      ),
    );
  }
}

class _RosterMiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _RosterMiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(22),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              fontFeatures: AppTheme.tabularNums,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewTabBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _ViewTabBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primary : AppColors.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebsiteRosterSelect<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<({T value, String label})> items;
  final bool isFiltered;
  final Color primary;
  final ValueChanged<T> onChanged;

  const _WebsiteRosterSelect({
    required this.icon,
    required this.value,
    required this.items,
    required this.isFiltered,
    required this.primary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isFiltered ? primary.withAlpha(14) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFiltered ? primary.withAlpha(120) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isFiltered ? primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: isFiltered ? primary : AppColors.textSecondary,
                ),
                style: TextStyle(
                  color: isFiltered ? primary : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isFiltered ? FontWeight.w800 : FontWeight.w700,
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item.value,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutToggleIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final Color primary;
  final VoidCallback onTap;

  const _LayoutToggleIcon({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primary.withAlpha(22) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: active ? primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MonthNavigatorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final Color primary;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigatorBar({
    required this.selectedMonth,
    required this.primary,
    required this.onPrev,
    required this.onNext,
  });

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${_months[selectedMonth.month - 1]} ${selectedMonth.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
          ),
          Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarRosterGrid extends StatelessWidget {
  final DateTime month;
  final List<DutyShiftAssignment> entries;
  final Color primary;
  final ValueChanged<DateTime> onSelectDay;

  const _MonthCalendarRosterGrid({
    required this.month,
    required this.entries,
    required this.primary,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = firstOfMonth.weekday % 7; // Sun=0..Sat=6

    final countsByDay = <int, int>{};
    for (final e in entries) {
      final dt = e.parsedDate?.toLocal() ?? DateTime.tryParse(e.date);
      if (dt != null && dt.year == month.year && dt.month == month.month) {
        countsByDay[dt.day] = (countsByDay[dt.day] ?? 0) + 1;
      }
    }

    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return SoftSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, idx) {
              final dayNum = idx - startOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final count = countsByDay[dayNum] ?? 0;
              final isToday = today.year == month.year &&
                  today.month == month.month &&
                  today.day == dayNum;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    onSelectDay(DateTime(month.year, month.month, dayNum)),
                child: Container(
                  decoration: BoxDecoration(
                    color: count > 0
                        ? primary.withAlpha(18)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday
                          ? primary
                          : (count > 0
                              ? primary.withAlpha(80)
                              : const Color(0xFFE2E8F0)),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isToday ? primary : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight:
                              isToday ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
    final isMorning = entry.shiftCategory == 'morning';
    final isEvening = entry.shiftCategory == 'evening';
    final shiftBg = isMorning
        ? const Color(0xFFE0F2FE)
        : (isEvening ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE));
    final shiftFg = isMorning
        ? const Color(0xFF0369A1)
        : (isEvening ? const Color(0xFFB45309) : const Color(0xFF6D28D9));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    entry.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (entry.staffCode.isNotEmpty)
                            Text(
                              '#${entry.staffCode.replaceAll("#", "")}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (entry.role.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.role,
                                style: const TextStyle(
                                  color: Color(0xFF7E22CE),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        entry.date.isNotEmpty ? entry.date : '—',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularNums,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: shiftBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '☀ ${entry.shiftName}',
                      style: TextStyle(
                        color: shiftFg,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        entry.shiftHour,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (entry.department.isNotEmpty || entry.floor.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (entry.department.isNotEmpty) ...[
                    const Icon(
                      Icons.local_hospital_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.department,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (entry.floor.isNotEmpty) ...[
                    const Spacer(),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Color(0xFFE11D48),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      entry.floor,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
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
