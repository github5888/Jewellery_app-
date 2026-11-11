import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';
import 'ipd_models.dart';

/// OPD - Out Patient Model (`GET /api/opd` & `POST /api/opd/:id/vitals`)
/// Matches Website `/opd` (image-7): `OPDN1015`, `CASE-896774`, `Waiting`, `In Consultation`, `Scheduled`, `Completed`, `Cancelled`.
class OpdVisitRecord {
  final String id;
  final String opdNo;
  final String caseReferenceId;
  final DateTime? appointmentDate;
  final String status;
  final String symptoms;
  final PatientProfile patient;
  final String doctorName;
  final String department;
  final VitalSignRecord? triageVitals;

  const OpdVisitRecord({
    required this.id,
    required this.opdNo,
    required this.caseReferenceId,
    this.appointmentDate,
    required this.status,
    required this.symptoms,
    required this.patient,
    required this.doctorName,
    required this.department,
    this.triageVitals,
  });

  bool get hasVitalsRecorded {
    if (triageVitals == null) return false;
    return triageVitals!.bp.isNotEmpty ||
        triageVitals!.pulse.isNotEmpty ||
        triageVitals!.temperature.isNotEmpty ||
        triageVitals!.spo2.isNotEmpty ||
        triageVitals!.respiratoryRate.isNotEmpty ||
        triageVitals!.weight.isNotEmpty ||
        triageVitals!.height.isNotEmpty;
  }

  /// Normalizes backend status string into the exact 5 OPD tabs on `/opd` (image-7):
  /// `Waiting` | `In Consultation` | `Scheduled` | `Completed` | `Cancelled`
  String get statusCategory {
    final st = status.trim().toLowerCase();
    if (st.contains('cancel') || st.contains('noshow') || st.contains('no_show') || st.contains('reject')) {
      return 'Cancelled';
    }
    if (st.contains('comp') || st.contains('done') || st.contains('closed') || st.contains('visit') || st.contains('discharg')) {
      return 'Completed';
    }
    if (st.contains('consult') || st.contains('progress') || st == 'active') {
      return 'In Consultation';
    }
    if (st.contains('sched') || st.contains('book') || st.contains('upcoming') || st.contains('confirm')) {
      return 'Scheduled';
    }
    return 'Waiting';
  }

  factory OpdVisitRecord.fromJson(Map<String, dynamic> json) {
    final patMap = json['patient'] is Map
        ? JsonParsers.asMap(json['patient'])
        : <String, dynamic>{};
    final patient = PatientProfile.fromJson(patMap, fallbackParent: json);

    String docName = '';
    String dept = JsonParsers.asString(json['department']);
    final rawDoc = json['doctor'] ??
        json['cons_doctor'] ??
        json['consultant_doctor'] ??
        json['consultantDoctor'];
    if (rawDoc is Map) {
      final dm = JsonParsers.asMap(rawDoc);
      docName = AppFormatters.formatDoctorName(
        JsonParsers.asString(dm['name']),
        JsonParsers.asString(dm['surname']),
      );
      if (dept.isEmpty) dept = JsonParsers.asString(dm['department']);
    } else {
      final s = JsonParsers.asString(
        json['doctor_name'] ?? json['doctorName'] ?? rawDoc,
      );
      docName = s.isNotEmpty ? AppFormatters.formatDoctorName(s) : '—';
    }

    VitalSignRecord? vitals;
    if (json['vitals'] is List) {
      final list = JsonParsers.asMapList(json['vitals']);
      if (list.isNotEmpty) {
        vitals = VitalSignRecord.fromJson(list.last);
      }
    } else if (json['vitals'] is Map) {
      vitals = VitalSignRecord.fromJson(JsonParsers.asMap(json['vitals']));
    } else if (json['bp'] != null ||
        json['pulse'] != null ||
        json['temperature'] != null ||
        json['spo2'] != null) {
      vitals = VitalSignRecord.fromJson(json);
    }

    final rawStatus = JsonParsers.asString(
      json['status'] ??
          json['visit_status'] ??
          json['visitStatus'] ??
          json['appointment_status'] ??
          json['appointmentStatus'] ??
          json['consultation_status'],
      fallback: 'Waiting',
    );

    return OpdVisitRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      opdNo: JsonParsers.asString(
        json['opd_no'] ?? json['opdNo'] ?? json['opd_id'],
        fallback: JsonParsers.asId(json['_id']),
      ),
      caseReferenceId: JsonParsers.asString(
        json['case_reference_id'] ??
            json['caseReferenceId'] ??
            json['case_id'] ??
            json['caseId'],
      ),
      appointmentDate: JsonParsers.asDateTime(
        json['appointment_date'] ??
            json['appointmentDate'] ??
            json['visit_date'] ??
            json['visitDate'] ??
            json['date'] ??
            json['createdAt'],
      ),
      status: rawStatus,
      symptoms: JsonParsers.asString(
        json['symptoms'] ??
            json['symptoms_description'] ??
            json['symptoms_title'] ??
            json['symptomsTitle'] ??
            json['reason'] ??
            json['note'],
      ),
      patient: patient,
      doctorName: docName,
      department: dept,
      triageVitals: vitals,
    );
  }
}
