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
      // Support DD/MM/YYYY format if returned by formatted endpoints
      final slashParts = trimmed.split('/');
      if (slashParts.length == 3) {
        final d = int.tryParse(slashParts[0]);
        final m = int.tryParse(slashParts[1]);
        final y = int.tryParse(slashParts[2].split(' ').first);
        if (d != null && m != null && y != null && y > 1900) {
          return DateTime(y, m, d);
        }
      }
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
      'patients',
      'ipd',
      'admissions',
      'opd',
      'visits',
      'beds',
      'groups',
      'bedGroups',
      'assignments',
      'rosters',
      'shifts',
      'holidays',
      'events',
      'bills',
      'reports',
      'tests',
      'bloodBank',
      'bloodGroups',
      'blood_groups',
      'bags',
      'donors',
      'issues',
      'status',
      'medicines',
      'stocks',
      'inventory',
      'units',
      'charges',
      'appointments',
      'staff',
      'staffs',
      'notifications',
      'messages',
      'checkins',
      'queue',
      'scanShare',
      'ambulances',
      'calls',
      'visitors',
      'invoices',
      'births',
      'deaths',
    ],
  }) {
    if (body is List) return asMapList(body);
    if (body is Map) {
      final map = asMap(body);
      for (final key in candidateKeys) {
        final v = map[key];
        if (v is List) return asMapList(v);
      }
      final nestedData = map['data'];
      if (nestedData is Map) {
        final nestedMap = asMap(nestedData);
        for (final key in candidateKeys) {
          final v = nestedMap[key];
          if (v is List) return asMapList(v);
        }
      }
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
