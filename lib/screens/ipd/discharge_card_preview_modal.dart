import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/print_helper.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';

/// Opens the `Discharge Card Preview` (`A4 (portrait)`) modal (`image-38` & `image-39`),
/// fetching live `GET /api/ipd/:id` details and supporting one-click A4 Print / PDF export.
Future<void> showDischargeCardPreviewModal(
  BuildContext context, {
  required IpdAdmission admission,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _DischargeCardPreviewDialog(initialAdmission: admission),
  );
}

class _DischargeCardPreviewDialog extends StatefulWidget {
  final IpdAdmission initialAdmission;

  const _DischargeCardPreviewDialog({required this.initialAdmission});

  @override
  State<_DischargeCardPreviewDialog> createState() =>
      _DischargeCardPreviewDialogState();
}

class _DischargeCardPreviewDialogState
    extends State<_DischargeCardPreviewDialog> {
  late IpdAdmission _ipd;
  bool _loading = false;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _ipd = widget.initialAdmission;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _refreshFromApi();
    }
  }

  Future<void> _refreshFromApi() async {
    if (_ipd.id.isEmpty) return;
    final ctrl = NursePortalScope.read(context);
    setState(() => _loading = true);
    try {
      final fresh = await ctrl.api.fetchIpdPatientDetail(_ipd.id);
      if (!mounted) return;
      setState(() {
        _ipd = fresh;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _diagnosisText(IpdAdmission ipd) {
    if (ipd.provisionalDiagnosis.trim().isNotEmpty) {
      return ipd.provisionalDiagnosis.trim();
    }
    if (ipd.presentingComplaint.trim().isNotEmpty) {
      return ipd.presentingComplaint.trim();
    }
    return 'Inpatient Clinical Care';
  }

  String _clinicalSummaryText(IpdAdmission ipd) {
    if (ipd.clinicalSummary.trim().isNotEmpty) {
      return ipd.clinicalSummary.trim();
    }
    if (ipd.nurseNotes.isNotEmpty &&
        ipd.nurseNotes.first.note.trim().isNotEmpty) {
      return ipd.nurseNotes.first.note.trim();
    }
    if (ipd.dischargeChecklist.checklistNotes.trim().isNotEmpty) {
      return ipd.dischargeChecklist.checklistNotes.trim();
    }
    return 'Patient treated conservatively in ward and discharged in stable clinical condition.';
  }

  List<String> _instructionLines(IpdAdmission ipd) {
    final raw = ipd.dischargeInstructions.trim();
    if (raw.isNotEmpty) {
      final lines = raw
          .split(RegExp(r'[\r\n•]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) return lines;
    }
    return const [
      'Follow medication schedule as prescribed by the consulting doctor.',
      'In case of acute distress or recurring fever, report immediately to Hospital Emergency.',
      'Schedule regular follow-up visit after 7 days.',
    ];
  }

  String _consultantRawName(IpdAdmission ipd) {
    final full =
        '${ipd.doctor.name.trim()} ${ipd.doctor.surname.trim()}'.trim();
    if (full.isNotEmpty) return full;
    return ipd.doctor.displayName;
  }

  Future<void> _handlePrint() async {
    final ctrl = NursePortalScope.read(context);
    final h = ctrl.hospitalInfo;
    final ipd = _ipd;
    final pat = ipd.patient;

    final hospTitle = h.name.trim().isNotEmpty &&
            h.name.trim() != 'Smart Super Speciality Hospital'
        ? h.name.trim()
        : 'Smart Hospital & Research Center';
    final hospAddr =
        h.address.trim().isNotEmpty ? h.address.trim() : '25 Kings Street, CA';
    final hospPhone =
        h.phone.trim().isNotEmpty ? h.phone.trim() : '89562423934';
    final hospEmail = h.email.trim().isNotEmpty
        ? h.email.trim()
        : 'smarthospitalrc@gmail.com';
    const hospWeb = 'www.smart-hospital.in';

    final genderAge =
        '${pat.gender.isEmpty ? "-" : pat.gender} / ${pat.age > 0 ? "${pat.age} Yrs" : "-"}';
    final admDate = AppFormatters.formatSlashDate(ipd.admissionDate);
    final disDate = AppFormatters.formatSlashDate(
      ipd.dischargeDate ?? ipd.admissionDate,
    );
    final diag = _diagnosisText(ipd);
    final summary = _clinicalSummaryText(ipd);
    final instructions = _instructionLines(ipd);

    String esc(String s) => const HtmlEscape().convert(s);

    final htmlDoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Discharge Card - ${esc(ipd.ipdNo)}</title>
  <style>
    @page { size: A4 portrait; margin: 14mm; }
    body { font-family: Arial, Helvetica, sans-serif; color: #0f172a; margin: 0; padding: 18px; }
    .hdr { display: flex; justify-content: space-between; align-items: flex-start; }
    .badge { display: inline-block; background: #facc15; color: #b91c1c; font-weight: 900; font-size: 11px; padding: 3px 8px; border-radius: 4px; }
    .h-title { font-size: 23px; font-weight: 800; margin: 6px 0 0 0; }
    .meta { text-align: right; font-size: 11.5px; line-height: 1.45; font-weight: 700; }
    .black-bar { background: #000; color: #fff; text-align: center; font-weight: 800; font-size: 13px; padding: 5px 0; margin: 12px 0; }
    .sub-row { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #0369a1; padding-bottom: 8px; margin-bottom: 14px; }
    .teal-pill { background: #0369a1; color: #fff; font-weight: 800; font-size: 12px; padding: 5px 10px; border-radius: 4px; }
    .grid { display: flex; gap: 24px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; margin-bottom: 14px; }
    .col { flex: 1; font-size: 12.5px; line-height: 1.75; }
    .col-hdr { color: #0369a1; font-weight: 800; font-size: 11px; margin-bottom: 4px; text-transform: uppercase; }
    .box { border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 14px; margin-bottom: 12px; }
    .box-title { font-weight: 800; font-size: 13px; margin-bottom: 5px; }
    .diag { color: #1e3a8a; font-weight: 700; font-size: 13px; }
    .inst-hdr { color: #0369a1; font-weight: 800; font-size: 13px; margin-bottom: 6px; }
    ul { margin: 4px 0 0 18px; padding: 0; font-size: 12.5px; line-height: 1.65; }
    .note { border-left: 3px solid #0284c7; background: #f8fafc; padding: 9px 12px; font-size: 11.5px; color: #475569; margin-top: 12px; }
  </style>
</head>
<body onload="window.print()">
  <div class="hdr">
    <div>
      <span class="badge">+ SMART HOSPITAL</span>
      <div class="h-title">${esc(hospTitle)}</div>
    </div>
    <div class="meta">
      Address: ${esc(hospAddr)}<br/>
      Phone No.: ${esc(hospPhone)}<br/>
      Email: ${esc(hospEmail)}<br/>
      Website: ${esc(hospWeb)}
    </div>
  </div>
  <div class="black-bar">Discharge Card</div>
  <div class="sub-row">
    <span class="teal-pill">PATIENT DISCHARGE CARD &amp; CLINICAL SUMMARY</span>
    <span style="font-size:12px;font-weight:700;">IPD No: <span style="color:#0369a1;">${esc(ipd.ipdNo)}</span> | Case ID: ${esc(ipd.caseReferenceId.isEmpty ? "-" : ipd.caseReferenceId)}</span>
  </div>
  <div class="grid">
    <div class="col">
      <div class="col-hdr">PATIENT DETAILS</div>
      <b>Name:</b> ${esc(pat.patientName)}<br/>
      <b>UHID:</b> ${esc(pat.patientUniqueId.isEmpty ? "-" : pat.patientUniqueId)}<br/>
      <b>Gender / Age:</b> ${esc(genderAge)}<br/>
      <b>Phone:</b> ${esc(pat.mobileNo.isEmpty ? "-" : pat.mobileNo)}<br/>
      <b>Blood Group:</b> ${esc(pat.bloodGroup.isEmpty ? "-" : pat.bloodGroup)}
    </div>
    <div class="col">
      <div class="col-hdr">ADMISSION DETAILS</div>
      <b>Consultant Doctor:</b> ${esc(_consultantRawName(ipd))}<br/>
      <b>Department:</b> ${esc(ipd.department.isEmpty ? "-" : ipd.department)}<br/>
      <b>Bed / Ward:</b> ${esc(ipd.bedDisplayLabel)}<br/>
      <b>Admission Date:</b> ${esc(admDate)}<br/>
      <b>Discharge Date:</b> ${esc(disDate)}
    </div>
  </div>
  <div class="box">
    <div class="box-title">Diagnosis / Reason for Hospitalization:</div>
    <div class="diag">${esc(diag)}</div>
  </div>
  <div class="box">
    <div class="box-title">Clinical Summary &amp; Inpatient Course:</div>
    <div style="font-size:12.5px;">${esc(summary)}</div>
  </div>
  <div class="box">
    <div class="inst-hdr">Post-Discharge Instructions &amp; Follow-up:</div>
    <ul>
      ${instructions.map((l) => '<li>${esc(l)}</li>').join()}
    </ul>
  </div>
  <div class="note">Follow-up appointment required as noted. In case of acute distress, report immediately to Hospital Emergency.</div>
  <div style="display:flex;justify-content:space-between;margin-top:34px;padding-top:8px;font-size:12px;">
    <div style="text-align:center;min-width:190px;border-top:1px solid #94a3b8;padding-top:6px;">
      <b>Attending Doctor Signature</b><br/>
      <span style="color:#64748b;font-size:11px;">(${esc(_consultantRawName(ipd))})</span>
    </div>
    <div style="text-align:center;min-width:190px;border-top:1px solid #94a3b8;padding-top:6px;">
      <b>Patient / Attendant Signature</b><br/>
      <span style="color:#64748b;font-size:11px;">(Acknowledged Discharge &amp; Meds)</span>
    </div>
  </div>
  <div style="text-align:center;color:#94a3b8;font-size:10.5px;margin-top:18px;border-top:1px dashed #e2e8f0;padding-top:8px;">
    Computer generated official hospital discharge summary &bull; ${esc(hospTitle)}
  </div>
</body>
</html>
''';

    final printedOk = await PrintDocumentHelper.printHtmlDocument(
      title: 'Discharge_Card_${ipd.ipdNo}',
      htmlContent: htmlDoc,
    );

    if (!printedOk && mounted) {
      final plainSummary = [
        '$hospTitle — DISCHARGE CARD (${ipd.ipdNo})',
        'Patient: ${pat.patientName} (UHID: ${pat.patientUniqueId})',
        'Doctor: ${_consultantRawName(ipd)} | Dept: ${ipd.department}',
        'Bed/Ward: ${ipd.bedDisplayLabel}',
        'Admission: $admDate | Discharge: $disDate',
        'Diagnosis: $diag',
        'Clinical Summary: $summary',
        'Instructions: ${instructions.join(" ")}',
      ].join('\n');
      await Clipboard.setData(ClipboardData(text: plainSummary));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rebuild app once to open native Android PDF Printer (summary copied to clipboard).',
          ),
          backgroundColor: Color(0xFF035C7A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = NursePortalScope.of(context);
    final h = ctrl.hospitalInfo;
    final ipd = _ipd;
    final pat = ipd.patient;

    final hospTitle = h.name.trim().isNotEmpty &&
            h.name.trim() != 'Smart Super Speciality Hospital'
        ? h.name.trim()
        : 'Smart Hospital & Research Center';
    final hospAddr =
        h.address.trim().isNotEmpty ? h.address.trim() : '25 Kings Street, CA';
    final hospPhone =
        h.phone.trim().isNotEmpty ? h.phone.trim() : '89562423934';
    final hospEmail = h.email.trim().isNotEmpty
        ? h.email.trim()
        : 'smarthospitalrc@gmail.com';

    final genderAge =
        '${pat.gender.isEmpty ? "-" : pat.gender} / ${pat.age > 0 ? "${pat.age} Yrs" : "-"}';
    final admDate = AppFormatters.formatSlashDate(ipd.admissionDate);
    final disDate = AppFormatters.formatSlashDate(
      ipd.dischargeDate ?? ipd.admissionDate,
    );
    final instructions = _instructionLines(ipd);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Preview Bar (`Screenshot 781`)
            Container(
              color: const Color(0xFF035C7A),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 19,
                      ),
                      const Text(
                        'Discharge Card Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'A4 (portrait)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handlePrint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF035C7A),
                          elevation: 0,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 15),
                        label: const Text(
                          'Print Discharge Card',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withAlpha(80)),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF035C7A),
                backgroundColor: Colors.transparent,
              ),

            // Scrollable A4 Document Body (`image-38.png` & `image-39.png`)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Letterhead
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFACC15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_box_rounded,
                                    size: 14,
                                    color: Color(0xFFDC2626),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'SMART HOSPITAL',
                                    style: TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hospTitle,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Address: $hospAddr',
                              style: _letterheadMetaStyle,
                            ),
                            Text(
                              'Phone No.: $hospPhone',
                              style: _letterheadMetaStyle,
                            ),
                            Text(
                              'Email: $hospEmail',
                              style: _letterheadMetaStyle,
                            ),
                            const Text(
                              'Website: www.smart-hospital.in',
                              style: _letterheadMetaStyle,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Black Title Strip
                    Container(
                      width: double.infinity,
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: const Text(
                        'Discharge Card',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Summary Banner + IPD / Case ID
                    Container(
                      padding: const EdgeInsets.only(bottom: 9),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF035C7A),
                            width: 1.8,
                          ),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF035C7A),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'PATIENT DISCHARGE CARD & CLINICAL SUMMARY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                const TextSpan(text: 'IPD No: '),
                                TextSpan(
                                  text: ipd.ipdNo,
                                  style: const TextStyle(
                                    color: Color(0xFF035C7A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '  |  Case ID: ${ipd.caseReferenceId.isEmpty ? "-" : ipd.caseReferenceId}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2-Column Patient Details & Admission Details Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final patientCol = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PATIENT DETAILS',
                                style: _colHeaderStyle,
                              ),
                              const SizedBox(height: 6),
                              _DocKeyVal('Name:', pat.patientName),
                              _DocKeyVal(
                                'UHID:',
                                pat.patientUniqueId.isEmpty
                                    ? '-'
                                    : pat.patientUniqueId,
                              ),
                              _DocKeyVal('Gender / Age:', genderAge),
                              _DocKeyVal(
                                'Phone:',
                                pat.mobileNo.isEmpty ? '-' : pat.mobileNo,
                              ),
                              _DocKeyVal(
                                'Blood Group:',
                                pat.bloodGroup.isEmpty ? '-' : pat.bloodGroup,
                              ),
                            ],
                          );

                          final admissionCol = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ADMISSION DETAILS',
                                style: _colHeaderStyle,
                              ),
                              const SizedBox(height: 6),
                              _DocKeyVal(
                                'Consultant Doctor:',
                                _consultantRawName(ipd),
                              ),
                              _DocKeyVal(
                                'Department:',
                                ipd.department.isEmpty ? '-' : ipd.department,
                              ),
                              _DocKeyVal('Bed / Ward:', ipd.bedDisplayLabel),
                              _DocKeyVal('Admission Date:', admDate),
                              _DocKeyVal('Discharge Date:', disDate),
                            ],
                          );

                          if (constraints.maxWidth >= 500) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: patientCol),
                                const SizedBox(width: 24),
                                Expanded(child: admissionCol),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              patientCol,
                              const Divider(height: 20),
                              admissionCol,
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Diagnosis / Reason for Hospitalization
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnosis / Reason for Hospitalization:',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _diagnosisText(ipd),
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Clinical Summary & Inpatient Course (`image-39.png`)
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clinical Summary & Inpatient Course:',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _clinicalSummaryText(ipd),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Post-Discharge Instructions & Follow-up (`image-39.png`)
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post-Discharge Instructions & Follow-up:',
                            style: TextStyle(
                              color: Color(0xFF035C7A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ...instructions.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '•  ',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.38,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Blue Left-Bordered Emergency Notice (`Screenshot 782`)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          left: BorderSide(
                            color: Color(0xFF0284C7),
                            width: 3,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Follow-up appointment required as noted. In case of acute distress, report immediately to Hospital Emergency.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Signature Block (`Screenshot 782`)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 200,
                          child: Column(
                            children: [
                              const Divider(color: Color(0xFFCBD5E1)),
                              const Text(
                                'Attending Doctor Signature',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '(${_consultantRawName(ipd)})',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 210,
                          child: const Column(
                            children: [
                              Divider(color: Color(0xFFCBD5E1)),
                              Text(
                                'Patient / Attendant Signature',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '(Acknowledged Discharge & Meds)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Text(
                      'Computer generated official hospital discharge summary • $hospTitle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),

            // Bottom Action Bar (`Print Discharge Card (A4)` + `Close` — overflow-safe Wrap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _handlePrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF035C7A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text(
                      'Print Discharge Card (A4)',
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

  static const TextStyle _letterheadMetaStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle _colHeaderStyle = TextStyle(
    color: Color(0xFF035C7A),
    fontSize: 10.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.4,
  );
}

class _DocKeyVal extends StatelessWidget {
  final String label;
  final String value;

  const _DocKeyVal(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
