import 'dart:convert';
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

  Map<String, dynamic> _mergeNonEmptyMap(
    Map<String, dynamic> primaryMap,
    Map<String, dynamic> secondaryMap,
  ) {
    final result = <String, dynamic>{...secondaryMap};
    primaryMap.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty ||
            trimmed.toLowerCase() == 'null' ||
            trimmed.toLowerCase() == 'undefined') {
          return;
        }
        result[key] = value;
      } else if (value is Map && result[key] is Map) {
        result[key] = _mergeNonEmptyMap(
          JsonParsers.asMap(value),
          JsonParsers.asMap(result[key]),
        );
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Future<NurseUser> fetchMe() async {
    final res = await _client.get(endpoints.authMe);
    Map<String, dynamic> merged = _mergeNonEmptyMap(
      JsonParsers.extractObject(res),
      JsonParsers.asMap(res),
    );
    var parsed = NurseUser.fromJson(merged);

    // Probe extended profile endpoints if photo or employment fields were omitted by `/api/auth/me`
    final extraUrls = <String>[
      endpoints.authProfile,
      endpoints.usersProfile,
      endpoints.profile,
      if (parsed.id.isNotEmpty) endpoints.staffDetail(parsed.id),
      if (parsed.id.isNotEmpty) endpoints.userDetail(parsed.id),
    ];

    for (final url in extraUrls) {
      if (parsed.image != null &&
          parsed.image!.trim().isNotEmpty &&
          parsed.qualification.isNotEmpty) {
        break;
      }
      try {
        final extraRes = await _client.get(
          url,
          timeout: const Duration(seconds: 6),
        );
        final extraObj = _mergeNonEmptyMap(
          JsonParsers.extractObject(extraRes),
          JsonParsers.asMap(extraRes),
        );
        if (extraObj.isNotEmpty) {
          merged = _mergeNonEmptyMap(merged, extraObj);
          parsed = NurseUser.fromJson(merged);
        }
      } catch (_) {}
    }

    // Final fallback: check `/api/staff` directory matching by ID, email, or employee code (`9008`)
    if (parsed.image == null || parsed.image!.trim().isEmpty) {
      try {
        final staffRes = await _client.get(
          endpoints.staffList,
          timeout: const Duration(seconds: 6),
        );
        final staffItems = JsonParsers.extractList(staffRes);
        for (final s in staffItems) {
          final sid = JsonParsers.asId(s['_id'] ?? s['id']);
          final semail = JsonParsers.asString(s['email']).toLowerCase();
          final scode = JsonParsers.asString(
            s['employee_id'] ?? s['employeeId'] ?? s['staff_id'],
          );
          final matches = (parsed.id.isNotEmpty && sid == parsed.id) ||
              (parsed.email.isNotEmpty &&
                  semail == parsed.email.toLowerCase()) ||
              (parsed.staffCode.isNotEmpty && scode == parsed.staffCode);
          if (matches) {
            merged = _mergeNonEmptyMap(merged, s);
            parsed = NurseUser.fromJson(merged);
            break;
          }
        }
      } catch (_) {}
    }

    return parsed;
  }

  Future<NurseUser> updateProfile({
    required String userId,
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String emergencyContact,
    required String gender,
    required String dob,
    required String bloodGroup,
    required String currentAddress,
    required String permanentAddress,
    String? image,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'firstName': name.trim(),
      'first_name': name.trim(),
      'surname': surname.trim(),
      'lastName': surname.trim(),
      'last_name': surname.trim(),
      'email': email.trim(),
      'contact_no': phone.trim(),
      'contactNo': phone.trim(),
      'phone': phone.trim(),
      'mobileno': phone.trim(),
      'emergency_contact_no': emergencyContact.trim(),
      'emergencyContactNo': emergencyContact.trim(),
      'emergency_contact': emergencyContact.trim(),
      'emergencyContact': emergencyContact.trim(),
      'gender': gender.trim(),
      if (dob.trim().isNotEmpty) 'dob': dob.trim(),
      'blood_group': bloodGroup.trim(),
      'bloodGroup': bloodGroup.trim(),
      'local_address': currentAddress.trim(),
      'localAddress': currentAddress.trim(),
      'current_address': currentAddress.trim(),
      'currentAddress': currentAddress.trim(),
      'permanent_address': permanentAddress.trim(),
      'permanentAddress': permanentAddress.trim(),
      if (image != null && image.trim().isNotEmpty) ...{
        'image': image.trim(),
        'photo': image.trim(),
        'avatar': image.trim(),
        'profilePhoto': image.trim(),
        'profile_photo': image.trim(),
        'profileImage': image.trim(),
        'profile_image': image.trim(),
      },
    };

    final candidateUrls = <String>[
      endpoints.authProfile,
      endpoints.authMe,
      endpoints.usersProfile,
      if (userId.trim().isNotEmpty) endpoints.staffDetail(userId.trim()),
    ];

    Object? lastError;
    for (final url in candidateUrls) {
      try {
        final res = await _client.put(url, body: payload);
        final obj = JsonParsers.extractObject(res);
        if (obj.isNotEmpty) {
          return NurseUser.fromJson(obj);
        }
        return await fetchMe();
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) {
          continue;
        }
        rethrow;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
    return await fetchMe();
  }

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
    String mimeType = 'image/jpeg',
  }) async {
    for (final target in [
      (url: endpoints.authProfilePhoto, field: 'photo'),
      (url: endpoints.authAvatar, field: 'avatar'),
      (url: endpoints.uploads, field: 'file'),
    ]) {
      try {
        final uploadedPath = await _client.uploadMultipartBytes(
          urlOrPath: target.url,
          bytes: bytes,
          filename: filename,
          fieldName: target.field,
        );
        if (uploadedPath.trim().isNotEmpty) {
          return uploadedPath.trim();
        }
      } catch (_) {}
    }
    // Fallback to inline data URI when server stores base64 avatar directly on User/Staff document
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
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
    String? confirmPassword,
  }) async {
    final confirm = confirmPassword ?? newPassword;
    final body = <String, dynamic>{
      'currentPassword': currentPassword,
      'old_password': currentPassword,
      'oldPassword': currentPassword,
      'newPassword': newPassword,
      'new_password': newPassword,
      'confirmPassword': confirm,
      'confirm_password': confirm,
    };

    Object? lastError;
    for (final attempt in [
      () => _client.put(endpoints.authChangePassword, body: body),
      () => _client.post(endpoints.authChangePassword, body: body),
      () => _client.put(endpoints.authPasswordAlt, body: body),
    ]) {
      try {
        await attempt();
        return;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) {
          continue;
        }
        rethrow;
      }
    }
    if (lastError != null) throw lastError;
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
    final admission = IpdAdmission.fromJson(JsonParsers.asMap(res));
    if (admission.investigations.isNotEmpty) {
      return admission;
    }

    // Also pull linked Pathology & Radiology investigations (matches Website IPD Chart `Investigations (N)`).
    try {
      final results = await Future.wait<List<InvestigationOrder>>([
        _fetchPatientInvestigationsFromEndpoints(
          urls: [endpoints.pathology, endpoints.pathologyBills],
          admission: admission,
          category: 'Pathology',
        ),
        _fetchPatientInvestigationsFromEndpoints(
          urls: [endpoints.radiology, endpoints.radiologyBills],
          admission: admission,
          category: 'Radiology',
        ),
      ]);
      final merged = <InvestigationOrder>[...results[0], ...results[1]];
      if (merged.isNotEmpty) {
        return admission.copyWith(investigations: merged);
      }
    } catch (_) {}

    return admission;
  }

  Future<List<InvestigationOrder>> _fetchPatientInvestigationsFromEndpoints({
    required List<String> urls,
    required IpdAdmission admission,
    required String category,
  }) async {
    for (final url in urls) {
      try {
        final raw = await _client.get(url);
        final list = JsonParsers.extractList(
          raw,
          candidateKeys: const ['bills', 'orders', 'records', 'items', 'data'],
        );
        if (list.isEmpty) continue;
        final matched = list.where((m) => _matchesAdmissionOrder(m, admission)).toList();
        return InvestigationOrder.parseBillOrOrderList(
          matched,
          fallbackCategory: category,
        );
      } catch (_) {
        // Try next candidate URL
      }
    }
    return const [];
  }

  bool _matchesAdmissionOrder(Map<String, dynamic> item, IpdAdmission ipd) {
    final itemIpdId = JsonParsers.asId(item['ipd_id'] ?? item['ipd']);
    if (ipd.id.isNotEmpty && itemIpdId == ipd.id) return true;

    final itemIpdNo = JsonParsers.asString(item['ipd_no']).trim().toLowerCase();
    if (ipd.ipdNo.isNotEmpty && itemIpdNo == ipd.ipdNo.trim().toLowerCase()) {
      return true;
    }

    final itemCase = JsonParsers.asString(
      item['case_reference_id'] ?? item['case_id'],
    ).trim().toLowerCase();
    if (ipd.caseReferenceId.isNotEmpty &&
        itemCase == ipd.caseReferenceId.trim().toLowerCase()) {
      return true;
    }

    final patMap = item['patient'] is Map
        ? JsonParsers.asMap(item['patient'])
        : <String, dynamic>{};
    final itemPatId = JsonParsers.asId(item['patient_id'] ?? patMap['_id'] ?? patMap['id']);
    if (ipd.patient.id.isNotEmpty && itemPatId == ipd.patient.id) return true;

    final itemUhid = JsonParsers.asString(
      item['patient_unique_id'] ?? patMap['patient_unique_id'] ?? item['uhid'],
    ).trim().toLowerCase();
    if (ipd.patient.patientUniqueId.isNotEmpty &&
        itemUhid == ipd.patient.patientUniqueId.trim().toLowerCase()) {
      return true;
    }

    return false;
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

  /// Fetches the live hospital staff directory (`GET /api/staff`) so Duty Roster
  /// populates `All Staff (N)` and `All Departments` identically to the website (image-17 & image-20).
  Future<List<StaffRosterMember>> fetchStaffDirectory() async {
    try {
      final res = await _client.get(endpoints.staffList);
      final parsed = JsonParsers.extractList(
        res,
        candidateKeys: const ['staff', 'users', 'members', 'records', 'items', 'data'],
      ).map(StaffRosterMember.fromJson).toList();
      parsed.sort((a, b) {
        final ai = int.tryParse(a.employeeId);
        final bi = int.tryParse(b.employeeId);
        if (ai != null && bi != null) return ai.compareTo(bi);
        if (a.employeeId.isNotEmpty && b.employeeId.isNotEmpty) {
          return a.employeeId.compareTo(b.employeeId);
        }
        return a.fullName.compareTo(b.fullName);
      });
      return parsed;
    } catch (_) {
      return const [];
    }
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
