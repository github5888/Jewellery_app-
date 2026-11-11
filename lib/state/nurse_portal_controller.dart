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
import '../models/ipd_models.dart';
import '../models/nurse_user.dart';
import '../models/nursing_task_model.dart';
import '../models/opd_models.dart';
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
  List<OpdVisitRecord> _opdQueue = const [];
  List<HospitalBed> _beds = const [];
  List<WardBedGroup> _bedGroups = const [];
  List<DutyShiftAssignment> _myShifts = const [];
  List<DutyShiftAssignment> _allRosterShifts = const [];
  List<MedicationPrescription> _wardPrescriptions = const [];
  List<ClinicalReportRecord> _labReports = const [];
  List<ClinicalReportRecord> _radiologyReports = const [];

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
      // Automatically refresh ward census & bedside records in background
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
  List<OpdVisitRecord> get opdQueue => _opdQueue;
  List<HospitalBed> get beds => _beds;
  List<WardBedGroup> get bedGroups => _bedGroups;
  List<DutyShiftAssignment> get myShifts => _myShifts;
  List<DutyShiftAssignment> get allRosterShifts => _allRosterShifts;
  List<MedicationPrescription> get wardPrescriptions => _wardPrescriptions;
  List<ClinicalReportRecord> get labReports => _labReports;
  List<ClinicalReportRecord> get radiologyReports => _radiologyReports;

  bool get isLoadingWorkspace => _isLoadingWorkspace;
  bool get isLoadingReports => _isLoadingReports;
  String? get workspaceError => _workspaceError;
  String? get reportsError => _reportsError;

  bool get socketConnected => _socketConnected;
  List<RealtimeClinicalEvent> get liveAlerts => List.unmodifiable(_liveAlerts);
  int get unreadAlertsCount => _unreadAlertsCount;
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
    if (_unreadAlertsCount != 0) {
      _unreadAlertsCount = 0;
      notifyListeners();
    }
  }

  // Computed real metrics (fallbacks to live array counts if dashboard endpoint omits any field)
  int get activePatientsCount =>
      _dashboard != null && _dashboard!.currentlyAdmitted > 0
          ? _dashboard!.currentlyAdmitted
          : _admittedPatients.length;

  int get pendingVitalsCount {
    if (_dashboard != null) return _dashboard!.pendingVitalsCount;
    return _admittedPatients.where((p) => p.latestVital == null).length;
  }

  int get medicationsDueCount {
    if (_dashboard != null && _dashboard!.medicationsDueCount > 0) {
      return _dashboard!.medicationsDueCount;
    }
    return _wardPrescriptions.where((rx) => rx.isPending).length;
  }

  int get totalBedsCount {
    if (_dashboard != null && _dashboard!.totalBeds > 0) {
      return _dashboard!.totalBeds;
    }
    return _beds.length;
  }

  int get occupiedBedsCount {
    if (_dashboard != null && _dashboard!.totalBeds > 0) {
      return _dashboard!.occupiedBeds;
    }
    return _beds.where((b) => b.isOccupied).length;
  }

  int get availableBedsCount {
    if (_dashboard != null && _dashboard!.totalBeds > 0) {
      return _dashboard!.availableBeds;
    }
    return _beds.where((b) => !b.isOccupied).length;
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
        tasks.add(
          NursingTaskItem(
            id: 'vital-due-${pv.ipdId.isNotEmpty ? pv.ipdId : pv.patientUniqueId}',
            kind: NursingTaskKind.ipdVitals,
            title: 'Record Bedside Vitals',
            subtitle: 'Hourly / shift vitals pending',
            patientName: pv.patientName,
            patientUniqueId: pv.patientUniqueId,
            locationLabel: '${pv.ward} • ${pv.bed}',
            isUrgent: true,
            isCompleted: false,
            ipdId: pv.ipdId.isNotEmpty ? pv.ipdId : null,
          ),
        );
      }
    }

    // 2. Any admitted IPD patients without vitals recorded today or with critical readings
    final now = DateTime.now();
    for (final ipd in _admittedPatients) {
      if (seenVitalsIpdIds.contains(ipd.id)) continue;
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
      if ((st.contains('wait') || st.contains('sched')) && !opd.hasVitalsRecorded) {
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
            billNo: rx.prescriptionNo.isNotEmpty ? rx.prescriptionNo : ipd.ipdNo,
            title: 'Prescription • ${rx.medicineName}',
            category: ClinicalReportCategory.others,
            patientName: ipd.patient.patientName,
            patientUniqueId: ipd.patient.patientUniqueId,
            doctorName: rx.orderedBy.isNotEmpty ? rx.orderedBy : ipd.doctor.displayName,
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

    // Check server health & load public hospital branding in parallel
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
          // Temporary network hiccup while token is still saved
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

    // Immediately enrich nurse profile via GET /api/auth/me
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
    await _clearAuthStorage();
    _currentUser = null;
    _dashboard = null;
    _admittedPatients = const [];
    _opdQueue = const [];
    _beds = const [];
    _bedGroups = const [];
    _myShifts = const [];
    _allRosterShifts = const [];
    _wardPrescriptions = const [];
    _labReports = const [];
    _radiologyReports = const [];
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
  // Live Workspace Data Synchronization
  // ---------------------------------------------------------------------------

  Future<void> refreshWorkspace({bool silent = false}) async {
    if (_authStage != AuthStage.authenticated) return;
    if (!silent) {
      _isLoadingWorkspace = true;
      _workspaceError = null;
      notifyListeners();
    }

    String? firstFatalError;

    // Fetch core Nurse Portal endpoints concurrently
    final dashFuture = api.fetchDashboard().then<NurseDashboardData?>(
      (v) => v,
      onError: (Object e) {
        firstFatalError ??= e.toString();
        return _dashboard;
      },
    );

    final ipdFuture = api.fetchIpdAdmissions(dischargeStatus: 'admitted').then(
      (v) => v,
      onError: (Object e) {
        firstFatalError ??= e.toString();
        return _admittedPatients;
      },
    );

    final opdFuture = api.fetchOpdQueue().then(
      (v) => v,
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

    final myRosterFuture = api
        .fetchDutyRoster(staffId: _currentUser?.id)
        .then((v) => v, onError: (_) => _myShifts);

    final allRosterFuture = api
        .fetchDutyRoster()
        .then((v) => v, onError: (_) => _allRosterShifts);

    final results = await Future.wait<dynamic>([
      dashFuture,
      ipdFuture,
      opdFuture,
      bedsFuture,
      groupsFuture,
      myRosterFuture,
      allRosterFuture,
    ]);

    _dashboard = results[0] as NurseDashboardData?;
    final basicIpdList = results[1] as List<IpdAdmission>;
    _opdQueue = results[2] as List<OpdVisitRecord>;
    _beds = results[3] as List<HospitalBed>;
    _bedGroups = results[4] as List<WardBedGroup>;
    _myShifts = results[5] as List<DutyShiftAssignment>;
    _allRosterShifts = results[6] as List<DutyShiftAssignment>;

    // Hydrate full bedside charts (`GET /api/ipd/:id`) for admitted ward patients
    // so prescriptions (MAR), nurse_notes, consultant_register, and vitals history
    // are always 100% live & accurate across Medications, Tasks, and Dashboard!
    if (basicIpdList.isNotEmpty) {
      final hydrated = await Future.wait<IpdAdmission>(
        basicIpdList.take(25).map((item) async {
          if (item.id.isEmpty) return item;
          try {
            return await api.fetchIpdPatientDetail(item.id);
          } catch (_) {
            return item;
          }
        }),
      );
      if (basicIpdList.length > 25) {
        hydrated.addAll(basicIpdList.skip(25));
      }
      _admittedPatients = hydrated;
    } else {
      _admittedPatients = const [];
    }

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

    if (_dashboard == null && _admittedPatients.isEmpty && firstFatalError != null) {
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

/// Clean InheritedNotifier scope so every screen reacts live to NursePortalController
/// without any external state-management package conflicts.
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
