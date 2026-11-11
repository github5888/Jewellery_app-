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

  static List<BloodBankGroupItem> _orderByStandardGroups(
    List<BloodBankGroupItem> items,
  ) {
    final byGroup = <String, BloodBankGroupItem>{};
    for (final item in items) {
      byGroup[item.bloodGroup.toUpperCase()] = item;
    }
    final ordered = <BloodBankGroupItem>[];
    for (final g in standardGroups) {
      if (byGroup.containsKey(g)) {
        ordered.add(byGroup.remove(g)!);
      }
    }
    ordered.addAll(byGroup.values);
    return ordered;
  }
}

/// Blood Donor Details (`[Donor Details]` button on `/admin/bloodbankstatus` image-9)
class BloodDonorRecord {
  final String id;
  final String donorName;
  final String bloodGroup;
  final String gender;
  final int age;
  final String contactNo;
  final DateTime? lastDonationDate;

  const BloodDonorRecord({
    required this.id,
    required this.donorName,
    required this.bloodGroup,
    required this.gender,
    required this.age,
    required this.contactNo,
    this.lastDonationDate,
  });

  factory BloodDonorRecord.fromJson(Map<String, dynamic> json) {
    return BloodDonorRecord(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      donorName: JsonParsers.asString(
        json['donor_name'] ?? json['donorName'] ?? json['name'],
        fallback: 'Donor',
      ),
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? json['bloodGroup'],
        fallback: '—',
      ),
      gender: JsonParsers.asString(json['gender'], fallback: '—'),
      age: JsonParsers.asInt(json['age']),
      contactNo: JsonParsers.asString(
        json['contact_no'] ?? json['contactNo'] ?? json['phone'] ?? json['mobileno'],
      ),
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
      fromDate: JsonParsers.asDateTime(
        json['from_date'] ??
            json['fromDate'] ??
            json['date'] ??
            json['start_date'] ??
            json['startDate'] ??
            json['holiday_date'],
      ),
      toDate: JsonParsers.asDateTime(
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
  final String mobile;
  final String status;
  final DateTime? createdAt;

  const AbhaScanCheckinItem({
    required this.id,
    required this.tokenNumber,
    required this.patientName,
    required this.abhaNumber,
    required this.abhaAddress,
    required this.gender,
    required this.mobile,
    required this.status,
    this.createdAt,
  });

  bool get isPending {
    final s = status.trim().toLowerCase();
    return s.isEmpty ||
        s == 'pending' ||
        s == 'waiting' ||
        s == 'queued' ||
        s == 'scanned';
  }

  factory AbhaScanCheckinItem.fromJson(Map<String, dynamic> json) {
    final rawDoc = AppFormatters.initials(
      JsonParsers.asString(json['patient_name'] ?? json['name']),
    );
    return AbhaScanCheckinItem(
      id: JsonParsers.asId(json['_id'] ?? json['id'] ?? rawDoc),
      tokenNumber: JsonParsers.asString(
        json['token_no'] ?? json['tokenNo'] ?? json['token'] ?? json['queue_no'],
      ),
      patientName: JsonParsers.asString(
        json['patient_name'] ?? json['patientName'] ?? json['name'],
        fallback: 'ABHA Check-in',
      ),
      abhaNumber: JsonParsers.asString(
        json['abha_number'] ?? json['abhaNumber'] ?? json['abha_no'],
      ),
      abhaAddress: JsonParsers.asString(
        json['abha_address'] ?? json['abhaAddress'],
      ),
      gender: JsonParsers.asString(json['gender']),
      mobile: JsonParsers.asString(
        json['mobile'] ?? json['mobileno'] ?? json['phone'],
      ),
      status: JsonParsers.asString(json['status'], fallback: 'pending'),
      createdAt: JsonParsers.asDateTime(json['createdAt'] ?? json['date']),
    );
  }
}
