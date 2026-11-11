import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';

/// Hospital Patient Directory (`GET /api/patients` — matches Website `/patients` image-6)
class PatientDirectoryRecord {
  final String id;
  final String patientUniqueId;
  final String patientName;
  final int age;
  final String gender;
  final String bloodGroup;
  final String phone;
  final String address;
  final String guardianName;
  final String knownAllergies;
  final String abhaNumber;
  final String abhaAddress;
  final double dueBalance;
  final bool isDisabled;
  final String? image;

  const PatientDirectoryRecord({
    required this.id,
    required this.patientUniqueId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.phone,
    required this.address,
    required this.guardianName,
    required this.knownAllergies,
    required this.abhaNumber,
    required this.abhaAddress,
    required this.dueBalance,
    this.isDisabled = false,
    this.image,
  });

  String get initials => AppFormatters.initials(patientName);

  bool get hasAbha =>
      abhaNumber.trim().isNotEmpty || abhaAddress.trim().isNotEmpty;

  factory PatientDirectoryRecord.fromJson(Map<String, dynamic> json) {
    final img = JsonParsers.asString(json['image'] ?? json['photo']);
    final dob = JsonParsers.asDateTime(json['dob'] ?? json['date_of_birth']);
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
      json['patient_name'] ?? json['patientName'] ?? json['name'],
    );
    final last = JsonParsers.asString(json['surname'] ?? json['last_name']);
    final combined = last.isNotEmpty && !first.toLowerCase().contains(last.toLowerCase())
        ? '$first $last'.trim()
        : first;

    return PatientDirectoryRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ??
            json['patientUniqueId'] ??
            json['uhid'] ??
            json['patient_id'],
      ),
      patientName: combined.isNotEmpty ? combined : '—',
      age: age,
      gender: JsonParsers.asString(json['gender'], fallback: '—'),
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? json['bloodGroup'],
      ),
      phone: JsonParsers.asString(
        json['mobileno'] ??
            json['mobile_no'] ??
            json['mobileNo'] ??
            json['phone'] ??
            json['mobile'],
      ),
      address: JsonParsers.asString(json['address']),
      guardianName: JsonParsers.asString(
        json['guardian_name'] ?? json['guardianName'],
      ),
      knownAllergies: JsonParsers.asString(
        json['known_allergies'] ?? json['knownAllergies'] ?? json['allergies'],
      ),
      abhaNumber: JsonParsers.asString(
        json['abha_number'] ?? json['abhaNumber'] ?? json['abha_no'],
      ),
      abhaAddress: JsonParsers.asString(
        json['abha_address'] ?? json['abhaAddress'],
      ),
      dueBalance: JsonParsers.asDouble(
        json['due_balance'] ??
            json['dueBalance'] ??
            json['due_amount'] ??
            json['dueAmount'] ??
            json['balance'],
      ),
      isDisabled: disabled,
      image: img.isEmpty ? null : img,
    );
  }
}
