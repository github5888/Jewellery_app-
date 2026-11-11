import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../vitals/record_vitals_screen.dart';

/// OPD Out-Patient Department Screen (`https://hospital.hrpocket.in/opd` — matches image-7 1-to-1):
/// - Top 4 KPI Cards: `WAITING QUEUE`, `IN CONSULTATION`, `SCHEDULED TODAY`, `COMPLETED TODAY`
/// - Tabs: `Waiting (N)` (default), `In Consultation (N)`, `Scheduled`, `Completed`, `Cancelled`, `Patient View`
/// - `ABHA Scan & Share` button (opens live `/api/opd/abha-queue` sheet)
/// - Search box: `Search by Patient, OPD, Case ID..`
/// - OPD Visit Card: `OPDN1015`, Patient Name, `PAT-1009`, `CASE-896774`, `10 Nov 2026 • 19:41`,
///   `Dr. Ajay Verma`, `Vitals Pending` / `Vitals Recorded`, Symptoms, `[Vitals]` button
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

    final body = RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          // Top 4 KPI Cards (matching image-7)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _OpdStatCard(
                icon: Icons.hourglass_bottom_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconFg: const Color(0xFFD97706),
                value: '${waitingList.length}',
                label: 'WAITING QUEUE',
                subtitle: 'Patients waiting to see doctor',
                selected: _selectedTab == 'waiting',
                onTap: () => setState(() => _selectedTab = 'waiting'),
              ),
              _OpdStatCard(
                icon: Icons.medical_information_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconFg: const Color(0xFF0284C7),
                value: '${inConsultList.length}',
                label: 'IN CONSULTATION',
                subtitle: 'Currently with doctor',
                selected: _selectedTab == 'in_consultation',
                onTap: () => setState(() => _selectedTab = 'in_consultation'),
              ),
              _OpdStatCard(
                icon: Icons.event_available_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconFg: const Color(0xFF7E22CE),
                value: '${scheduledList.length}',
                label: 'SCHEDULED TODAY',
                subtitle: 'Upcoming slots today',
                selected: _selectedTab == 'scheduled',
                onTap: () => setState(() => _selectedTab = 'scheduled'),
              ),
              _OpdStatCard(
                icon: Icons.check_circle_outline_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconFg: const Color(0xFF16A34A),
                value: '${completedList.length}',
                label: 'COMPLETED TODAY',
                subtitle: 'Finished consultations today',
                selected: _selectedTab == 'completed',
                onTap: () => setState(() => _selectedTab = 'completed'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + ABHA Scan & Share Button (matching image-7)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OPD Out-Patient Department',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Live Consultation Queue, Vitals Triage & Prescription Desk',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showAbhaQueueSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 15,
                              color: Color(0xFF047857),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'ABHA Scan & Share',
                              style: TextStyle(
                                color: Color(0xFF047857),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (controller.pendingAbhaCount > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${controller.pendingAbhaCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tabs Row (`Waiting (2)`, `In Consultation (4)`, `Scheduled`, `Completed`, `Cancelled`, `Patient View` — image-7)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _OpdTabPill(
                        label: 'Waiting',
                        count: waitingList.length,
                        selected: _selectedTab == 'waiting',
                        activeColor: const Color(0xFFF59E0B),
                        onTap: () => setState(() => _selectedTab = 'waiting'),
                      ),
                      const SizedBox(width: 6),
                      _OpdTabPill(
                        label: 'In Consultation',
                        count: inConsultList.length,
                        selected: _selectedTab == 'in_consultation',
                        activeColor: const Color(0xFF0284C7),
                        onTap: () =>
                            setState(() => _selectedTab = 'in_consultation'),
                      ),
                      const SizedBox(width: 6),
                      _OpdTabPill(
                        label: 'Scheduled',
                        count: scheduledList.length,
                        selected: _selectedTab == 'scheduled',
                        activeColor: const Color(0xFF7E22CE),
                        onTap: () => setState(() => _selectedTab = 'scheduled'),
                      ),
                      const SizedBox(width: 6),
                      _OpdTabPill(
                        label: 'Completed',
                        count: completedList.length,
                        selected: _selectedTab == 'completed',
                        activeColor: const Color(0xFF16A34A),
                        onTap: () => setState(() => _selectedTab = 'completed'),
                      ),
                      const SizedBox(width: 6),
                      _OpdTabPill(
                        label: 'Cancelled',
                        count: cancelledList.length,
                        selected: _selectedTab == 'cancelled',
                        activeColor: const Color(0xFF64748B),
                        onTap: () => setState(() => _selectedTab = 'cancelled'),
                      ),
                      const SizedBox(width: 6),
                      _OpdTabPill(
                        label: 'All Visits',
                        count: visits.length,
                        selected: _selectedTab == 'all',
                        activeColor: const Color(0xFF0A4D78),
                        onTap: () => setState(() => _selectedTab = 'all'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Search Box (`Search by Patient, OPD, Case ID..` — image-7)
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by Patient, OPD, Case ID..',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
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

                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  const ClinicalEmptyState(
                    icon: Icons.medical_information_outlined,
                    title: 'No OPD Consultations in This Queue',
                    subtitle:
                        'Switch tabs above or pull down to refresh from /api/opd.',
                  )
                else
                  ...filtered.map(
                    (visit) => _OpdVisitCard(visit: visit),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('OPD - Out Patient')),
      body: body,
    );
  }

  void _showAbhaQueueSheet(BuildContext context) {
    final controller = NursePortalScope.read(context);
    final tokens = controller.abhaQueue;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ABHA Scan & Share Queue (${tokens.length})',
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
                        title: 'No ABHA Scan & Share Tokens',
                        subtitle:
                            'Patients scanning the hospital ABDM QR appear here automatically.',
                      )
                    : ListView.separated(
                        itemCount: tokens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = tokens[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '#${t.tokenNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF15803D),
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

class _OpdStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String value;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OpdStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.value,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? iconFg : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconFg, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
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

class _OpdTabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _OpdTabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.activeColor,
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
          color: selected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (count > 0 || selected) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x33FFFFFF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF334155),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpdVisitCard extends StatelessWidget {
  final OpdVisitRecord visit;

  const _OpdVisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final time24 = AppFormatters.formatTime24h(visit.appointmentDate);
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
          // Top Row: OPD No (`OPDN1015`), Case ID (`CASE-896774`), Vitals Badge
          Row(
            children: [
              Text(
                visit.opdNo,
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (visit.caseReferenceId.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    visit.caseReferenceId,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: visit.hasVitalsRecorded
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  visit.hasVitalsRecorded
                      ? '✓ Vitals Recorded'
                      : '• Vitals Pending',
                  style: TextStyle(
                    color: visit.hasVitalsRecorded
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Patient Name & UHID (`Arun Pratap singh • PAT-1009`)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.patient.patientName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (visit.patient.patientUniqueId.isNotEmpty)
                          visit.patient.patientUniqueId,
                        if (visit.patient.age > 0) '${visit.patient.age} Yrs',
                        visit.patient.gender,
                      ].join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
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
                      color: Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (time24.isNotEmpty)
                    Text(
                      time24,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Consultant Doctor & Symptoms (`Dr. Ajay Verma`, `Consultation from Appointment Desk`)
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: Color(0xFF0A4D78),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  visit.doctorName,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (visit.symptoms.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              visit.symptoms,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Action Row: `[Vitals]` button matching image-7
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0369A1),
                backgroundColor: const Color(0xFFE0F2FE),
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
