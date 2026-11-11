import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';
import 'ipd_models.dart';

/// Section 6: OPD Triage Desk Model (`GET /api/opd` & `POST /api/opd/:id/vitals`)
class OpdVisitRecord {
  final String id;
  final String opdNo;
  final String caseReferenceId;
  final DateTime? appointmentDate;
  final String status; // Waiting | In Consultation | Scheduled | Completed | Cancelled
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
        triageVitals!.spo2.isNotEmpty;
  }

  factory OpdVisitRecord.fromJson(Map<String, dynamic> json) {
    final patMap = json['patient'] is Map
        ? JsonParsers.asMap(json['patient'])
        : <String, dynamic>{};
    final patient = PatientProfile.fromJson(patMap, fallbackParent: json);

    String docName = '';
    String dept = JsonParsers.asString(json['department']);
    final rawDoc = json['doctor'] ?? json['cons_doctor'] ?? json['consultant_doctor'];
    if (rawDoc is Map) {
      final dm = JsonParsers.asMap(rawDoc);
      docName = AppFormatters.formatDoctorName(
        JsonParsers.asString(dm['name']),
        JsonParsers.asString(dm['surname']),
      );
      if (dept.isEmpty) dept = JsonParsers.asString(dm['department']);
    } else {
      final s = JsonParsers.asString(json['doctor_name'] ?? rawDoc);
      docName = s.isNotEmpty ? AppFormatters.formatDoctorName(s) : 'OPD Consultant';
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
        json['weight'] != null) {
      vitals = VitalSignRecord.fromJson(json);
    }

    final rawStatus = JsonParsers.asString(
      json['status'] ?? json['visit_status'] ?? json['consultation_status'],
      fallback: 'Waiting',
    );

    return OpdVisitRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      opdNo: JsonParsers.asString(
        json['opd_no'] ?? json['opd_id'],
        fallback: JsonParsers.asId(json['_id']),
      ),
      caseReferenceId: JsonParsers.asString(
        json['case_reference_id'] ?? json['case_id'],
      ),
      appointmentDate: JsonParsers.asDateTime(
        json['appointment_date'] ?? json['visit_date'] ?? json['date'] ?? json['createdAt'],
      ),
      status: rawStatus,
      symptoms: JsonParsers.asString(
        json['symptoms'] ?? json['symptoms_title'] ?? json['reason'] ?? json['note'],
      ),
      patient: patient,
      doctorName: docName,
      department: dept,
      triageVitals: vitals,
    );
  }
}
