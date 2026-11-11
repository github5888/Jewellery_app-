import 'app_config.dart';

/// Centralized Full API URL Registry for Smart Super Speciality Hospital (`server.ts`).
/// Every method constructs the complete live URL (default base: `https://hospital.hrpocket.in`).
class ApiEndpoints {
  final String baseUrl;

  ApiEndpoints([String rawBaseUrl = AppConfig.defaultBaseUrl])
      : baseUrl = AppConfig.normalizeBaseUrl(rawBaseUrl);

  String _url(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$clean';
  }

  // 0. Health & Public Hospital Settings
  String get health => _url('/api/health');
  String get settingsPublic => _url('/api/settings/public');
  String get settings => _url('/api/settings');

  // 1. Authentication & Nurse Profile
  String get authLogin => _url('/api/auth/login');
  String get authMe => _url('/api/auth/me');
  String get authLogout => _url('/api/auth/logout');
  String get authChangePassword => _url('/api/auth/change-password');

  // 2. Nurse Home Dashboard
  String get dashboard => _url('/api/dashboard');

  // 3. IPD Ward & Bed-Side Patient Care
  String get ipdList => _url('/api/ipd');
  String ipdDetail(String ipdId) => _url('/api/ipd/$ipdId');

  // 4. Bedside Nurse Action Endpoints
  String ipdVitals(String ipdId) => _url('/api/ipd/$ipdId/vitals');
  String ipdNurseNotes(String ipdId) => _url('/api/ipd/$ipdId/nurse-notes');
  String ipdAdministerPrescription(String ipdId, String prescriptionId) =>
      _url('/api/ipd/$ipdId/prescriptions/$prescriptionId/administer');
  String ipdTransferBed(String ipdId) => _url('/api/ipd/$ipdId/transfer-bed');
  String ipdDischargeChecklist(String ipdId) =>
      _url('/api/ipd/$ipdId/discharge-checklist');
  String ipdCharges(String ipdId) => _url('/api/ipd/$ipdId/charges');

  // 5. Beds & Ward Groups
  String get beds => _url('/api/beds');
  String get bedGroups => _url('/api/beds/groups');

  // 6. OPD Triage Desk
  String get opdList => _url('/api/opd');
  String opdDetail(String opdId) => _url('/api/opd/$opdId');
  String opdVitals(String opdId) => _url('/api/opd/$opdId/vitals');

  // 7. Nurse Duty Roster & Shifts (`server.ts` mounts `/api/dutyroster` + spec `/api/duty-rosters/assignments`)
  String get dutyRosterAssignments => _url('/api/dutyroster/assignments');
  String get dutyRoster => _url('/api/dutyroster');
  String get dutyRostersAssignmentsLegacy =>
      _url('/api/duty-rosters/assignments');

  // 8. Patient Directory & ABHA
  String get patients => _url('/api/patients');
  String patientDetail(String patientId) => _url('/api/patients/$patientId');
  String get abha => _url('/api/abha');
  String get abhaScanShare => _url('/api/abha/scan-share');

  // 9. Clinical Diagnostic Reports & Authenticated Viewers
  String get pathology => _url('/api/pathology');
  String get pathologyBills => _url('/api/pathology/bills');
  String get radiology => _url('/api/radiology');
  String get radiologyBills => _url('/api/radiology/bills');
  String pathologyReportFile(String fileName) =>
      _url('/api/files/pathology_report/$fileName');
  String radiologyReportFile(String fileName) =>
      _url('/api/files/radiology_report/$fileName');

  // 10. Hospital Clinical & Support Modules (`server.ts` routes)
  String get appointments => _url('/api/appointments');
  String get pharmacy => _url('/api/pharmacy');
  String get pharmacyMedicines => _url('/api/pharmacy/medicines');
  String get staff => _url('/api/staff');
  String get bloodBank => _url('/api/blood-bank');
  String get bloodBankAlt => _url('/api/bloodbank');
  String get holidays => _url('/api/holidays');
  String get holidayAlt => _url('/api/holiday');
  String get notifications => _url('/api/notifications');
  String get messaging => _url('/api/messaging');
  String notificationRead(String id) => _url('/api/notifications/$id/read');
  String get inventory => _url('/api/inventory');
  String get itemStock => _url('/api/itemstock');
  String get charges => _url('/api/charges');
  String get uploads => _url('/api/uploads');
  String get ambulance => _url('/api/ambulance');
  String get frontOffice => _url('/api/front-office');
  String get billing => _url('/api/billing');
  String get birthDeath => _url('/api/birth-death');
}
