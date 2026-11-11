import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Annual Calendar Screen (`https://hospital.hrpocket.in/calendar` — matches image-11 1-to-1):
/// - Header: `Annual Calendar` + `India • 2026` blue pill + `N Holidays` green pill
/// - Tabs: `Upcoming (N)` (default), `Today (N)`, `Past (N)`, `All Holidays (N)`
/// - Filter & Search: `All Types` dropdown (`All Types`, `Holiday`, `Activity`, `Vacation`) + `Search description, date...`
/// - Holiday Card: `Tue, 24 Nov, 2026`, `Holiday` amber pill, `Guru Nanak's Birthday`,
///   `Government of India`, `Front Site: Yes` green pill, `Default` badge
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
  String _selectedTab = 'upcoming'; // upcoming | today | past | all
  String _selectedType = 'All Types';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final allHolidays = List<HospitalHolidayItem>.from(controller.holidays)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });

    final now = DateTime.now();
    final upcomingList =
        allHolidays.where((h) => h.isUpcoming(now)).toList();
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

    final yearLabel = now.year;

    final body = RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          // Header Card (`Annual Calendar` + `India • 2026` + `14 Holidays` — image-11)
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
                        Icons.calendar_month_rounded,
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
                            spacing: 7,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Annual Calendar',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'India • $yearLabel',
                                  style: const TextStyle(
                                    color: Color(0xFF0369A1),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${allHolidays.length} Holidays',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Hospital Holidays, Activity Events, Important Dates & Front-Site Notices',
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

                const SizedBox(height: 14),

                // Tabs (`Upcoming (2)`, `Today (0)`, `Past (12)`, `All Holidays (14)` — image-11)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CalendarTabPill(
                        label: 'Upcoming (${upcomingList.length})',
                        selected: _selectedTab == 'upcoming',
                        onTap: () => setState(() => _selectedTab = 'upcoming'),
                      ),
                      const SizedBox(width: 6),
                      _CalendarTabPill(
                        label: 'Today (${todayList.length})',
                        selected: _selectedTab == 'today',
                        onTap: () => setState(() => _selectedTab = 'today'),
                      ),
                      const SizedBox(width: 6),
                      _CalendarTabPill(
                        label: 'Past (${pastList.length})',
                        selected: _selectedTab == 'past',
                        onTap: () => setState(() => _selectedTab = 'past'),
                      ),
                      const SizedBox(width: 6),
                      _CalendarTabPill(
                        label: 'All Holidays (${allHolidays.length})',
                        selected: _selectedTab == 'all',
                        onTap: () => setState(() => _selectedTab = 'all'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Type Dropdown + Search Box (`All Types` + `Search description, date...` — image-11)
                Row(
                  children: [
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
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
                            color: Color(0xFF334155),
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
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
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
                  const ClinicalEmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No Calendar Events in This View',
                    subtitle: 'Switch tabs above or clear search filters.',
                  )
                else
                  ...filtered.map((item) => _HolidayCard(item: item)),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Annual Calendar')),
      body: body,
    );
  }
}

class _CalendarTabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CalendarTabPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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

class _HolidayCard extends StatelessWidget {
  final HospitalHolidayItem item;

  const _HolidayCard({required this.item});

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
          // Top Row: Date (`Tue, 24 Nov, 2026`) + Type (`Holiday`) + `Default`
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppFormatters.formatCalendarDate(item.date),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.type,
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (item.isDefault) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Description (`Guru Nanak's Birthday` / `Christmas Day` — image-11)
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          // Created By (`Government of India`) & Front Site (`Yes`)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Created By: ${item.createdBy}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.frontSite
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Front Site: ${item.frontSite ? "Yes" : "No"}',
                  style: TextStyle(
                    color: item.frontSite
                        ? const Color(0xFF15803D)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
