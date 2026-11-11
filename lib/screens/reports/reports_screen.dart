import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/clinical_report_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';
import 'report_viewer_screen.dart';

/// Screen 9 of Nurse Portal UI (`Reports`):
/// Tabs: `Lab`, `Radiology`, `Others` + authenticated clinical report viewer.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ClinicalReportCategory _tab = ClinicalReportCategory.lab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NursePortalScope.read(context).refreshClinicalReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final hospital = controller.hospitalInfo;

    List<ClinicalReportRecord> activeReports;
    switch (_tab) {
      case ClinicalReportCategory.lab:
        activeReports = controller.labReports;
        break;
      case ClinicalReportCategory.radiology:
        activeReports = controller.radiologyReports;
        break;
      case ClinicalReportCategory.others:
        activeReports = controller.otherClinicalDocuments;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          // Category Tabs (`Lab`, `Radiology`, `Others` — matching image-2.png)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                _ReportTabChip(
                  label: 'Lab',
                  selected: _tab == ClinicalReportCategory.lab,
                  onTap: () => setState(() => _tab = ClinicalReportCategory.lab),
                ),
                const SizedBox(width: 8),
                _ReportTabChip(
                  label: 'Radiology',
                  selected: _tab == ClinicalReportCategory.radiology,
                  onTap: () =>
                      setState(() => _tab = ClinicalReportCategory.radiology),
                ),
                const SizedBox(width: 8),
                _ReportTabChip(
                  label: 'Others',
                  selected: _tab == ClinicalReportCategory.others,
                  onTap: () =>
                      setState(() => _tab = ClinicalReportCategory.others),
                ),
              ],
            ),
          ),

          if (controller.isLoadingReports)
            const LinearProgressIndicator(minHeight: 2.5),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.refreshClinicalReports();
                await controller.refreshWorkspace(silent: true);
              },
              child: controller.reportsError != null && activeReports.isEmpty
                  ? ListView(
                      children: [
                        ClinicalErrorState(
                          message: controller.reportsError!,
                          onRetry: controller.refreshClinicalReports,
                        ),
                      ],
                    )
                  : activeReports.isEmpty
                      ? ListView(
                          children: [
                            ClinicalEmptyState(
                              icon: Icons.description_outlined,
                              title: 'No Clinical Reports Available',
                              subtitle:
                                  'Pathology lab bills, radiology scans, and bedside documents appear here as soon as generated.',
                              actionLabel: 'Refresh Reports',
                              onAction: controller.refreshClinicalReports,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                          itemCount: activeReports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, idx) {
                            final rep = activeReports[idx];
                            return SoftSurfaceCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportViewerScreen(report: rep),
                                  ),
                                );
                              },
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.infoSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      rep.category ==
                                              ClinicalReportCategory.radiology
                                          ? Icons.medical_information_rounded
                                          : Icons.description_rounded,
                                      color: AppColors.primary,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rep.title,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            rep.patientName,
                                            if (rep.date != null)
                                              AppFormatters.formatDateShort(
                                                rep.date,
                                              ),
                                          ].join(' • '),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (rep.hasDownloadableFile)
                                              const Text(
                                                'Download',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              )
                                            else
                                              StatusBadge(label: rep.status),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    rep.hasDownloadableFile
                                        ? Icons.download_rounded
                                        : Icons.chevron_right_rounded,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),

          // Need Help? Contact Support Footer Card (matching image-2.png)
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              6,
              18,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            child: SoftSurfaceCard(
              color: const Color(0xFFEAF3FE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need Help?',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          hospital.phone.isNotEmpty
                              ? 'Lab / IT Desk: ${hospital.phone}'
                              : 'Contact ${hospital.name} Diagnostic Desk',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
