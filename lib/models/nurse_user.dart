import '../core/utils/formatters.dart';
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
      json['hospital_name'] ??
          json['name'] ??
          json['title'] ??
          json['clinic_name'],
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
        json['phone'] ??
            json['contact_no'] ??
            json['mobileno'] ??
            json['helpline'],
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

/// Nurse Account & Staff Profile (`GET /api/auth/me`, `PUT /api/auth/profile`)
/// Covers all fields on `https://hospital.hrpocket.in/profile` (image-13 & image-15):
/// - Personal & Contact Information (`First Name`, `Surname`, `Email`, `Phone`, `Emergency Contact`,
///   `Gender`, `Date of Birth`, `Blood Group`, `Current Address`, `Permanent Address`)
/// - Hospital Employment & Role Details (`EMPLOYEE ID`, `ASSIGNED ROLE`, `DEPARTMENT`,
///   `DESIGNATION`, `SPECIALIST`, `QUALIFICATION`, `DATE OF JOINING`, `WORK SHIFT`)
class NurseUser {
  final String id;
  final String staffCode;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String emergencyContact;
  final String gender;
  final DateTime? dob;
  final String dobRaw;
  final String bloodGroup;
  final String currentAddress;
  final String permanentAddress;
  final String roleName;
  final String designation;
  final String department;
  final String specialist;
  final String qualification;
  final DateTime? dateOfJoining;
  final String dateOfJoiningRaw;
  final String workShift;
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
    this.emergencyContact = '',
    this.gender = '',
    this.dob,
    this.dobRaw = '',
    this.bloodGroup = '',
    this.currentAddress = '',
    this.permanentAddress = '',
    required this.roleName,
    required this.designation,
    required this.department,
    this.specialist = '',
    this.qualification = '',
    this.dateOfJoining,
    this.dateOfJoiningRaw = '',
    this.workShift = '',
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

  /// `dd-mm-yyyy` display for `Date of Birth` input (matches image-15)
  String get dobDdMmYyyy {
    if (dob != null) {
      final d = dob!.toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd-$mm-${d.year}';
    }
    return dobRaw;
  }

  /// `01/01/2024` display for `DATE OF JOINING` in Professional Info (matches image-13)
  String get dateOfJoiningDisplay {
    if (dateOfJoining != null) {
      return AppFormatters.formatSlashDate(dateOfJoining);
    }
    if (dateOfJoiningRaw.trim().isNotEmpty) return dateOfJoiningRaw.trim();
    return '—';
  }

  NurseUser copyWith({
    String? staffCode,
    String? name,
    String? surname,
    String? email,
    String? phone,
    String? emergencyContact,
    String? gender,
    DateTime? dob,
    String? dobRaw,
    String? bloodGroup,
    String? currentAddress,
    String? permanentAddress,
    String? roleName,
    String? designation,
    String? department,
    String? specialist,
    String? qualification,
    DateTime? dateOfJoining,
    String? dateOfJoiningRaw,
    String? workShift,
    String? image,
    HospitalInfo? hospitalInfo,
  }) {
    return NurseUser(
      id: id,
      staffCode: staffCode ?? this.staffCode,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      dobRaw: dobRaw ?? this.dobRaw,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      roleName: roleName ?? this.roleName,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      specialist: specialist ?? this.specialist,
      qualification: qualification ?? this.qualification,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      dateOfJoiningRaw: dateOfJoiningRaw ?? this.dateOfJoiningRaw,
      workShift: workShift ?? this.workShift,
      image: image ?? this.image,
      hospitalId: hospitalId,
      hospitalInfo: hospitalInfo ?? this.hospitalInfo,
    );
  }

  factory NurseUser.fromJson(Map<String, dynamic> json) {
    final userSub = json['user'] is Map
        ? JsonParsers.asMap(json['user'])
        : <String, dynamic>{};
    final staffSub = json['staff'] is Map
        ? JsonParsers.asMap(json['staff'])
        : (userSub['staff'] is Map
            ? JsonParsers.asMap(userSub['staff'])
            : <String, dynamic>{});

    // Merge keys with priority: nested user -> nested staff -> root json
    final source = <String, dynamic>{
      ...json,
      ...staffSub,
      ...userSub,
    };

    String pickStr(List<String> keys, {String fallback = ''}) {
      for (final m in [userSub, staffSub, json, source]) {
        for (final k in keys) {
          final v = JsonParsers.asString(m[k]);
          if (v.isNotEmpty) return v;
        }
      }
      return fallback;
    }

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
      parsedHospital =
          HospitalInfo.fromJson(JsonParsers.asMap(json['hospital_info']));
    }

    String rawName = pickStr(const ['name', 'firstName', 'first_name']);
    String rawSurname = pickStr(const ['surname', 'lastName', 'last_name']);
    // If backend stored full name in `name` and left `surname` empty, split cleanly when appropriate
    if (rawSurname.isEmpty && rawName.contains(' ')) {
      final parts = rawName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        rawName = parts.first;
        rawSurname = parts.sublist(1).join(' ');
      }
    }

    final img = pickStr(const [
      'image',
      'photo',
      'avatar',
      'profilePhoto',
      'profile_photo',
    ]);

    final rawDobVal = source['dob'] ??
        source['dateOfBirth'] ??
        source['date_of_birth'] ??
        staffSub['dob'];
    final parsedDob = JsonParsers.asDateTime(rawDobVal);
    final rawDobStr = JsonParsers.asString(rawDobVal);

    final rawDojVal = source['date_of_joining'] ??
        source['dateOfJoining'] ??
        source['joining_date'] ??
        source['joiningDate'] ??
        staffSub['date_of_joining'] ??
        staffSub['dateOfJoining'];
    final parsedDoj = JsonParsers.asDateTime(rawDojVal);
    final rawDojStr = JsonParsers.asString(rawDojVal);

    return NurseUser(
      id: JsonParsers.asId(
        userSub['_id'] ??
            userSub['id'] ??
            staffSub['_id'] ??
            json['_id'] ??
            json['id'],
      ),
      staffCode: pickStr(const [
        'employee_id',
        'employeeId',
        'staff_id',
        'staffId',
        'staff_code',
        'staffCode',
      ]),
      name: rawName,
      surname: rawSurname,
      email: pickStr(const ['email', 'username']),
      phone: pickStr(const [
        'contact_no',
        'contactNo',
        'phone',
        'mobileno',
        'mobile_no',
        'mobile',
      ]),
      emergencyContact: pickStr(const [
        'emergency_contact_no',
        'emergencyContactNo',
        'emergency_contact',
        'emergencyContact',
        'emergencyPhone',
      ]),
      gender: pickStr(const ['gender']),
      dob: parsedDob,
      dobRaw: rawDobStr.contains('T') ? rawDobStr.split('T').first : rawDobStr,
      bloodGroup: pickStr(const ['blood_group', 'bloodGroup']),
      currentAddress: pickStr(const [
        'local_address',
        'localAddress',
        'current_address',
        'currentAddress',
        'address',
      ]),
      permanentAddress: pickStr(const [
        'permanent_address',
        'permanentAddress',
      ]),
      roleName: pickStr(
        const ['role_name', 'roleName', 'role'],
        fallback: 'Nurse',
      ),
      designation: pickStr(const ['designation']),
      department: pickStr(const ['department']),
      specialist: pickStr(const [
        'specialist',
        'specialization',
        'speciality',
      ]),
      qualification: pickStr(const [
        'qualification',
        'qualifications',
        'education',
      ]),
      dateOfJoining: parsedDoj,
      dateOfJoiningRaw:
          rawDojStr.contains('T') ? rawDojStr.split('T').first : rawDojStr,
      workShift: pickStr(const [
        'work_shift',
        'workShift',
        'shift',
      ]),
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
        'emergency_contact_no': emergencyContact,
        'gender': gender,
        if (dob != null) 'dob': dob!.toIso8601String() else if (dobRaw.isNotEmpty) 'dob': dobRaw,
        'blood_group': bloodGroup,
        'local_address': currentAddress,
        'permanent_address': permanentAddress,
        'role_name': roleName,
        'designation': designation,
        'department': department,
        'specialist': specialist,
        'qualification': qualification,
        if (dateOfJoining != null)
          'date_of_joining': dateOfJoining!.toIso8601String()
        else if (dateOfJoiningRaw.isNotEmpty)
          'date_of_joining': dateOfJoiningRaw,
        'work_shift': workShift,
        if (image != null) 'image': image,
        'hospital': hospitalInfo != null ? hospitalInfo!.toJson() : hospitalId,
      };
}
