import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';
import 'clinical_report_model.dart';
import 'ipd_models.dart';

/// Hospital Patient Directory (`GET /api/patients` & `GET /api/patients/:id` — image-27..34)
class PatientDirectoryRecord {
  final String id;
  final String patientUniqueId;
  final String patientName;
  final int age;
  final DateTime? dob;
  final String gender;
  final String bloodGroup;
  final String phone;
  final String email;
  final String address;
  final String guardianName;
  final String guardianRelation;
  final String maritalStatus;
  final String knownAllergies;
  final String tpaInsurance;
  final String abhaNumber;
  final String abhaAddress;
  final double dueBalance;
  final double totalInvoiced;
  final double totalPaid;
  final bool isDisabled;
  final String? image;

  const PatientDirectoryRecord({
    required this.id,
    required this.patientUniqueId,
    required this.patientName,
    required this.age,
    this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.phone,
    this.email = '',
    required this.address,
    required this.guardianName,
    this.guardianRelation = '',
    this.maritalStatus = '',
    required this.knownAllergies,
    this.tpaInsurance = '',
    required this.abhaNumber,
    required this.abhaAddress,
    required this.dueBalance,
    this.totalInvoiced = 0.0,
    this.totalPaid = 0.0,
    this.isDisabled = false,
    this.image,
  });

  String get initials => AppFormatters.initials(patientName);

  bool get hasAbha =>
      abhaNumber.trim().isNotEmpty || abhaAddress.trim().isNotEmpty;

  PatientDirectoryRecord copyWith({
    String? id,
    String? patientUniqueId,
    String? patientName,
    int? age,
    DateTime? dob,
    String? gender,
    String? bloodGroup,
    String? phone,
    String? email,
    String? address,
    String? guardianName,
    String? guardianRelation,
    String? maritalStatus,
    String? knownAllergies,
    String? tpaInsurance,
    String? abhaNumber,
    String? abhaAddress,
    double? dueBalance,
    double? totalInvoiced,
    double? totalPaid,
    bool? isDisabled,
    String? image,
  }) {
    return PatientDirectoryRecord(
      id: id ?? this.id,
      patientUniqueId: patientUniqueId ?? this.patientUniqueId,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      guardianName: guardianName ?? this.guardianName,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      knownAllergies: knownAllergies ?? this.knownAllergies,
      tpaInsurance: tpaInsurance ?? this.tpaInsurance,
      abhaNumber: abhaNumber ?? this.abhaNumber,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      dueBalance: dueBalance ?? this.dueBalance,
      totalInvoiced: totalInvoiced ?? this.totalInvoiced,
      totalPaid: totalPaid ?? this.totalPaid,
      isDisabled: isDisabled ?? this.isDisabled,
      image: image ?? this.image,
    );
  }

  factory PatientDirectoryRecord.fromJson(Map<String, dynamic> rawJson) {
    final nestedPat = rawJson['patient'] is Map
        ? JsonParsers.asMap(rawJson['patient'])
        : <String, dynamic>{};
    final json = nestedPat.isNotEmpty
        ? <String, dynamic>{...rawJson, ...nestedPat}
        : rawJson;

    final abhaObj = json['abha'] is Map
        ? JsonParsers.asMap(json['abha'])
        : (json['abha_profile'] is Map
            ? JsonParsers.asMap(json['abha_profile'])
            : (json['abhaProfile'] is Map
                ? JsonParsers.asMap(json['abhaProfile'])
                : (json['abdm'] is Map
                    ? JsonParsers.asMap(json['abdm'])
                    : (json['abha_card'] is Map
                        ? JsonParsers.asMap(json['abha_card'])
                        : <String, dynamic>{}))));

    final img = JsonParsers.asString(
      json['image'] ?? json['photo'] ?? abhaObj['photo'],
    );
    final dob = JsonParsers.asDateTime(
      json['dob'] ??
          json['date_of_birth'] ??
          json['dateOfBirth'] ??
          abhaObj['dob'] ??
          abhaObj['dateOfBirth'],
    );
    int age = JsonParsers.asInt(json['age'] ?? json['age_years']);
    if (age <= 0 && dob != null) {
      age = ((DateTime.now().difference(dob).inDays) / 365.25).floor();
    }

    bool disabled = false;
    if (json.containsKey('is_disabled') || json.containsKey('disabled')) {
      disabled = JsonParsers.asBool(json['is_disabled'] ?? json['disabled']);
    } else if (json.containsKey('is_active') || json.containsKey('isActive')) {
      disabled = !JsonParsers.asBool(
        json['is_active'] ?? json['isActive'],
        fallback: true,
      );
    }

    final first = JsonParsers.asString(
      json['patient_name'] ??
          json['patientName'] ??
          json['name'] ??
          abhaObj['name'] ??
          abhaObj['patient_name'],
    );
    final last = JsonParsers.asString(json['surname'] ?? json['last_name']);
    final combined =
        last.isNotEmpty && !first.toLowerCase().contains(last.toLowerCase())
            ? '$first $last'.trim()
            : first;

    final rawAbhaNumber = JsonParsers.asString(
      json['abha_number'] ??
          json['abhaNumber'] ??
          json['abha_no'] ??
          json['abhaNo'] ??
          json['abha_id'] ??
          json['abhaId'] ??
          json['health_id_number'] ??
          json['healthIdNumber'] ??
          abhaObj['abha_number'] ??
          abhaObj['abhaNumber'] ??
          abhaObj['abha_no'] ??
          abhaObj['abha_id'] ??
          abhaObj['abhaId'] ??
          abhaObj['health_id_number'] ??
          abhaObj['healthIdNumber'] ??
          abhaObj['number'],
    );
    final rawAbhaAddress = JsonParsers.asString(
      json['abha_address'] ??
          json['abhaAddress'] ??
          json['phr_address'] ??
          json['phrAddress'] ??
          json['health_id'] ??
          json['healthId'] ??
          abhaObj['abha_address'] ??
          abhaObj['abhaAddress'] ??
          abhaObj['phr_address'] ??
          abhaObj['phrAddress'] ??
          abhaObj['health_id'] ??
          abhaObj['healthId'] ??
          abhaObj['address'],
    );

    return PatientDirectoryRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ??
            json['patientUniqueId'] ??
            json['uhid'] ??
            json['patient_code'] ??
            json['patient_id'],
      ),
      patientName: combined.isNotEmpty ? combined : '—',
      age: age,
      dob: dob,
      gender: JsonParsers.asString(
        json['gender'] ?? abhaObj['gender'],
        fallback: '—',
      ),
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? json['bloodGroup'],
      ),
      phone: JsonParsers.asString(
        json['mobileno'] ??
            json['mobile_no'] ??
            json['mobileNo'] ??
            json['phone'] ??
            json['mobile'] ??
            abhaObj['mobile'] ??
            abhaObj['mobileno'],
      ),
      email: JsonParsers.asString(json['email'] ?? json['email_address']),
      address: JsonParsers.asString(
        json['address'] ?? json['residential_address'],
      ),
      guardianName: JsonParsers.asString(
        json['guardian_name'] ?? json['guardianName'] ?? json['father_name'],
      ),
      guardianRelation: JsonParsers.asString(
        json['guardian_relation'] ??
            json['guardianRelation'] ??
            json['guardian_relationship'] ??
            json['relation'],
      ),
      maritalStatus: JsonParsers.asString(
        json['marital_status'] ?? json['maritalStatus'],
      ),
      knownAllergies: JsonParsers.asString(
        json['known_allergies'] ?? json['knownAllergies'] ?? json['allergies'],
      ),
      tpaInsurance: JsonParsers.asString(
        json['tpa'] ??
            json['tpa_name'] ??
            json['tpaName'] ??
            json['organisation_name'] ??
            json['insurance'],
      ),
      abhaNumber: rawAbhaNumber,
      abhaAddress: rawAbhaAddress,
      dueBalance: JsonParsers.asDouble(
        json['due_balance'] ??
            json['dueBalance'] ??
            json['due_amount'] ??
            json['dueAmount'] ??
            json['balance'],
      ),
      totalInvoiced: JsonParsers.asDouble(
        json['total_invoiced'] ?? json['totalInvoiced'] ?? json['net_amount'],
      ),
      totalPaid: JsonParsers.asDouble(
        json['total_paid'] ?? json['totalPaid'] ?? json['paid_amount'],
      ),
      isDisabled: disabled,
      image: img.isEmpty ? null : img,
    );
  }
}

/// OPD Consultation row inside Patient Profile -> `Visits / OPD & IPD` (image-32)
class PatientOpdEncounter {
  final String id;
  final String opdNo;
  final String caseRef;
  final DateTime? date;
  final String doctorName;
  final double charge;
  final double paid;
  final String status;

  const PatientOpdEncounter({
    required this.id,
    required this.opdNo,
    required this.caseRef,
    this.date,
    required this.doctorName,
    required this.charge,
    required this.paid,
    required this.status,
  });

  factory PatientOpdEncounter.fromJson(Map<String, dynamic> json) {
    String docName = '';
    final rawDoc = json['doctor'] ??
        json['cons_doctor'] ??
        json['consultant_doctor'] ??
        json['consultantDoctor'] ??
        json['consultant'] ??
        json['doctor_id'];
    if (rawDoc is Map) {
      final dm = JsonParsers.asMap(rawDoc);
      docName = AppFormatters.formatDoctorName(
        JsonParsers.asString(dm['name'] ?? dm['doctor_name']),
        JsonParsers.asString(dm['surname'] ?? dm['last_name']),
      );
    } else {
      final s = JsonParsers.asString(
        json['doctor_name'] ??
            json['doctorName'] ??
            json['consultant_name'] ??
            rawDoc,
      );
      if (s.isNotEmpty) docName = AppFormatters.formatDoctorName(s);
    }

    final chargeVal = JsonParsers.asDouble(
      json['standard_charge'] ??
          json['applied_charge'] ??
          json['amount'] ??
          json['charge'] ??
          json['net_amount'] ??
          json['total_amount'] ??
          json['total'] ??
          json['consultation_fee'] ??
          json['doctor_fee'] ??
          json['fee'],
    );
    final paidVal = JsonParsers.asDouble(
      json['paid_amount'] ??
          json['paidAmount'] ??
          json['paid'] ??
          json['amount_paid'] ??
          json['payment_amount'] ??
          (JsonParsers.asString(json['payment_status']).toLowerCase() == 'paid'
              ? chargeVal
              : null),
      fallback: chargeVal > 0 && json['due_amount'] == null ? chargeVal : 0.0,
    );

    return PatientOpdEncounter(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      opdNo: JsonParsers.asString(
        json['opd_no'] ??
            json['opdNo'] ??
            json['opd_id'] ??
            json['visit_no'] ??
            json['token_no'],
        fallback: 'OPD',
      ),
      caseRef: JsonParsers.asString(
        json['case_reference_id'] ??
            json['caseReferenceId'] ??
            json['case_id'] ??
            json['caseId'] ??
            json['caseRef'] ??
            json['case_no'],
      ),
      date: JsonParsers.asDateTime(
        json['appointment_date'] ??
            json['appointmentDate'] ??
            json['visit_date'] ??
            json['visitDate'] ??
            json['opd_date'] ??
            json['date'] ??
            json['createdAt'],
      ),
      doctorName: docName.isEmpty ? '—' : docName,
      charge: chargeVal,
      paid: paidVal,
      status: JsonParsers.asString(
        json['status'] ?? json['opd_status'] ?? json['visit_status'],
        fallback: 'Completed',
      ),
    );
  }
}

/// Appointment row inside Patient Profile -> `Appointments` (image-31)
class PatientAppointmentItem {
  final String id;
  final String appointmentNo;
  final DateTime? date;
  final String timeSlot;
  final String doctorName;
  final String department;
  final String status;

  const PatientAppointmentItem({
    required this.id,
    required this.appointmentNo,
    this.date,
    required this.timeSlot,
    required this.doctorName,
    required this.department,
    required this.status,
  });

  factory PatientAppointmentItem.fromJson(Map<String, dynamic> json) {
    String docName = '';
    if (json['doctor'] is Map) {
      final dm = JsonParsers.asMap(json['doctor']);
      docName = AppFormatters.formatDoctorName(
        JsonParsers.asString(dm['name']),
        JsonParsers.asString(dm['surname']),
      );
    } else {
      final raw = JsonParsers.asString(
        json['doctor_name'] ?? json['doctorName'] ?? json['doctor'],
      );
      if (raw.isNotEmpty) docName = AppFormatters.formatDoctorName(raw);
    }

    return PatientAppointmentItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      appointmentNo: JsonParsers.asString(
        json['appointment_no'] ?? json['appointmentNo'] ?? json['token_no'],
        fallback: 'APT',
      ),
      date: JsonParsers.asDateTime(
        json['date'] ??
            json['appointment_date'] ??
            json['appointmentDate'] ??
            json['createdAt'],
      ),
      timeSlot: JsonParsers.asString(
        json['time'] ?? json['slot'] ?? json['shift'],
      ),
      doctorName: docName.isEmpty ? '—' : docName,
      department: JsonParsers.asString(json['department']),
      status: JsonParsers.asString(
        json['appointment_status'] ?? json['status'],
        fallback: 'Scheduled',
      ),
    );
  }
}

/// Service / Order row inside Patient Profile -> `Services & Orders` (image-33)
class PatientServiceOrderItem {
  final String id;
  final String serviceType;
  final String billReference;
  final String description;
  final double amount;
  final String status;
  final DateTime? date;

  const PatientServiceOrderItem({
    required this.id,
    required this.serviceType,
    required this.billReference,
    required this.description,
    required this.amount,
    required this.status,
    this.date,
  });

  factory PatientServiceOrderItem.fromJson(
    Map<String, dynamic> json, {
    String fallbackType = 'Service',
  }) {
    return PatientServiceOrderItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      serviceType: JsonParsers.asString(
        json['service_type'] ??
            json['serviceType'] ??
            json['module'] ??
            json['category'] ??
            json['charge_type'] ??
            json['type'],
        fallback: fallbackType,
      ),
      billReference: JsonParsers.asString(
        json['bill_no'] ??
            json['billNo'] ??
            json['invoice_no'] ??
            json['invoiceNo'] ??
            json['reference_no'] ??
            json['order_no'],
        fallback: 'ORD',
      ),
      description: JsonParsers.asString(
        json['description'] ??
            json['test_name'] ??
            json['testName'] ??
            json['charge_name'] ??
            json['medicine_name'] ??
            json['service_name'] ??
            json['title'] ??
            json['name'] ??
            json['note'],
        fallback: 'Clinical Service / Order',
      ),
      amount: JsonParsers.asDouble(
        json['net_amount'] ??
            json['total_amount'] ??
            json['applied_charge'] ??
            json['standard_charge'] ??
            json['total'] ??
            json['amount'],
      ),
      status: JsonParsers.asString(
        json['status'] ?? json['payment_status'] ?? json['report_status'],
        fallback: 'Completed',
      ),
      date: JsonParsers.asDateTime(
        json['date'] ?? json['order_date'] ?? json['createdAt'],
      ),
    );
  }
}

/// Invoice row inside Patient Profile -> `Overview` (`Recent Invoices` — image-29)
class PatientInvoiceSummaryItem {
  final String id;
  final String invoiceNo;
  final String module;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final DateTime? date;

  const PatientInvoiceSummaryItem({
    required this.id,
    required this.invoiceNo,
    required this.module,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    this.date,
  });

  factory PatientInvoiceSummaryItem.fromJson(Map<String, dynamic> json) {
    final total = JsonParsers.asDouble(
      json['net_amount'] ??
          json['total_amount'] ??
          json['total'] ??
          json['amount'],
    );
    final paid = JsonParsers.asDouble(
      json['paid_amount'] ?? json['paid'] ?? json['total_paid'],
    );
    final due = JsonParsers.asDouble(
      json['due_amount'] ?? json['balance'] ?? (total > paid ? total - paid : 0),
    );
    return PatientInvoiceSummaryItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      invoiceNo: JsonParsers.asString(
        json['invoice_no'] ?? json['bill_no'] ?? json['reference_no'],
        fallback: 'INV',
      ),
      module: JsonParsers.asString(
        json['module'] ?? json['section'] ?? json['type'],
        fallback: 'Billing',
      ),
      totalAmount: total,
      paidAmount: paid,
      dueAmount: due,
      status: JsonParsers.asString(
        json['payment_status'] ?? json['status'],
        fallback: due <= 0 ? 'Paid' : 'Partial',
      ),
      date: JsonParsers.asDateTime(json['date'] ?? json['createdAt']),
    );
  }
}

/// Complete 6-Tab Patient Dossier (`GET /api/patients/:id` + linked clinical modules)
class PatientFullDossier {
  final PatientDirectoryRecord patient;
  final List<ClinicalReportRecord> labAndRadiology;
  final List<PatientAppointmentItem> appointments;
  final List<PatientOpdEncounter> opdEncounters;
  final List<IpdAdmission> ipdAdmissions;
  final List<PatientServiceOrderItem> serviceOrders;
  final List<PatientInvoiceSummaryItem> invoices;
  final double totalInvoicedAmount;
  final double totalPaymentsReceived;
  final double currentOutstandingBalance;
  final int invoiceCount;
  final int paymentTransactionCount;

  const PatientFullDossier({
    required this.patient,
    required this.labAndRadiology,
    required this.appointments,
    required this.opdEncounters,
    required this.ipdAdmissions,
    required this.serviceOrders,
    required this.invoices,
    required this.totalInvoicedAmount,
    required this.totalPaymentsReceived,
    required this.currentOutstandingBalance,
    required this.invoiceCount,
    required this.paymentTransactionCount,
  });

  int get totalVisitsCount => opdEncounters.length + ipdAdmissions.length;

  List<ClinicalReportRecord> get pathologyReports => labAndRadiology
      .where((r) => r.category == ClinicalReportCategory.lab)
      .toList();

  List<ClinicalReportRecord> get radiologyReports => labAndRadiology
      .where((r) => r.category == ClinicalReportCategory.radiology)
      .toList();
}
