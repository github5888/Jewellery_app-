import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Native Mobile Annual Calendar Screen (`GET /api/holidays`):
/// - Clean `MobileScreenHeader` (`Annual Calendar`, `N Holidays`, `India • 2026` badge)
/// - Segmented Tabs (`Upcoming` default, `Today`, `Past`, `All Holidays`)
/// - Type Filter + Search (`Search description, date...`)
/// - Crisp floating white Holiday Cards (`Tue, 24 Nov, 2026`, `Guru Nanak's Birthday`, `Front Site: Yes`, `Default`).
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
  final _searchCtrl = TextEditingController();
  String _selectedTab = 'upcoming';
  String _selectedType = 'All Types';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

    final typeOptions = <String>{
      'All Types',
      ...allHolidays.map((h) => h.type.trim()).where((t) => t.isNotEmpty),
    }.toList();
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
            dateStr.contains(q);
      }
      return true;
    }).toList();

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
              subtitle: 'India • ${now.year} hospital holidays & notices',
              countBadge: '${allHolidays.length}',
            ),

          // Tabs Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CalendarTabPill(
                  label: 'Upcoming (${upcomingList.length})',
                  selected: _selectedTab == 'upcoming',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'upcoming'),
                ),
                const SizedBox(width: 6),
                _CalendarTabPill(
                  label: 'Today (${todayList.length})',
                  selected: _selectedTab == 'today',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'today'),
                ),
                const SizedBox(width: 6),
                _CalendarTabPill(
                  label: 'Past (${pastList.length})',
                  selected: _selectedTab == 'past',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'past'),
                ),
                const SizedBox(width: 6),
                _CalendarTabPill(
                  label: 'All (${allHolidays.length})',
                  selected: _selectedTab == 'all',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Type Filter + Search Row
          Row(
            children: [
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeType,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    items: typeOptions
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search description, date...',
                    prefixIcon:
                        Icon(Icons.search_rounded, size: 19, color: primary),
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
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (filtered.isEmpty)
            const SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.event_note_outlined,
                title: 'No Calendar Events in View',
                subtitle: 'Switch tabs above or clear search filters.',
              ),
            )
          else
            ...filtered.map(
              (item) => _HolidayCard(item: item, primaryColor: primary),
            ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Annual Calendar')),
      body: content,
    );
  }
}

class _CalendarTabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _CalendarTabPill({
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

class _HolidayCard extends StatelessWidget {
  final HospitalHolidayItem item;
  final Color primaryColor;

  const _HolidayCard({
    required this.item,
    required this.primaryColor,
  });

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftSurfaceCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Clean Calendar Leaf Badge on Left
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monLabel,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
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
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type,
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.formatCalendarDate(item.date)}  •  ${item.createdBy}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.frontSite
                              ? AppColors.successSoft
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Front Site: ${item.frontSite ? "Yes" : "No"}',
                          style: TextStyle(
                            color: item.frontSite
                                ? const Color(0xFF059669)
                                : AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (item.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
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
