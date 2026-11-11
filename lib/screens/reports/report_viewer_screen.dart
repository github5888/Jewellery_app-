import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/clinical_report_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

/// Authenticated Clinical Report Viewer:
/// Fetches protected `/api/files/pathology_report/*` & `/api/files/radiology_report/*`
/// bytes with `Authorization: Bearer <TOKEN>` (matching backend server.ts).
class ReportViewerScreen extends StatefulWidget {
  final ClinicalReportRecord report;

  const ReportViewerScreen({super.key, required this.report});

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  Uint8List? _downloadedBytes;
  String? _contentType;
  bool _downloading = false;
  String? _downloadError;

  Future<void> _fetchProtectedFile() async {
    final path = widget.report.reportPdf;
    if (path == null || path.trim().isEmpty) return;

    setState(() {
      _downloading = true;
      _downloadError = null;
    });

    try {
      final res = await NursePortalScope.read(context)
          .api
          .downloadClinicalReportFile(path);
      if (mounted) {
        setState(() {
          _downloadedBytes = res.bytes;
          _contentType = res.contentType;
          _downloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadError = e.toString();
          _downloading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.report.hasDownloadableFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProtectedFile());
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = NursePortalScope.of(context).baseUrl;
    final r = widget.report;
    final isImage = _contentType != null && _contentType!.startsWith('image/');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text(r.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          SoftSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusBadge(label: r.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Patient: ${r.patientName}${r.patientUniqueId.isNotEmpty ? " (${r.patientUniqueId})" : ""}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (r.billNo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reference / Bill: ${r.billNo}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (r.doctorName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ordered By: ${r.doctorName}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (r.date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${AppFormatters.formatDateTimeShort(r.date)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                if (r.resultSummary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'Clinical Findings / Summary',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.resultSummary,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.42,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (r.hasDownloadableFile)
            SoftSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Authenticated Clinical Document',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConfig.resolveAuthenticatedReportUrl(
                      baseUrl,
                      r.reportPdf!,
                    ),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_downloading)
                    const Center(child: CircularProgressIndicator())
                  else if (_downloadError != null)
                    ClinicalErrorState(
                      message: _downloadError!,
                      onRetry: _fetchProtectedFile,
                    )
                  else if (_downloadedBytes != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Authenticated report verified & downloaded (${(_downloadedBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB • ${_contentType ?? "document"})',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isImage) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          child: Image.memory(_downloadedBytes!),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
