import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/socket_service.dart';
import '../models/bed_models.dart';
import '../models/clinical_report_model.dart';
import '../models/dashboard_data.dart';
import '../models/duty_roster_model.dart';
import '../models/hospital_modules_models.dart';
import '../models/ipd_models.dart';
import '../models/nurse_user.dart';
import '../models/nursing_task_model.dart';
import '../models/opd_models.dart';
import '../models/patient_directory_model.dart';
import '../services/nurse_api_service.dart';

enum AuthStage { initializing, unauthenticated, authenticated }

class NursePortalController extends ChangeNotifier {
  late final ApiClient _apiClient;
  late final NurseApiService api;
  final SocketService _socketService = SocketService();

  SharedPreferences? _prefs;

  AuthStage _authStage = AuthStage.initializing;
  String _baseUrl = AppConfig.defaultBaseUrl;
  bool _serverReachable = true;

  NurseUser? _currentUser;
  HospitalInfo _hospitalInfo = const HospitalInfo(
    id: '',
    name: 'Smart Super Speciality Hospital',
  );

  // Live clinical state (100% populated from backend APIs — zero dummy data)
  NurseDashboardData? _dashboard;
  List<IpdAdmission> _admittedPatients = const [];
  List<IpdAdmission> _dischargedPatients = const [];
  List<PatientDirectoryRecord> _patientDirectory = const [];
  List<OpdVisitRecord> _opdQueue = const [];
  List<HospitalBed> _beds = const [];
  List<WardBedGroup> _bedGroups = const [];
  List<DutyShiftAssignment> _myShifts = const [];
  List<DutyShiftAssignment> _allRosterShifts = const [];
  List<MedicationPrescription> _wardPrescriptions = const [];
  List<ClinicalReportRecord> _labReports = const [];
  List<ClinicalReportRecord> _radiologyReports = const [];
  List<HospitalAppointmentItem> _appointments = const [];
  List<ServerNotificationItem> _serverNotifications = const [];
  List<AbhaScanCheckinItem> _abhaQueue = const [];

  bool _hasLoadedIpd = false;
  bool _hasLoadedPatients = false;
  bool _hasLoadedOpd = false;

  bool _isLoadingWorkspace = false;
  bool _isLoadingReports = false;
  String? _workspaceError;
  String? _reportsError;

  bool _socketConnected = false;
  final List<RealtimeClinicalEvent> _liveAlerts = <RealtimeClinicalEvent>[];
  int _unreadAlertsCount = 0;
  RealtimeClinicalEvent? _latestBannerEvent;

  int _selectedNavIndex = 0;

  NursePortalController() {
    _apiClient = ApiClient(
      baseUrl: _baseUrl,
      onUnauthorized: _handleUnauthorizedSession,
    );
    api = NurseApiService(_apiClient);

    _socketService.onConnectionChanged = (connected) {
      _socketConnected = connected;
      notifyListeners();
    };

    _socketService.onClinicalEvent = (event) {
      _liveAlerts.insert(0, event);
      if (_liveAlerts.length > 50) {
        _liveAlerts.removeLast();
      }
      _unreadAlertsCount++;
      _latestBannerEvent = event;
      notifyListeners();
      refreshWorkspace(silent: true);
    };
  }

  // Getters
  AuthStage get authStage => _authStage;
  String get baseUrl => _baseUrl;
  bool get serverReachable => _serverReachable;
  NurseUser? get currentUser => _currentUser;
  HospitalInfo get hospitalInfo =>
      _currentUser?.hospitalInfo ?? _hospitalInfo;

  NurseDashboardData? get dashboard => _dashboard;
  List<IpdAdmission> get admittedPatients => _admittedPatients;
  List<IpdAdmission> get dischargedPatients => _dischargedPatients;
  List<PatientDirectoryRecord> get patientDirectory => _patientDirectory;
  List<OpdVisitRecord> get opdQueue => _opdQueue;
  List<HospitalBed> get beds => _beds;
  List<WardBedGroup> get bedGroups => _bedGroups;
  List<DutyShiftAssignment> get myShifts => _myShifts;
  List<DutyShiftAssignment> get allRosterShifts => _allRosterShifts;
  List<MedicationPrescription> get wardPrescriptions => _wardPrescriptions;
  List<ClinicalReportRecord> get labReports => _labReports;
  List<ClinicalReportRecord> get radiologyReports => _radiologyReports;
  List<HospitalAppointmentItem> get appointments => _appointments;
  List<ServerNotificationItem> get serverNotifications => _serverNotifications;
  List<AbhaScanCheckinItem> get abhaQueue => _abhaQueue;

  int get pendingAbhaCount =>
      _abhaQueue.where((item) => item.isPending).length;

  bool get isLoadingWorkspace => _isLoadingWorkspace;
  bool get isLoadingReports => _isLoadingReports;
  String? get workspaceError => _workspaceError;
  String? get reportsError => _reportsError;

  bool get socketConnected => _socketConnected;
  List<RealtimeClinicalEvent> get liveAlerts => List.unmodifiable(_liveAlerts);
  int get unreadAlertsCount =>
      _unreadAlertsCount +
      _serverNotifications.where((n) => !n.isRead).length;
  RealtimeClinicalEvent? get latestBannerEvent => _latestBannerEvent;

  int get selectedNavIndex => _selectedNavIndex;

  void setSelectedNavIndex(int index) {
    if (_selectedNavIndex != index) {
      _selectedNavIndex = index;
      notifyListeners();
    }
  }

  void dismissLatestBanner() {
    if (_latestBannerEvent != null) {
      _latestBannerEvent = null;
      notifyListeners();
    }
  }

  void markAllAlertsRead() {
    for (final n in _serverNotifications.where((item) => !item.isRead)) {
      if (n.id.isNotEmpty) {
        api.markNotificationRead(n.id);
      }
    }
    _serverNotifications = _serverNotifications
        .map(
          (n) => ServerNotificationItem(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          ),
        )
        .toList();
    _unreadAlertsCount = 0;
    notifyListeners();
  }

  // Exact Website-Matched Metrics (matching Screenshot 720 & live collection lengths)
  int get totalPatientsCount {
    if (_hasLoadedPatients) return _patientDirectory.length;
    return _dashboard?.totalPatients ?? 0;
  }

  int get activePatientsCount {
    if (_hasLoadedIpd) return _admittedPatients.length;
    return _dashboard?.currentlyAdmitted ?? 0;
  }

  int get opdPatientsCount {
    if (_hasLoadedOpd) return _opdQueue.length;
    return _dashboard?.opdPatients ?? 0;
  }

  int get dischargedPatientsCount {
    if (_hasLoadedIpd) return _dischargedPatients.length;
    return _dashboard?.dischargedPatients ?? 0;
  }

  int get pendingVitalsCount {
    if (_hasLoadedIpd) {
      final now = DateTime.now();
      final dueToday = _admittedPatients.where((ipd) {
        final lv = ipd.latestVital;
        if (lv == null || lv.date == null) return true;
        return lv.date!.year != now.year ||
            lv.date!.month != now.month ||
            lv.date!.day != now.day;
      }).length;
      if (_dashboard != null && _dashboard!.pendingVitalsCount > dueToday) {
        return _dashboard!.pendingVitalsCount;
      }
      return dueToday;
    }
    return _dashboard?.pendingVitalsCount ?? 0;
  }

  int get medicationsDueCount {
    final pendingRx = _wardPrescriptions.where((rx) => rx.isPending).length;
    if (pendingRx > 0) return pendingRx;
    return _dashboard?.medicationsDueCount ?? 0;
  }

  int get pendingNursingTasksCount {
    if (_dashboard != null && _dashboard!.pendingNursingTasksCount > 0) {
      return _dashboard!.pendingNursingTasksCount;
    }
    return pendingNursingTasks.length;
  }

  int get totalBedsCount {
    if (_beds.isNotEmpty) return _beds.length;
    return _dashboard?.totalBeds ?? 0;
  }

  int get occupiedBedsCount {
    if (_beds.isNotEmpty) {
      return _beds.where((b) => b.isOccupied).length;
    }
    return _dashboard?.occupiedBeds ?? 0;
  }

  int get availableBedsCount {
    if (_beds.isNotEmpty) {
      return _beds.where((b) => !b.isOccupied).length;
    }
    return _dashboard?.availableBeds ?? 0;
  }

  double get bedOccupancyRatio {
    final total = totalBedsCount;
    if (total <= 0) return 0.0;
    return (occupiedBedsCount / total).clamp(0.0, 1.0);
  }

  int get bedOccupancyPercent => (bedOccupancyRatio * 100).round();

  /// Synthesizes real clinical tasks from live ward & OPD queue state (zero fake tasks).
  List<NursingTaskItem> get pendingNursingTasks {
    final tasks = <NursingTaskItem>[];
    final seenVitalsIpdIds = <String>{};

    // 1. Pending IPD Vitals from `/api/dashboard` pendingVitalsRecords
    if (_dashboard != null) {
      for (final pv in _dashboard!.pendingVitalsRecords) {
        if (pv.ipdId.isNotEmpty) {
          seenVitalsIpdIds.add(pv.ipdId);
        }
        final loc = [
          if (pv.ward.isNotEmpty) pv.ward,
          if (pv.bed.isNotEmpty) pv.bed,
        ].join(' / ');
        tasks.add(
          NursingTaskItem(
            id: 'vital-due-${pv.ipdId.isNotEmpty ? pv.ipdId : pv.patientUniqueId}',
            kind: NursingTaskKind.ipdVitals,
            title: 'Record Bedside Vitals',
            subtitle: 'Hourly / shift vitals pending',
            patientName: pv.patientName,
            patientUniqueId: pv.patientUniqueId,
            locationLabel: loc,
            isUrgent: true,
            isCompleted: false,
            ipdId: pv.ipdId.isNotEmpty ? pv.ipdId : null,
          ),
        );
      }
    }

    // 2. Admitted IPD patients without vitals recorded today + shift care note check
    final now = DateTime.now();
    for (final ipd in _admittedPatients) {
      if (!seenVitalsIpdIds.contains(ipd.id)) {
        final lv = ipd.latestVital;
        final recordedToday = lv?.date != null &&
            lv!.date!.year == now.year &&
            lv.date!.month == now.month &&
            lv.date!.day == now.day;

        if (!recordedToday) {
          tasks.add(
            NursingTaskItem(
              id: 'ipd-vital-${ipd.id}',
              kind: NursingTaskKind.ipdVitals,
              title: 'Monitor BP, SpO2 & Temp',
              subtitle: lv == null
                  ? 'Initial admission vitals required'
                  : 'Due for today\'s shift vitals',
              patientName: ipd.patient.patientName,
              patientUniqueId: ipd.patient.patientUniqueId,
              locationLabel: ipd.wardAndBedLabel,
              isUrgent: ipd.isCasualty || ipd.clinicalStatusLabel == 'Critical',
              isCompleted: false,
              ipdId: ipd.id,
            ),
          );
        }
      }

      // Shift nurse progress note due today (matches website `Care tasks & nurse notes due`)
      final hasNoteToday = ipd.nurseNotes.any(
        (n) =>
            n.date != null &&
            n.date!.year == now.year &&
            n.date!.month == now.month &&
            n.date!.day == now.day,
      );
      if (!hasNoteToday) {
        tasks.add(
          NursingTaskItem(
            id: 'ipd-note-due-${ipd.id}',
            kind: NursingTaskKind.nursingCareNote,
            title: 'Shift Nursing Progress Note',
            subtitle: 'Daily bedside shift observation & handover note due',
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            locationLabel: ipd.wardAndBedLabel,
            isUrgent: false,
            isCompleted: false,
            ipdId: ipd.id,
          ),
        );
      }
    }

    // 3. Pending MAR Medication Doses
    for (final rx in _wardPrescriptions) {
      if (!rx.isPending) continue;
      final doseInfo = [
        if (rx.dose.isNotEmpty) rx.dose,
        if (rx.frequency.isNotEmpty) rx.frequency,
        if (rx.instruction.isNotEmpty) rx.instruction,
      ].join(' • ');
      tasks.add(
        NursingTaskItem(
          id: 'mar-${rx.ipdId}-${rx.id}',
          kind: NursingTaskKind.medicationDose,
          title: 'Administer ${rx.medicineName}',
          subtitle: doseInfo.isNotEmpty ? doseInfo : 'Scheduled MAR medication',
          patientName: rx.patientName,
          patientUniqueId: rx.patientUniqueId,
          locationLabel: rx.bedLabel,
          isUrgent: rx.frequency.toUpperCase().contains('STAT') ||
              rx.instruction.toLowerCase().contains('iv'),
          isCompleted: false,
          timestamp: rx.orderedDate,
          ipdId: rx.ipdId.isNotEmpty ? rx.ipdId : null,
          prescriptionId: rx.id,
        ),
      );
    }

    // 4. OPD Waiting Queue Patients Pending Triage Vitals
    for (final opd in _opdQueue) {
      final st = opd.status.toLowerCase();
      if ((st.contains('wait') || st.contains('sched')) &&
          !opd.hasVitalsRecorded) {
        tasks.add(
          NursingTaskItem(
            id: 'opd-triage-${opd.id}',
            kind: NursingTaskKind.opdTriageVitals,
            title: 'OPD Triage Vitals (${opd.opdNo})',
            subtitle: 'Pre-consultation vitals for ${opd.doctorName}',
            patientName: opd.patient.patientName,
            patientUniqueId: opd.patient.patientUniqueId,
            locationLabel: 'OPD Waiting Queue',
            isUrgent: false,
            isCompleted: false,
            timestamp: opd.appointmentDate,
            opdId: opd.id,
          ),
        );
      }
    }

    // 5. Doctor Round Instructions from admitted patients
    for (final ipd in _admittedPatients) {
      for (final ins in ipd.consultantRegister) {
        if (ins.instruction.isEmpty) continue;
        tasks.add(
          NursingTaskItem(
            id: 'round-${ipd.id}-${ins.id}',
            kind: NursingTaskKind.doctorInstruction,
            title: ins.instruction,
            subtitle: ins.doctorName.isNotEmpty
                ? 'Round order by ${ins.doctorName}'
                : 'Consultant round instruction',
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            locationLabel: ipd.wardAndBedLabel,
            isUrgent: false,
            isCompleted: false,
            timestamp: ins.date,
            ipdId: ipd.id,
          ),
        );
      }
    }

    return tasks;
  }

  /// Completed nursing activities from real recorded vitals, given MAR doses, and shift notes.
  List<NursingTaskItem> get completedNursingTasks {
    final completed = <NursingTaskItem>[];

    for (final rx in _wardPrescriptions) {
      if (!rx.isGiven) continue;
      completed.add(
        NursingTaskItem(
          id: 'done-mar-${rx.ipdId}-${rx.id}',
          kind: NursingTaskKind.medicationDose,
          title: '${rx.medicineName} (${rx.status})',
          subtitle: rx.administeredBy.isNotEmpty
              ? 'Administered by ${rx.administeredBy}'
              : 'Dose logged in MAR',
          patientName: rx.patientName,
          patientUniqueId: rx.patientUniqueId,
          locationLabel: rx.bedLabel,
          isUrgent: false,
          isCompleted: true,
          timestamp: rx.administeredAt,
          ipdId: rx.ipdId.isNotEmpty ? rx.ipdId : null,
          prescriptionId: rx.id,
        ),
      );
    }

    for (final ipd in _admittedPatients) {
      final lv = ipd.latestVital;
      if (lv != null) {
        final metrics = [
          if (lv.bp.isNotEmpty) 'BP ${lv.bp}',
          if (lv.pulse.isNotEmpty) 'HR ${lv.pulse} bpm',
          if (lv.spo2.isNotEmpty) 'SpO2 ${lv.spo2}%',
        ].join(' • ');
        completed.add(
          NursingTaskItem(
            id: 'done-vital-${ipd.id}-${lv.id}',
            kind: NursingTaskKind.ipdVitals,
            title: 'Vitals Recorded',
            subtitle: metrics.isNotEmpty ? metrics : 'Bedside vitals saved',
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            locationLabel: ipd.wardAndBedLabel,
            isUrgent: false,
            isCompleted: true,
            timestamp: lv.date,
            ipdId: ipd.id,
          ),
        );
      }

      for (final note in ipd.nurseNotes) {
        completed.add(
          NursingTaskItem(
            id: 'done-note-${ipd.id}-${note.id}',
            kind: NursingTaskKind.nursingCareNote,
            title: note.note,
            subtitle: 'Care note by ${note.nurseName}',
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            locationLabel: ipd.wardAndBedLabel,
            isUrgent: false,
            isCompleted: true,
            timestamp: note.date,
            ipdId: ipd.id,
          ),
        );
      }
    }

    completed.sort((a, b) {
      final da = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return completed;
  }

  /// Other clinical documents synthesized from live IPD investigations & prescriptions.
  List<ClinicalReportRecord> get otherClinicalDocuments {
    final docs = <ClinicalReportRecord>[];
    for (final ipd in _admittedPatients) {
      for (final inv in ipd.investigations) {
        docs.add(
          ClinicalReportRecord(
            id: inv.id,
            billNo: ipd.ipdNo,
            title: inv.testName,
            category: ClinicalReportCategory.others,
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            doctorName: ipd.doctor.displayName,
            date: inv.orderedAt ?? ipd.admissionDate,
            status: inv.status,
            resultSummary: inv.resultSummary,
            reportPdf: inv.reportPdf,
          ),
        );
      }
      for (final rx in ipd.prescriptions) {
        docs.add(
          ClinicalReportRecord(
            id: rx.id,
            billNo:
                rx.prescriptionNo.isNotEmpty ? rx.prescriptionNo : ipd.ipdNo,
            title: 'Prescription • ${rx.medicineName}',
            category: ClinicalReportCategory.others,
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            doctorName:
                rx.orderedBy.isNotEmpty ? rx.orderedBy : ipd.doctor.displayName,
            date: rx.orderedDate ?? ipd.admissionDate,
            status: rx.status,
            resultSummary: [
              if (rx.dose.isNotEmpty) rx.dose,
              if (rx.frequency.isNotEmpty) rx.frequency,
              if (rx.duration.isNotEmpty) rx.duration,
              if (rx.instruction.isNotEmpty) rx.instruction,
            ].join(' • '),
          ),
        );
      }
    }
    return docs;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle & Session Bootstrap
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    _authStage = AuthStage.initializing;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();
    final savedUrl = _prefs?.getString(AppConfig.storageKeyBaseUrl);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = AppConfig.normalizeBaseUrl(savedUrl);
      _apiClient.updateBaseUrl(_baseUrl);
    }

    final healthFuture = api.checkHealth();
    final publicInfoFuture = api.fetchPublicHospitalInfo();

    final savedToken = _prefs?.getString(AppConfig.storageKeyToken);
    final cachedUserStr = _prefs?.getString(AppConfig.storageKeyCachedUser);
    if (cachedUserStr != null && cachedUserStr.isNotEmpty) {
      try {
        _currentUser = NurseUser.fromJson(
          jsonDecode(cachedUserStr) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    _serverReachable = await healthFuture;
    final publicInfo = await publicInfoFuture;
    if (publicInfo != null) {
      _hospitalInfo = publicInfo;
    }

    if (savedToken != null && savedToken.trim().isNotEmpty) {
      _apiClient.updateToken(savedToken);
      try {
        final freshUser = await api.fetchMe();
        _currentUser = freshUser;
        if (freshUser.hospitalInfo != null) {
          _hospitalInfo = freshUser.hospitalInfo!;
        }
        await _prefs?.setString(
          AppConfig.storageKeyCachedUser,
          jsonEncode(freshUser.toJson()),
        );
        _authStage = AuthStage.authenticated;
        _connectRealtime(savedToken);
        notifyListeners();
        await refreshWorkspace();
        return;
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await _clearAuthStorage();
        } else if (_currentUser != null) {
          _authStage = AuthStage.authenticated;
          _connectRealtime(savedToken);
          notifyListeners();
          await refreshWorkspace();
          return;
        }
      } catch (_) {}
    }

    _authStage = AuthStage.unauthenticated;
    notifyListeners();
  }

  Future<void> updateServerBaseUrl(String newBaseUrl) async {
    final normalized = AppConfig.normalizeBaseUrl(newBaseUrl);
    _baseUrl = normalized;
    _apiClient.updateBaseUrl(normalized);
    await _prefs?.setString(AppConfig.storageKeyBaseUrl, normalized);
    _serverReachable = await api.checkHealth();
    final publicInfo = await api.fetchPublicHospitalInfo();
    if (publicInfo != null) {
      _hospitalInfo = publicInfo;
    }
    if (_authStage == AuthStage.authenticated && _apiClient.hasToken) {
      _connectRealtime(_apiClient.authToken!);
      await refreshWorkspace();
    } else {
      notifyListeners();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final result = await api.login(username: username, password: password);
    _apiClient.updateToken(result.token);
    _currentUser = result.user;

    try {
      final fullProfile = await api.fetchMe();
      _currentUser = fullProfile;
      if (fullProfile.hospitalInfo != null) {
        _hospitalInfo = fullProfile.hospitalInfo!;
      }
    } catch (_) {}

    await _prefs?.setString(AppConfig.storageKeyToken, result.token);
    if (_currentUser != null) {
      await _prefs?.setString(
        AppConfig.storageKeyCachedUser,
        jsonEncode(_currentUser!.toJson()),
      );
    }

    _selectedNavIndex = 0;
    _authStage = AuthStage.authenticated;
    _connectRealtime(result.token);
    notifyListeners();

    await refreshWorkspace();
  }

  Future<void> logout() async {
    _socketService.disconnect();
    await api.logoutServer();
    await _clearAuthStorage();
    _currentUser = null;
    _dashboard = null;
    _admittedPatients = const [];
    _dischargedPatients = const [];
    _patientDirectory = const [];
    _opdQueue = const [];
    _beds = const [];
    _bedGroups = const [];
    _myShifts = const [];
    _allRosterShifts = const [];
    _wardPrescriptions = const [];
    _labReports = const [];
    _radiologyReports = const [];
    _appointments = const [];
    _serverNotifications = const [];
    _abhaQueue = const [];
    _hasLoadedIpd = false;
    _hasLoadedPatients = false;
    _hasLoadedOpd = false;
    _liveAlerts.clear();
    _unreadAlertsCount = 0;
    _latestBannerEvent = null;
    _workspaceError = null;
    _selectedNavIndex = 0;
    _authStage = AuthStage.unauthenticated;
    notifyListeners();
  }

  void _handleUnauthorizedSession() {
    if (_authStage == AuthStage.authenticated) {
      logout();
    }
  }

  Future<void> _clearAuthStorage() async {
    _apiClient.updateToken(null);
    await _prefs?.remove(AppConfig.storageKeyToken);
    await _prefs?.remove(AppConfig.storageKeyCachedUser);
  }

  void _connectRealtime(String token) {
    _socketService.connect(
      baseUrl: _baseUrl,
      token: token,
      hospitalId: _currentUser?.hospitalId,
    );
  }

  // ---------------------------------------------------------------------------
  // Live Workspace Data Synchronization (100% Website Parity)
  // ---------------------------------------------------------------------------

  Future<void> refreshWorkspace({bool silent = false}) async {
    if (_authStage != AuthStage.authenticated) return;
    if (!silent) {
      _isLoadingWorkspace = true;
      _workspaceError = null;
      notifyListeners();
    }

    String? firstFatalError;

    final dashFuture = api.fetchDashboard().then<NurseDashboardData?>(
      (v) => v,
      onError: (Object e) {
        firstFatalError ??= e.toString();
        return _dashboard;
      },
    );

    final allIpdFuture = api.fetchIpdAdmissions(dischargeStatus: 'all').then(
      (v) {
        _hasLoadedIpd = true;
        return v;
      },
      onError: (Object e) {
        firstFatalError ??= e.toString();
        return <IpdAdmission>[..._admittedPatients, ..._dischargedPatients];
      },
    );

    final patientsFuture = api.fetchPatientDirectory().then(
      (v) {
        _hasLoadedPatients = true;
        return v;
      },
      onError: (_) => _patientDirectory,
    );

    final opdFuture = api.fetchOpdQueue().then(
      (v) {
        _hasLoadedOpd = true;
        return v;
      },
      onError: (_) => _opdQueue,
    );

    final bedsFuture = api.fetchBeds().then(
      (v) => v,
      onError: (_) => _beds,
    );

    final groupsFuture = api.fetchBedGroups().then(
      (v) => v,
      onError: (_) => _bedGroups,
    );

    final allRosterFuture = api
        .fetchDutyRoster()
        .then((v) => v, onError: (_) => _allRosterShifts);

    final appointmentsFuture = api
        .fetchAppointments()
        .then((v) => v, onError: (_) => _appointments);

    final notificationsFuture = api
        .fetchNotifications()
        .then((v) => v, onError: (_) => _serverNotifications);

    final abhaFuture = api
        .fetchAbhaQueue()
        .then((v) => v, onError: (_) => _abhaQueue);

    final results = await Future.wait<dynamic>([
      dashFuture,
      allIpdFuture,
      patientsFuture,
      opdFuture,
      bedsFuture,
      groupsFuture,
      allRosterFuture,
      appointmentsFuture,
      notificationsFuture,
      abhaFuture,
    ]);

    _dashboard = results[0] as NurseDashboardData?;
    final allIpdList = results[1] as List<IpdAdmission>;
    _patientDirectory = results[2] as List<PatientDirectoryRecord>;
    _opdQueue = results[3] as List<OpdVisitRecord>;
    final rawBeds = results[4] as List<HospitalBed>;
    _bedGroups = results[5] as List<WardBedGroup>;
    _allRosterShifts = results[6] as List<DutyShiftAssignment>;
    _appointments = results[7] as List<HospitalAppointmentItem>;
    _serverNotifications = results[8] as List<ServerNotificationItem>;
    _abhaQueue = results[9] as List<AbhaScanCheckinItem>;

    // Filter myShifts from allRosterShifts for logged-in nurse
    final uid = _currentUser?.id ?? '';
    final ucode = _currentUser?.staffCode.toLowerCase() ?? '';
    final uname = _currentUser?.fullName.toLowerCase() ?? '';
    _myShifts = _allRosterShifts.where((s) {
      if (uid.isNotEmpty && s.staffId == uid) return true;
      if (ucode.isNotEmpty && s.staffCode.toLowerCase() == ucode) return true;
      if (uname.isNotEmpty && s.staffName.toLowerCase() == uname) return true;
      return false;
    }).toList();

    final basicAdmitted = allIpdList.where((p) => !p.isDischarged).toList();
    _dischargedPatients = allIpdList.where((p) => p.isDischarged).toList();

    // Hydrate full bedside charts (`GET /api/ipd/:id`) for admitted ward patients
    if (basicAdmitted.isNotEmpty) {
      final hydrated = await Future.wait<IpdAdmission>(
        basicAdmitted.take(25).map((item) async {
          if (item.id.isEmpty) return item;
          try {
            return await api.fetchIpdPatientDetail(item.id);
          } catch (_) {
            return item;
          }
        }),
      );
      if (basicAdmitted.length > 25) {
        hydrated.addAll(basicAdmitted.skip(25));
      }
      _admittedPatients = hydrated;
    } else {
      _admittedPatients = const [];
    }

    // Cross-enrich beds with active IPD admissions so occupancy & currentPatientName
    // always match admitted ward patients 100% (just like the live web portal).
    _beds = rawBeds.map((b) {
      final occupant = _admittedPatients.where((ipd) {
        if (b.id.isNotEmpty && ipd.bedId.isNotEmpty && b.id == ipd.bedId) {
          return true;
        }
        return b.name.isNotEmpty &&
            ipd.bed.isNotEmpty &&
            b.name.toLowerCase() == ipd.bed.toLowerCase();
      }).firstOrNull;

      if (occupant == null) return b;
      return HospitalBed(
        id: b.id,
        name: b.name,
        bedGroupId: b.bedGroupId,
        bedGroupName:
            b.bedGroupName.isNotEmpty ? b.bedGroupName : occupant.bedGroup,
        bedType: b.bedType,
        isOccupied: true,
        status: 'Occupied',
        currentPatientName: b.currentPatientName.isNotEmpty
            ? b.currentPatientName
            : occupant.patient.patientName,
        currentPatientUhid: b.currentPatientUhid.isNotEmpty
            ? b.currentPatientUhid
            : occupant.patient.patientUniqueId,
      );
    }).toList();

    // Aggregate all real ward prescriptions across admitted patients
    final allRx = <MedicationPrescription>[];
    for (final ipd in _admittedPatients) {
      for (final rx in ipd.prescriptions) {
        allRx.add(
          rx.ipdId.isNotEmpty
              ? rx
              : rx.withPatientContext(
                  ipdId: ipd.id,
                  patientName: ipd.patient.patientName,
                  patientUniqueId: ipd.patient.patientUniqueId,
                  bedLabel: ipd.wardAndBedLabel,
                ),
        );
      }
    }
    _wardPrescriptions = allRx;

    if (_dashboard == null &&
        _admittedPatients.isEmpty &&
        _patientDirectory.isEmpty &&
        firstFatalError != null) {
      _workspaceError = firstFatalError;
    } else {
      _workspaceError = null;
    }

    _isLoadingWorkspace = false;
    notifyListeners();
  }

  Future<void> refreshClinicalReports() async {
    _isLoadingReports = true;
    _reportsError = null;
    notifyListeners();

    try {
      final results = await Future.wait<List<ClinicalReportRecord>>([
        api.fetchPathologyReports(),
        api.fetchRadiologyReports(),
      ]);
      _labReports = results[0];
      _radiologyReports = results[1];
    } catch (e) {
      _reportsError = e.toString();
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }
}

class NursePortalScope extends InheritedNotifier<NursePortalController> {
  const NursePortalScope({
    super.key,
    required NursePortalController controller,
    required super.child,
  }) : super(notifier: controller);

  static NursePortalController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NursePortalScope>();
    assert(scope != null, 'NursePortalScope not found in widget tree');
    return scope!.notifier!;
  }

  static NursePortalController read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<NursePortalScope>();
    assert(element != null, 'NursePortalScope not found in widget tree');
    return (element!.widget as NursePortalScope).notifier!;
  }
}
