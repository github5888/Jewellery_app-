import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/socket_service.dart';
import '../models/bed_models.dart';
import '../models/dashboard_data.dart';
import '../models/duty_roster_model.dart';
import '../models/hospital_modules_models.dart';
import '../models/ipd_models.dart';
import '../models/nurse_user.dart';
import '../models/opd_models.dart';
import '../models/patient_directory_model.dart';
import '../services/nurse_api_service.dart';

enum AuthStage { initializing, unauthenticated, authenticated }

/// Navigation indices matching the exact 7 Nurse Sidebar items on `https://hospital.hrpocket.in` (image-5):
/// 0: Dashboard
/// 1: Patient (Patient Directory)
/// 2: OPD - Out Patient
/// 3: IPD - In Patient
/// 4: Blood Bank
/// 5: Duty Roster
/// 6: Annual Calendar
class NurseNavIndex {
  static const int dashboard = 0;
  static const int patients = 1;
  static const int opd = 2;
  static const int ipd = 3;
  static const int bloodBank = 4;
  static const int dutyRoster = 5;
  static const int annualCalendar = 6;
}

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

  // Live website-synced state (zero dummy data)
  NurseDashboardData? _dashboard;
  List<IpdAdmission> _admittedPatients = const [];
  List<IpdAdmission> _dischargedPatients = const [];
  List<PatientDirectoryRecord> _patientDirectory = const [];
  List<OpdVisitRecord> _opdQueue = const [];
  List<HospitalBed> _beds = const [];
  List<WardBedGroup> _bedGroups = const [];
  List<DutyShiftAssignment> _allRosterShifts = const [];
  List<MedicationPrescription> _wardPrescriptions = const [];
  List<BloodBankGroupItem> _bloodBankGroups = const [];
  List<HospitalHolidayItem> _holidays = const [];
  List<ServerNotificationItem> _serverNotifications = const [];
  List<AbhaScanCheckinItem> _abhaQueue = const [];

  bool _hasLoadedIpd = false;
  bool _hasLoadedPatients = false;
  bool _hasLoadedOpd = false;

  bool _isLoadingWorkspace = false;
  String? _workspaceError;

  bool _socketConnected = false;
  final List<RealtimeClinicalEvent> _liveAlerts = <RealtimeClinicalEvent>[];
  int _unreadAlertsCount = 0;
  RealtimeClinicalEvent? _latestBannerEvent;

  int _selectedNavIndex = NurseNavIndex.dashboard;
  bool _ipdShowDischarged = false;

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
  List<DutyShiftAssignment> get allRosterShifts => _allRosterShifts;
  List<MedicationPrescription> get wardPrescriptions => _wardPrescriptions;
  List<BloodBankGroupItem> get bloodBankGroups => _bloodBankGroups;
  List<HospitalHolidayItem> get holidays => _holidays;
  List<ServerNotificationItem> get serverNotifications => _serverNotifications;
  List<AbhaScanCheckinItem> get abhaQueue => _abhaQueue;

  int get pendingAbhaCount =>
      _abhaQueue.where((item) => item.isPending).length;

  bool get isLoadingWorkspace => _isLoadingWorkspace;
  String? get workspaceError => _workspaceError;

  bool get socketConnected => _socketConnected;
  List<RealtimeClinicalEvent> get liveAlerts => List.unmodifiable(_liveAlerts);
  int get unreadAlertsCount =>
      _unreadAlertsCount +
      _serverNotifications.where((n) => !n.isRead).length;
  RealtimeClinicalEvent? get latestBannerEvent => _latestBannerEvent;

  int get selectedNavIndex => _selectedNavIndex;
  bool get ipdShowDischarged => _ipdShowDischarged;

  void setSelectedNavIndex(int index) {
    if (index == NurseNavIndex.ipd) {
      _ipdShowDischarged = false;
    }
    if (_selectedNavIndex != index) {
      _selectedNavIndex = index;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void openIpdSection({bool showDischarged = false}) {
    _ipdShowDischarged = showDischarged;
    _selectedNavIndex = NurseNavIndex.ipd;
    notifyListeners();
  }

  void setIpdShowDischarged(bool value) {
    if (_ipdShowDischarged != value) {
      _ipdShowDischarged = value;
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

  // ---------------------------------------------------------------------------
  // Exact Website-Matched Dashboard Metrics (image-4, image-5, image-8)
  // ---------------------------------------------------------------------------

  /// Card 1: Total Patients (`9` — active patients in Patient Directory)
  int get totalPatientsCount {
    if (_hasLoadedPatients) {
      return _patientDirectory.where((p) => !p.isDisabled).length;
    }
    return _dashboard?.totalPatients ?? 0;
  }

  /// Card 2: Currently Admitted (`1` — active admitted in-patients in wards)
  int get activePatientsCount {
    if (_hasLoadedIpd) return _admittedPatients.length;
    return _dashboard?.currentlyAdmitted ?? 0;
  }

  /// Card 3: OPD Patients (`12` — outpatient clinic consultations)
  int get opdPatientsCount {
    if (_hasLoadedOpd) return _opdQueue.length;
    return _dashboard?.opdPatients ?? 0;
  }

  /// Card 4: Discharged Patients (`5` — completed hospital discharges)
  int get dischargedPatientsCount {
    if (_hasLoadedIpd) return _dischargedPatients.length;
    return _dashboard?.dischargedPatients ?? 0;
  }

  /// Card 7: Pending Vitals (`1` — admitted patients due for vitals today)
  int get pendingVitalsCount {
    if (_dashboard != null && _dashboard!.pendingVitalsCount > 0) {
      return _dashboard!.pendingVitalsCount;
    }
    if (_hasLoadedIpd) {
      final now = DateTime.now();
      return _admittedPatients.where((ipd) {
        final lv = ipd.latestVital;
        if (lv == null || lv.date == null) return true;
        return lv.date!.year != now.year ||
            lv.date!.month != now.month ||
            lv.date!.day != now.day;
      }).length;
    }
    return 0;
  }

  /// Card 6: Medications Due (`0` — prescriptions requiring administration)
  int get medicationsDueCount {
    if (_dashboard != null && _dashboard!.medicationsDueCount > 0) {
      return _dashboard!.medicationsDueCount;
    }
    return _wardPrescriptions.where((rx) => rx.isPending).length;
  }

  /// Card 5: Pending Nursing Tasks (`2` — care tasks & nurse notes due)
  int get pendingNursingTasksCount {
    if (_dashboard != null && _dashboard!.pendingNursingTasksCount > 0) {
      return _dashboard!.pendingNursingTasksCount;
    }
    if (_hasLoadedIpd) {
      final now = DateTime.now();
      final missingNotesToday = _admittedPatients.where((ipd) {
        return !ipd.nurseNotes.any(
          (n) =>
              n.date != null &&
              n.date!.year == now.year &&
              n.date!.month == now.month &&
              n.date!.day == now.day,
        );
      }).length;
      return pendingVitalsCount + missingNotesToday + medicationsDueCount;
    }
    return 0;
  }

  /// Card 8: Ward Bed Occupancy (`1 / 2`, `50% Full`, `1 Available Beds`)
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

  double get ipdOutstandingDues {
    double sum = 0;
    for (final ipd in _admittedPatients) {
      sum += ipd.outstandingDue;
    }
    return sum;
  }

  int get ipdAntenatalCount =>
      _admittedPatients.where((p) => p.isAntenatal).length;

  /// Synthesizes today's Recent Patient Clinical Activity if `/api/dashboard` omits `recentActivity`
  /// while vitals or nurse notes were recorded today; otherwise returns empty list (`[]`)
  /// so Dashboard shows exact website text `"No recent vitals or nursing notes recorded today yet."`
  List<ClinicalActivityItem> get todayClinicalActivity {
    if (_dashboard != null && _dashboard!.recentActivity.isNotEmpty) {
      return _dashboard!.recentActivity;
    }
    final now = DateTime.now();
    final todayItems = <ClinicalActivityItem>[];
    for (final ipd in _admittedPatients) {
      for (final v in ipd.vitals) {
        if (v.date != null &&
            v.date!.year == now.year &&
            v.date!.month == now.month &&
            v.date!.day == now.day) {
          todayItems.add(
            ClinicalActivityItem(
              id: v.id,
              type: 'vitals',
              title: 'Vitals Recorded • ${ipd.patient.patientName}',
              description: [
                if (v.bp.isNotEmpty) 'BP ${v.bp}',
                if (v.pulse.isNotEmpty) 'Pulse ${v.pulse}',
                if (v.temperature.isNotEmpty) 'Temp ${v.temperature}°F',
                if (v.spo2.isNotEmpty) 'SpO2 ${v.spo2}%',
              ].join(' • '),
              patientName: ipd.patient.patientName,
              nurseName: v.recordedBy,
              timestamp: v.date,
            ),
          );
        }
      }
      for (final n in ipd.nurseNotes) {
        if (n.date != null &&
            n.date!.year == now.year &&
            n.date!.month == now.month &&
            n.date!.day == now.day) {
          todayItems.add(
            ClinicalActivityItem(
              id: n.id,
              type: 'note',
              title: 'Nursing Note • ${ipd.patient.patientName}',
              description: n.note,
              patientName: ipd.patient.patientName,
              nurseName: n.nurseName,
              timestamp: n.date,
            ),
          );
        }
      }
    }
    todayItems.sort((a, b) {
      final da = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return todayItems;
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

    _selectedNavIndex = NurseNavIndex.dashboard;
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
    _allRosterShifts = const [];
    _wardPrescriptions = const [];
    _bloodBankGroups = const [];
    _holidays = const [];
    _serverNotifications = const [];
    _abhaQueue = const [];
    _hasLoadedIpd = false;
    _hasLoadedPatients = false;
    _hasLoadedOpd = false;
    _liveAlerts.clear();
    _unreadAlertsCount = 0;
    _latestBannerEvent = null;
    _workspaceError = null;
    _selectedNavIndex = NurseNavIndex.dashboard;
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
  // Live Workspace Synchronization (100% Website Parity)
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

    final bloodBankFuture = api
        .fetchBloodBank()
        .then((v) => v, onError: (_) => _bloodBankGroups);

    final holidaysFuture = api
        .fetchHolidays()
        .then((v) => v, onError: (_) => _holidays);

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
      bloodBankFuture,
      holidaysFuture,
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
    _bloodBankGroups = results[7] as List<BloodBankGroupItem>;
    _holidays = results[8] as List<HospitalHolidayItem>;
    _serverNotifications = results[9] as List<ServerNotificationItem>;
    _abhaQueue = results[10] as List<AbhaScanCheckinItem>;

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

    // Cross-enrich beds with active IPD admissions so occupancy & currentPatientName match 100%
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

    // Aggregate real ward prescriptions across admitted patients
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
