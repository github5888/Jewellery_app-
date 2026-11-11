import 'app_config.dart';

/// Centralized Full API URL Registry for Smart Super Speciality Hospital (`https://hospital.hrpocket.in`).
/// Strictly maps the live Nurse Portal endpoints from `server.ts`.
class ApiEndpoints {
  final String baseUrl;

  ApiEndpoints([String rawBaseUrl = AppConfig.defaultBaseUrl])
      : baseUrl = AppConfig.normalizeBaseUrl(rawBaseUrl);

  String _url(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$clean';
  }

  // 0. Health & Public Hospital Branding
  String get health => _url('/api/health');
  String get settingsPublic => _url('/api/settings/public');
  String get settings => _url('/api/settings');

  // 1. Authentication & Nurse Profile
  String get authLogin => _url('/api/auth/login');
  String get authMe => _url('/api/auth/me');
  String get authProfile => _url('/api/auth/profile');
  String get authProfilePhoto => _url('/api/auth/profile/photo');
  String get authAvatar => _url('/api/auth/avatar');
  String get authLogout => _url('/api/auth/logout');
  String get authChangePassword => _url('/api/auth/change-password');
  String get authPasswordAlt => _url('/api/auth/password');
  String get usersProfile => _url('/api/users/profile');
  String get profile => _url('/api/profile');
  String get staffList => _url('/api/staff');
  String staffDetail(String staffId) => _url('/api/staff/$staffId');
  String userDetail(String userId) => _url('/api/users/$userId');

  // 2. Nurse Dashboard
  String get dashboard => _url('/api/dashboard');

  // 3. Patient Directory & ABHA Queue
  String get patients => _url('/api/patients');
  String patientDetail(String patientId) => _url('/api/patients/$patientId');
  String get abha => _url('/api/abha');
  String get abhaScanShare => _url('/api/abha/scan-share');
  String get abhaQueue => _url('/api/abha/queue');

  // 4. OPD - Out Patient & Triage Vitals
  String get opdList => _url('/api/opd');
  String opdDetail(String opdId) => _url('/api/opd/$opdId');
  String opdVitals(String opdId) => _url('/api/opd/$opdId/vitals');

  // 5. IPD - In Patient & Bedside Nurse Actions
  String get ipdList => _url('/api/ipd');
  String ipdDetail(String ipdId) => _url('/api/ipd/$ipdId');
  String ipdVitals(String ipdId) => _url('/api/ipd/$ipdId/vitals');
  String ipdNurseNotes(String ipdId) => _url('/api/ipd/$ipdId/nurse-notes');
  String ipdAdministerPrescription(String ipdId, String prescriptionId) =>
      _url('/api/ipd/$ipdId/prescriptions/$prescriptionId/administer');
  String ipdTransferBed(String ipdId) => _url('/api/ipd/$ipdId/transfer-bed');
  String ipdDischargeChecklist(String ipdId) =>
      _url('/api/ipd/$ipdId/discharge-checklist');
  String ipdCharges(String ipdId) => _url('/api/ipd/$ipdId/charges');

  // 6. Beds & Ward Groups
  String get beds => _url('/api/beds');
  String get bedGroups => _url('/api/beds/groups');
  String get bedGroupsAlt => _url('/api/bed-groups');
  String get charges => _url('/api/charges');
  String get uploads => _url('/api/uploads');

  // 7. Blood Bank Status & Donors
  String get bloodBankStatus => _url('/api/blood-bank/status');
  String get bloodBankAltStatus => _url('/api/bloodbank/status');
  String get bloodBankStatusLegacy => _url('/api/bloodbankstatus');
  String get bloodBank => _url('/api/blood-bank');
  String get bloodBankAlt => _url('/api/bloodbank');
  String get bloodBankGroups => _url('/api/blood-bank/groups');
  String get bloodBankAltGroups => _url('/api/bloodbank/groups');
  String get bloodBankInventory => _url('/api/blood-bank/inventory');
  String get bloodBankBags => _url('/api/blood-bank/bags');
  String get bloodBankDonors => _url('/api/blood-bank/donors');
  String get bloodBankAltDonors => _url('/api/bloodbank/donors');
  String get bloodBankDonorSearch => _url('/api/bloodbank/search');

  // 8. Duty Roster & Shifts
  String get dutyRoster => _url('/api/dutyroster');
  String get dutyRosterAssignments => _url('/api/dutyroster/assignments');
  String get dutyRosterRosters => _url('/api/dutyroster/rosters');
  String get dutyRostersAssignmentsLegacy =>
      _url('/api/duty-rosters/assignments');

  // 9. Annual Calendar / Holidays
  String get holidays => _url('/api/holidays');
  String get holidayAlt => _url('/api/holiday');
  String get calendar => _url('/api/calendar');

  // 10. Notifications, Pathology/Radiology & Protected Report Files
  String get pathology => _url('/api/pathology');
  String get pathologyBills => _url('/api/pathology/bills');
  String get radiology => _url('/api/radiology');
  String get radiologyBills => _url('/api/radiology/bills');
  String get notifications => _url('/api/notifications');
  String notificationRead(String id) => _url('/api/notifications/$id/read');
  String pathologyReportFile(String fileName) =>
      _url('/api/files/pathology_report/$fileName');
  String radiologyReportFile(String fileName) =>
      _url('/api/files/radiology_report/$fileName');
}
