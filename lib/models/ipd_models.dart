import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';

/// Section 6: Patient Personal Details Variables (`patient` object)
class PatientProfile {
  final String id;
  final String patientUniqueId;
  final String patientName;
  final String gender;
  final int age;
  final DateTime? dob;
  final String bloodGroup;
  final String knownAllergies;
  final String mobileNo;
  final String? image;
  final String guardianName;
  final String address;
  final String abhaNumber;
  final String abhaAddress;

  const PatientProfile({
    required this.id,
    required this.patientUniqueId,
    required this.patientName,
    required this.gender,
    required this.age,
    this.dob,
    required this.bloodGroup,
    required this.knownAllergies,
    required this.mobileNo,
    this.image,
    required this.guardianName,
    required this.address,
    required this.abhaNumber,
    required this.abhaAddress,
  });

  String? get photo => image;
  String get phone => mobileNo;
  String get ageLabel => age > 0 ? '$age Yrs' : '—';

  bool get hasAllergyAlert {
    final cleaned = knownAllergies.trim().toLowerCase();
    return cleaned.isNotEmpty &&
        cleaned != 'none' &&
        cleaned != 'nil' &&
        cleaned != 'no' &&
        cleaned != 'n/a' &&
        cleaned != 'na';
  }

  factory PatientProfile.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> fallbackParent = const {},
  }) {
    final rawImg = JsonParsers.asString(
      json['image'] ?? json['photo'] ?? fallbackParent['patient_image'],
    );
    final dob = JsonParsers.asDateTime(json['dob'] ?? fallbackParent['dob']);
    int age = JsonParsers.asInt(json['age'] ?? fallbackParent['age']);
    if (age <= 0 && dob != null) {
      age = ((DateTime.now().difference(dob).inDays) / 365.25).floor();
    }

    return PatientProfile(
      id: JsonParsers.asId(json['_id'] ?? json['id'] ?? fallbackParent['patient_id']),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ??
            json['uhid'] ??
            fallbackParent['patient_unique_id'] ??
            fallbackParent['uhid'],
      ),
      patientName: JsonParsers.asString(
        json['patient_name'] ??
            json['name'] ??
            fallbackParent['patient_name'] ??
            fallbackParent['name'],
        fallback: 'Unnamed Patient',
      ),
      gender: JsonParsers.asString(
        json['gender'] ?? fallbackParent['gender'],
        fallback: '—',
      ),
      age: age,
      dob: dob,
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? fallbackParent['blood_group'],
      ),
      knownAllergies: JsonParsers.asString(
        json['known_allergies'] ??
            json['allergies'] ??
            fallbackParent['known_allergies'],
      ),
      mobileNo: JsonParsers.asString(
        json['mobileno'] ??
            json['phone'] ??
            json['mobile'] ??
            fallbackParent['mobileno'] ??
            fallbackParent['phone'],
      ),
      image: rawImg.isEmpty ? null : rawImg,
      guardianName: JsonParsers.asString(
        json['guardian_name'] ?? fallbackParent['guardian_name'],
      ),
      address: JsonParsers.asString(
        json['address'] ?? fallbackParent['address'],
      ),
      abhaNumber: JsonParsers.asString(
        json['abha_number'] ??
            json['abhaNumber'] ??
            json['abha_id'] ??
            json['abhaId'] ??
            fallbackParent['abha_number'] ??
            fallbackParent['abhaNumber'] ??
            fallbackParent['abha_id'],
      ),
      abhaAddress: JsonParsers.asString(
        json['abha_address'] ??
            json['abhaAddress'] ??
            json['health_id'] ??
            fallbackParent['abha_address'] ??
            fallbackParent['abhaAddress'],
      ),
    );
  }
}

/// Section 7: Attending Doctor Variables (`doctor` object)
class AttendingDoctor {
  final String id;
  final String name;
  final String surname;
  final String department;
  final String specialist;
  final String contactNo;

  const AttendingDoctor({
    required this.id,
    required this.name,
    required this.surname,
    required this.department,
    required this.specialist,
    required this.contactNo,
  });

  String get displayName => AppFormatters.formatDoctorName(name, surname);

  factory AttendingDoctor.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> fallbackParent = const {},
  }) {
    final name = JsonParsers.asString(
      json['name'] ??
          fallbackParent['doctor_name'] ??
          fallbackParent['consultant_doctor'],
    );
    final surname = JsonParsers.asString(json['surname']);
    return AttendingDoctor(
      id: JsonParsers.asId(json['_id'] ?? json['id'] ?? fallbackParent['doctor_id']),
      name: name,
      surname: surname,
      department: JsonParsers.asString(
        json['department'] ?? fallbackParent['department'],
      ),
      specialist: JsonParsers.asString(
        json['specialist'] ?? json['specialization'],
      ),
      contactNo: JsonParsers.asString(
        json['contact_no'] ?? json['phone'] ?? json['mobileno'],
      ),
    );
  }
}

/// Section 1: Vitals Recording Screen Variables
class VitalSignRecord {
  final String id;
  final DateTime? date;
  final String bp;
  final String pulse;
  final String temperature;
  final String spo2;
  final String respiratoryRate;
  final String weight;
  final String height;
  final String recordedBy;
  final String recordedById;
  final String notes;

  const VitalSignRecord({
    required this.id,
    this.date,
    required this.bp,
    required this.pulse,
    required this.temperature,
    required this.spo2,
    required this.respiratoryRate,
    required this.weight,
    required this.height,
    required this.recordedBy,
    required this.recordedById,
    required this.notes,
  });

  double? get pulseNumeric => double.tryParse(pulse.replaceAll(RegExp(r'[^0-9.]'), ''));
  double? get tempNumeric =>
      double.tryParse(temperature.replaceAll(RegExp(r'[^0-9.]'), ''));
  double? get spo2Numeric => double.tryParse(spo2.replaceAll(RegExp(r'[^0-9.]'), ''));
  double? get systolicNumeric {
    if (!bp.contains('/')) return null;
    return double.tryParse(bp.split('/').first.trim());
  }

  double? get diastolicNumeric {
    if (!bp.contains('/')) return null;
    final parts = bp.split('/');
    if (parts.length < 2) return null;
    return double.tryParse(parts[1].trim());
  }

  /// Flags abnormal clinical thresholds so ward nurses spot critical vitals immediately.
  bool get hasCriticalReading {
    final s = spo2Numeric;
    if (s != null && s > 0 && s < 93) return true;
    final p = pulseNumeric;
    if (p != null && p > 0 && (p < 48 || p > 125)) return true;
    final t = tempNumeric;
    if (t != null && t > 0 && t >= 101.5) return true;
    final sys = systolicNumeric;
    if (sys != null && sys > 0 && (sys < 88 || sys >= 165)) return true;
    return false;
  }

  factory VitalSignRecord.fromJson(Map<String, dynamic> json) {
    return VitalSignRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      date: JsonParsers.asDateTime(json['date'] ?? json['recorded_at'] ?? json['createdAt']),
      bp: JsonParsers.asString(json['bp'] ?? json['blood_pressure']),
      pulse: JsonParsers.asString(json['pulse'] ?? json['heart_rate']),
      temperature: JsonParsers.asString(json['temperature'] ?? json['temp']),
      spo2: JsonParsers.asString(json['spo2'] ?? json['oxygen_saturation']),
      respiratoryRate: JsonParsers.asString(
        json['respiratory_rate'] ?? json['rr'],
      ),
      weight: JsonParsers.asString(json['weight']),
      height: JsonParsers.asString(json['height']),
      recordedBy: JsonParsers.asString(
        json['recorded_by'] ?? json['nurse_name'] ?? json['added_by'],
      ),
      recordedById: JsonParsers.asId(json['recorded_by_id']),
      notes: JsonParsers.asString(json['notes'] ?? json['remark'] ?? json['comment']),
    );
  }
}

/// Section 2: Nurse Progress Notes Screen Variables
class NurseProgressNote {
  final String id;
  final DateTime? date;
  final String nurseName;
  final String note;
  final String comment;
  final String? attachment;

  const NurseProgressNote({
    required this.id,
    this.date,
    required this.nurseName,
    required this.note,
    required this.comment,
    this.attachment,
  });

  factory NurseProgressNote.fromJson(Map<String, dynamic> json) {
    final att = JsonParsers.asString(json['attachment'] ?? json['file']);
    return NurseProgressNote(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      date: JsonParsers.asDateTime(json['date'] ?? json['createdAt']),
      nurseName: JsonParsers.asString(
        json['nurse_name'] ?? json['recorded_by'] ?? json['staff_name'],
        fallback: 'Duty Nurse',
      ),
      note: JsonParsers.asString(json['note'] ?? json['description']),
      comment: JsonParsers.asString(json['comment'] ?? json['remarks']),
      attachment: att.isEmpty ? null : att,
    );
  }
}

/// Section 3: Medication Administration Record (MAR) & Prescription Variables
class MedicationPrescription {
  final String id;
  final String prescriptionNo;
  final String medicineName;
  final String dose;
  final String frequency;
  final String duration;
  final String instruction;
  final String orderedBy;
  final String status; // Pending | Active | Given | Missed | Refused | Held
  final DateTime? administeredAt;
  final String administeredBy;
  final String remarks;
  final DateTime? orderedDate;

  // Contextual IPD linkage when aggregated across all ward patients
  final String ipdId;
  final String patientName;
  final String patientUniqueId;
  final String bedLabel;

  const MedicationPrescription({
    required this.id,
    required this.prescriptionNo,
    required this.medicineName,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.instruction,
    required this.orderedBy,
    required this.status,
    this.administeredAt,
    required this.administeredBy,
    required this.remarks,
    this.orderedDate,
    this.ipdId = '',
    this.patientName = '',
    this.patientUniqueId = '',
    this.bedLabel = '',
  });

  bool get isGiven => status.toLowerCase() == 'given' || status.toLowerCase() == 'administered';
  bool get isAdministered => isGiven;
  bool get isPending => !isGiven &&
      status.toLowerCase() != 'missed' &&
      status.toLowerCase() != 'refused' &&
      status.toLowerCase() != 'held';

  MedicationPrescription withPatientContext({
    required String ipdId,
    required String patientName,
    required String patientUniqueId,
    required String bedLabel,
  }) {
    return MedicationPrescription(
      id: id,
      prescriptionNo: prescriptionNo,
      medicineName: medicineName,
      dose: dose,
      frequency: frequency,
      duration: duration,
      instruction: instruction,
      orderedBy: orderedBy,
      status: status,
      administeredAt: administeredAt,
      administeredBy: administeredBy,
      remarks: remarks,
      orderedDate: orderedDate,
      ipdId: ipdId,
      patientName: patientName,
      patientUniqueId: patientUniqueId,
      bedLabel: bedLabel,
    );
  }

  /// Parses both flat prescription items AND prescription headers containing a nested `medicines` array.
  static List<MedicationPrescription> parseListFromJson(
    dynamic rawPrescriptions, {
    String ipdId = '',
    String patientName = '',
    String patientUniqueId = '',
    String bedLabel = '',
  }) {
    final items = JsonParsers.asMapList(rawPrescriptions);
    final result = <MedicationPrescription>[];

    for (final raw in items) {
      final headerId = JsonParsers.asId(raw['_id'] ?? raw['id']);
      final headerRxNo = JsonParsers.asString(
        raw['prescription_no'] ?? raw['rx_no'],
      );
      final headerDoctor = JsonParsers.asString(
        raw['ordered_by'] ?? raw['doctor_name'] ?? raw['prescribed_by'],
      );
      final headerDate = JsonParsers.asDateTime(raw['date'] ?? raw['createdAt']);

      // Check if nested `medicines` array exists
      final nestedMeds = raw['medicines'] ?? raw['items'] ?? raw['drugs'];
      if (nestedMeds is List && nestedMeds.isNotEmpty) {
        final medMaps = JsonParsers.asMapList(nestedMeds);
        for (final med in medMaps) {
          final medId = JsonParsers.asId(med['_id'] ?? med['id']);
          result.add(
            _fromSingleMap(
              med,
              fallbackId: medId.isNotEmpty ? medId : headerId,
              fallbackRxNo: headerRxNo,
              fallbackDoctor: headerDoctor,
              fallbackDate: headerDate,
              parentAdminLogs: raw['administration_logs'] ?? raw['administrations'],
              ipdId: ipdId,
              patientName: patientName,
              patientUniqueId: patientUniqueId,
              bedLabel: bedLabel,
            ),
          );
        }
      } else {
        result.add(
          _fromSingleMap(
            raw,
            fallbackId: headerId,
            fallbackRxNo: headerRxNo,
            fallbackDoctor: headerDoctor,
            fallbackDate: headerDate,
            parentAdminLogs: raw['administration_logs'] ?? raw['administrations'],
            ipdId: ipdId,
            patientName: patientName,
            patientUniqueId: patientUniqueId,
            bedLabel: bedLabel,
          ),
        );
      }
    }
    return result;
  }

  static MedicationPrescription _fromSingleMap(
    Map<String, dynamic> json, {
    required String fallbackId,
    required String fallbackRxNo,
    required String fallbackDoctor,
    required DateTime? fallbackDate,
    dynamic parentAdminLogs,
    required String ipdId,
    required String patientName,
    required String patientUniqueId,
    required String bedLabel,
  }) {
    // Extract latest administration record if stored in an array
    Map<String, dynamic> latestAdmin = <String, dynamic>{};
    final logsRaw = json['administrations'] ??
        json['administration_logs'] ??
        json['mar_logs'] ??
        parentAdminLogs;
    if (logsRaw is List && logsRaw.isNotEmpty) {
      final list = JsonParsers.asMapList(logsRaw);
      if (list.isNotEmpty) {
        latestAdmin = list.last;
      }
    }

    final adminAt = JsonParsers.asDateTime(
      json['administered_at'] ?? latestAdmin['administered_at'] ?? latestAdmin['date'],
    );
    final rawStatus = JsonParsers.asString(
      json['mar_status'] ??
          json['administration_status'] ??
          latestAdmin['status'] ??
          json['status'],
      fallback: adminAt != null ? 'Given' : 'Pending',
    );

    return MedicationPrescription(
      id: JsonParsers.asId(json['_id'] ?? json['id']).isNotEmpty
          ? JsonParsers.asId(json['_id'] ?? json['id'])
          : fallbackId,
      prescriptionNo: JsonParsers.asString(
        json['prescription_no'],
        fallback: fallbackRxNo,
      ),
      medicineName: JsonParsers.asString(
        json['medicine_name'] ?? json['medicine'] ?? json['drug_name'] ?? json['name'],
        fallback: 'Prescribed Medication',
      ),
      dose: JsonParsers.asString(json['dose'] ?? json['dosage']),
      frequency: JsonParsers.asString(json['frequency'] ?? json['interval']),
      duration: JsonParsers.asString(json['duration']),
      instruction: JsonParsers.asString(
        json['instruction'] ?? json['instructions'] ?? json['note'],
      ),
      orderedBy: JsonParsers.asString(
        json['ordered_by'] ?? json['doctor_name'],
        fallback: fallbackDoctor,
      ),
      status: rawStatus,
      administeredAt: adminAt,
      administeredBy: JsonParsers.asString(
        json['administered_by'] ?? latestAdmin['administered_by'],
      ),
      remarks: JsonParsers.asString(
        json['remarks'] ?? latestAdmin['remarks'],
      ),
      orderedDate: JsonParsers.asDateTime(json['date'] ?? json['createdAt']) ??
          fallbackDate,
      ipdId: ipdId,
      patientName: patientName,
      patientUniqueId: patientUniqueId,
      bedLabel: bedLabel,
    );
  }
}

/// Section 8: Doctor Rounds & Instructions Variables (`consultant_register`)
class DoctorRoundInstruction {
  final String id;
  final DateTime? date;
  final String instruction;
  final String doctorName;
  final String notes;

  const DoctorRoundInstruction({
    required this.id,
    this.date,
    required this.instruction,
    required this.doctorName,
    required this.notes,
  });

  factory DoctorRoundInstruction.fromJson(Map<String, dynamic> json) {
    String docName = '';
    if (json['doctor'] is Map) {
      final dm = JsonParsers.asMap(json['doctor']);
      docName = AppFormatters.formatDoctorName(
        JsonParsers.asString(dm['name']),
        JsonParsers.asString(dm['surname']),
      );
    } else {
      final raw = JsonParsers.asString(json['doctor_name'] ?? json['consultant']);
      if (raw.isNotEmpty) {
        docName = AppFormatters.formatDoctorName(raw);
      }
    }
    return DoctorRoundInstruction(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      date: JsonParsers.asDateTime(json['date'] ?? json['ins_date'] ?? json['createdAt']),
      instruction: JsonParsers.asString(
        json['instruction'] ?? json['instructions'] ?? json['note'],
      ),
      doctorName: docName,
      notes: JsonParsers.asString(json['comment'] ?? json['remarks']),
    );
  }
}

/// Bedside Ordered Lab/Radiology Investigations (`investigations` array in IPD)
class InvestigationOrder {
  final String id;
  final String testName;
  final String category; // Pathology | Radiology | Lab
  final String status;
  final DateTime? orderedAt;
  final String resultSummary;
  final String? reportPdf;

  const InvestigationOrder({
    required this.id,
    required this.testName,
    required this.category,
    required this.status,
    this.orderedAt,
    required this.resultSummary,
    this.reportPdf,
  });

  factory InvestigationOrder.fromJson(
    Map<String, dynamic> json, {
    String fallbackCategory = 'Lab',
  }) {
    final pdf = JsonParsers.asString(
      json['report_pdf'] ?? json['attachment'] ?? json['file'],
    );
    return InvestigationOrder(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      testName: JsonParsers.asString(
        json['test_name'] ??
            json['name'] ??
            json['investigation_name'] ??
            json['title'] ??
            json['bill_no'],
        fallback: 'Diagnostic Test',
      ),
      category: JsonParsers.asString(
        json['category'] ?? json['type'] ?? json['department'],
        fallback: fallbackCategory,
      ),
      status: JsonParsers.asString(
        json['status'],
        fallback: pdf.isNotEmpty ? 'Ready' : 'Ordered',
      ),
      orderedAt: JsonParsers.asDateTime(
        json['date'] ?? json['report_date'] ?? json['createdAt'],
      ),
      resultSummary: JsonParsers.asString(
        json['result'] ?? json['finding'] ?? json['remarks'] ?? json['notes'],
      ),
      reportPdf: pdf.isEmpty ? null : pdf,
    );
  }

  /// Extracts investigations from embedded arrays or pathology/radiology bill objects
  /// (including nested `tests` arrays used by Smart Hospital MERN).
  static List<InvestigationOrder> parseBillOrOrderList(
    dynamic rawList, {
    String fallbackCategory = 'Lab',
  }) {
    final out = <InvestigationOrder>[];
    for (final item in JsonParsers.asMapList(rawList)) {
      final parentDate = JsonParsers.asDateTime(
        item['date'] ?? item['report_date'] ?? item['createdAt'],
      );
      final parentPdf = JsonParsers.asString(
        item['report_pdf'] ?? item['attachment'],
      );
      final parentStatus = JsonParsers.asString(item['status']);
      if (item['tests'] is List) {
        final nestedTests = JsonParsers.asMapList(item['tests']);
        if (nestedTests.isNotEmpty) {
          for (final t in nestedTests) {
            final tPdf = JsonParsers.asString(
              t['report_pdf'],
              fallback: parentPdf,
            );
            out.add(
              InvestigationOrder(
                id: JsonParsers.asId(t['_id'] ?? item['_id'] ?? item['id']),
                testName: JsonParsers.asString(
                  t['test_name'] ?? t['name'] ?? item['test_name'],
                  fallback: '$fallbackCategory Test',
                ),
                category: JsonParsers.asString(
                  t['category'] ?? item['category'],
                  fallback: fallbackCategory,
                ),
                status: JsonParsers.asString(
                  t['status'] ?? parentStatus,
                  fallback: tPdf.isNotEmpty ? 'Ready' : 'Ordered',
                ),
                orderedAt: JsonParsers.asDateTime(t['report_date']) ?? parentDate,
                resultSummary: JsonParsers.asString(
                  t['result'] ?? t['finding'] ?? t['remarks'] ?? item['note'],
                ),
                reportPdf: tPdf.isEmpty ? null : tPdf,
              ),
            );
          }
          continue;
        }
      }
      out.add(
        InvestigationOrder.fromJson(item, fallbackCategory: fallbackCategory),
      );
    }
    return out;
  }
}

/// Bed Transfer History Entry (`bed_history` / `bed_transfers` on IPD chart)
class BedTransferHistoryEntry {
  final String id;
  final String fromBed;
  final String toBed;
  final String wardGroup;
  final String reason;
  final String transferredBy;
  final DateTime? date;

  const BedTransferHistoryEntry({
    required this.id,
    required this.fromBed,
    required this.toBed,
    required this.wardGroup,
    required this.reason,
    required this.transferredBy,
    this.date,
  });

  factory BedTransferHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BedTransferHistoryEntry(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      fromBed: JsonParsers.asString(
        json['from_bed'] ?? json['previous_bed'] ?? json['old_bed'],
      ),
      toBed: JsonParsers.asString(
        json['to_bed'] ?? json['bed'] ?? json['new_bed'] ?? json['bed_name'],
      ),
      wardGroup: JsonParsers.asString(
        json['bed_group'] ?? json['ward'] ?? json['ward_group'],
      ),
      reason: JsonParsers.asString(
        json['transfer_reason'] ?? json['reason'] ?? json['note'],
      ),
      transferredBy: JsonParsers.asString(
        json['transferred_by'] ?? json['updated_by'] ?? json['staff_name'],
      ),
      date: JsonParsers.asDateTime(
        json['transfer_date'] ??
            json['from_date'] ??
            json['date'] ??
            json['createdAt'],
      ),
    );
  }
}

/// Section 9: Nursing Procedures / Charges Variables
class NursingProcedureCharge {
  final String id;
  final String chargeName;
  final String chargeType;
  final String chargeCategory;
  final int qty;
  final double appliedCharge;
  final DateTime? date;
  final String note;
  final String addedBy;

  const NursingProcedureCharge({
    required this.id,
    required this.chargeName,
    required this.chargeType,
    required this.chargeCategory,
    required this.qty,
    required this.appliedCharge,
    this.date,
    required this.note,
    required this.addedBy,
  });

  double get totalAmount => appliedCharge * qty;

  factory NursingProcedureCharge.fromJson(Map<String, dynamic> json) {
    return NursingProcedureCharge(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      chargeName: JsonParsers.asString(
        json['charge_name'] ?? json['name'],
        fallback: 'Nursing Procedure',
      ),
      chargeType: JsonParsers.asString(json['charge_type'], fallback: 'IPD'),
      chargeCategory: JsonParsers.asString(
        json['charge_category'] ?? json['category'],
        fallback: 'Nursing Charges',
      ),
      qty: JsonParsers.asInt(json['qty'], fallback: 1),
      appliedCharge: JsonParsers.asDouble(
        json['applied_charge'] ?? json['amount'] ?? json['standard_charge'],
      ),
      date: JsonParsers.asDateTime(json['date'] ?? json['createdAt']),
      note: JsonParsers.asString(json['note'] ?? json['notes']),
      addedBy: JsonParsers.asString(json['added_by']),
    );
  }
}

/// Section 4: Nursing Pre-Discharge Checklist Variables
class DischargeChecklist {
  final bool handoverCompleted;
  final bool ivCannulaRemoved;
  final bool catheterRemoved;
  final bool drainRemoved;
  final bool woundDressingClean;
  final bool medicationsExplained;
  final bool belongingsReturned;
  final bool vitalSignsStable;
  final bool dischargeSlipHandedOver;
  final String checklistNotes;

  const DischargeChecklist({
    this.handoverCompleted = false,
    this.ivCannulaRemoved = false,
    this.catheterRemoved = false,
    this.drainRemoved = false,
    this.woundDressingClean = false,
    this.medicationsExplained = false,
    this.belongingsReturned = false,
    this.vitalSignsStable = false,
    this.dischargeSlipHandedOver = false,
    this.checklistNotes = '',
  });

  int get completedItemsCount {
    final flags = [
      handoverCompleted,
      ivCannulaRemoved,
      catheterRemoved,
      drainRemoved,
      woundDressingClean,
      medicationsExplained,
      belongingsReturned,
      vitalSignsStable,
      dischargeSlipHandedOver,
    ];
    return flags.where((b) => b).length;
  }

  bool get isFullyVerified => completedItemsCount == 9;

  factory DischargeChecklist.fromJson(Map<String, dynamic> json) {
    return DischargeChecklist(
      handoverCompleted: JsonParsers.asBool(json['handover_completed']),
      ivCannulaRemoved: JsonParsers.asBool(
        json['iv_cannula_removed'] ?? json['peripheral_iv_removed'],
      ),
      catheterRemoved: JsonParsers.asBool(json['catheter_removed']),
      drainRemoved: JsonParsers.asBool(
        json['drain_removed'] ?? json['surgical_packing_removed'],
      ),
      woundDressingClean: JsonParsers.asBool(json['wound_dressing_clean']),
      medicationsExplained: JsonParsers.asBool(json['medications_explained']),
      belongingsReturned: JsonParsers.asBool(json['belongings_returned']),
      vitalSignsStable: JsonParsers.asBool(
        json['vital_signs_stable'] ?? json['pre_discharge_vitals_stable'],
      ),
      dischargeSlipHandedOver: JsonParsers.asBool(
        json['discharge_slip_handed_over'] ?? json['discharge_summary_handed'],
      ),
      checklistNotes: JsonParsers.asString(
        json['checklist_notes'] ?? json['notes'],
      ),
    );
  }

  DischargeChecklist copyWith({
    bool? handoverCompleted,
    bool? ivCannulaRemoved,
    bool? catheterRemoved,
    bool? drainRemoved,
    bool? woundDressingClean,
    bool? medicationsExplained,
    bool? belongingsReturned,
    bool? vitalSignsStable,
    bool? dischargeSlipHandedOver,
    String? checklistNotes,
  }) {
    return DischargeChecklist(
      handoverCompleted: handoverCompleted ?? this.handoverCompleted,
      ivCannulaRemoved: ivCannulaRemoved ?? this.ivCannulaRemoved,
      catheterRemoved: catheterRemoved ?? this.catheterRemoved,
      drainRemoved: drainRemoved ?? this.drainRemoved,
      woundDressingClean: woundDressingClean ?? this.woundDressingClean,
      medicationsExplained: medicationsExplained ?? this.medicationsExplained,
      belongingsReturned: belongingsReturned ?? this.belongingsReturned,
      vitalSignsStable: vitalSignsStable ?? this.vitalSignsStable,
      dischargeSlipHandedOver:
          dischargeSlipHandedOver ?? this.dischargeSlipHandedOver,
      checklistNotes: checklistNotes ?? this.checklistNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'handover_completed': handoverCompleted,
        'iv_cannula_removed': ivCannulaRemoved,
        'catheter_removed': catheterRemoved,
        'drain_removed': drainRemoved,
        'surgical_packing_removed': drainRemoved,
        'wound_dressing_clean': woundDressingClean,
        'medications_explained': medicationsExplained,
        'belongings_returned': belongingsReturned,
        'vital_signs_stable': vitalSignsStable,
        'discharge_slip_handed_over': dischargeSlipHandedOver,
        'checklist_notes': checklistNotes,
      };
}

/// Section 5: IPD Patient Admission Master (`IIpdDetail`)
class IpdAdmission {
  final String id;
  final String ipdNo;
  final String caseReferenceId;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String dischargeStatus;
  final bool isDischargedFlag;
  final String bed;
  final String bedId;
  final String bedGroup;
  final String admissionType;
  final String provisionalDiagnosis;
  final String presentingComplaint;
  final String clinicalSummary;
  final String dischargeInstructions;
  final String referringDoctor;
  final String department;
  final String attendantName;
  final String attendantPhone;
  final String attendantRelation;
  final String payerType;
  final String tpaInsurance;
  final double creditLimit;
  final bool isCasualty;
  final bool isAntenatal;
  final double outstandingDue;

  final PatientProfile patient;
  final AttendingDoctor doctor;
  final List<VitalSignRecord> vitals;
  final List<MedicationPrescription> prescriptions;
  final List<NurseProgressNote> nurseNotes;
  final List<DoctorRoundInstruction> consultantRegister;
  final List<InvestigationOrder> investigations;
  final List<NursingProcedureCharge> charges;
  final List<BedTransferHistoryEntry> bedTransferHistory;
  final DischargeChecklist dischargeChecklist;

  const IpdAdmission({
    required this.id,
    required this.ipdNo,
    required this.caseReferenceId,
    this.admissionDate,
    this.dischargeDate,
    required this.dischargeStatus,
    this.isDischargedFlag = false,
    required this.bed,
    required this.bedId,
    required this.bedGroup,
    required this.admissionType,
    required this.provisionalDiagnosis,
    this.presentingComplaint = '',
    this.clinicalSummary = '',
    this.dischargeInstructions = '',
    this.referringDoctor = '',
    required this.department,
    required this.attendantName,
    required this.attendantPhone,
    required this.attendantRelation,
    this.payerType = 'Self-pay',
    this.tpaInsurance = 'None',
    this.creditLimit = 0.0,
    required this.isCasualty,
    required this.isAntenatal,
    this.outstandingDue = 0.0,
    required this.patient,
    required this.doctor,
    required this.vitals,
    required this.prescriptions,
    required this.nurseNotes,
    required this.consultantRegister,
    required this.investigations,
    required this.charges,
    this.bedTransferHistory = const [],
    required this.dischargeChecklist,
  });

  IpdAdmission copyWith({
    List<InvestigationOrder>? investigations,
    DischargeChecklist? dischargeChecklist,
  }) {
    return IpdAdmission(
      id: id,
      ipdNo: ipdNo,
      caseReferenceId: caseReferenceId,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      dischargeStatus: dischargeStatus,
      isDischargedFlag: isDischargedFlag,
      bed: bed,
      bedId: bedId,
      bedGroup: bedGroup,
      admissionType: admissionType,
      provisionalDiagnosis: provisionalDiagnosis,
      presentingComplaint: presentingComplaint,
      clinicalSummary: clinicalSummary,
      dischargeInstructions: dischargeInstructions,
      referringDoctor: referringDoctor,
      department: department,
      attendantName: attendantName,
      attendantPhone: attendantPhone,
      attendantRelation: attendantRelation,
      payerType: payerType,
      tpaInsurance: tpaInsurance,
      creditLimit: creditLimit,
      isCasualty: isCasualty,
      isAntenatal: isAntenatal,
      outstandingDue: outstandingDue,
      patient: patient,
      doctor: doctor,
      vitals: vitals,
      prescriptions: prescriptions,
      nurseNotes: nurseNotes,
      consultantRegister: consultantRegister,
      investigations: investigations ?? this.investigations,
      charges: charges,
      bedTransferHistory: bedTransferHistory,
      dischargeChecklist: dischargeChecklist ?? this.dischargeChecklist,
    );
  }

  /// Accurately detects whether an IPD record is discharged across all backend conventions:
  /// `discharge_status` ('discharged' / 'yes'), `status` ('Discharged'), `is_discharged` (true), or `discharge_date`.
  bool get isDischarged {
    if (isDischargedFlag) return true;
    final ds = dischargeStatus.trim().toLowerCase();
    if (ds == 'discharged' ||
        ds == 'yes' ||
        ds == 'true' ||
        ds == '1' ||
        ds == 'completed') {
      return true;
    }
    if (ds == 'admitted' || ds == 'no' || ds == 'active' || ds == 'false' || ds == '0') {
      return false;
    }
    return dischargeDate != null;
  }

  VitalSignRecord? get latestVital {
    if (vitals.isEmpty) return null;
    final sorted = List<VitalSignRecord>.from(vitals);
    sorted.sort((a, b) {
      final da = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return sorted.first;
  }

  String get wardAndBedLabel {
    if (bedGroup.isNotEmpty && bed.isNotEmpty) {
      return '$bedGroup / $bed';
    }
    if (bed.isNotEmpty) return bed;
    if (bedGroup.isNotEmpty) return bedGroup;
    return 'Unassigned Bed';
  }

  /// Matches `Deluxe-201 (General Ward Male)` format on Discharge Card Preview (image-38).
  String get bedDisplayLabel {
    if (bed.isNotEmpty && bedGroup.isNotEmpty) {
      return '$bed ($bedGroup)';
    }
    return wardAndBedLabel;
  }

  String get doctorName => doctor.displayName;

  /// Computes clinical badge label directly from real patient status, emergency flags, and latest vitals.
  String get clinicalStatusLabel {
    if (isDischarged) return 'Discharged';
    final lv = latestVital;
    if (isCasualty ||
        admissionType.toLowerCase() == 'emergency' ||
        (lv != null && lv.hasCriticalReading)) {
      return 'Critical';
    }
    if (lv != null) return 'Stable';
    return 'In Ward';
  }

  factory IpdAdmission.fromJson(Map<String, dynamic> raw) {
    final extracted = JsonParsers.extractObject(raw);
    final nestedIpd = extracted['ipd'] is Map
        ? JsonParsers.asMap(extracted['ipd'])
        : (extracted['admission'] is Map
            ? JsonParsers.asMap(extracted['admission'])
            : <String, dynamic>{});
    final json = nestedIpd.isNotEmpty
        ? <String, dynamic>{...extracted, ...nestedIpd}
        : extracted;
    final id = JsonParsers.asId(json['_id'] ?? json['id']);

    final dischargeSub = json['discharge'] is Map
        ? JsonParsers.asMap(json['discharge'])
        : (json['discharge_details'] is Map
            ? JsonParsers.asMap(json['discharge_details'])
            : (json['dischargeDetails'] is Map
                ? JsonParsers.asMap(json['dischargeDetails'])
                : <String, dynamic>{}));

    final patientMap = json['patient'] is Map
        ? JsonParsers.asMap(json['patient'])
        : <String, dynamic>{};
    final patient = PatientProfile.fromJson(patientMap, fallbackParent: json);

    final rawDoctor = json['doctor'] ?? json['cons_doctor'] ?? json['consultant_doctor'];
    final doctorMap = rawDoctor is Map ? JsonParsers.asMap(rawDoctor) : <String, dynamic>{};
    final doctor = AttendingDoctor.fromJson(doctorMap, fallbackParent: json);

    // Bed & Ward can be populated objects OR strings
    final rawBed = json['bed'] ?? json['bed_id'] ?? json['bed_details'];
    final bedName = JsonParsers.asString(
      rawBed,
      fallback: JsonParsers.asString(json['bed_name'] ?? json['bed_number']),
    );
    final bedId = rawBed is Map
        ? JsonParsers.asId(rawBed)
        : JsonParsers.asString(json['bed_id']);

    String bedGroupName = JsonParsers.asString(
      json['bed_group'] ?? json['ward'] ?? json['bed_group_name'],
    );
    if (bedGroupName.isEmpty && rawBed is Map && rawBed['bed_group'] != null) {
      bedGroupName = JsonParsers.asString(rawBed['bed_group']);
    }

    // Parse vitals (can be `vitals` array and/or `current_vitals` / `latest_vitals` object)
    final vitalsList = <VitalSignRecord>[];
    if (json['vitals'] is List) {
      vitalsList.addAll(
        JsonParsers.asMapList(json['vitals']).map(VitalSignRecord.fromJson),
      );
    } else if (json['vitals'] is Map) {
      vitalsList.add(VitalSignRecord.fromJson(JsonParsers.asMap(json['vitals'])));
    }
    if (vitalsList.isEmpty && json['current_vitals'] is Map) {
      vitalsList.add(
        VitalSignRecord.fromJson(JsonParsers.asMap(json['current_vitals'])),
      );
    }

    final combinedBedLabel = [
      if (bedGroupName.isNotEmpty) bedGroupName,
      if (bedName.isNotEmpty) bedName,
    ].join(' • ');

    final prescriptions = MedicationPrescription.parseListFromJson(
      json['prescriptions'],
      ipdId: id,
      patientName: patient.patientName,
      patientUniqueId: patient.patientUniqueId,
      bedLabel: combinedBedLabel,
    );

    final nurseNotes = JsonParsers.asMapList(json['nurse_notes'])
        .map(NurseProgressNote.fromJson)
        .toList();

    final consultantRegister = JsonParsers.asMapList(json['consultant_register'])
        .map(DoctorRoundInstruction.fromJson)
        .toList();

    final investigations = <InvestigationOrder>[
      ...InvestigationOrder.parseBillOrOrderList(
        json['investigations'] ?? json['lab_investigations'] ?? json['diagnostics'],
        fallbackCategory: 'Lab',
      ),
      ...InvestigationOrder.parseBillOrOrderList(
        json['pathology_orders'] ?? json['pathology_bills'] ?? json['pathology'],
        fallbackCategory: 'Pathology',
      ),
      ...InvestigationOrder.parseBillOrOrderList(
        json['radiology_orders'] ?? json['radiology_bills'] ?? json['radiology'],
        fallbackCategory: 'Radiology',
      ),
    ];

    final charges = JsonParsers.asMapList(json['charges'])
        .map(NursingProcedureCharge.fromJson)
        .toList();

    final bedTransferHistory = JsonParsers.asMapList(
      json['bed_history'] ??
          json['bed_transfers'] ??
          json['transfers'] ??
          json['bedHistory'],
    ).map(BedTransferHistoryEntry.fromJson).toList();

    final checklistMap = json['discharge_checklist'] is Map
        ? JsonParsers.asMap(json['discharge_checklist'])
        : <String, dynamic>{};

    final rawDischargeStatus = JsonParsers.asString(
      json['discharge_status'] ?? dischargeSub['status'] ?? json['status'],
    );
    final dischargedBool = JsonParsers.asBool(
      json['is_discharged'] ?? json['discharged'] ?? dischargeSub['discharged'],
    );
    final dischargeDt = JsonParsers.asDateTime(
      json['discharge_date'] ??
          json['discharged_at'] ??
          json['dischargeDate'] ??
          dischargeSub['date'] ??
          dischargeSub['discharge_date'] ??
          dischargeSub['discharged_at'],
    );

    final dueVal = json['due_amount'] ??
        json['dueAmount'] ??
        json['balance_amount'] ??
        json['balanceAmount'] ??
        json['outstanding_dues'] ??
        json['due_balance'];
    double computedDue = JsonParsers.asDouble(dueVal);
    if (dueVal == null &&
        (json['net_amount'] != null || json['total_charges'] != null)) {
      final totalBill = JsonParsers.asDouble(
        json['net_amount'] ?? json['total_charges'],
      );
      final paid = JsonParsers.asDouble(
        json['paid_amount'] ?? json['total_paid'],
      );
      if (totalBill > paid) computedDue = totalBill - paid;
    }

    final rawTpa = JsonParsers.asString(
      json['tpa'] ??
          json['tpa_name'] ??
          json['tpaName'] ??
          json['organisation_name'] ??
          json['insurance'],
    );
    final rawPayerType = JsonParsers.asString(
      json['payer_type'] ?? json['payerType'] ?? json['payment_mode'],
      fallback: rawTpa.isNotEmpty && rawTpa.toLowerCase() != 'none'
          ? 'TPA / Insurance'
          : 'Self-pay',
    );

    return IpdAdmission(
      id: id,
      ipdNo: JsonParsers.asString(
        json['ipd_no'] ?? json['ipdNo'],
        fallback: id,
      ),
      caseReferenceId: JsonParsers.asString(
        json['case_reference_id'] ??
            json['caseReferenceId'] ??
            json['case_id'] ??
            json['caseId'],
      ),
      admissionDate: JsonParsers.asDateTime(
        json['admission_date'] ??
            json['admissionDate'] ??
            json['date'] ??
            json['createdAt'],
      ),
      dischargeDate: dischargeDt,
      dischargeStatus: rawDischargeStatus.isNotEmpty
          ? rawDischargeStatus
          : (dischargedBool ? 'discharged' : 'admitted'),
      isDischargedFlag: dischargedBool,
      bed: bedName,
      bedId: bedId,
      bedGroup: bedGroupName,
      admissionType: JsonParsers.asString(
        json['admission_type'] ?? json['admissionType'] ?? json['type'],
        fallback: 'Planned',
      ),
      provisionalDiagnosis: JsonParsers.asString(
        json['provisional_diagnosis'] ??
            json['provisionalDiagnosis'] ??
            json['final_diagnosis'] ??
            json['finalDiagnosis'] ??
            json['diagnosis'] ??
            dischargeSub['diagnosis'],
      ),
      presentingComplaint: JsonParsers.asString(
        json['presenting_complaint'] ??
            json['presentingComplaint'] ??
            json['symptoms'] ??
            json['symptoms_description'] ??
            json['symptoms_title'] ??
            json['reason_for_admission'] ??
            json['reason'] ??
            json['note'],
      ),
      clinicalSummary: JsonParsers.asString(
        json['doctor_discharge_summary'] ??
            json['doctorDischargeSummary'] ??
            json['doctor_discharge_note'] ??
            json['discharge_note'] ??
            json['dischargeNote'] ??
            json['discharge_remarks'] ??
            json['dischargeRemarks'] ??
            json['discharge_summary'] ??
            json['dischargeSummary'] ??
            json['clinical_summary'] ??
            json['clinicalSummary'] ??
            json['inpatient_course'] ??
            json['summary'] ??
            dischargeSub['summary'] ??
            dischargeSub['note'] ??
            dischargeSub['remarks'] ??
            dischargeSub['discharge_note'] ??
            json['remarks'] ??
            json['note'],
      ),
      dischargeInstructions: JsonParsers.asString(
        json['discharge_instructions'] ??
            json['dischargeInstructions'] ??
            json['post_discharge_instructions'] ??
            json['follow_up_instructions'] ??
            json['advice'] ??
            json['follow_up'] ??
            dischargeSub['instructions'] ??
            dischargeSub['advice'] ??
            dischargeSub['follow_up'],
      ),
      referringDoctor: JsonParsers.asString(
        json['referring_doctor'] ??
            json['refference'] ??
            json['reference'] ??
            json['referred_by'],
        fallback: 'Self / Hospital OPD',
      ),
      department: JsonParsers.asString(
        json['department'],
        fallback: doctor.department,
      ),
      attendantName: JsonParsers.asString(
        json['attendant_name'] ?? json['attendantName'],
      ),
      attendantPhone: JsonParsers.asString(
        json['attendant_phone'] ?? json['attendantPhone'],
      ),
      attendantRelation: JsonParsers.asString(
        json['attendant_relation'] ?? json['attendantRelation'] ?? json['relation'],
      ),
      payerType: rawPayerType,
      tpaInsurance: rawTpa.isEmpty ? 'None' : rawTpa,
      creditLimit: JsonParsers.asDouble(
        json['credit_limit'] ?? json['creditLimit'],
      ),
      isCasualty: JsonParsers.asBool(json['casualty'] ?? json['is_casualty']),
      isAntenatal: JsonParsers.asBool(
        json['is_antenatal'] ?? json['isAntenatal'] ?? json['antenatal'],
      ),
      outstandingDue: computedDue,
      patient: patient,
      doctor: doctor,
      vitals: vitalsList,
      prescriptions: prescriptions,
      nurseNotes: nurseNotes,
      consultantRegister: consultantRegister,
      investigations: investigations,
      charges: charges,
      bedTransferHistory: bedTransferHistory,
      dischargeChecklist: DischargeChecklist.fromJson(checklistMap),
    );
  }
}
