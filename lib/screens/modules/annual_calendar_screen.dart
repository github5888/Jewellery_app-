import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Executive Mobile Annual Calendar Screen (`GET /api/holidays`):
/// - Studio-lit `PremiumScreenBackground` + `MobileScreenHeader`
/// - Smooth Capsule Tabs (`Upcoming`, `Today`, `Past`, `All`)
/// - `PremiumSearchField` + Type Selector
/// - Sculpted Two-Tone Calendar Leaf Holiday Cards (`NOV 24`, `Guru Nanak's Birthday`, `Front Site: Yes`).
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

          // Capsule Tabs Row
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
                const SizedBox(width: 7),
                _CalendarTabPill(
                  label: 'Today (${todayList.length})',
                  selected: _selectedTab == 'today',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'today'),
                ),
                const SizedBox(width: 7),
                _CalendarTabPill(
                  label: 'Past (${pastList.length})',
                  selected: _selectedTab == 'past',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'past'),
                ),
                const SizedBox(width: 7),
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

          // Search + Type Filter
          Row(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
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
                      fontWeight: FontWeight.w800,
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
                child: PremiumSearchField(
                  controller: _searchCtrl,
                  accentColor: primary,
                  hintText: 'Search holiday or date...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
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
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(7),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: item.frontSite
                              ? AppColors.successSoft
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(7),
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
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
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
