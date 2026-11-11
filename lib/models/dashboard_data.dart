import '../core/utils/json_parsers.dart';

class PendingVitalItem {
  final String ipdId;
  final String ipdNo;
  final String patientName;
  final String patientUniqueId;
  final String bed;
  final String ward;
  final String doctorName;

  const PendingVitalItem({
    required this.ipdId,
    required this.ipdNo,
    required this.patientName,
    required this.patientUniqueId,
    required this.bed,
    required this.ward,
    required this.doctorName,
  });

  factory PendingVitalItem.fromJson(Map<String, dynamic> json) {
    final patientMap = json['patient'] is Map
        ? JsonParsers.asMap(json['patient'])
        : <String, dynamic>{};
    final doctorMap = json['doctor'] is Map
        ? JsonParsers.asMap(json['doctor'])
        : <String, dynamic>{};

    return PendingVitalItem(
      ipdId: JsonParsers.asId(json['_id'] ?? json['ipd_id'] ?? json['id']),
      ipdNo: JsonParsers.asString(json['ipd_no']),
      patientName: JsonParsers.asString(
        json['patient_name'] ?? patientMap['patient_name'] ?? patientMap['name'],
      ),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ?? patientMap['patient_unique_id'],
      ),
      bed: JsonParsers.asString(json['bed'] ?? json['bed_name']),
      ward: JsonParsers.asString(json['bed_group'] ?? json['ward']),
      doctorName: JsonParsers.asString(
        json['doctor_name'] ?? doctorMap['name'],
      ),
    );
  }
}

class ClinicalActivityItem {
  final String id;
  final String type;
  final String title;
  final String description;
  final String patientName;
  final String nurseName;
  final DateTime? timestamp;

  const ClinicalActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.patientName,
    required this.nurseName,
    this.timestamp,
  });

  factory ClinicalActivityItem.fromJson(Map<String, dynamic> json) {
    final type = JsonParsers.asString(
      json['type'] ?? json['category'] ?? json['action'],
      fallback: 'clinical',
    );
    final patientName = JsonParsers.asString(
      json['patient_name'] ?? json['patient'],
    );
    final title = JsonParsers.asString(
      json['title'] ?? json['summary'] ?? json['label'],
      fallback: patientName.isNotEmpty ? patientName : 'Clinical Update',
    );
    final desc = JsonParsers.asString(
      json['description'] ??
          json['note'] ??
          json['notes'] ??
          json['message'] ??
          json['details'],
    );
    return ClinicalActivityItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      type: type,
      title: title,
      description: desc,
      patientName: patientName,
      nurseName: JsonParsers.asString(
        json['recorded_by'] ??
            json['nurse_name'] ??
            json['added_by'] ??
            json['staff_name'],
      ),
      timestamp: JsonParsers.asDateTime(
        json['date'] ??
            json['createdAt'] ??
            json['timestamp'] ??
            json['administered_at'],
      ),
    );
  }
}

class NurseDashboardData {
  final int currentlyAdmitted;
  final int totalPatients;
  final int opdPatients;
  final int dischargedPatients;
  final int totalBeds;
  final int occupiedBeds;
  final int availableBeds;
  final int pendingVitalsCount;
  final int medicationsDueCount;
  final int pendingNursingTasksCount;
  final List<PendingVitalItem> pendingVitalsRecords;
  final List<ClinicalActivityItem> recentActivity;

  const NurseDashboardData({
    required this.currentlyAdmitted,
    required this.totalPatients,
    required this.opdPatients,
    required this.dischargedPatients,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.availableBeds,
    required this.pendingVitalsCount,
    required this.medicationsDueCount,
    required this.pendingNursingTasksCount,
    required this.pendingVitalsRecords,
    required this.recentActivity,
  });

  double get bedOccupancyRatio {
    if (totalBeds <= 0) return 0.0;
    return (occupiedBeds / totalBeds).clamp(0.0, 1.0);
  }

  int get bedOccupancyPercent => (bedOccupancyRatio * 100).round();

  factory NurseDashboardData.fromJson(Map<String, dynamic> raw) {
    final json = JsonParsers.extractObject(raw);
    final subMaps = <Map<String, dynamic>>[
      json,
      if (json['stats'] is Map) JsonParsers.asMap(json['stats']),
      if (json['counts'] is Map) JsonParsers.asMap(json['counts']),
      if (json['summary'] is Map) JsonParsers.asMap(json['summary']),
      if (json['kpis'] is Map) JsonParsers.asMap(json['kpis']),
      if (json['nurse'] is Map) JsonParsers.asMap(json['nurse']),
      if (json['ward'] is Map) JsonParsers.asMap(json['ward']),
      raw,
    ];

    final bedSubMap = json['bedStats'] is Map
        ? JsonParsers.asMap(json['bedStats'])
        : (json['beds'] is Map
            ? JsonParsers.asMap(json['beds'])
            : <String, dynamic>{});

    int? pickOptionalInt(List<String> keys) {
      for (final m in subMaps) {
        for (final k in keys) {
          final v = m[k];
          if (v != null && v is! Map && v is! List) {
            return JsonParsers.asInt(v);
          }
        }
      }
      return null;
    }

    int pickInt(List<String> keys) => pickOptionalInt(keys) ?? 0;

    dynamic findRawList(List<String> keys) {
      for (final m in subMaps) {
        for (final k in keys) {
          if (m[k] is List) return m[k];
        }
      }
      return null;
    }

    final pendingRecords = JsonParsers.asMapList(
      findRawList(const ['pendingVitalsRecords', 'pending_vitals_records']),
    ).map(PendingVitalItem.fromJson).toList();

    final activity = JsonParsers.asMapList(
      findRawList(const [
        'recentActivity',
        'recentClinicalActivity',
        'recent_activity',
        'clinicalActivity',
      ]),
    ).map(ClinicalActivityItem.fromJson).toList();

    final totalBeds = pickOptionalInt(const ['totalBeds', 'total_beds']) ??
        JsonParsers.asInt(bedSubMap['total'] ?? bedSubMap['totalBeds']);
    final occupiedBeds =
        pickOptionalInt(const ['occupiedBeds', 'occupied_beds']) ??
            JsonParsers.asInt(bedSubMap['occupied'] ?? bedSubMap['occupiedBeds']);
    final explicitAvail =
        pickOptionalInt(const ['availableBeds', 'available_beds']) ??
            (bedSubMap['available'] != null
                ? JsonParsers.asInt(bedSubMap['available'])
                : null);
    final availableBeds = explicitAvail ??
        (totalBeds >= occupiedBeds ? totalBeds - occupiedBeds : 0);

    final pendingVitalsCount = pickOptionalInt(const [
          'pendingVitalsCount',
          'pendingVitals',
          'pending_vitals',
        ]) ??
        pendingRecords.length;

    final medsDue = pickInt(const [
      'medicationsDueCount',
      'medicationsDue',
      'medications_due',
    ]);

    final pendingTasks = pickOptionalInt(const [
      'pendingNursingTasks',
      'pendingNursingTasksCount',
      'pendingTasksCount',
      'pending_nursing_tasks',
    ]);

    return NurseDashboardData(
      currentlyAdmitted: pickInt(const [
        'currentlyAdmitted',
        'admittedPatients',
        'activeIpd',
        'ipdAdmittedCount',
        'ipdCount',
      ]),
      totalPatients: pickInt(const [
        'totalPatients',
        'patientsCount',
        'patientCount',
        'total_patients',
      ]),
      opdPatients: pickInt(const [
        'opdPatients',
        'opdCount',
        'totalOpd',
        'opd_patients',
      ]),
      dischargedPatients: pickInt(const [
        'dischargedPatients',
        'dischargedCount',
        'dischargedIpd',
        'totalDischarged',
      ]),
      totalBeds: totalBeds,
      occupiedBeds: occupiedBeds,
      availableBeds: availableBeds,
      pendingVitalsCount: pendingVitalsCount,
      medicationsDueCount: medsDue,
      pendingNursingTasksCount: pendingTasks ?? (pendingVitalsCount + medsDue),
      pendingVitalsRecords: pendingRecords,
      recentActivity: activity,
    );
  }
}
