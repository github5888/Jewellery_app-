import '../core/utils/json_parsers.dart';

enum ClinicalReportCategory { lab, radiology, others }

class ClinicalReportRecord {
  final String id;
  final String billNo;
  final String title;
  final ClinicalReportCategory category;
  final String patientName;
  final String patientUniqueId;
  final String doctorName;
  final DateTime? date;
  final String status;
  final String resultSummary;
  final String? reportPdf;

  const ClinicalReportRecord({
    required this.id,
    required this.billNo,
    required this.title,
    required this.category,
    required this.patientName,
    required this.patientUniqueId,
    required this.doctorName,
    this.date,
    required this.status,
    required this.resultSummary,
    this.reportPdf,
  });

  bool get hasDownloadableFile => reportPdf != null && reportPdf!.trim().isNotEmpty;

  static List<ClinicalReportRecord> fromBillJson(
    Map<String, dynamic> json,
    ClinicalReportCategory category,
  ) {
    final patMap = json['patient'] is Map
        ? JsonParsers.asMap(json['patient'])
        : <String, dynamic>{};
    final patName = JsonParsers.asString(
      json['patient_name'] ?? patMap['patient_name'] ?? patMap['name'],
      fallback: 'Hospital Patient',
    );
    final patUhid = JsonParsers.asString(
      json['patient_unique_id'] ?? patMap['patient_unique_id'],
    );
    final docName = JsonParsers.asString(
      json['doctor_name'] ?? json['referral_doctor'] ?? json['doctor'],
    );
    final billNo = JsonParsers.asString(
      json['bill_no'] ?? json['invoice_no'] ?? json['case_reference_id'],
    );
    final billDate = JsonParsers.asDateTime(
      json['date'] ?? json['report_date'] ?? json['createdAt'],
    );
    final topPdf = JsonParsers.asString(json['report_pdf'] ?? json['attachment']);

    // Check nested `tests` array (matches server.ts: `{ 'tests.report_pdf': reportPath }`)
    if (json['tests'] is List) {
      final tests = JsonParsers.asMapList(json['tests']);
      if (tests.isNotEmpty) {
        return tests.map((t) {
          final testPdf = JsonParsers.asString(t['report_pdf'], fallback: topPdf);
          final defaultLabel = category == ClinicalReportCategory.lab
              ? 'Pathology Lab Report'
              : 'Radiology Scan Report';
          return ClinicalReportRecord(
            id: JsonParsers.asId(t['_id'] ?? json['_id']),
            billNo: billNo,
            title: JsonParsers.asString(
              t['test_name'] ?? t['name'] ?? json['test_name'],
              fallback: defaultLabel,
            ),
            category: category,
            patientName: patName,
            patientUniqueId: patUhid,
            doctorName: docName,
            date: JsonParsers.asDateTime(t['report_date']) ?? billDate,
            status: JsonParsers.asString(
              t['status'] ?? json['status'],
              fallback: testPdf.isNotEmpty ? 'Ready' : 'Processing',
            ),
            resultSummary: JsonParsers.asString(
              t['result'] ?? t['finding'] ?? t['remarks'] ?? json['note'],
            ),
            reportPdf: testPdf.isEmpty ? null : testPdf,
          );
        }).toList();
      }
    }

    final fallbackLabel = category == ClinicalReportCategory.lab
        ? 'Pathology Blood / Lab Report'
        : 'Radiology Diagnostic Report';

    return [
      ClinicalReportRecord(
        id: JsonParsers.asId(json['_id'] ?? json['id']),
        billNo: billNo,
        title: JsonParsers.asString(
          json['test_name'] ?? json['title'] ?? json['bill_no'],
          fallback: fallbackLabel,
        ),
        category: category,
        patientName: patName,
        patientUniqueId: patUhid,
        doctorName: docName,
        date: billDate,
        status: JsonParsers.asString(
          json['status'],
          fallback: topPdf.isNotEmpty ? 'Ready' : 'Recorded',
        ),
        resultSummary: JsonParsers.asString(
          json['result'] ?? json['note'] ?? json['remarks'],
        ),
        reportPdf: topPdf.isEmpty ? null : topPdf,
      ),
    ];
  }
}
