import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Website-Aligned Annual Calendar Screen (`/calendar` — image-21):
/// - Live `GET /api/holidays` integration
/// - Header pills (`India · 2026`, `14 Holidays`)
/// - Exact 4 Tabs (`Upcoming`, `Today`, `Past`, `All Holidays`) with live counts
/// - Exact `All Types` dropdown (`All Types`, `Holiday`, `Activity`, `Vacation` + any live custom types)
/// - `Search description, date...` + Holiday Cards (`DATE`, `TYPE`, `DESCRIPTION`, `CREATED BY`, `FRONT SITE`, `Default`).
class AnnualCalendarScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const AnnualCalendarScreen({
    super.key,
    this.isEmbeddedInShell = false,
  });

  @override
  State<AnnualCalendarScreen> createState() => _AnnualCalendarScreenState();
}

class _AnnualCalendarScreenState extends State<AnnualCalendarScreen> {
  static const List<String> _websiteBaseTypes = [
    'Holiday',
    'Activity',
    'Vacation',
  ];

  final _searchCtrl = TextEditingController();
  String _selectedTab = 'upcoming';
  String _selectedType = 'All Types';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _buildTypeOptions(List<HospitalHolidayItem> allHolidays) {
    final seenLower = <String>{'all types'};
    final ordered = <String>['All Types'];

    for (final base in _websiteBaseTypes) {
      seenLower.add(base.toLowerCase());
      ordered.add(base);
    }

    for (final h in allHolidays) {
      final raw = h.type.trim();
      if (raw.isEmpty) continue;
      if (seenLower.add(raw.toLowerCase())) {
        ordered.add(raw);
      }
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final allHolidays = List<HospitalHolidayItem>.from(controller.holidays)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });

    final now = DateTime.now();
    final upcomingList = allHolidays.where((h) => h.isUpcoming(now)).toList();
    final todayList = allHolidays.where((h) => h.isToday(now)).toList();
    final pastList = allHolidays.where((h) => h.isPast(now)).toList();

    final typeOptions = _buildTypeOptions(allHolidays);
    final activeType =
        typeOptions.contains(_selectedType) ? _selectedType : 'All Types';

    List<HospitalHolidayItem> tabList;
    switch (_selectedTab) {
      case 'upcoming':
        tabList = upcomingList;
        break;
      case 'today':
        tabList = todayList;
        break;
      case 'past':
        tabList = pastList;
        break;
      case 'all':
      default:
        tabList = allHolidays;
        break;
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = tabList.where((h) {
      if (activeType != 'All Types' &&
          h.type.trim().toLowerCase() != activeType.toLowerCase()) {
        return false;
      }
      if (q.isNotEmpty) {
        final dateStr = AppFormatters.formatCalendarDate(h.date).toLowerCase();
        return h.title.toLowerCase().contains(q) ||
            h.createdBy.toLowerCase().contains(q) ||
            h.type.toLowerCase().contains(q) ||
            dateStr.contains(q);
      }
      return true;
    }).toList();

    final isTypeFiltered = activeType != 'All Types';

    final content = RefreshIndicator(
      color: primary,
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: 'Annual Calendar',
              subtitle: 'Administration / Annual Calendar',
              countBadge: '${allHolidays.length} Holidays',
              trailingAction: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  'India · ${now.year}',
                  style: const TextStyle(
                    color: Color(0xFFC2410C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          // Exact 4 Website Tabs (`Upcoming`, `Today`, `Past`, `All Holidays`)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CalendarTabPill(
                  label: 'Upcoming',
                  count: upcomingList.length,
                  selected: _selectedTab == 'upcoming',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'upcoming'),
                ),
                const SizedBox(width: 7),
                _CalendarTabPill(
                  label: 'Today',
                  count: todayList.length,
                  selected: _selectedTab == 'today',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'today'),
                ),
                const SizedBox(width: 7),
                _CalendarTabPill(
                  label: 'Past',
                  count: pastList.length,
                  selected: _selectedTab == 'past',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'past'),
                ),
                const SizedBox(width: 7),
                _CalendarTabPill(
                  label: 'All Holidays',
                  count: allHolidays.length,
                  selected: _selectedTab == 'all',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // `All Types` Dropdown (`All Types`, `Holiday`, `Activity`, `Vacation`) + Search Box
          Row(
            children: [
              Container(
                width: 136,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: isTypeFiltered ? primary.withAlpha(14) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        isTypeFiltered ? primary.withAlpha(120) : AppColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 15,
                      color: isTypeFiltered ? primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activeType,
                          isExpanded: true,
                          isDense: true,
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: isTypeFiltered
                                ? primary
                                : AppColors.textSecondary,
                          ),
                          style: TextStyle(
                            color:
                                isTypeFiltered ? primary : AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                          items: typeOptions
                              .map(
                                (t) => DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedType = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PremiumSearchField(
                  controller: _searchCtrl,
                  accentColor: primary,
                  hintText: 'Search description, date...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.event_note_outlined,
                title: 'No Calendar Events in View',
                subtitle: isTypeFiltered || q.isNotEmpty
                    ? 'No "$activeType" records match the current tab or search.'
                    : 'Switch tabs above to view other calendar dates.',
                actionLabel:
                    (isTypeFiltered || q.isNotEmpty) ? 'Reset Filter' : null,
                onAction: (isTypeFiltered || q.isNotEmpty)
                    ? () => setState(() {
                          _selectedType = 'All Types';
                          _searchCtrl.clear();
                        })
                    : null,
              ),
            )
          else ...[
            ...filtered.map(
              (item) => _HolidayCard(item: item, primaryColor: primary),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Records: 1 to ${filtered.length} of ${filtered.length}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Type: $activeType',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      appBar: AppBar(title: const Text('Annual Calendar')),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: content,
      ),
    );
  }
}

class _CalendarTabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _CalendarTabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? primary : AppColors.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primary.withAlpha(55),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withAlpha(45)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFeatures: AppTheme.tabularNums,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final HospitalHolidayItem item;
  final Color primaryColor;

  const _HolidayCard({
    required this.item,
    required this.primaryColor,
  });

  ({Color bg, Color fg}) _typePalette(String type) {
    final lower = type.trim().toLowerCase();
    if (lower == 'activity') {
      return (bg: const Color(0xFFF3E8FF), fg: const Color(0xFF7E22CE));
    }
    if (lower == 'vacation') {
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    }
    return (bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0369A1));
  }

  @override
  Widget build(BuildContext context) {
    final dt = item.date?.toLocal();
    final dayNum = dt != null ? dt.day.toString().padLeft(2, '0') : '—';
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final monLabel = dt != null ? months[dt.month - 1] : '';
    final typeColors = _typePalette(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sculpted Two-Tone Calendar Leaf Badge
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      monLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      dayNum,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontFeatures: AppTheme.tabularNums,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColors.bg,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          item.type,
                          style: TextStyle(
                            color: typeColors.fg,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppFormatters.formatCalendarDate(item.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 13,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.createdBy,
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.frontSite
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.frontSite
                                  ? Icons.check_circle_rounded
                                  : Icons.remove_circle_outline_rounded,
                              size: 11,
                              color: item.frontSite
                                  ? const Color(0xFF16A34A)
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Front Site: ${item.frontSite ? "Yes" : "No"}',
                              style: TextStyle(
                                color: item.frontSite
                                    ? const Color(0xFF047857)
                                    : AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 10.5,
                                color: Color(0xFF15803D),
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Default',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
