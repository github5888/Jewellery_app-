import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Annual Calendar (`GET /api/holidays` — matches Web Screenshot 726)
class AnnualCalendarScreen extends StatefulWidget {
  const AnnualCalendarScreen({super.key});

  @override
  State<AnnualCalendarScreen> createState() => _AnnualCalendarScreenState();
}

class _AnnualCalendarScreenState extends State<AnnualCalendarScreen> {
  List<HospitalHolidayItem> _holidays = const [];
  String _filter = 'All'; // All | Upcoming | Past
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await NursePortalScope.read(context).api.fetchHolidays();
      if (mounted) {
        setState(() {
          _holidays = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final filtered = _holidays.where((h) {
      if (_filter == 'All' || h.fromDate == null) return true;
      if (_filter == 'Past') return h.fromDate!.isBefore(todayStart);
      return !h.fromDate!.isBefore(todayStart);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Annual Calendar (${_holidays.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: ['All', 'Upcoming', 'Past'].map((tab) {
                final active = _filter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = tab),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ClinicalErrorState(message: _error!, onRetry: _load)
                    : filtered.isEmpty
                        ? ClinicalEmptyState(
                            icon: Icons.calendar_today_outlined,
                            title: 'No Calendar Holidays Found',
                            subtitle:
                                'Hospital holidays and events from /api/holidays appear here.',
                            actionLabel: 'Refresh',
                            onAction: _load,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, idx) {
                                final h = filtered[idx];
                                return SoftSurfaceCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.infoSoft,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.event_available_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              h.title,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              [
                                                AppFormatters.formatDateShort(
                                                  h.fromDate,
                                                ),
                                                h.createdBy,
                                              ].join(' • '),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(label: h.type),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
