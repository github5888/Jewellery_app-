import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../vitals/record_vitals_screen.dart';
import 'abha_scan_share_modal.dart';

/// Executive Mobile OPD Queue & Triage Screen (`GET /api/opd`):
/// - Studio-lit `PremiumScreenBackground` + `MobileScreenHeader` + `ABHA Scan` capsule
/// - Sculpted 4-Column OPD Queue Telemetry Strip (`Waiting`, `Consult`, `Scheduled`, `Completed`)
/// - `PremiumSearchField` + Smooth Capsule Filter Pills
/// - Executive OPD Consultation Cards with Token/OPD pill, Vitals status badge, Consultant bar & `Record Vitals` CTA.
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
              title: 'OPD Triage',
              subtitle: 'Out-patient consultations & pre-doctor vitals',
              countBadge: '${visits.length}',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showAbhaQueueSheet(context),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(14),
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
                            : (controller.totalAbhaCount > 0
                                ? 'ABHA (${controller.totalAbhaCount})'
                                : 'ABHA'),
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

          // 4-Column Sculpted OPD Queue Strip
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

          const SizedBox(height: 14),

          // Elevated Pill Search Field
          PremiumSearchField(
            controller: _searchCtrl,
            accentColor: primary,
            hintText: 'Search patient, OPD no, case ID or doctor...',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Queue Filter Capsule Pills
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
                const SizedBox(width: 7),
                _QueueTabChip(
                  label: 'In Consult (${inConsultList.length})',
                  selected: _selectedTab == 'in_consultation',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'in_consultation'),
                ),
                const SizedBox(width: 7),
                _QueueTabChip(
                  label: 'Scheduled (${scheduledList.length})',
                  selected: _selectedTab == 'scheduled',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'scheduled'),
                ),
                const SizedBox(width: 7),
                _QueueTabChip(
                  label: 'Completed (${completedList.length})',
                  selected: _selectedTab == 'completed',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'completed'),
                ),
                const SizedBox(width: 7),
                _QueueTabChip(
                  label: 'Cancelled (${cancelledList.length})',
                  selected: _selectedTab == 'cancelled',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'cancelled'),
                ),
                const SizedBox(width: 7),
                _QueueTabChip(
                  label: 'All (${visits.length})',
                  selected: _selectedTab == 'all',
                  primary: primary,
                  onTap: () => setState(() => _selectedTab = 'all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            const SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.medical_information_outlined,
                title: 'No Consultations in Selected Queue',
                subtitle: 'Switch queue status tabs above or pull down to sync.',
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
      return PremiumScreenBackground(
        accentColor: primary,
        child: SafeArea(bottom: false, child: content),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('OPD - Out Patient'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAbhaQueueSheet(context),
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 17,
                color: Color(0xFFB45309),
              ),
              label: Text(
                controller.pendingAbhaCount > 0
                    ? 'ABHA Scan (${controller.pendingAbhaCount})'
                    : 'ABHA Scan & Share',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: content,
      ),
    );
  }

  void _showAbhaQueueSheet(BuildContext context) {
    showAbhaScanShareModal(context);
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
    return SoftSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: BorderRadius.circular(18),
      borderColor: selected ? accent : AppColors.border,
      color: selected ? accent.withAlpha(14) : Colors.white,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: selected ? accent : AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              fontFeatures: AppTheme.tabularNums,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? accent : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
    final initials = AppFormatters.initials(visit.patient.patientName);

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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          visit.opdNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFeatures: AppTheme.tabularNums,
                          ),
                        ),
                      ),
                      if (visit.caseReferenceId.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Case #${visit.caseReferenceId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: visit.hasVitalsRecorded
                        ? AppColors.successSoft
                        : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    visit.hasVitalsRecorded
                        ? '✓ Vitals Recorded'
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
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
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
                          letterSpacing: -0.3,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 15,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.doctorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (visit.symptoms.trim().isNotEmpty)
                          Text(
                            visit.symptoms,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
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
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecordVitalsScreen(opdVisit: visit),
                        ),
                      );
                    },
                    icon: const Icon(Icons.monitor_heart_rounded, size: 15),
                    label: const Text(
                      'Vitals',
                      style: TextStyle(
                        fontSize: 12,
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
    );
  }
}
