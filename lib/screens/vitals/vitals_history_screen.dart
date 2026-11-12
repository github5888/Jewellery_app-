import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/vitals_trend_chart.dart';
import 'record_vitals_screen.dart';

class VitalsHistoryScreen extends StatefulWidget {
  final IpdAdmission admission;

  const VitalsHistoryScreen({super.key, required this.admission});

  @override
  State<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<VitalsHistoryScreen> {
  late IpdAdmission _admission;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _admission = widget.admission;
  }

  Future<void> _reload() async {
    setState(() => _refreshing = true);
    try {
      final fresh = await NursePortalScope.read(context)
          .api
          .fetchIpdPatientDetail(_admission.id);
      if (mounted) {
        setState(() => _admission = fresh);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<VitalSignRecord>.from(_admission.vitals)
      ..sort((a, b) {
        final da = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('Vitals Chart • ${_admission.patient.patientName}'),
        actions: [
          IconButton(
            tooltip: 'Record New Vitals',
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => RecordVitalsScreen(ipdAdmission: _admission),
                ),
              );
              if (ok == true) await _reload();
            },
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            if (_refreshing) const LinearProgressIndicator(minHeight: 2.5),
            SoftSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bedside Vitals Trend',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  VitalsTrendChart(vitals: _admission.vitals),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Recorded Entries (${sorted.length})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (sorted.isEmpty)
              const SoftSurfaceCard(
                child: ClinicalEmptyState(
                  icon: Icons.monitor_heart_outlined,
                  title: 'No Vitals Recorded Yet',
                  subtitle: 'Tap + in the top-right to record bedside vitals.',
                ),
              )
            else
              ...sorted.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftSurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppFormatters.formatDateTimeShort(v.date),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            StatusBadge(
                              label: v.hasCriticalReading ? 'Critical' : 'Normal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          children: [
                            if (v.bp.isNotEmpty) Text('BP: ${v.bp} mmHg'),
                            if (v.pulse.isNotEmpty) Text('HR: ${v.pulse} bpm'),
                            if (v.temperature.isNotEmpty)
                              Text('Temp: ${v.temperature}°F'),
                            if (v.spo2.isNotEmpty) Text('SpO2: ${v.spo2}%'),
                            if (v.respiratoryRate.isNotEmpty)
                              Text('RR: ${v.respiratoryRate}/min'),
                            if (v.weight.isNotEmpty) Text('Wt: ${v.weight} kg'),
                          ],
                        ),
                        if (v.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Note: ${v.notes}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                        if (v.recordedBy.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Logged by ${v.recordedBy}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
