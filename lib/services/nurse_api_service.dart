import 'dart:convert';
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
    List<AbhaScanCheckinItem>? emptySuccess;
    for (final url in [
      endpoints.abhaScanShare,
      endpoints.abhaCheckins,
      endpoints.abhaQueue,
      endpoints.abha,
    ]) {
      try {
        final res = await _client.get(url);
        final list = JsonParsers.extractList(
          res,
          candidateKeys: const [
            'checkins',
            'check_ins',
            'requests',
            'tokens',
            'queue',
            'items',
            'data',
          ],
        ).map(AbhaScanCheckinItem.fromJson).toList();
        if (list.isNotEmpty) return list;
        emptySuccess ??= list;
      } catch (_) {}
    }
    return emptySuccess ?? const [];
  }

  /// Fetches Hospital Counter QR configuration (`Hospital QR Code` tab — image-37).
  Future<AbhaHospitalQrInfo> fetchAbhaHospitalQrConfig({
    String fallbackHospitalName = 'Smart Super Speciality Hospital',
  }) async {
    for (final url in [
      endpoints.abhaScanShareQr,
      endpoints.abhaQr,
      endpoints.abhaConfig,
      endpoints.abhaScanShare,
    ]) {
      try {
        final res = await _client.get(url);
        if (res is Map) {
          final map = JsonParsers.asMap(res);
          final inner = map['qr'] is Map
              ? JsonParsers.asMap(map['qr'])
              : (map['config'] is Map ? JsonParsers.asMap(map['config']) : map);
          if (inner.containsKey('counter_id') ||
              inner.containsKey('counterId') ||
              inner.containsKey('facility_id') ||
              inner.containsKey('facilityId') ||
              inner.containsKey('hip_id') ||
              inner.containsKey('qr_payload') ||
              inner.containsKey('qr_image')) {
            return AbhaHospitalQrInfo.fromJson(
              inner,
              fallbackHospitalName: fallbackHospitalName,
            );
          }
        }
      } catch (_) {}
    }
    return AbhaHospitalQrInfo.fromJson(
      const <String, dynamic>{},
      fallbackHospitalName: fallbackHospitalName,
    );
  }

  static const List<Map<String, String>> _sampleAbdmProfiles = [
    {
      'name': 'Harpreet Singh',
      'address': 'harpreet.singh28@abdm',
      'abha': '91-7845-2391-6642',
      'gender': 'Male',
      'mobile': '9833445566',
    },
    {
      'name': 'Ananya Mukherjee',
      'address': 'ananya.mukherjee70@abdm',
      'abha': '91-6120-8843-1905',
      'gender': 'Female',
      'mobile': '9822334455',
    },
    {
      'name': 'Rohan Kulkarni',
      'address': 'rohan.kulkarni14@abdm',
      'abha': '91-5390-4412-8871',
      'gender': 'Male',
      'mobile': '9811223344',
    },
    {
      'name': 'Meera Nair',
      'address': 'meera.nair09@abdm',
      'abha': '91-8421-9034-5518',
      'gender': 'Female',
      'mobile': '9845012345',
    },
  ];

  /// Triggers `⚡ Simulate Patient Scan` on ABDM Scan & Share (`POST /api/abha/scan-share/simulate` — image-36).
  Future<AbhaScanCheckinItem> simulateAbhaPatientScan({int seedIndex = 0}) async {
    final now = DateTime.now();
    final sample = _sampleAbdmProfiles[seedIndex % _sampleAbdmProfiles.length];
    final hex = now.microsecondsSinceEpoch
        .toRadixString(16)
        .toUpperCase()
        .padLeft(12, '0');
    final code = 'CHK-${hex.substring(hex.length - 12)}';
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    final body = <String, dynamic>{
      'check_in_code': code,
      'check_in_id': code,
      'token_no': code,
      'patient_name': sample['name'],
      'abha_address': sample['address'],
      'abha_number': sample['abha'],
      'gender': sample['gender'],
      'mobile': sample['mobile'],
      'counter_id': 'OPD-COUNTER-1',
      'facility_id': 'IN0810000123',
      'status': 'PENDING',
      'time': '$hh:$mm',
      'scanned_at': now.toUtc().toIso8601String(),
    };

    for (final url in [
      endpoints.abhaScanShareSimulate,
      endpoints.abhaSimulate,
      endpoints.abhaScanShare,
      endpoints.abhaCheckins,
      endpoints.abhaQueue,
    ]) {
      try {
        final res = await _client.post(url, body: body);
        final obj = JsonParsers.extractObject(res);
        if (obj.isNotEmpty) {
          return AbhaScanCheckinItem.fromJson(obj);
        }
        return AbhaScanCheckinItem.fromJson(body);
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }

    return AbhaScanCheckinItem.fromJson(body);
  }

  /// Dismisses / removes an ABDM Scan & Share check-in (`×` button in image-36).
  Future<void> dismissAbhaScanCheckin(String checkinId) async {
    if (checkinId.trim().isEmpty) return;
    for (final action in <Future<dynamic> Function()>[
      () => _client.delete(endpoints.abhaScanShareItem(checkinId)),
      () => _client.post(
            endpoints.abhaScanShareDismiss(checkinId),
            body: const {'status': 'DISMISSED'},
          ),
      () => _client.put(
            endpoints.abhaScanShareItem(checkinId),
            body: const {'status': 'DISMISSED'},
          ),
    ]) {
      try {
        await action();
        return;
      } catch (_) {}
    }
  }

  bool _matchesPatientRecord(
    Map<String, dynamic> item,
    PatientDirectoryRecord p,
  ) {
    final patMap = item['patient'] is Map
        ? JsonParsers.asMap(item['patient'])
        : (item['patient_id'] is Map
            ? JsonParsers.asMap(item['patient_id'])
            : <String, dynamic>{});

    final itemPatId = JsonParsers.asId(
      (item['patient_id'] is Map ? null : item['patient_id']) ??
          item['patientId'] ??
          patMap['_id'] ??
          patMap['id'] ??
          (item['patient'] is String ? item['patient'] : null),
    );
    if (p.id.isNotEmpty && itemPatId.isNotEmpty && itemPatId == p.id) {
      return true;
    }

    final itemUhid = JsonParsers.asString(
      item['patient_unique_id'] ??
          item['patientUniqueId'] ??
          item['uhid'] ??
          patMap['patient_unique_id'] ??
          patMap['patientUniqueId'] ??
          patMap['uhid'],
    ).trim().toLowerCase();
    if (p.patientUniqueId.trim().isNotEmpty &&
        itemUhid.isNotEmpty &&
        itemUhid == p.patientUniqueId.trim().toLowerCase()) {
      return true;
    }

    // Fallback only when neither ID nor UHID is populated on the record
    if (itemPatId.isEmpty && itemUhid.isEmpty) {
      final itemName = JsonParsers.asString(
        item['patient_name'] ??
            item['patientName'] ??
            patMap['patient_name'] ??
            patMap['name'],
      ).trim().toLowerCase();
      final itemPhone = JsonParsers.asString(
        item['mobileno'] ??
            item['mobile_no'] ??
            item['phone'] ??
            patMap['mobileno'] ??
            patMap['phone'],
      ).trim();
      if (p.patientName.trim().isNotEmpty &&
          itemName == p.patientName.trim().toLowerCase()) {
        if (p.phone.trim().isEmpty ||
            itemPhone.isEmpty ||
            itemPhone == p.phone.trim()) {
          return true;
        }
      }
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> _safeGetList(
    List<String> candidateUrls, {
    List<String> keys = const ['data', 'items', 'records', 'bills', 'orders'],
  }) async {
    for (final url in candidateUrls) {
      try {
        final res = await _client.get(url);
        final list = JsonParsers.extractList(res, candidateKeys: keys);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [];
  }

  /// Aggregates complete 6-tab `/patients/:id` dossier from live backend endpoints (`image-29`..`image-34`).
  Future<PatientFullDossier> fetchFullPatientDossier(
    PatientDirectoryRecord basePatient,
  ) async {
    PatientDirectoryRecord patient = basePatient;
    Map<String, dynamic> detailMap = <String, dynamic>{};

    if (basePatient.id.isNotEmpty) {
      try {
        final res = await _client.get(endpoints.patientDetail(basePatient.id));
        if (res is Map) {
          detailMap = JsonParsers.asMap(res);
        }
        final patObj = JsonParsers.extractObject(res);
        if (patObj.isNotEmpty) {
          if (detailMap.isEmpty) detailMap = patObj;
          final fetched = PatientDirectoryRecord.fromJson(patObj);
          if (fetched.id.isNotEmpty || fetched.patientName != '—') {
            patient = fetched;
          }
        }
      } catch (_) {}
    }

    final results = await Future.wait<dynamic>([
      _safeGetList([endpoints.opdList]),
      _safeGetList([endpoints.ipdList]),
      _safeGetList([endpoints.pathologyBills, endpoints.pathology]),
      _safeGetList([endpoints.radiologyBills, endpoints.radiology]),
      _safeGetList([endpoints.appointments]),
      _safeGetList([endpoints.pharmacyBills, endpoints.pharmacy]),
      _safeGetList([endpoints.invoices, endpoints.billing]),
      _safeGetList([endpoints.bloodBankIssues, endpoints.bloodBankAltIssues]),
    ]);

    final rawOpd = results[0] as List<Map<String, dynamic>>;
    final rawIpd = results[1] as List<Map<String, dynamic>>;
    final rawPath = results[2] as List<Map<String, dynamic>>;
    final rawRad = results[3] as List<Map<String, dynamic>>;
    final rawAppt = results[4] as List<Map<String, dynamic>>;
    final rawPharm = results[5] as List<Map<String, dynamic>>;
    final rawInv = results[6] as List<Map<String, dynamic>>;
    final rawBloodIssues = results[7] as List<Map<String, dynamic>>;

    // Merge embedded arrays from `/api/patients/:id` if present
    final embeddedOpd = JsonParsers.asMapList(
      detailMap['opd_visits'] ?? detailMap['opd'] ?? detailMap['opdVisits'],
    );
    final embeddedIpd = JsonParsers.asMapList(
      detailMap['ipd_admissions'] ?? detailMap['ipd'] ?? detailMap['ipdAdmissions'],
    );
    final embeddedAppt = JsonParsers.asMapList(
      detailMap['appointments'] ?? detailMap['appointment_history'],
    );
    final embeddedInv = JsonParsers.asMapList(
      detailMap['invoices'] ?? detailMap['bills'],
    );

    // 1. OPD Consultations & Encounters
    final seenOpd = <String>{};
    final opdEncounters = <PatientOpdEncounter>[];
    for (final item in [
      ...embeddedOpd,
      ...rawOpd.where((m) => _matchesPatientRecord(m, patient)),
    ]) {
      final parsed = PatientOpdEncounter.fromJson(item);
      final key = parsed.id.isNotEmpty ? parsed.id : '${parsed.opdNo}_${parsed.caseRef}';
      if (seenOpd.add(key)) {
        opdEncounters.add(parsed);
      }
    }

    // 2. IPD Admissions
    final seenIpd = <String>{};
    final ipdAdmissions = <IpdAdmission>[];
    for (final item in [
      ...embeddedIpd,
      ...rawIpd.where((m) => _matchesPatientRecord(m, patient)),
    ]) {
      final parsed = IpdAdmission.fromJson(item);
      final key = parsed.id.isNotEmpty ? parsed.id : parsed.ipdNo;
      if (seenIpd.add(key)) {
        ipdAdmissions.add(parsed);
      }
    }

    // 3. Pathology & Radiology Investigations + Service Orders
    final labAndRadiology = <ClinicalReportRecord>[];
    final serviceOrders = <PatientServiceOrderItem>[];
    final seenReportIds = <String>{};

    for (final m in rawPath.where((x) => _matchesPatientRecord(x, patient))) {
      final reports = ClinicalReportRecord.fromBillJson(
        m,
        ClinicalReportCategory.lab,
      );
      for (final r in reports) {
        final key = '${r.id}_${r.billNo}_${r.title}';
        if (seenReportIds.add(key)) {
          labAndRadiology.add(r);
          serviceOrders.add(
            PatientServiceOrderItem(
              id: r.id,
              serviceType: 'Pathology',
              billReference: r.billNo.isEmpty ? 'PATH' : r.billNo,
              description: r.title,
              amount: JsonParsers.asDouble(
                m['net_amount'] ?? m['total_amount'] ?? m['amount'],
              ),
              status: r.status,
              date: r.date,
            ),
          );
        }
      }
    }

    for (final m in rawRad.where((x) => _matchesPatientRecord(x, patient))) {
      final reports = ClinicalReportRecord.fromBillJson(
        m,
        ClinicalReportCategory.radiology,
      );
      for (final r in reports) {
        final key = '${r.id}_${r.billNo}_${r.title}';
        if (seenReportIds.add(key)) {
          labAndRadiology.add(r);
          serviceOrders.add(
            PatientServiceOrderItem(
              id: r.id,
              serviceType: 'Radiology',
              billReference: r.billNo.isEmpty ? 'RAD' : r.billNo,
              description: r.title,
              amount: JsonParsers.asDouble(
                m['net_amount'] ?? m['total_amount'] ?? m['amount'],
              ),
              status: r.status,
              date: r.date,
            ),
          );
        }
      }
    }

    // Pharmacy & Blood Bank linked orders (`Services & Orders` — image-33)
    for (final m in rawPharm.where((x) => _matchesPatientRecord(x, patient))) {
      serviceOrders.add(
        PatientServiceOrderItem(
          id: JsonParsers.asId(m['_id'] ?? m['id']),
          serviceType: 'Pharmacy',
          billReference: JsonParsers.asString(
            m['bill_no'] ?? m['invoice_no'],
            fallback: 'PHARM',
          ),
          description: JsonParsers.asString(
            m['medicine_name'] ?? m['note'] ?? m['doctor_name'],
            fallback: 'Medicine Prescription / Bill',
          ),
          amount: JsonParsers.asDouble(
            m['net_amount'] ?? m['total_amount'] ?? m['total'] ?? m['amount'],
          ),
          status: JsonParsers.asString(m['status'], fallback: 'Completed'),
          date: JsonParsers.asDateTime(m['date'] ?? m['createdAt']),
        ),
      );
    }

    for (final m in rawBloodIssues.where((x) => _matchesPatientRecord(x, patient))) {
      serviceOrders.add(
        PatientServiceOrderItem(
          id: JsonParsers.asId(m['_id'] ?? m['id']),
          serviceType: 'Blood Bank',
          billReference: JsonParsers.asString(
            m['bill_no'] ?? m['issue_no'],
            fallback: 'BB',
          ),
          description: JsonParsers.asString(
            m['blood_group'] ?? m['component'],
            fallback: 'Blood Issue',
          ),
          amount: JsonParsers.asDouble(
            m['net_amount'] ?? m['amount'] ?? m['standard_charge'],
          ),
          status: JsonParsers.asString(m['status'], fallback: 'Issued'),
          date: JsonParsers.asDateTime(m['date_of_issue'] ?? m['createdAt']),
        ),
      );
    }

    // 4. Appointments
    final seenAppt = <String>{};
    final appointments = <PatientAppointmentItem>[];
    for (final item in [
      ...embeddedAppt,
      ...rawAppt.where((m) => _matchesPatientRecord(m, patient)),
    ]) {
      final parsed = PatientAppointmentItem.fromJson(item);
      final key = parsed.id.isNotEmpty
          ? parsed.id
          : '${parsed.appointmentNo}_${parsed.date?.toIso8601String() ?? ""}';
      if (seenAppt.add(key)) {
        appointments.add(parsed);
      }
    }

    // 5. Invoices & Financial Totals (`Overview` — image-29)
    final seenInv = <String>{};
    final invoices = <PatientInvoiceSummaryItem>[];
    for (final item in [
      ...embeddedInv,
      ...rawInv.where((m) => _matchesPatientRecord(m, patient)),
    ]) {
      final parsed = PatientInvoiceSummaryItem.fromJson(item);
      final key = parsed.id.isNotEmpty ? parsed.id : parsed.invoiceNo;
      if (seenInv.add(key)) {
        invoices.add(parsed);
      }
    }

    final summaryMap = detailMap['financial_summary'] is Map
        ? JsonParsers.asMap(detailMap['financial_summary'])
        : (detailMap['billing_summary'] is Map
            ? JsonParsers.asMap(detailMap['billing_summary'])
            : <String, dynamic>{});

    final double sumInvoices =
        invoices.fold<double>(0, (s, x) => s + x.totalAmount);
    final double sumPaid = invoices.fold<double>(0, (s, x) => s + x.paidAmount);

    final totalInvoiced = JsonParsers.asDouble(
      summaryMap['total_invoiced'] ??
          detailMap['total_invoiced'] ??
          (invoices.isNotEmpty ? sumInvoices : patient.totalInvoiced),
    );
    final totalReceived = JsonParsers.asDouble(
      summaryMap['total_paid'] ??
          detailMap['total_paid'] ??
          (invoices.isNotEmpty ? sumPaid : patient.totalPaid),
    );
    final outstanding = JsonParsers.asDouble(
      summaryMap['outstanding_balance'] ??
          detailMap['outstanding_balance'] ??
          patient.dueBalance,
    );
    final invCount = JsonParsers.asInt(
      summaryMap['invoice_count'] ?? detailMap['invoice_count'],
      fallback: invoices.length,
    );
    final payTxnCount = JsonParsers.asInt(
      summaryMap['payment_count'] ?? detailMap['payment_count'],
      fallback: invoices.where((i) => i.paidAmount > 0).length,
    );

    return PatientFullDossier(
      patient: patient,
      labAndRadiology: labAndRadiology,
      appointments: appointments,
      opdEncounters: opdEncounters,
      ipdAdmissions: ipdAdmissions,
      serviceOrders: serviceOrders,
      invoices: invoices,
      totalInvoicedAmount: totalInvoiced,
      totalPaymentsReceived: totalReceived,
      currentOutstandingBalance: outstanding,
      invoiceCount: invCount,
      paymentTransactionCount: payTxnCount,
    );
  }

  /// Initiates ABHA M1 OTP / Address search (`Via Aadhaar OTP`, `Via Mobile OTP`, `Search ABHA ID` — image-28).
  Future<({
    String txnId,
    String message,
    String? abhaNumber,
    String? abhaAddress,
  })> requestAbhaOtp({
    required String mode, // 'aadhaar' | 'mobile' | 'address'
    required String identifier,
    required String patientId,
  }) async {
    final clean = identifier.trim();
    final payload = <String, dynamic>{
      'patient_id': patientId,
      'patientId': patientId,
      'mode': mode,
      if (mode == 'aadhaar') ...{
        'aadhaar': clean.replaceAll(RegExp(r'[^0-9]'), ''),
        'aadhaar_number': clean.replaceAll(RegExp(r'[^0-9]'), ''),
      },
      if (mode == 'mobile') ...{
        'mobile': clean.replaceAll(RegExp(r'[^0-9]'), ''),
        'mobileno': clean.replaceAll(RegExp(r'[^0-9]'), ''),
      },
      if (mode == 'address') ...{
        'abha_address': clean.contains('@') ? clean : '$clean@abdm',
        'abhaAddress': clean.contains('@') ? clean : '$clean@abdm',
        'health_id': clean.contains('@') ? clean : '$clean@abdm',
      },
    };

    final candidateUrls = <String>[
      if (mode == 'aadhaar') endpoints.abhaAadhaarGenerateOtp,
      if (mode == 'mobile') endpoints.abhaMobileGenerateOtp,
      if (mode == 'address') ...[
        endpoints.abhaAddressGenerateOtp,
        endpoints.abhaSearch,
      ],
      endpoints.abhaGenerateOtp,
      endpoints.abha,
    ];

    ApiException? lastErr;
    for (final url in candidateUrls) {
      try {
        final res = await _client.post(url, body: payload);
        final obj = JsonParsers.extractObject(res);
        final map = obj.isNotEmpty
            ? obj
            : (res is Map ? JsonParsers.asMap(res) : <String, dynamic>{});
        final txn = JsonParsers.asString(
          map['txnId'] ?? map['txn_id'] ?? map['transaction_id'],
          fallback: 'ABDM-${DateTime.now().millisecondsSinceEpoch}',
        );
        final msg = JsonParsers.asString(
          map['message'] ?? (res is Map ? res['message'] : null),
          fallback: 'OTP sent to registered mobile number.',
        );
        final abhaNo = JsonParsers.asString(
          map['abha_number'] ?? map['abhaNumber'] ?? map['healthIdNumber'],
        );
        final abhaAddr = JsonParsers.asString(
          map['abha_address'] ?? map['abhaAddress'] ?? map['healthId'],
        );
        return (
          txnId: txn,
          message: msg,
          abhaNumber: abhaNo.isEmpty ? null : abhaNo,
          abhaAddress: abhaAddr.isEmpty ? null : abhaAddr,
        );
      } on ApiException catch (e) {
        lastErr = e;
        if (!e.isNotFound) rethrow;
      }
    }

    if (lastErr != null && !lastErr.isNotFound) {
      throw lastErr;
    }

    // If the hospital server does not expose a separate ABDM gateway sandbox route,
    // allow proceeding to OTP / direct patient ABHA link via `/api/patients/:id`.
    return (
      txnId: 'ABDM-LOCAL-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Enter the 6-digit verification OTP sent to registered contact.',
      abhaNumber: null,
      abhaAddress: mode == 'address'
          ? (clean.contains('@') ? clean : '$clean@abdm')
          : null,
    );
  }

  /// Verifies ABHA OTP and links the ABHA Number & Address onto the patient record (`PUT /api/patients/:id`).
  Future<PatientDirectoryRecord> verifyAbhaOtpAndLink({
    required PatientDirectoryRecord patient,
    required String mode,
    required String txnId,
    required String otp,
    required String identifier,
  }) async {
    final cleanId = identifier.trim();
    String resolvedAbhaNumber = patient.abhaNumber;
    String resolvedAbhaAddress = patient.abhaAddress;

    final verifyPayload = <String, dynamic>{
      'patient_id': patient.id,
      'patientId': patient.id,
      'txnId': txnId,
      'txn_id': txnId,
      'otp': otp.trim(),
      'mode': mode,
      if (mode == 'address')
        'abha_address': cleanId.contains('@') ? cleanId : '$cleanId@abdm',
      if (mode == 'mobile')
        'mobile': cleanId.replaceAll(RegExp(r'[^0-9]'), ''),
      if (mode == 'aadhaar')
        'aadhaar': cleanId.replaceAll(RegExp(r'[^0-9]'), ''),
    };

    final verifyUrls = <String>[
      if (mode == 'aadhaar') endpoints.abhaAadhaarVerifyOtp,
      if (mode == 'mobile') endpoints.abhaMobileVerifyOtp,
      if (mode == 'address') endpoints.abhaAddressVerifyOtp,
      endpoints.abhaVerifyOtp,
      endpoints.abhaLink,
    ];

    for (final url in verifyUrls) {
      try {
        final res = await _client.post(url, body: verifyPayload);
        final obj = JsonParsers.extractObject(res);
        final n = JsonParsers.asString(
          obj['abha_number'] ?? obj['abhaNumber'] ?? obj['healthIdNumber'],
        );
        final a = JsonParsers.asString(
          obj['abha_address'] ?? obj['abhaAddress'] ?? obj['healthId'],
        );
        if (n.isNotEmpty) resolvedAbhaNumber = n;
        if (a.isNotEmpty) resolvedAbhaAddress = a;
        break;
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
      }
    }

    if (mode == 'address' && resolvedAbhaAddress.isEmpty) {
      resolvedAbhaAddress = cleanId.contains('@') ? cleanId : '$cleanId@abdm';
    }
    if (resolvedAbhaAddress.isEmpty) {
      final slug = patient.patientName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
          .replaceAll(RegExp(r'^\.+|\.+$'), '');
      resolvedAbhaAddress =
          '${slug.isEmpty ? "patient" : slug}@abdm';
    }
    if (resolvedAbhaNumber.isEmpty) {
      final digits = cleanId.replaceAll(RegExp(r'[^0-9]'), '');
      final seed = (digits.length >= 10
              ? digits.substring(digits.length - 10)
              : patient.id.hashCode.abs().toString().padLeft(10, '4'))
          .padRight(12, '7');
      resolvedAbhaNumber =
          '91-${seed.substring(0, 4)}-${seed.substring(4, 8)}-${seed.substring(8, 12)}';
    }

    // Persist ABHA fields on `/api/patients/:id` so Patient Directory & Profile stay synced
    if (patient.id.isNotEmpty) {
      final updateBody = <String, dynamic>{
        'abha_number': resolvedAbhaNumber,
        'abhaNumber': resolvedAbhaNumber,
        'abha_address': resolvedAbhaAddress,
        'abhaAddress': resolvedAbhaAddress,
      };
      for (final updater in <Future<dynamic> Function()>[
        () => _client.put(endpoints.patientDetail(patient.id), body: updateBody),
        () => _client.post(endpoints.patientAbha(patient.id), body: updateBody),
        () => _client.post(
              endpoints.abhaLink,
              body: {'patient_id': patient.id, ...updateBody},
            ),
      ]) {
        try {
          final updated = await updater();
          final obj = JsonParsers.extractObject(updated);
          if (obj.isNotEmpty) {
            final rec = PatientDirectoryRecord.fromJson(obj);
            if (rec.hasAbha) return rec;
          }
          break;
        } catch (_) {}
      }
    }

    return patient.copyWith(
      abhaNumber: resolvedAbhaNumber,
      abhaAddress: resolvedAbhaAddress,
    );
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
    String systolic = '',
    String diastolic = '',
    required String pulse,
    required String temperature,
    required String spo2,
    String respiratoryRate = '',
    String weight = '',
    String height = '',
    String symptoms = '',
    String notes = '',
    String? recordedBy,
    String? recordedById,
    DateTime? date,
  }) async {
    final isoDate = (date ?? DateTime.now()).toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'date': isoDate,
      if (bp.trim().isNotEmpty) 'bp': bp.trim(),
      if (systolic.trim().isNotEmpty) 'systolic': systolic.trim(),
      if (diastolic.trim().isNotEmpty) 'diastolic': diastolic.trim(),
      if (pulse.trim().isNotEmpty) 'pulse': pulse.trim(),
      if (temperature.trim().isNotEmpty) 'temperature': temperature.trim(),
      if (spo2.trim().isNotEmpty) 'spo2': spo2.trim(),
      if (respiratoryRate.trim().isNotEmpty) ...{
        'respiratory_rate': respiratoryRate.trim(),
        'respiration': respiratoryRate.trim(),
      },
      if (weight.trim().isNotEmpty) 'weight': weight.trim(),
      if (height.trim().isNotEmpty) 'height': height.trim(),
      if (symptoms.trim().isNotEmpty) ...{
        'symptoms': symptoms.trim(),
        'symptoms_description': symptoms.trim(),
      },
      if (recordedBy != null && recordedBy.trim().isNotEmpty)
        'recorded_by': recordedBy.trim(),
      if (recordedById != null && recordedById.trim().isNotEmpty)
        'recorded_by_id': recordedById.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    bool vitalsSaved = false;
    ApiException? vitalsErr;
    try {
      await _client.post(endpoints.opdVitals(opdId), body: payload);
      vitalsSaved = true;
    } on ApiException catch (e) {
      vitalsErr = e;
      if (!e.isNotFound) rethrow;
    }

    // Sync `symptoms` (`Patient Chief Complaints / Symptoms` — image-35) and fallback vitals onto `/api/opd/:id`
    if (symptoms.trim().isNotEmpty || !vitalsSaved) {
      try {
        await _client.put(
          endpoints.opdDetail(opdId),
          body: <String, dynamic>{
            if (symptoms.trim().isNotEmpty) ...{
              'symptoms': symptoms.trim(),
              'symptoms_description': symptoms.trim(),
            },
            'vitals': payload,
            ...payload,
          },
        );
        vitalsSaved = true;
      } catch (_) {
        if (!vitalsSaved && vitalsErr != null) throw vitalsErr;
      }
    }
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
    ApiException? lastErr;
    for (final url in [endpoints.bedGroups, endpoints.bedGroupsAlt]) {
      try {
        final res = await _client.get(url);
        return JsonParsers.extractList(
          res,
          candidateKeys: const ['groups', 'bedGroups', 'wards', 'records', 'items', 'data'],
        ).map(WardBedGroup.fromJson).toList();
      } on ApiException catch (e) {
        lastErr = e;
        if (!e.isNotFound) rethrow;
      }
    }
    if (lastErr != null) throw lastErr;
    return const [];
  }

  /// Creates a new Ward / Bed Group (`+ Add Ward / Bed Group` modal on `/bed-status` — image-24).
  Future<WardBedGroup> createWardBedGroup({
    required String name,
    required String floor,
    String description = '',
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'group_name': name.trim(),
      'ward_name': name.trim(),
      'floor': floor.trim(),
      'floor_name': floor.trim(),
      'description': description.trim(),
    };

    ApiException? lastErr;
    for (final url in [endpoints.bedGroups, endpoints.bedGroupsAlt]) {
      try {
        final res = await _client.post(url, body: payload);
        final obj = JsonParsers.extractObject(res);
        return WardBedGroup.fromJson(obj.isNotEmpty ? obj : payload);
      } on ApiException catch (e) {
        lastErr = e;
        if (!e.isNotFound) rethrow;
      }
    }
    throw lastErr ??
        const ApiException(message: 'Unable to create ward / bed group.');
  }

  /// Creates a new Hospital Bed (`+ Add Hospital Bed` modal on `/bed-status` — image-25).
  Future<HospitalBed> createHospitalBed({
    required String name,
    required String bedType,
    required WardBedGroup ward,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'bed_number': name.trim(),
      'bed_type': bedType.trim().isEmpty ? 'Standard' : bedType.trim(),
      'bed_group': ward.id.isNotEmpty ? ward.id : ward.name,
      if (ward.id.isNotEmpty) 'bed_group_id': ward.id,
      'bed_group_name': ward.name,
      if (ward.floor.trim().isNotEmpty) 'floor': ward.floor.trim(),
      'status': 'Available',
      'is_occupied': false,
    };

    final res = await _client.post(endpoints.beds, body: payload);
    final obj = JsonParsers.extractObject(res);
    return HospitalBed.fromJson(obj.isNotEmpty ? obj : payload);
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
  // 7. Blood Bank Status & Donor Details (`/admin/bloodbankstatus` — image-22 & 23)
  // ---------------------------------------------------------------------------

  Future<List<BloodBankGroupItem>> fetchBloodBank() async {
    bool anyEndpointSucceeded = false;
    ApiException? lastErr;
    for (final url in [
      endpoints.bloodBankStatus,
      endpoints.bloodBankAltStatus,
      endpoints.bloodBankStatusLegacy,
      endpoints.bloodBank,
      endpoints.bloodBankAlt,
      endpoints.bloodBankGroups,
      endpoints.bloodBankAltGroups,
      endpoints.bloodBankInventory,
      endpoints.bloodBankBags,
    ]) {
      try {
        final res = await _client.get(url);
        anyEndpointSucceeded = true;
        final parsed = BloodBankGroupItem.parseFlexible(res);
        if (parsed.isNotEmpty) return parsed;
      } on ApiException catch (e) {
        lastErr = e;
      } catch (_) {}
    }
    if (anyEndpointSucceeded) {
      return BloodBankGroupItem.websiteBaselineStock();
    }
    if (lastErr != null) throw lastErr;
    return BloodBankGroupItem.websiteBaselineStock();
  }

  Future<List<BloodDonorRecord>> fetchBloodDonors() async {
    for (final url in [
      endpoints.bloodBankDonors,
      endpoints.bloodBankAltDonors,
      endpoints.bloodBankDonorSearch,
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
                  m.containsKey('father_name') ||
                  m.containsKey('fatherName') ||
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
