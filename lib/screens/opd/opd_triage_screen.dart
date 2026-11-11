import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';
import '../vitals/record_vitals_screen.dart';

/// Section 6: OPD Triage Desk (`GET /api/opd` & `POST /api/opd/:id/vitals`)
/// Matches Web Portal Screenshot 723 (`Waiting`, `In Consultation`, `Scheduled`, `Completed`).
class OpdTriageScreen extends StatefulWidget {
  const OpdTriageScreen({super.key});

  @override
  State<OpdTriageScreen> createState() => _OpdTriageScreenState();
}

class _OpdTriageScreenState extends State<OpdTriageScreen> {
  String _statusTab = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesTab(OpdVisitRecord o, String tab) {
    if (tab == 'All') return true;
    final st = o.status.toLowerCase();
    switch (tab) {
      case 'Waiting':
        return st.contains('wait') || st.contains('pend');
      case 'In Consultation':
        return st.contains('consult') || st.contains('progress');
      case 'Scheduled':
        return st.contains('sched');
      case 'Completed':
        return st.contains('comp') || st.contains('done');
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final allOpd = controller.opdQueue;
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = allOpd.where((o) {
      if (!_matchesTab(o, _statusTab)) return false;
      if (q.isEmpty) return true;
      return o.patient.patientName.toLowerCase().contains(q) ||
          o.patient.patientUniqueId.toLowerCase().contains(q) ||
          o.opdNo.toLowerCase().contains(q) ||
          o.caseReferenceId.toLowerCase().contains(q) ||
          o.doctorName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('OPD Triage Queue')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by Patient, OPD No, Case ID...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                'All',
                'Waiting',
                'In Consultation',
                'Scheduled',
                'Completed',
              ].map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TabButtonChip(
                    label: t,
                    selected: _statusTab == t,
                    onTap: () => setState(() => _statusTab = t),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.refreshWorkspace(),
              child: filtered.isEmpty
                  ? ListView(
                      children: [
                        ClinicalEmptyState(
                          icon: Icons.queue_play_next_rounded,
                          title: 'No OPD Patients in Queue',
                          subtitle:
                              'Patients waiting outside OPD cabins appear here for pre-consultation triage vitals.',
                          actionLabel: 'Refresh Queue',
                          onAction: () => controller.refreshWorkspace(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) {
                        final opd = filtered[idx];
                        return SoftSurfaceCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      opd.opdNo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(
                                    label: opd.hasVitalsRecorded
                                        ? 'Vitals Recorded'
                                        : 'Vitals Pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                opd.patient.patientName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (opd.patient.patientUniqueId.isNotEmpty)
                                    opd.patient.patientUniqueId,
                                  if (opd.caseReferenceId.isNotEmpty)
                                    opd.caseReferenceId,
                                  opd.doctorName,
                                ].join(' • '),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                              if (opd.symptoms.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  opd.symptoms,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppFormatters.formatDateTimeShort(
                                      opd.appointmentDate,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(124, 38),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => RecordVitalsScreen(
                                            opdVisit: opd,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.favorite_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Vitals',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
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

class _TabButtonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButtonChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8.5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
