enum NursingTaskKind {
  ipdVitals,
  opdTriageVitals,
  medicationDose,
  doctorInstruction,
  nursingCareNote,
}

/// Real clinical nursing tasks synthesized directly from live IPD/OPD/Dashboard APIs
/// (zero dummy/placeholder tasks).
class NursingTaskItem {
  final String id;
  final NursingTaskKind kind;
  final String title;
  final String subtitle;
  final String patientName;
  final String patientUniqueId;
  final String locationLabel;
  final bool isUrgent;
  final bool isCompleted;
  final DateTime? timestamp;
  final String? ipdId;
  final String? opdId;
  final String? prescriptionId;

  const NursingTaskItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.patientName,
    required this.patientUniqueId,
    required this.locationLabel,
    required this.isUrgent,
    required this.isCompleted,
    this.timestamp,
    this.ipdId,
    this.opdId,
    this.prescriptionId,
  });
}
