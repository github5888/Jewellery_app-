import '../core/utils/json_parsers.dart';

class HospitalInfo {
  final String id;
  final String name;
  final String tagline;
  final String phone;
  final String email;
  final String address;
  final String? logo;

  const HospitalInfo({
    required this.id,
    required this.name,
    this.tagline = 'Care • Heal • Live Better',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.logo,
  });

  factory HospitalInfo.fromJson(Map<String, dynamic> json) {
    final name = JsonParsers.asString(
      json['hospital_name'] ?? json['name'] ?? json['title'] ?? json['clinic_name'],
      fallback: 'Smart Super Speciality Hospital',
    );
    return HospitalInfo(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      name: name.isEmpty ? 'Smart Super Speciality Hospital' : name,
      tagline: JsonParsers.asString(
        json['tagline'] ?? json['subtitle'],
        fallback: 'Care • Heal • Live Better',
      ),
      phone: JsonParsers.asString(
        json['phone'] ?? json['contact_no'] ?? json['mobileno'] ?? json['helpline'],
      ),
      email: JsonParsers.asString(json['email'] ?? json['support_email']),
      address: JsonParsers.asString(json['address']),
      logo: JsonParsers.asString(json['logo'] ?? json['image']).isEmpty
          ? null
          : JsonParsers.asString(json['logo'] ?? json['image']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'tagline': tagline,
        'phone': phone,
        'email': email,
        'address': address,
        if (logo != null) 'logo': logo,
      };
}

class NurseUser {
  final String id;
  final String staffCode;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String roleName;
  final String designation;
  final String department;
  final String? image;
  final String hospitalId;
  final HospitalInfo? hospitalInfo;

  const NurseUser({
    required this.id,
    required this.staffCode,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.roleName,
    required this.designation,
    required this.department,
    this.image,
    required this.hospitalId,
    this.hospitalInfo,
  });

  String get fullName {
    final combined = '${name.trim()} ${surname.trim()}'.trim();
    if (combined.isNotEmpty) return combined;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Duty Nurse';
  }

  factory NurseUser.fromJson(Map<String, dynamic> json) {
    // Unwrap nested `user` or `staff` if present inside `/api/auth/me`
    final source = json['user'] is Map
        ? JsonParsers.asMap(json['user'])
        : (json['staff'] is Map ? JsonParsers.asMap(json['staff']) : json);

    final rawHospital = source['hospital'] ?? json['hospital'];
    HospitalInfo? parsedHospital;
    String hospitalId = '';
    if (rawHospital is Map) {
      final hMap = JsonParsers.asMap(rawHospital);
      parsedHospital = HospitalInfo.fromJson(hMap);
      hospitalId = parsedHospital.id;
    } else {
      hospitalId = JsonParsers.asString(rawHospital);
    }

    if (parsedHospital == null && json['hospital_info'] is Map) {
      parsedHospital = HospitalInfo.fromJson(JsonParsers.asMap(json['hospital_info']));
    }

    final rawName = JsonParsers.asString(source['name'] ?? source['first_name']);
    final rawSurname = JsonParsers.asString(source['surname'] ?? source['last_name']);
    final img = JsonParsers.asString(
      source['image'] ?? source['photo'] ?? source['avatar'],
    );

    return NurseUser(
      id: JsonParsers.asId(source['_id'] ?? source['id']),
      staffCode: JsonParsers.asString(
        source['employee_id'] ?? source['staff_id'] ?? source['username'],
      ),
      name: rawName,
      surname: rawSurname,
      email: JsonParsers.asString(source['email']),
      phone: JsonParsers.asString(
        source['contact_no'] ?? source['mobileno'] ?? source['phone'],
      ),
      roleName: JsonParsers.asString(
        source['role_name'] ?? source['role'],
        fallback: 'Nurse',
      ),
      designation: JsonParsers.asString(
        source['designation'],
        fallback: 'Registered Ward Nurse',
      ),
      department: JsonParsers.asString(
        source['department'],
        fallback: 'In-Patient Nursing & Ward Care',
      ),
      image: img.isEmpty ? null : img,
      hospitalId: hospitalId,
      hospitalInfo: parsedHospital,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'employee_id': staffCode,
        'name': name,
        'surname': surname,
        'email': email,
        'contact_no': phone,
        'role_name': roleName,
        'designation': designation,
        'department': department,
        if (image != null) 'image': image,
        'hospital': hospitalInfo != null ? hospitalInfo!.toJson() : hospitalId,
      };
}
