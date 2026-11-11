import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Hospital Appointments (`GET https://hospital.hrpocket.in/api/appointments`)
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<HospitalAppointmentItem> _items = const [];
  String _tab = 'All'; // All | Upcoming | Completed | Cancelled
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await NursePortalScope.read(context).api.fetchAppointments();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((a) {
      if (_tab == 'All') return true;
      final st = a.status.toLowerCase();
      if (_tab == 'Completed') return st.contains('comp') || st.contains('done');
      if (_tab == 'Cancelled') return st.contains('cancel') || st.contains('noshow');
      return !st.contains('comp') && !st.contains('cancel');
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Appointments (${_items.length})')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: ['All', 'Upcoming', 'Completed', 'Cancelled'].map((t) {
                final active = _tab == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: active,
                    onSelected: (_) => setState(() => _tab = t),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? ClinicalEmptyState(
                        icon: Icons.event_note_outlined,
                        title: 'No Appointments Found',
                        subtitle:
                            'Scheduled consultations from /api/appointments appear here.',
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
                            final a = filtered[idx];
                            return SoftSurfaceCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.patientName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      StatusBadge(label: a.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (a.appointmentNo.isNotEmpty)
                                        a.appointmentNo,
                                      a.doctorName,
                                      if (a.department.isNotEmpty) a.department,
                                    ].join(' • '),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      AppFormatters.formatDateTimeShort(a.date),
                                      if (a.slot.isNotEmpty) a.slot,
                                    ].join(' • '),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
