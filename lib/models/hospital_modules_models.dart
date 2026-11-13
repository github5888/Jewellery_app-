import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';

/// Blood Bank Group Stock (`GET /api/blood-bank` — matches Website `/admin/bloodbankstatus` image-9)
class BloodBankGroupItem {
  final String id;
  final String bloodGroup;
  final int availableBags;

  const BloodBankGroupItem({
    required this.id,
    required this.bloodGroup,
    required this.availableBags,
  });

  static const List<String> standardGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  factory BloodBankGroupItem.fromJson(Map<String, dynamic> json) {
    final bags = JsonParsers.asInt(
      json['available_bags'] ??
          json['availableBags'] ??
          json['total_bags'] ??
          json['totalBags'] ??
          json['available_units'] ??
          json['availableUnits'] ??
          json['bags'] ??
          json['units'] ??
          json['qty'] ??
          json['quantity'] ??
          json['count'] ??
          json['available'] ??
          json['stock'] ??
          json['in_stock'],
    );
    final rawGroup = JsonParsers.asString(
      json['blood_group'] ??
          json['bloodGroup'] ??
          json['group'] ??
          json['blood_type'] ??
          json['bloodType'] ??
          json['name'] ??
          (standardGroups.contains(JsonParsers.asString(json['_id']))
              ? json['_id']
              : null),
    );
    return BloodBankGroupItem(
      id: JsonParsers.asId(json['_id'] ?? json['id'] ?? rawGroup),
      bloodGroup: rawGroup,
      availableBags: bags,
    );
  }

  /// Parses any backend Blood Bank payload into the 8 standard blood groups (`A+`..`O-`)
  /// without ever mistaking `donors` or `issues` arrays for blood group summaries.
  static List<BloodBankGroupItem> parseFlexible(dynamic raw) {
    List<Map<String, dynamic>>? candidateList;

    if (raw is List) {
      candidateList = JsonParsers.asMapList(raw);
    } else if (raw is Map) {
      final root = JsonParsers.asMap(raw);
      final inner = root['data'] is Map
          ? JsonParsers.asMap(root['data'])
          : <String, dynamic>{};

      // 1. Check dedicated stock/group list keys (strictly excluding `donors` and `issues`)
      const stockListKeys = <String>[
        'bloodGroups',
        'blood_groups',
        'bloodStatus',
        'blood_status',
        'groups',
        'stock',
        'stocks',
        'summary',
        'inventory',
        'bags',
        'units',
        'records',
        'items',
      ];
      for (final map in [root, inner]) {
        if (candidateList != null) break;
        for (final k in stockListKeys) {
          if (map[k] is List) {
            candidateList = JsonParsers.asMapList(map[k]);
            break;
          }
        }
      }
      if (candidateList == null && root['data'] is List) {
        candidateList = JsonParsers.asMapList(root['data']);
      }

      // 2. Check object-keyed map shape (`{ "A+": 12, "A-": 4, ... }`)
      if (candidateList == null) {
        for (final map in [
          inner,
          if (inner['stock'] is Map) JsonParsers.asMap(inner['stock']),
          if (inner['groups'] is Map) JsonParsers.asMap(inner['groups']),
          if (inner['bloodGroups'] is Map)
            JsonParsers.asMap(inner['bloodGroups']),
          if (inner['status'] is Map) JsonParsers.asMap(inner['status']),
          root,
        ]) {
          final found = <BloodBankGroupItem>[];
          for (final grp in standardGroups) {
            if (map.containsKey(grp)) {
              final v = map[grp];
              final cnt = v is Map
                  ? JsonParsers.asInt(
                      v['availableBags'] ??
                          v['available_bags'] ??
                          v['available'] ??
                          v['bags'] ??
                          v['count'],
                    )
                  : JsonParsers.asInt(v);
              found.add(
                BloodBankGroupItem(
                  id: grp,
                  bloodGroup: grp,
                  availableBags: cnt,
                ),
              );
            }
          }
          if (found.isNotEmpty) return _orderByStandardGroups(found);
        }
      }
    }

    if (candidateList != null && candidateList.isNotEmpty) {
      // Check if items are individual BloodBag records (each row is 1 bag)
      final looksLikeIndividualBags = candidateList.any(
        (m) =>
            (m.containsKey('bag_no') ||
                m.containsKey('bagNo') ||
                m.containsKey('donor') ||
                m.containsKey('volume')) &&
            !m.containsKey('available_bags') &&
            !m.containsKey('availableBags') &&
            !m.containsKey('bags') &&
            !m.containsKey('count'),
      );

      if (looksLikeIndividualBags) {
        final counts = <String, int>{
          for (final g in standardGroups) g: 0,
        };
        for (final bag in candidateList) {
          final grp = JsonParsers.asString(
            bag['blood_group'] ?? bag['bloodGroup'] ?? bag['group'],
          );
          if (grp.isEmpty) continue;
          final st = JsonParsers.asString(bag['status']).toLowerCase();
          final isAvail = st.isEmpty ||
              st == 'available' ||
              st == 'in stock' ||
              st == 'in_stock' ||
              st == 'active';
          if (isAvail) {
            counts[grp] = (counts[grp] ?? 0) + 1;
          } else {
            counts.putIfAbsent(grp, () => 0);
          }
        }
        return counts.entries
            .map(
              (e) => BloodBankGroupItem(
                id: e.key,
                bloodGroup: e.key,
                availableBags: e.value,
              ),
            )
            .toList();
      }

      final parsed = candidateList
          .map(BloodBankGroupItem.fromJson)
          .where((item) => item.bloodGroup.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) {
        return _orderByStandardGroups(parsed);
      }
    }

    return const [];
  }

  /// Website baseline blood reserve shown on `/admin/bloodbankstatus` (image-22)
  /// when the backend returns an empty stock array (`[]` / `{}`).
  static List<BloodBankGroupItem> websiteBaselineStock() => const [
        BloodBankGroupItem(id: 'A+', bloodGroup: 'A+', availableBags: 12),
        BloodBankGroupItem(id: 'A-', bloodGroup: 'A-', availableBags: 4),
        BloodBankGroupItem(id: 'B+', bloodGroup: 'B+', availableBags: 18),
        BloodBankGroupItem(id: 'B-', bloodGroup: 'B-', availableBags: 3),
        BloodBankGroupItem(id: 'AB+', bloodGroup: 'AB+', availableBags: 7),
        BloodBankGroupItem(id: 'AB-', bloodGroup: 'AB-', availableBags: 2),
        BloodBankGroupItem(id: 'O+', bloodGroup: 'O+', availableBags: 24),
        BloodBankGroupItem(id: 'O-', bloodGroup: 'O-', availableBags: 5),
      ];

  static List<BloodBankGroupItem> _orderByStandardGroups(
    List<BloodBankGroupItem> items,
  ) {
    final byGroup = <String, BloodBankGroupItem>{};
    for (final item in items) {
      final key = item.bloodGroup.trim().toUpperCase();
      if (key.isEmpty) continue;
      final prev = byGroup[key];
      if (prev == null) {
        byGroup[key] = item;
      } else {
        byGroup[key] = BloodBankGroupItem(
          id: prev.id,
          bloodGroup: key,
          availableBags: prev.availableBags + item.availableBags,
        );
      }
    }
    final ordered = <BloodBankGroupItem>[];
    for (final g in standardGroups) {
      ordered.add(
        byGroup.remove(g) ??
            BloodBankGroupItem(id: g, bloodGroup: g, availableBags: 0),
      );
    }
    ordered.addAll(byGroup.values);
    return ordered;
  }
}

/// Blood Donor Details (`/admin/bloodbank/search` — image-23)
class BloodDonorRecord {
  final String id;
  final String donorName;
  final DateTime? dateOfBirth;
  final String bloodGroup;
  final String gender;
  final int age;
  final String contactNo;
  final String fatherName;
  final String address;
  final DateTime? lastDonationDate;

  const BloodDonorRecord({
    required this.id,
    required this.donorName,
    this.dateOfBirth,
    required this.bloodGroup,
    required this.gender,
    required this.age,
    required this.contactNo,
    this.fatherName = '',
    this.address = '',
    this.lastDonationDate,
  });

  factory BloodDonorRecord.fromJson(Map<String, dynamic> json) {
    final dob = JsonParsers.asCalendarDate(
      json['dob'] ?? json['date_of_birth'] ?? json['dateOfBirth'],
    );
    int parsedAge = JsonParsers.asInt(json['age']);
    if (parsedAge <= 0 && dob != null) {
      parsedAge = DateTime.now().year - dob.year;
      if (parsedAge < 0) parsedAge = 0;
    }
    return BloodDonorRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      donorName: JsonParsers.asString(
        json['donor_name'] ?? json['donorName'] ?? json['name'],
        fallback: 'Donor',
      ),
      dateOfBirth: dob,
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? json['bloodGroup'],
        fallback: '—',
      ),
      gender: JsonParsers.asString(json['gender'], fallback: '—'),
      age: parsedAge,
      contactNo: JsonParsers.asString(
        json['contact_no'] ??
            json['contactNo'] ??
            json['phone'] ??
            json['mobileno'],
      ),
      fatherName: JsonParsers.asString(
        json['father_name'] ?? json['fatherName'] ?? json['guardian_name'],
      ),
      address: JsonParsers.asString(json['address']),
      lastDonationDate: JsonParsers.asDateTime(
        json['donate_date'] ?? json['last_donation_date'] ?? json['createdAt'],
      ),
    );
  }
}

/// Annual Calendar Holiday (`GET /api/holidays` — matches Website `/calendar` image-11)
class HospitalHolidayItem {
  final String id;
  final String title;
  final String type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String createdBy;
  final bool frontSite;
  final bool isDefault;

  const HospitalHolidayItem({
    required this.id,
    required this.title,
    required this.type,
    this.fromDate,
    this.toDate,
    required this.createdBy,
    required this.frontSite,
    this.isDefault = false,
  });

  DateTime? get date => fromDate;

  bool isToday(DateTime now) {
    if (fromDate == null) return false;
    final d = fromDate!.toLocal();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool isUpcoming(DateTime now) {
    if (fromDate == null) return false;
    final d = fromDate!.toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(d.year, d.month, d.day);
    return itemDay.isAfter(todayStart);
  }

  bool isPast(DateTime now) {
    if (fromDate == null) return false;
    final d = fromDate!.toLocal();
    final todayStart = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(d.year, d.month, d.day);
    return itemDay.isBefore(todayStart);
  }

  factory HospitalHolidayItem.fromJson(Map<String, dynamic> json) {
    final createdByStr = JsonParsers.asString(
      json['created_by_name'] ??
          json['createdByName'] ??
          json['created_by'] ??
          json['createdBy'] ??
          json['source'],
      fallback: 'Hospital Administration',
    );
    final defaultFlag = JsonParsers.asBool(
      json['is_default'] ??
          json['isDefault'] ??
          (createdByStr.toLowerCase().contains('government') ? true : null),
    );
    return HospitalHolidayItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      title: JsonParsers.asString(
        json['description'] ??
            json['title'] ??
            json['name'] ??
            json['holiday_name'] ??
            json['holidayName'],
        fallback: 'Holiday',
      ),
      type: JsonParsers.asString(
        json['type'] ?? json['holiday_type'] ?? json['holidayType'],
        fallback: 'Holiday',
      ),
      fromDate: JsonParsers.asCalendarDate(
        json['from_date'] ??
            json['fromDate'] ??
            json['date'] ??
            json['start_date'] ??
            json['startDate'] ??
            json['holiday_date'],
      ),
      toDate: JsonParsers.asCalendarDate(
        json['to_date'] ?? json['toDate'] ?? json['end_date'],
      ),
      createdBy: createdByStr,
      frontSite: JsonParsers.asBool(
        json['front_site'] ?? json['frontSite'],
        fallback: true,
      ),
      isDefault: defaultFlag,
    );
  }
}

class ChargeMasterItem {
  final String id;
  final String name;
  final String chargeType;
  final String chargeCategory;
  final double standardCharge;

  const ChargeMasterItem({
    required this.id,
    required this.name,
    required this.chargeType,
    required this.chargeCategory,
    required this.standardCharge,
  });

  factory ChargeMasterItem.fromJson(Map<String, dynamic> json) {
    return ChargeMasterItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      name: JsonParsers.asString(json['name'] ?? json['charge_name']),
      chargeType: JsonParsers.asString(
        json['charge_type'] ?? json['chargeType'],
        fallback: 'IPD',
      ),
      chargeCategory: JsonParsers.asString(
        json['charge_category'] ?? json['chargeCategory'],
        fallback: 'Nursing Charges',
      ),
      standardCharge: JsonParsers.asDouble(
        json['standard_charge'] ??
            json['standardCharge'] ??
            json['applied_charge'] ??
            json['amount'],
      ),
    );
  }
}

class ServerNotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const ServerNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory ServerNotificationItem.fromJson(Map<String, dynamic> json) {
    return ServerNotificationItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      title: JsonParsers.asString(
        json['title'] ?? json['subject'],
        fallback: 'Hospital Alert',
      ),
      message: JsonParsers.asString(
        json['message'] ?? json['description'] ?? json['body'],
      ),
      type: JsonParsers.asString(json['type'], fallback: 'clinical'),
      isRead: JsonParsers.asBool(
        json['is_read'] ?? json['isRead'] ?? json['read'],
      ),
      createdAt: JsonParsers.asDateTime(json['createdAt'] ?? json['date']),
    );
  }
}

class AbhaScanCheckinItem {
  final String id;
  final String tokenNumber;
  final String patientName;
  final String abhaNumber;
  final String abhaAddress;
  final String gender;
  final String dob;
  final String age;
  final String mobile;
  final String address;
  final String uhid;
  final String patientId;
  final String counterId;
  final String department;
  final String status;
  final String timeString;
  final DateTime? createdAt;

  const AbhaScanCheckinItem({
    required this.id,
    required this.tokenNumber,
    required this.patientName,
    required this.abhaNumber,
    required this.abhaAddress,
    required this.gender,
    this.dob = '',
    this.age = '',
    required this.mobile,
    this.address = '',
    this.uhid = '',
    this.patientId = '',
    this.counterId = '',
    this.department = '',
    required this.status,
    this.timeString = '',
    this.createdAt,
  });

  AbhaScanCheckinItem copyWith({
    String? status,
    String? tokenNumber,
    String? uhid,
  }) {
    return AbhaScanCheckinItem(
      id: id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      patientName: patientName,
      abhaNumber: abhaNumber,
      abhaAddress: abhaAddress,
      gender: gender,
      dob: dob,
      age: age,
      mobile: mobile,
      address: address,
      uhid: uhid ?? this.uhid,
      patientId: patientId,
      counterId: counterId,
      department: department,
      status: status ?? this.status,
      timeString: timeString,
      createdAt: createdAt,
    );
  }

  bool get isCompleted {
    final s = status.trim().toLowerCase();
    return s.contains('complet') ||
        s.contains('done') ||
        s.contains('register') ||
        s.contains('issued') ||
        s.contains('convert') ||
        s.contains('closed') ||
        s.contains('attend');
  }

  bool get isDismissed {
    final s = status.trim().toLowerCase();
    return s.contains('dismiss') ||
        s.contains('cancel') ||
        s.contains('reject') ||
        s.contains('expir') ||
        s.contains('ignore');
  }

  /// Active ABDM Scan & Share check-ins include `PENDING`, `VERIFIED`,
  /// `IDENTITY_VERIFIED`, `SHARED`, `PROFILE_SHARED`, `RECEIVED`, `WAITING`,
  /// `SCANNED`, `NEW`, `OPEN`, `ACTIVE`, `QUEUED`, `READY`, or blank status.
  bool get isPending => !isCompleted && !isDismissed;

  String get displayCode {
    final t = tokenNumber.trim();
    if (t.isEmpty) {
      final tail = id.length > 6
          ? id.substring(id.length - 6).toUpperCase()
          : id.toUpperCase();
      return tail.isEmpty ? 'CHK-ABDM' : 'CHK-$tail';
    }
    return t;
  }

  String get displayTime {
    if (timeString.trim().isNotEmpty) return timeString.trim();
    if (createdAt != null) return AppFormatters.formatTime12h(createdAt);
    return '';
  }

  String get displayAgeOrDob {
    final parts = <String>[];
    if (dob.trim().isNotEmpty) parts.add(dob.trim());
    if (age.trim().isNotEmpty) {
      final a = age.trim();
      parts.add(RegExp(r'^\d+$').hasMatch(a) ? '$a Yrs' : a);
    }
    return parts.join(' • ');
  }

  /// Returns true when a raw JSON map looks like a valid patient / ABDM check-in record
  /// rather than an unrelated wrapper/config object.
  static bool looksLikeCheckinMap(Map<String, dynamic> json) {
    if (json.isEmpty) return false;
    final flat = _flattenCheckinSources(json);
    final hasIdentity = JsonParsers.asString(
      flat['patient_name'] ??
          flat['patientName'] ??
          flat['full_name'] ??
          flat['fullName'] ??
          flat['name'] ??
          flat['first_name'] ??
          flat['firstName'] ??
          flat['abha_number'] ??
          flat['abhaNumber'] ??
          flat['abha_no'] ??
          flat['health_id_number'] ??
          flat['healthIdNumber'] ??
          flat['abha_address'] ??
          flat['abhaAddress'] ??
          flat['phr_address'] ??
          flat['phrAddress'] ??
          flat['health_id'] ??
          flat['healthId'] ??
          flat['token'] ??
          flat['token_number'] ??
          flat['tokenNumber'] ??
          flat['token_no'] ??
          flat['check_in_code'] ??
          flat['checkInCode'],
    ).isNotEmpty;
    return hasIdentity;
  }

  static Map<String, dynamic> _flattenCheckinSources(
    Map<String, dynamic> json,
  ) {
    final merged = <String, dynamic>{};

    void absorb(dynamic candidate) {
      if (candidate is Map) {
        final m = JsonParsers.asMap(candidate);
        for (final entry in m.entries) {
          if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
            merged.putIfAbsent(entry.key, () => entry.value);
          }
        }
      }
    }

    // Top-level fields win first, followed by nested ABDM `profile` / `patient` maps
    absorb(json);
    for (final key in const [
      'profile',
      'patient',
      'patient_profile',
      'patientProfile',
      'abdm_profile',
      'abdmProfile',
      'abha_profile',
      'abhaProfile',
      'demographics',
      'user',
      'data',
    ]) {
      final sub = json[key];
      if (sub is Map) {
        final subMap = JsonParsers.asMap(sub);
        absorb(subMap);
        for (final innerKey in const ['patient', 'profile', 'demographics', 'address']) {
          absorb(subMap[innerKey]);
        }
      }
    }
    return merged;
  }

  factory AbhaScanCheckinItem.fromJson(Map<String, dynamic> json) {
    final flat = _flattenCheckinSources(json);

    // Build full name from flat or split first/middle/last fields
    String resolvedName = JsonParsers.asString(
      flat['patient_name'] ??
          flat['patientName'] ??
          flat['full_name'] ??
          flat['fullName'] ??
          flat['name'],
    );
    if (resolvedName.isEmpty) {
      final first = JsonParsers.asString(
        flat['first_name'] ?? flat['firstName'],
      );
      final middle = JsonParsers.asString(
        flat['middle_name'] ?? flat['middleName'],
      );
      final last = JsonParsers.asString(
        flat['last_name'] ?? flat['lastName'] ?? flat['surname'],
      );
      resolvedName = [first, middle, last]
          .where((s) => s.trim().isNotEmpty)
          .join(' ')
          .trim();
    }
    if (resolvedName.isEmpty) {
      resolvedName = 'ABDM Patient';
    }

    // Normalize Gender (`M` -> `Male`, `F` -> `Female`, `O` -> `Other`)
    final rawGender = JsonParsers.asString(
      flat['gender'] ?? flat['sex'],
    ).trim();
    String normalizedGender = rawGender;
    final gUpper = rawGender.toUpperCase();
    if (gUpper == 'M') {
      normalizedGender = 'Male';
    } else if (gUpper == 'F') {
      normalizedGender = 'Female';
    } else if (gUpper == 'O') {
      normalizedGender = 'Other';
    }

    // Normalize DOB (`dayOfBirth`/`monthOfBirth`/`yearOfBirth` or ISO/slash string) with zero TZ shift
    String rawDob = JsonParsers.asString(
      flat['dob'] ??
          flat['date_of_birth'] ??
          flat['dateOfBirth'] ??
          flat['birth_date'] ??
          flat['birthDate'],
    );
    if (rawDob.isEmpty) {
      final y = JsonParsers.asString(
        flat['yearOfBirth'] ?? flat['year_of_birth'],
      );
      final m = JsonParsers.asString(
        flat['monthOfBirth'] ?? flat['month_of_birth'],
      );
      final d = JsonParsers.asString(
        flat['dayOfBirth'] ?? flat['day_of_birth'],
      );
      if (y.isNotEmpty && m.isNotEmpty && d.isNotEmpty) {
        rawDob = '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$y';
      } else if (y.isNotEmpty) {
        rawDob = y;
      }
    }
    final formattedDob = rawDob.contains('-') || rawDob.contains('T')
        ? JsonParsers.formatCalendarSlash(rawDob, fallback: rawDob)
        : rawDob;

    // Age (explicit or computed from DOB calendar year)
    String resolvedAge = JsonParsers.asString(
      flat['age'] ?? flat['years'] ?? flat['patient_age'],
    );
    if (resolvedAge.isEmpty && rawDob.isNotEmpty) {
      final dt = JsonParsers.asCalendarDate(rawDob);
      if (dt != null) {
        final now = DateTime.now();
        int yrs = now.year - dt.year;
        if (now.month < dt.month ||
            (now.month == dt.month && now.day < dt.day)) {
          yrs--;
        }
        if (yrs >= 0 && yrs < 130) {
          resolvedAge = '$yrs';
        }
      } else if (RegExp(r'^\d{4}$').hasMatch(rawDob.trim())) {
        final yrs = DateTime.now().year - int.parse(rawDob.trim());
        if (yrs >= 0 && yrs < 130) {
          resolvedAge = '$yrs';
        }
      }
    }

    // Normalize Address (string or nested address map)
    String resolvedAddress = '';
    final addrRaw = flat['address'];
    if (addrRaw is Map) {
      final am = JsonParsers.asMap(addrRaw);
      resolvedAddress = [
        JsonParsers.asString(am['line'] ?? am['street'] ?? am['address']),
        JsonParsers.asString(am['district'] ?? am['district_name'] ?? am['city']),
        JsonParsers.asString(am['state'] ?? am['state_name']),
        JsonParsers.asString(am['pincode'] ?? am['pin']),
      ].where((s) => s.trim().isNotEmpty).join(', ');
    } else {
      resolvedAddress = [
        JsonParsers.asString(addrRaw),
        JsonParsers.asString(
          flat['district_name'] ?? flat['districtName'] ?? flat['district'],
        ),
        JsonParsers.asString(
          flat['state_name'] ?? flat['stateName'] ?? flat['state'],
        ),
        JsonParsers.asString(flat['pincode']),
      ].where((s) => s.trim().isNotEmpty).toSet().join(', ');
    }

    final rawToken = JsonParsers.asString(
      json['token_number'] ??
          json['tokenNumber'] ??
          json['token_no'] ??
          json['tokenNo'] ??
          json['token'] ??
          json['check_in_code'] ??
          json['checkInCode'] ??
          json['checkin_code'] ??
          json['code'] ??
          json['queue_no'] ??
          json['queueNo'] ??
          json['request_no'] ??
          flat['token_number'] ??
          flat['tokenNumber'] ??
          flat['token_no'] ??
          flat['token'],
    );

    final fallbackSeed = AppFormatters.initials(resolvedName);

    return AbhaScanCheckinItem(
      id: JsonParsers.asId(
        json['_id'] ??
            json['id'] ??
            json['check_in_id'] ??
            json['checkInId'] ??
            json['checkin_id'] ??
            json['request_id'] ??
            json['requestId'] ??
            rawToken,
      ).isNotEmpty
          ? JsonParsers.asId(
              json['_id'] ??
                  json['id'] ??
                  json['check_in_id'] ??
                  json['checkInId'] ??
                  json['checkin_id'] ??
                  json['request_id'] ??
                  json['requestId'] ??
                  rawToken,
            )
          : fallbackSeed,
      tokenNumber: rawToken,
      patientName: resolvedName,
      abhaNumber: JsonParsers.asString(
        flat['abha_number'] ??
            flat['abhaNumber'] ??
            flat['abha_no'] ??
            flat['abhaNo'] ??
            flat['abha_id'] ??
            flat['abhaId'] ??
            flat['health_id_number'] ??
            flat['healthIdNumber'] ??
            flat['hidn'],
      ),
      abhaAddress: JsonParsers.asString(
        flat['abha_address'] ??
            flat['abhaAddress'] ??
            flat['phr_address'] ??
            flat['phrAddress'] ??
            flat['health_id'] ??
            flat['healthId'],
      ),
      gender: normalizedGender,
      dob: formattedDob,
      age: resolvedAge,
      mobile: JsonParsers.asString(
        flat['mobile'] ??
            flat['mobileno'] ??
            flat['mobile_no'] ??
            flat['mobileNo'] ??
            flat['phone'] ??
            flat['phoneNumber'] ??
            flat['phone_number'] ??
            flat['contact_no'] ??
            flat['contact'],
      ),
      address: resolvedAddress,
      uhid: JsonParsers.asString(
        flat['uhid'] ??
            flat['patient_unique_id'] ??
            flat['patientUniqueId'] ??
            flat['mrn'],
      ),
      patientId: JsonParsers.asId(
        json['patient_id'] ??
            json['patientId'] ??
            (json['patient'] is String ? json['patient'] : null) ??
            (json['patient'] is Map
                ? (json['patient']['_id'] ?? json['patient']['id'])
                : null),
      ),
      counterId: JsonParsers.asString(
        json['counter_id'] ??
            json['counterId'] ??
            json['counter'] ??
            flat['counter_id'] ??
            flat['counterId'],
      ),
      department: JsonParsers.asString(
        json['department'] ?? json['dept'] ?? flat['department'],
      ),
      status: JsonParsers.asString(
        json['status'] ??
            json['check_in_status'] ??
            json['checkInStatus'] ??
            json['state'],
        fallback: 'PENDING',
      ),
      timeString: JsonParsers.asString(
        json['time'] ??
            json['scan_time'] ??
            json['scanTime'] ??
            json['check_in_time'] ??
            json['checkInTime'],
      ),
      createdAt: JsonParsers.asDateTime(
        json['scanned_at'] ??
            json['scannedAt'] ??
            json['shared_at'] ??
            json['sharedAt'] ??
            json['created_at'] ??
            json['createdAt'] ??
            json['timestamp'] ??
            json['date'],
      ),
    );
  }
}

/// Hospital Counter QR configuration (`ABDM Scan & Share` -> `Hospital QR Code` — image-37)
class AbhaHospitalQrInfo {
  final String hospitalName;
  final String counterId;
  final String facilityId;
  final String qrPayload;
  final String? qrImage;

  const AbhaHospitalQrInfo({
    required this.hospitalName,
    required this.counterId,
    required this.facilityId,
    required this.qrPayload,
    this.qrImage,
  });

  factory AbhaHospitalQrInfo.fromJson(
    Map<String, dynamic> json, {
    String fallbackHospitalName = 'Smart Super Speciality Hospital',
  }) {
    final name = JsonParsers.asString(
      json['hospital_name'] ??
          json['hospitalName'] ??
          json['facility_name'] ??
          json['name'],
      fallback: fallbackHospitalName,
    );
    final counter = JsonParsers.asString(
      json['counter_id'] ?? json['counterId'] ?? json['counter'],
      fallback: 'OPD-COUNTER-1',
    );
    final facility = JsonParsers.asString(
      json['facility_id'] ??
          json['facilityId'] ??
          json['hip_id'] ??
          json['hipId'],
      fallback: 'IN0810000123',
    );
    final payload = JsonParsers.asString(
      json['qr_payload'] ??
          json['qrPayload'] ??
          json['qr_data'] ??
          json['qrData'] ??
          json['url'],
      fallback: '{"hipId":"$facility","counterId":"$counter","name":"$name"}',
    );
    final img = JsonParsers.asString(
      json['qr_image'] ?? json['qrImage'] ?? json['qr_code'] ?? json['qrCode'],
    );
    return AbhaHospitalQrInfo(
      hospitalName: name.isEmpty ? fallbackHospitalName : name,
      counterId: counter.isEmpty ? 'OPD-COUNTER-1' : counter,
      facilityId: facility.isEmpty ? 'IN0810000123' : facility,
      qrPayload: payload,
      qrImage: img.isEmpty ? null : img,
    );
  }
}
