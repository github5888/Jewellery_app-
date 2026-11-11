import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../vitals/record_vitals_screen.dart';

/// Native Mobile OPD Queue & Triage Screen (`GET /api/opd`):
/// - Clean `MobileScreenHeader` + `ABHA Scan` button
/// - Sleek 4-column OPD Queue Strip (`Waiting`, `In Consult`, `Scheduled`, `Completed`)
/// - Segmented Filter Pills (`Waiting` default, `In Consultation`, `Scheduled`, `Completed`, `Cancelled`, `All`)
/// - Search (`Search by Patient, OPD, Case ID..`)
/// - Floating white OPD Consultation Cards with `Vitals` recording action.
class OpdTriageScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const OpdTriageScreen({
    super.key,
    this.isEmbeddedInShell = false,
  });

  @override
  State<OpdTriageScreen> createState() => _OpdTriageScreenState();
}

class _OpdTriageScreenState extends State<OpdTriageScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedTab = 'waiting';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final visits = controller.opdQueue;

    final waitingList =
        visits.where((v) => v.statusCategory == 'Waiting').toList();
    final inConsultList =
        visits.where((v) => v.statusCategory == 'In Consultation').toList();
    final scheduledList =
        visits.where((v) => v.statusCategory == 'Scheduled').toList();
    final completedList =
        visits.where((v) => v.statusCategory == 'Completed').toList();
    final cancelledList =
        visits.where((v) => v.statusCategory == 'Cancelled').toList();

    List<OpdVisitRecord> activeList;
    switch (_selectedTab) {
      case 'waiting':
        activeList = waitingList;
        break;
      case 'in_consultation':
        activeList = inConsultList;
        break;
      case 'scheduled':
        activeList = scheduledList;
        break;
      case 'completed':
        activeList = completedList;
        break;
      case 'cancelled':
        activeList = cancelledList;
        break;
      case 'all':
      default:
        activeList = visits;
        break;
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = activeList.where((v) {
      if (q.isEmpty) return true;
      return v.patient.patientName.toLowerCase().contains(q) ||
          v.patient.patientUniqueId.toLowerCase().contains(q) ||
          v.opdNo.toLowerCase().contains(q) ||
          v.caseReferenceId.toLowerCase().contains(q) ||
          v.doctorName.toLowerCase().contains(q);
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
              title: 'OPD Queue',
              subtitle: 'Outpatient consultations & triage vitals',
              countBadge: '${visits.length}',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showAbhaQueueSheet(context),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 16,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        controller.pendingAbhaCount > 0
                            ? 'ABHA (${controller.pendingAbhaCount})'
                            : 'ABHA',
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4-Column Compact OPD Queue Summary Strip
          Row(
            children: [
              Expanded(
                child: _MiniQueueMetric(
                  label: 'Waiting',
                  value: '${waitingList.length}',
                  accent: const Color(0xFFD97706),
                  selected: _selectedTab == 'waiting',
                  onTap: () => setState(() => _selectedTab = 'waiting'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniQueueMetric(
                  label: 'Consult',
                  value: '${inConsultList.length}',
                  accent: const Color(0xFF2563EB),
                  selected: _selectedTab == 'in_consultation',
                  onTap: () => setState(() => _selectedTab = 'in_consultation'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniQueueMetric(
                  label: 'Scheduled',
                  value: '${scheduledList.length}',
                  accent: const Color(0xFF7C3AED),
                  selected: _selectedTab == 'scheduled',
                  onTap: () => setState(() => _selectedTab = 'scheduled'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniQueueMetric(
                  label: 'Done',
                  value: '${completedList.length}',
                  accent: const Color(0xFF059669),
                  selected: _selectedTab == 'completed',
                  onTap: () => setState(() => _selectedTab = 'completed'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by Patient, OPD, Case ID..',
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

          // Queue Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QueueTabChip(
                  label: 'Waiting (${waitingList.length})',
                  selected: _selectedTab == 'waiting',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'waiting'),
                ),
                const SizedBox(width: 6),
                _QueueTabChip(
                  label: 'In Consultation (${inConsultList.length})',
                  selected: _selectedTab == 'in_consultation',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'in_consultation'),
                ),
                const SizedBox(width: 6),
                _QueueTabChip(
                  label: 'Scheduled (${scheduledList.length})',
                  selected: _selectedTab == 'scheduled',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'scheduled'),
                ),
                const SizedBox(width: 6),
                _QueueTabChip(
                  label: 'Completed (${completedList.length})',
                  selected: _selectedTab == 'completed',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'completed'),
                ),
                const SizedBox(width: 6),
                _QueueTabChip(
                  label: 'Cancelled (${cancelledList.length})',
                  selected: _selectedTab == 'cancelled',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'cancelled'),
                ),
                const SizedBox(width: 6),
                _QueueTabChip(
                  label: 'All (${visits.length})',
                  selected: _selectedTab == 'all',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (filtered.isEmpty)
            const SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.medical_information_outlined,
                title: 'No Consultations in Queue',
                subtitle: 'Switch queue tabs above or pull down to refresh.',
              ),
            )
          else
            ...filtered.map(
              (visit) => _OpdVisitCard(visit: visit, primaryColor: primary),
            ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return SafeArea(bottom: false, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('OPD - Out Patient')),
      body: content,
    );
  }

  void _showAbhaQueueSheet(BuildContext context) {
    final controller = NursePortalScope.read(context);
    final tokens = controller.abhaQueue;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ABHA Scan & Share (${tokens.length})',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 12),
              Expanded(
                child: tokens.isEmpty
                    ? const ClinicalEmptyState(
                        icon: Icons.qr_code_2_rounded,
                        title: 'No ABHA Scan Tokens',
                        subtitle:
                            'Patients scanning the hospital ABDM QR appear here.',
                      )
                    : ListView.separated(
                        itemCount: tokens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = tokens[index];
                          return SoftSurfaceCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '#${t.tokenNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        [
                                          if (t.abhaNumber.isNotEmpty)
                                            t.abhaNumber,
                                          if (t.mobile.isNotEmpty) t.mobile,
                                          t.status,
                                        ].join(' • '),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniQueueMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _MiniQueueMetric({
    required this.label,
    required this.value,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: selected ? accent : AppColors.textPrimary,
                fontSize: 20,
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
      ),
    );
  }
}

class _QueueTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _QueueTabChip({
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

class _OpdVisitCard extends StatelessWidget {
  final OpdVisitRecord visit;
  final Color primaryColor;

  const _OpdVisitCard({
    required this.visit,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final time24 = AppFormatters.formatTime24h(visit.appointmentDate);

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    visit.opdNo,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (visit.caseReferenceId.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    visit.caseReferenceId,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: visit.hasVitalsRecorded
                        ? AppColors.successSoft
                        : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    visit.hasVitalsRecorded
                        ? '✓ Vitals Done'
                        : '• Vitals Pending',
                    style: TextStyle(
                      color: visit.hasVitalsRecorded
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.patient.patientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (visit.patient.patientUniqueId.isNotEmpty)
                            visit.patient.patientUniqueId,
                          if (visit.patient.age > 0) '${visit.patient.age} Yrs',
                          visit.patient.gender,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatDateShort(visit.appointmentDate),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (time24.isNotEmpty)
                      Text(
                        time24,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.doctorName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (visit.symptoms.trim().isNotEmpty)
                        Text(
                          visit.symptoms,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecordVitalsScreen(opdVisit: visit),
                      ),
                    );
                  },
                  icon: const Icon(Icons.monitor_heart_outlined, size: 15),
                  label: const Text(
                    'Vitals',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
