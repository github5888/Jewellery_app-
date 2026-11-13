class JsonParsers {
  JsonParsers._();

  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    if (value is Map) {
      // Handle populated Mongoose refs & media objects seamlessly
      for (final key in const [
        'url',
        'secure_url',
        'path',
        'filePath',
        'file_path',
        'src',
        'location',
        'filename',
        'name',
        'title',
        'patient_name',
        'bed_number',
        'bed_no',
        'label',
        'code',
        '_id',
      ]) {
        final nested = value[key];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString().trim();
        }
      }
    }
    return fallback;
  }

  static String asId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is Map) {
      final raw = value['_id'] ?? value['id'];
      if (raw != null) return raw.toString().trim();
    }
    return value.toString().trim();
  }

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9.-]'), '');
      if (cleaned.isEmpty) return fallback;
      final parsedInt = int.tryParse(cleaned);
      if (parsedInt != null) return parsedInt;
      final parsedDouble = double.tryParse(cleaned);
      if (parsedDouble != null) return parsedDouble.round();
    }
    return fallback;
  }

  static double asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9.-]'), '');
      if (cleaned.isEmpty) return fallback;
      return double.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == 'yes' || v == '1' || v == 'active' || v == 'occupied') {
        return true;
      }
      if (v == 'false' || v == 'no' || v == '0' || v == 'vacant' || v == 'available') {
        return false;
      }
    }
    return fallback;
  }

  static DateTime? _parseSlashOrDashParts(String raw) {
    final dateOnly = raw.contains('T')
        ? raw.split('T').first.trim()
        : raw.split(' ').first.trim();
    final sep = dateOnly.contains('/')
        ? '/'
        : (dateOnly.contains('-') ? '-' : '');
    if (sep.isEmpty) return null;
    final parts = dateOnly.split(sep);
    if (parts.length != 3) return null;
    final p0 = int.tryParse(parts[0]);
    final p1 = int.tryParse(parts[1]);
    final p2 = int.tryParse(parts[2]);
    if (p0 == null || p1 == null || p2 == null) return null;
    // YYYY-MM-DD or YYYY/MM/DD
    if (p0 > 1900 && p1 >= 1 && p1 <= 12 && p2 >= 1 && p2 <= 31) {
      return DateTime(p0, p1, p2);
    }
    // DD-MM-YYYY or DD/MM/YYYY
    if (p2 > 1900 && p1 >= 1 && p1 <= 12 && p0 >= 1 && p0 <= 31) {
      return DateTime(p2, p1, p0);
    }
    return null;
  }

  /// Parses calendar-only dates (`dob`, `date_of_joining`, `holiday`, `roster.date`)
  /// using the exact calendar day from the server string (`YYYY-MM-DD`, `YYYY-MM-DDTHH:mm:ssZ`,
  /// `DD/MM/YYYY`, or `DD-MM-YYYY`) without shifting across midnight due to local timezone offsets.
  static DateTime? asCalendarDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    if (value is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        value < 10000000000 ? value * 1000 : value,
        isUtc: true,
      );
      return DateTime(dt.year, dt.month, dt.day);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final lower = trimmed.toLowerCase();
      if (lower == 'null' || lower == 'undefined' || lower == 'n/a') {
        return null;
      }
      final exact = _parseSlashOrDashParts(trimmed);
      if (exact != null) return exact;
      final direct = DateTime.tryParse(trimmed);
      if (direct != null) {
        return DateTime(direct.year, direct.month, direct.day);
      }
    }
    return null;
  }

  /// Formats any raw calendar date string (`1994-12-31T18:30:00.000Z`, `1994-12-31`,
  /// `31-12-1994`, `31/12/1994`, or year `1994`) into `DD/MM/YYYY` matching the React web portal.
  static String formatCalendarSlash(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final parsed = asCalendarDate(value);
    if (parsed != null) {
      final dd = parsed.day.toString().padLeft(2, '0');
      final mm = parsed.month.toString().padLeft(2, '0');
      return '$dd/$mm/${parsed.year}';
    }
    final raw = asString(value);
    if (raw.isEmpty) return fallback;
    final lower = raw.toLowerCase();
    if (lower == 'null' || lower == 'undefined' || lower == 'none') {
      return fallback;
    }
    return raw;
  }

  static DateTime? asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value < 10000000000 ? value * 1000 : value,
      );
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final direct = DateTime.tryParse(trimmed);
      if (direct != null) return direct.toLocal();
      final partsDt = _parseSlashOrDashParts(trimmed);
      if (partsDt != null) return partsDt;
    }
    return null;
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asMapList(dynamic value) {
    if (value is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map) {
        out.add(asMap(item));
      }
    }
    return out;
  }

  /// Extracts a list payload from common MERN response envelopes:
  /// - `[...]`
  /// - `{ status: 1, data: [...] }`
  /// - `{ status: 1, data: { records/items/patients/ipd/opd/beds/assignments/holidays/bills: [...] } }`
  static List<Map<String, dynamic>> extractList(
    dynamic body, {
    List<String> candidateKeys = const [
      'data',
      'records',
      'items',
      'results',
      'list',
      'rows',
      'patients',
      'ipd',
      'admissions',
      'ipdAdmissions',
      'ipd_admissions',
      'opd',
      'visits',
      'encounters',
      'opdVisits',
      'opd_visits',
      'beds',
      'groups',
      'bedGroups',
      'wards',
      'assignments',
      'rosters',
      'shifts',
      'holidays',
      'events',
      'bills',
      'reports',
      'tests',
      'pathology',
      'pathologyBills',
      'pathology_bills',
      'radiology',
      'radiologyBills',
      'radiology_bills',
      'pharmacy',
      'pharmacyBills',
      'pharmacy_bills',
      'bloodBank',
      'bloodGroups',
      'blood_groups',
      'bags',
      'donors',
      'issues',
      'bloodIssues',
      'blood_issues',
      'status',
      'medicines',
      'stocks',
      'inventory',
      'units',
      'charges',
      'services',
      'orders',
      'serviceOrders',
      'service_orders',
      'appointments',
      'staff',
      'staffs',
      'users',
      'members',
      'notifications',
      'messages',
      'checkins',
      'check_ins',
      'checkInRequests',
      'check_in_requests',
      'abdmCheckins',
      'abdm_checkins',
      'abhaCheckins',
      'abha_checkins',
      'scanShareRequests',
      'scan_share_requests',
      'scanShare',
      'scan_share',
      'pendingRequests',
      'pending_requests',
      'sharedProfiles',
      'shared_profiles',
      'profiles',
      'requests',
      'tokens',
      'queue',
      'ambulances',
      'calls',
      'ambulanceCalls',
      'visitors',
      'invoices',
      'payments',
      'transactions',
      'births',
      'deaths',
    ],
  }) {
    if (body is List) return asMapList(body);
    if (body is Map) {
      final map = asMap(body);
      List<Map<String, dynamic>>? emptyFallback;

      // 1. Prefer non-empty candidate list on top-level map
      for (final key in candidateKeys) {
        final v = map[key];
        if (v is List) {
          final parsed = asMapList(v);
          if (parsed.isNotEmpty) return parsed;
          emptyFallback ??= parsed;
        }
      }

      // 2. Prefer non-empty list inside nested `data` / `result` / `payload` map
      for (final wrapperKey in const ['data', 'result', 'payload', 'response']) {
        final nestedData = map[wrapperKey];
        if (nestedData is Map) {
          final nestedMap = asMap(nestedData);
          for (final key in candidateKeys) {
            final v = nestedMap[key];
            if (v is List) {
              final parsed = asMapList(v);
              if (parsed.isNotEmpty) return parsed;
              emptyFallback ??= parsed;
            }
          }
          for (final val in nestedMap.values) {
            if (val is List) {
              final parsed = asMapList(val);
              if (parsed.isNotEmpty) return parsed;
              emptyFallback ??= parsed;
            }
          }
        }
      }

      // 3. Prefer any non-empty list anywhere on top-level map
      for (final val in map.values) {
        if (val is List) {
          final parsed = asMapList(val);
          if (parsed.isNotEmpty) return parsed;
          emptyFallback ??= parsed;
        }
      }

      if (emptyFallback != null) return emptyFallback;
    }
    return const [];
  }

  /// Extracts a single object payload from `{ status: 1, data: {...} }` or `{...}`.
  static Map<String, dynamic> extractObject(dynamic body) {
    if (body is! Map) return <String, dynamic>{};
    final map = asMap(body);
    final inner = map['data'];
    if (inner is Map) {
      return asMap(inner);
    }
    return map;
  }
}
