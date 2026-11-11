import '../core/utils/json_parsers.dart';

/// Hospital Patient Directory (`GET /api/patients` — matches Web Screenshot 722)
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
    this.image,
  });

  factory PatientDirectoryRecord.fromJson(Map<String, dynamic> json) {
    final img = JsonParsers.asString(json['image'] ?? json['photo']);
    return PatientDirectoryRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ?? json['uhid'],
      ),
      patientName: JsonParsers.asString(
        json['patient_name'] ?? json['name'],
        fallback: 'Patient',
      ),
      age: JsonParsers.asInt(json['age']),
      gender: JsonParsers.asString(json['gender'], fallback: '—'),
      bloodGroup: JsonParsers.asString(json['blood_group']),
      phone: JsonParsers.asString(
        json['mobileno'] ?? json['phone'] ?? json['mobile'],
      ),
      address: JsonParsers.asString(json['address']),
      guardianName: JsonParsers.asString(json['guardian_name']),
      knownAllergies: JsonParsers.asString(json['known_allergies']),
      abhaNumber: JsonParsers.asString(json['abha_number']),
      abhaAddress: JsonParsers.asString(json['abha_address']),
      dueBalance: JsonParsers.asDouble(json['due_balance'] ?? json['balance']),
      image: img.isEmpty ? null : img,
    );
  }
}
