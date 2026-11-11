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
        fallback: 'Admitted Patient',
      ),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ?? patientMap['patient_unique_id'],
      ),
      bed: JsonParsers.asString(json['bed'] ?? json['bed_name'], fallback: 'Ward Bed'),
      ward: JsonParsers.asString(json['bed_group'] ?? json['ward'], fallback: 'IPD Ward'),
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
      fallback: patientName.isNotEmpty ? 'Care Update • $patientName' : 'Clinical Update',
    );
    final desc = JsonParsers.asString(
      json['description'] ?? json['note'] ?? json['notes'] ?? json['message'] ?? json['details'],
    );
    return ClinicalActivityItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      type: type,
      title: title,
      description: desc,
      patientName: patientName,
      nurseName: JsonParsers.asString(
        json['recorded_by'] ?? json['nurse_name'] ?? json['added_by'] ?? json['staff_name'],
      ),
      timestamp: JsonParsers.asDateTime(
        json['date'] ?? json['createdAt'] ?? json['timestamp'] ?? json['administered_at'],
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
    final ratio = occupiedBeds / totalBeds;
    if (ratio < 0) return 0.0;
    if (ratio > 1) return 1.0;
    return ratio;
  }

  int get bedOccupancyPercent => (bedOccupancyRatio * 100).round();

  factory NurseDashboardData.fromJson(Map<String, dynamic> raw) {
    final json = JsonParsers.extractObject(raw);
    final stats = json['stats'] is Map ? JsonParsers.asMap(json['stats']) : <String, dynamic>{};
    final counts = json['counts'] is Map ? JsonParsers.asMap(json['counts']) : <String, dynamic>{};

    int pickInt(List<String> keys) {
      for (final k in keys) {
        final v = json[k] ?? stats[k] ?? counts[k] ?? raw[k];
        if (v != null) return JsonParsers.asInt(v);
      }
      return 0;
    }

    final pendingListRaw = json['pendingVitalsRecords'] ??
        stats['pendingVitalsRecords'] ??
        raw['pendingVitalsRecords'];
    final pendingRecords = JsonParsers.asMapList(pendingListRaw)
        .map(PendingVitalItem.fromJson)
        .toList();

    final activityListRaw = json['recentActivity'] ??
        json['recentClinicalActivity'] ??
        stats['recentActivity'] ??
        raw['recentActivity'];
    final activity = JsonParsers.asMapList(activityListRaw)
        .map(ClinicalActivityItem.fromJson)
        .toList();

    final totalBeds = pickInt(const ['totalBeds', 'total_beds']);
    final occupiedBeds = pickInt(const ['occupiedBeds', 'occupied_beds']);
    final availableBeds = (json['availableBeds'] != null || stats['availableBeds'] != null)
        ? pickInt(const ['availableBeds', 'available_beds'])
        : (totalBeds >= occupiedBeds ? totalBeds - occupiedBeds : 0);

    final pendingVitalsCount = (json['pendingVitalsCount'] != null ||
            stats['pendingVitalsCount'] != null)
        ? pickInt(const ['pendingVitalsCount', 'pending_vitals'])
        : pendingRecords.length;

    final medsDue = pickInt(const [
      'medicationsDueCount',
      'medications_due',
      'medicationsDue',
    ]);

    final pendingTasks = pickInt(const [
      'pendingNursingTasks',
      'pendingTasksCount',
      'pending_nursing_tasks',
    ]);

    return NurseDashboardData(
      currentlyAdmitted: pickInt(const [
        'currentlyAdmitted',
        'admittedPatients',
        'ipdAdmittedCount',
        'ipdCount',
      ]),
      totalPatients: pickInt(const ['totalPatients', 'patientsCount', 'total_patients']),
      opdPatients: pickInt(const ['opdPatients', 'opdCount', 'totalOpd']),
      dischargedPatients: pickInt(const [
        'dischargedPatients',
        'dischargedCount',
        'totalDischarged',
      ]),
      totalBeds: totalBeds,
      occupiedBeds: occupiedBeds,
      availableBeds: availableBeds,
      pendingVitalsCount: pendingVitalsCount,
      medicationsDueCount: medsDue,
      pendingNursingTasksCount:
          pendingTasks > 0 ? pendingTasks : (pendingVitalsCount + medsDue),
      pendingVitalsRecords: pendingRecords,
      recentActivity: activity,
    );
  }
}
