import 'dart:typed_data';

import '../core/config/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/utils/json_parsers.dart';
import '../models/bed_models.dart';
import '../models/dashboard_data.dart';
import '../models/duty_roster_model.dart';
import '../models/hospital_modules_models.dart';
import '../models/ipd_models.dart';
import '../models/nurse_user.dart';
import '../models/opd_models.dart';
import '../models/patient_directory_model.dart';

class NurseApiService {
  final ApiClient _client;

  const NurseApiService(this._client);

  ApiClient get client => _client;
  ApiEndpoints get endpoints => ApiEndpoints(_client.baseUrl);

  // ---------------------------------------------------------------------------
  // 0. Server Health & Public Hospital Branding
  // ---------------------------------------------------------------------------

  Future<bool> checkHealth() async {
    try {
      final res = await _client.get(
        endpoints.health,
        includeAuth: false,
        timeout: const Duration(seconds: 8),
      );
      final map = JsonParsers.asMap(res);
      return map['status'] == 1 || map['status'] == true || map.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<HospitalInfo?> fetchPublicHospitalInfo() async {
    for (final url in [endpoints.settingsPublic, endpoints.settings]) {
      try {
        final res = await _client.get(
          url,
          includeAuth: _client.hasToken,
          timeout: const Duration(seconds: 8),
        );
        final obj = JsonParsers.extractObject(res);
        if (obj.isNotEmpty) {
          return HospitalInfo.fromJson(obj);
        }
      } catch (_) {}
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 1. Authentication & Nurse Profile APIs
  // ---------------------------------------------------------------------------

  Future<({String token, NurseUser user})> login({
    required String username,
    required String password,
  }) async {
    final res = await _client.post(
      endpoints.authLogin,
      includeAuth: false,
      body: <String, dynamic>{
        'username': username.trim(),
        'password': password,
      },
    );

    final root = JsonParsers.asMap(res);
    final dataObj = JsonParsers.extractObject(root);
    final token = JsonParsers.asString(
      root['token'] ?? dataObj['token'] ?? root['accessToken'],
    );
    if (token.isEmpty) {
      throw const ApiException(
        message: 'Authentication succeeded without returning an access token.',
      );
    }
    final user = NurseUser.fromJson(dataObj.isNotEmpty ? dataObj : root);
    return (token: token, user: user);
  }

  Future<NurseUser> fetchMe() async {
    final res = await _client.get(endpoints.authMe);
    final obj = JsonParsers.extractObject(res);
    return NurseUser.fromJson(obj);
  }

  Future<void> logoutServer() async {
    try {
      await _client.post(
        endpoints.authLogout,
        timeout: const Duration(seconds: 6),
      );
    } catch (_) {}
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      endpoints.authChangePassword,
      body: <String, dynamic>{
        'currentPassword': currentPassword,
        'old_password': currentPassword,
        'newPassword': newPassword,
        'new_password': newPassword,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Nurse Dashboard
  // ---------------------------------------------------------------------------

  Future<NurseDashboardData> fetchDashboard() async {
    final res = await _client.get(endpoints.dashboard);
    return NurseDashboardData.fromJson(JsonParsers.asMap(res));
  }

  // ---------------------------------------------------------------------------
  // 3. Patient Directory & ABHA Scan & Share Queue
  // ---------------------------------------------------------------------------

  Future<List<PatientDirectoryRecord>> fetchPatientDirectory() async {
    final res = await _client.get(endpoints.patients);
    return JsonParsers.extractList(res)
        .map(PatientDirectoryRecord.fromJson)
        .toList();
  }

  Future<PatientDirectoryRecord> fetchPatientDetail(String patientId) async {
    final res = await _client.get(endpoints.patientDetail(patientId));
    return PatientDirectoryRecord.fromJson(JsonParsers.extractObject(res));
  }

  Future<List<AbhaScanCheckinItem>> fetchAbhaQueue() async {
    for (final url in [
      endpoints.abhaScanShare,
      endpoints.abhaQueue,
      endpoints.abha,
    ]) {
      try {
        final res = await _client.get(url);
        final list = JsonParsers.extractList(res)
            .map(AbhaScanCheckinItem.fromJson)
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [];
  }

  // ---------------------------------------------------------------------------
  // 4. OPD - Out Patient & Triage Vitals
  // ---------------------------------------------------------------------------

  Future<List<OpdVisitRecord>> fetchOpdQueue() async {
    final res = await _client.get(endpoints.opdList);
    return JsonParsers.extractList(res).map(OpdVisitRecord.fromJson).toList();
  }

  Future<OpdVisitRecord> fetchOpdDetail(String opdId) async {
    final res = await _client.get(endpoints.opdDetail(opdId));
    return OpdVisitRecord.fromJson(JsonParsers.extractObject(res));
  }

  Future<void> recordOpdTriageVitals({
    required String opdId,
    required String bp,
    required String pulse,
    required String temperature,
    required String spo2,
    String respiratoryRate = '',
    String weight = '',
    String height = '',
    String notes = '',
    String? recordedBy,
    String? recordedById,
    DateTime? date,
  }) async {
    final payload = <String, dynamic>{
      'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      if (bp.trim().isNotEmpty) 'bp': bp.trim(),
      if (pulse.trim().isNotEmpty) 'pulse': pulse.trim(),
      if (temperature.trim().isNotEmpty) 'temperature': temperature.trim(),
      if (spo2.trim().isNotEmpty) 'spo2': spo2.trim(),
      if (respiratoryRate.trim().isNotEmpty)
        'respiratory_rate': respiratoryRate.trim(),
      if (weight.trim().isNotEmpty) 'weight': weight.trim(),
      if (height.trim().isNotEmpty) 'height': height.trim(),
      if (recordedBy != null && recordedBy.trim().isNotEmpty)
        'recorded_by': recordedBy.trim(),
      if (recordedById != null && recordedById.trim().isNotEmpty)
        'recorded_by_id': recordedById.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    await _client.post(endpoints.opdVitals(opdId), body: payload);
  }

  // ---------------------------------------------------------------------------
  // 5. IPD - In Patient & Bedside Clinical Actions
  // ---------------------------------------------------------------------------

  Future<List<IpdAdmission>> fetchIpdAdmissions({
    String dischargeStatus = 'all',
  }) async {
    final res = await _client.get(endpoints.ipdList);
    final all = JsonParsers.extractList(res).map(IpdAdmission.fromJson).toList();
    final filter = dischargeStatus.trim().toLowerCase();
    if (filter == 'admitted') {
      return all.where((ipd) => !ipd.isDischarged).toList();
    }
    if (filter == 'discharged') {
      return all.where((ipd) => ipd.isDischarged).toList();
    }
    return all;
  }

  Future<IpdAdmission> fetchIpdPatientDetail(String ipdId) async {
    final res = await _client.get(endpoints.ipdDetail(ipdId));
    return IpdAdmission.fromJson(JsonParsers.asMap(res));
  }

  Future<void> recordIpdVitals({
    required String ipdId,
    required String bp,
    required String pulse,
    required String temperature,
    required String spo2,
    String respiratoryRate = '',
    String weight = '',
    String height = '',
    String notes = '',
    String? recordedBy,
    String? recordedById,
    DateTime? date,
  }) async {
    final payload = <String, dynamic>{
      'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      if (bp.trim().isNotEmpty) 'bp': bp.trim(),
      if (pulse.trim().isNotEmpty) 'pulse': pulse.trim(),
      if (temperature.trim().isNotEmpty) 'temperature': temperature.trim(),
      if (spo2.trim().isNotEmpty) 'spo2': spo2.trim(),
      if (respiratoryRate.trim().isNotEmpty)
        'respiratory_rate': respiratoryRate.trim(),
      if (weight.trim().isNotEmpty) 'weight': weight.trim(),
      if (height.trim().isNotEmpty) 'height': height.trim(),
      if (recordedBy != null && recordedBy.trim().isNotEmpty)
        'recorded_by': recordedBy.trim(),
      if (recordedById != null && recordedById.trim().isNotEmpty)
        'recorded_by_id': recordedById.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    await _client.post(endpoints.ipdVitals(ipdId), body: payload);
  }

  Future<void> addNurseProgressNote({
    required String ipdId,
    required String note,
    String comment = '',
    String? nurseName,
    String? attachment,
    DateTime? date,
  }) async {
    final payload = <String, dynamic>{
      'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      'note': note.trim(),
      if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      if (nurseName != null && nurseName.trim().isNotEmpty)
        'nurse_name': nurseName.trim(),
      if (attachment != null && attachment.trim().isNotEmpty)
        'attachment': attachment.trim(),
    };
    await _client.post(endpoints.ipdNurseNotes(ipdId), body: payload);
  }

  Future<void> administerMedication({
    required String ipdId,
    required String prescriptionId,
    required String status,
    String remarks = '',
    String? administeredBy,
    String? administeredById,
    DateTime? administeredAt,
  }) async {
    final payload = <String, dynamic>{
      'status': status.trim(),
      'administered_at':
          (administeredAt ?? DateTime.now()).toUtc().toIso8601String(),
      if (administeredBy != null && administeredBy.trim().isNotEmpty)
        'administered_by': administeredBy.trim(),
      if (administeredById != null && administeredById.trim().isNotEmpty)
        'administered_by_id': administeredById.trim(),
      if (remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    };
    await _client.post(
      endpoints.ipdAdministerPrescription(ipdId, prescriptionId),
      body: payload,
    );
  }

  Future<void> transferPatientBed({
    required String ipdId,
    required String bedId,
    required String transferReason,
  }) async {
    await _client.post(
      endpoints.ipdTransferBed(ipdId),
      body: <String, dynamic>{
        'bed_id': bedId.trim(),
        'transfer_reason': transferReason.trim(),
      },
    );
  }

  Future<void> updateDischargeChecklist({
    required String ipdId,
    required DischargeChecklist checklist,
  }) async {
    await _client.put(
      endpoints.ipdDischargeChecklist(ipdId),
      body: checklist.toJson(),
    );
  }

  Future<void> addNursingProcedureCharge({
    required String ipdId,
    required String chargeName,
    String chargeType = 'IPD',
    String chargeCategory = 'Nursing Charges',
    required int qty,
    required double appliedCharge,
    String note = '',
    String? addedBy,
    DateTime? date,
  }) async {
    await _client.post(
      endpoints.ipdCharges(ipdId),
      body: <String, dynamic>{
        'charge_name': chargeName.trim(),
        'charge_type': chargeType.trim(),
        'charge_category': chargeCategory.trim(),
        'qty': qty,
        'applied_charge': appliedCharge,
        'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
        if (addedBy != null && addedBy.trim().isNotEmpty)
          'added_by': addedBy.trim(),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Beds & Ward Status APIs
  // ---------------------------------------------------------------------------

  Future<List<HospitalBed>> fetchBeds({bool? isOccupied}) async {
    final res = await _client.get(endpoints.beds);
    final all = JsonParsers.extractList(res).map(HospitalBed.fromJson).toList();
    if (isOccupied == null) return all;
    return all.where((b) => b.isOccupied == isOccupied).toList();
  }

  Future<List<WardBedGroup>> fetchBedGroups() async {
    final res = await _client.get(endpoints.bedGroups);
    return JsonParsers.extractList(res).map(WardBedGroup.fromJson).toList();
  }

  Future<List<ChargeMasterItem>> fetchChargeMaster() async {
    try {
      final res = await _client.get(endpoints.charges);
      return JsonParsers.extractList(res)
          .map(ChargeMasterItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // 7. Blood Bank Status & Donor Details (`/admin/bloodbankstatus` — image-9)
  // ---------------------------------------------------------------------------

  Future<List<BloodBankGroupItem>> fetchBloodBank() async {
    List<BloodBankGroupItem>? emptyOk;
    ApiException? lastErr;
    for (final url in [
      endpoints.bloodBankStatus,
      endpoints.bloodBankAltStatus,
      endpoints.bloodBank,
      endpoints.bloodBankAlt,
      endpoints.bloodBankGroups,
      endpoints.bloodBankInventory,
      endpoints.bloodBankBags,
    ]) {
      try {
        final res = await _client.get(url);
        final parsed = BloodBankGroupItem.parseFlexible(res);
        if (parsed.isNotEmpty) return parsed;
        emptyOk ??= parsed;
      } on ApiException catch (e) {
        lastErr = e;
        if (!e.isNotFound) rethrow;
      }
    }
    if (emptyOk != null) return emptyOk;
    if (lastErr != null) throw lastErr;
    return const [];
  }

  Future<List<BloodDonorRecord>> fetchBloodDonors() async {
    for (final url in [
      endpoints.bloodBankDonors,
      endpoints.bloodBankAltDonors,
      endpoints.bloodBank,
      endpoints.bloodBankAlt,
    ]) {
      try {
        final res = await _client.get(url);
        final list = JsonParsers.extractList(
          res,
          candidateKeys: const ['donors', 'records', 'items', 'data'],
        );
        final filtered = list
            .where(
              (m) =>
                  m.containsKey('donor_name') ||
                  m.containsKey('donorName') ||
                  m.containsKey('contact_no') ||
                  m.containsKey('donate_date'),
            )
            .map(BloodDonorRecord.fromJson)
            .toList();
        if (filtered.isNotEmpty) return filtered;
      } catch (_) {}
    }
    return const [];
  }

  // ---------------------------------------------------------------------------
  // 8. Duty Roster & Shifts (`/duty-roster` — image-10)
  // ---------------------------------------------------------------------------

  Future<List<DutyShiftAssignment>> fetchDutyRoster() async {
    final candidateUrls = <String>[
      endpoints.dutyRoster,
      endpoints.dutyRosterAssignments,
      endpoints.dutyRosterRosters,
      endpoints.dutyRostersAssignmentsLegacy,
    ];

    List<DutyShiftAssignment>? firstValidEmpty;
    ApiException? lastError;

    for (final url in candidateUrls) {
      try {
        final res = await _client.get(url);
        final parsed = JsonParsers.extractList(
          res,
          candidateKeys: const [
            'assignments',
            'rosters',
            'records',
            'items',
            'data',
          ],
        ).map(DutyShiftAssignment.fromJson).toList();

        if (parsed.isNotEmpty) return parsed;
        firstValidEmpty ??= parsed;
      } on ApiException catch (e) {
        lastError = e;
        if (!e.isNotFound) rethrow;
      }
    }

    if (firstValidEmpty != null) return firstValidEmpty;
    if (lastError != null) throw lastError;
    return const [];
  }

  // ---------------------------------------------------------------------------
  // 9. Annual Calendar / Holidays (`/calendar` — image-11)
  // ---------------------------------------------------------------------------

  Future<List<HospitalHolidayItem>> fetchHolidays() async {
    List<HospitalHolidayItem>? emptyOk;
    ApiException? lastErr;
    for (final url in [
      endpoints.holidays,
      endpoints.holidayAlt,
      endpoints.calendar,
    ]) {
      try {
        final res = await _client.get(url);
        final parsed = JsonParsers.extractList(
          res,
          candidateKeys: const ['holidays', 'events', 'records', 'items', 'data'],
        ).map(HospitalHolidayItem.fromJson).toList();
        if (parsed.isNotEmpty) return parsed;
        emptyOk ??= parsed;
      } on ApiException catch (e) {
        lastErr = e;
        if (!e.isNotFound) rethrow;
      }
    }
    if (emptyOk != null) return emptyOk;
    if (lastErr != null) throw lastErr;
    return const [];
  }

  // ---------------------------------------------------------------------------
  // 10. Notifications & Protected Report File Downloads
  // ---------------------------------------------------------------------------

  Future<List<ServerNotificationItem>> fetchNotifications() async {
    try {
      final res = await _client.get(endpoints.notifications);
      return JsonParsers.extractList(res)
          .map(ServerNotificationItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client.put(endpoints.notificationRead(notificationId));
    } catch (_) {}
  }

  Future<({Uint8List bytes, String contentType})> downloadClinicalReportFile(
    String reportPath,
  ) {
    return _client.downloadAuthenticatedBytes(reportPath);
  }
}
