import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/nursing_task_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../medications/medications_mar_screen.dart';
import '../opd/opd_triage_screen.dart';
import '../patients/ipd_patient_detail_screen.dart';
import '../vitals/record_vitals_screen.dart';

/// Screen 8 of Nurse Portal UI (`Nursing Tasks`):
/// Displays 100% live clinical nursing tasks from ward vitals, MAR doses,
/// OPD triage queue, and consultant round orders.
class NursingTasksScreen extends StatefulWidget {
  final bool isEmbeddedInTab;

  const NursingTasksScreen({
    super.key,
    this.isEmbeddedInTab = false,
  });

  @override
  State<NursingTasksScreen> createState() => _NursingTasksScreenState();
}

class _NursingTasksScreenState extends State<NursingTasksScreen> {
  bool _showCompleted = false;
  String? _selectedTaskId;

  Future<void> _executeTask(
    BuildContext context,
    NursingTaskItem task,
  ) async {
    final controller = NursePortalScope.read(context);

    switch (task.kind) {
      case NursingTaskKind.ipdVitals:
        final ipd = controller.admittedPatients
            .where((a) => a.id == task.ipdId)
            .firstOrNull;
        if (ipd != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecordVitalsScreen(ipdAdmission: ipd),
            ),
          );
        } else if (task.ipdId != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IpdPatientDetailScreen(ipdId: task.ipdId!),
            ),
          );
        }
        break;

      case NursingTaskKind.opdTriageVitals:
        final opd = controller.opdQueue
            .where((o) => o.id == task.opdId)
            .firstOrNull;
        if (opd != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecordVitalsScreen(opdVisit: opd),
            ),
          );
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OpdTriageScreen()),
          );
        }
        break;

      case NursingTaskKind.medicationDose:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MedicationsMarScreen(
              filterIpdId: task.ipdId,
              patientTitle:
                  task.patientName.isNotEmpty ? task.patientName : null,
            ),
          ),
        );
        break;

      case NursingTaskKind.doctorInstruction:
      case NursingTaskKind.nursingCareNote:
        if (task.ipdId != null && task.ipdId!.isNotEmpty) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IpdPatientDetailScreen(ipdId: task.ipdId!),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final pending = controller.pendingNursingTasks;
    final completed = controller.completedNursingTasks;
    final activeList = _showCompleted ? completed : pending;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedInTab,
        title: const Text('Nursing Tasks'),
      ),
      body: Column(
        children: [
          // Top Toggle (`Pending (N)` | `Completed` — matching image-2.png)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompleted = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_showCompleted
                            ? Colors.white
                            : const Color(0xFFE3ECF8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: !_showCompleted
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Pending (${pending.length})',
                        style: TextStyle(
                          color: !_showCompleted
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCompleted = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _showCompleted
                            ? Colors.white
                            : const Color(0xFFE3ECF8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _showCompleted
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Completed (${completed.length})',
                        style: TextStyle(
                          color: _showCompleted
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.refreshWorkspace(),
              child: activeList.isEmpty
                  ? ListView(
                      children: [
                        ClinicalEmptyState(
                          icon: _showCompleted
                              ? Icons.task_outlined
                              : Icons.verified_rounded,
                          title: _showCompleted
                              ? 'No Completed Tasks Yet'
                              : 'All Ward Nursing Tasks Up to Date!',
                          subtitle: _showCompleted
                              ? 'Vitals, MAR doses, and care notes you record will appear here.'
                              : 'No pending vitals, medications, or OPD triage tasks at this moment.',
                          actionLabel: 'Refresh Tasks',
                          onAction: () => controller.refreshWorkspace(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: activeList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) {
                        final task = activeList[idx];
                        final selected = _selectedTaskId == task.id;

                        return SoftSurfaceCard(
                          onTap: () {
                            setState(() => _selectedTaskId = task.id);
                            _executeTask(context, task);
                          },
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: task.isCompleted
                                      ? AppColors.successSoft
                                      : (task.isUrgent
                                          ? AppColors.dangerSoft
                                          : AppColors.skySurface),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle_rounded
                                      : (task.isUrgent
                                          ? Icons.shield_rounded
                                          : (selected
                                              ? Icons.radio_button_checked_rounded
                                              : Icons.radio_button_unchecked_rounded)),
                                  color: task.isCompleted
                                      ? AppColors.success
                                      : (task.isUrgent
                                          ? AppColors.danger
                                          : AppColors.primary),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${task.patientName} • ${task.locationLabel}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (task.isUrgent && !task.isCompleted)
                                          'Urgent',
                                        task.subtitle,
                                        if (task.timestamp != null)
                                          AppFormatters.formatTime12h(
                                            task.timestamp,
                                          ),
                                      ].join(' • '),
                                      style: TextStyle(
                                        color: task.isUrgent && !task.isCompleted
                                            ? AppColors.danger
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight:
                                            task.isUrgent && !task.isCompleted
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
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
      bottomNavigationBar: !_showCompleted && pending.isNotEmpty
          ? Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: ElevatedButton(
                onPressed: () {
                  final target = pending
                          .where((t) => t.id == _selectedTaskId)
                          .firstOrNull ??
                      pending.first;
                  _executeTask(context, target);
                },
                child: const Text('Update Tasks'),
              ),
            )
          : null,
    );
  }
}
