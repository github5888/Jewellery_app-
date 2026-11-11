import 'dart:typed_data';

import '../core/config/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/utils/json_parsers.dart';
import '../models/bed_models.dart';
import '../models/clinical_report_model.dart';
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
  // 2. Nurse Home Dashboard API
  // ---------------------------------------------------------------------------

  Future<NurseDashboardData> fetchDashboard() async {
    final res = await _client.get(endpoints.dashboard);
    return NurseDashboardData.fromJson(JsonParsers.asMap(res));
  }

  // ---------------------------------------------------------------------------
  // 3. IPD Ward & Bed-Side Patient Care APIs
  // ---------------------------------------------------------------------------

  Future<List<IpdAdmission>> fetchIpdAdmissions({
    String dischargeStatus = 'admitted',
  }) async {
    final query = <String, String>{};
    if (dischargeStatus.isNotEmpty && dischargeStatus != 'all') {
      query['discharge_status'] = dischargeStatus;
    }
    final res = await _client.get(endpoints.ipdList, queryParameters: query);
    final list = JsonParsers.extractList(res);
    return list.map(IpdAdmission.fromJson).toList();
  }

  Future<IpdAdmission> fetchIpdPatientDetail(String ipdId) async {
    final res = await _client.get(endpoints.ipdDetail(ipdId));
    return IpdAdmission.fromJson(JsonParsers.asMap(res));
  }

  // ---------------------------------------------------------------------------
  // 4. Vitals & Bedside Logging (Nurse Action APIs)
  // ---------------------------------------------------------------------------

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

  Future<String> uploadAttachmentBytes({
    required Uint8List bytes,
    required String filename,
  }) {
    return _client.uploadMultipartBytes(
      urlOrPath: endpoints.uploads,
      bytes: bytes,
      filename: filename,
    );
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
  // 5. Beds & Ward Status APIs
  // ---------------------------------------------------------------------------

  Future<List<HospitalBed>> fetchBeds({bool? isOccupied}) async {
    final query = <String, String>{};
    if (isOccupied != null) {
      query['is_occupied'] = isOccupied.toString();
    }
    final res = await _client.get(endpoints.beds, queryParameters: query);
    return JsonParsers.extractList(res).map(HospitalBed.fromJson).toList();
  }

  Future<List<WardBedGroup>> fetchBedGroups() async {
    final res = await _client.get(endpoints.bedGroups);
    return JsonParsers.extractList(res).map(WardBedGroup.fromJson).toList();
  }

  // ---------------------------------------------------------------------------
  // 6. OPD Triage Desk APIs
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
  // 7. Nurse Duty Roster & Shifts APIs
  // ---------------------------------------------------------------------------

  Future<List<DutyShiftAssignment>> fetchDutyRoster({String? staffId}) async {
    final query = <String, String>{
      if (staffId != null && staffId.trim().isNotEmpty)
        'staff_id': staffId.trim(),
    };
    final candidateUrls = <String>[
      endpoints.dutyRosterAssignments,
      endpoints.dutyRoster,
      endpoints.dutyRostersAssignmentsLegacy,
    ];

    ApiException? lastError;
    for (final url in candidateUrls) {
      try {
        final res = await _client.get(url, queryParameters: query);
        return JsonParsers.extractList(res)
            .map(DutyShiftAssignment.fromJson)
            .toList();
      } on ApiException catch (e) {
        lastError = e;
        if (!e.isNotFound) rethrow;
      }
    }
    if (lastError != null) throw lastError;
    return const [];
  }

  // ---------------------------------------------------------------------------
  // 8. Patient Directory, Reports, Appointments, Staff, Pharmacy, Inventory, etc.
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

  Future<List<ClinicalReportRecord>> fetchPathologyReports() async {
    for (final url in [endpoints.pathology, endpoints.pathologyBills]) {
      try {
        final res = await _client.get(url);
        final rawList = JsonParsers.extractList(res);
        return rawList
            .expand(
              (item) => ClinicalReportRecord.fromBillJson(
                item,
                ClinicalReportCategory.lab,
              ),
            )
            .toList();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    return const [];
  }

  Future<List<ClinicalReportRecord>> fetchRadiologyReports() async {
    for (final url in [endpoints.radiology, endpoints.radiologyBills]) {
      try {
        final res = await _client.get(url);
        final rawList = JsonParsers.extractList(res);
        return rawList
            .expand(
              (item) => ClinicalReportRecord.fromBillJson(
                item,
                ClinicalReportCategory.radiology,
              ),
            )
            .toList();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    return const [];
  }

  Future<({Uint8List bytes, String contentType})> downloadClinicalReportFile(
    String reportPath,
  ) {
    return _client.downloadAuthenticatedBytes(reportPath);
  }

  Future<List<HospitalAppointmentItem>> fetchAppointments() async {
    try {
      final res = await _client.get(endpoints.appointments);
      return JsonParsers.extractList(res)
          .map(HospitalAppointmentItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<StaffDirectoryMember>> fetchStaffDirectory() async {
    final res = await _client.get(endpoints.staff);
    return JsonParsers.extractList(res)
        .map(StaffDirectoryMember.fromJson)
        .toList();
  }

  Future<List<PharmacyMedicineItem>> fetchPharmacyStock() async {
    for (final url in [endpoints.pharmacyMedicines, endpoints.pharmacy]) {
      try {
        final res = await _client.get(url);
        return JsonParsers.extractList(res)
            .map(PharmacyMedicineItem.fromJson)
            .toList();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    return const [];
  }

  Future<List<InventoryStockItem>> fetchWardInventory() async {
    for (final url in [endpoints.inventory, endpoints.itemStock]) {
      try {
        final res = await _client.get(url);
        return JsonParsers.extractList(res)
            .map(InventoryStockItem.fromJson)
            .toList();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    return const [];
  }

  Future<List<ServerNotificationItem>> fetchNotifications() async {
    for (final url in [endpoints.notifications, endpoints.messaging]) {
      try {
        final res = await _client.get(url);
        return JsonParsers.extractList(res)
            .map(ServerNotificationItem.fromJson)
            .toList();
      } catch (_) {}
    }
    return const [];
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client.put(endpoints.notificationRead(notificationId));
    } catch (_) {}
  }

  Future<List<BloodBankGroupItem>> fetchBloodBank() async {
    for (final url in [endpoints.bloodBank, endpoints.bloodBankAlt]) {
      try {
        final res = await _client.get(url);
        return JsonParsers.extractList(res)
            .map(BloodBankGroupItem.fromJson)
            .toList();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    return const [];
  }

  Future<List<HospitalHolidayItem>> fetchHolidays() async {
    for (final url in [endpoints.holidays, endpoints.holidayAlt]) {
      try {
        final res = await _client.get(url);
        return JsonParsers.extractList(res)
            .map(HospitalHolidayItem.fromJson)
            .toList();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }
    return const [];
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

  /// Live diagnostic probe for the API Connections Status screen.
  Future<({bool ok, String detail})> probeEndpoint(String fullUrl) async {
    try {
      final res = await _client.get(
        fullUrl,
        timeout: const Duration(seconds: 10),
      );
      final list = JsonParsers.extractList(res);
      if (list.isNotEmpty) {
        return (ok: true, detail: '200 OK (${list.length} records)');
      }
      return (ok: true, detail: '200 OK (Connected)');
    } on ApiException catch (e) {
      if (e.isForbidden) {
        return (ok: true, detail: '403 RBAC Restricted for Nurse Role');
      }
      return (ok: false, detail: e.message);
    } catch (e) {
      return (ok: false, detail: e.toString());
    }
  }
}
