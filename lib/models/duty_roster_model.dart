import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';

/// Nurse Shift & Duty Roster (`GET /api/dutyroster` — matches Website `/duty-roster` image-10)
class DutyShiftAssignment {
  final String id;
  final String staffId;
  final String staffCode;
  final String staffName;
  final String role;
  final String date;
  final DateTime? parsedDate;
  final String shiftName;
  final String shiftStart;
  final String shiftEnd;
  final String shiftHour;
  final String department;
  final String floor;

  const DutyShiftAssignment({
    required this.id,
    required this.staffId,
    required this.staffCode,
    required this.staffName,
    required this.role,
    required this.date,
    this.parsedDate,
    required this.shiftName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.shiftHour,
    required this.department,
    required this.floor,
  });

  String get initials => AppFormatters.initials(staffName);

  String get shiftCategory {
    final s = shiftName.trim().toLowerCase();
    if (s.contains('morn')) return 'morning';
    if (s.contains('even') || s.contains('after')) return 'evening';
    return 'night_general';
  }

  String get timeRangeLabel {
    if (shiftStart.isNotEmpty && shiftEnd.isNotEmpty) {
      return '$shiftStart - $shiftEnd';
    }
    if (shiftStart.isNotEmpty) return shiftStart;
    return '';
  }

  static int? _parseMinutesOfDay(String raw) {
    final s = raw.trim().toUpperCase();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$').firstMatch(s);
    if (m == null) return null;
    int hh = int.parse(m.group(1)!);
    final mm = int.parse(m.group(2)!);
    final ampm = m.group(3);
    if (ampm == 'PM' && hh < 12) hh += 12;
    if (ampm == 'AM' && hh == 12) hh = 0;
    return hh * 60 + mm;
  }

  static String _computeHours(String start, String end) {
    final s = _parseMinutesOfDay(start);
    final e = _parseMinutesOfDay(end);
    if (s == null || e == null) return '';
    int diff = e - s;
    if (diff <= 0) diff += 24 * 60;
    return '${(diff / 60.0).toStringAsFixed(2)} Hrs';
  }

  factory DutyShiftAssignment.fromJson(Map<String, dynamic> json) {
    final staffMap = json['staff'] is Map
        ? JsonParsers.asMap(json['staff'])
        : <String, dynamic>{};
    final shiftMap = json['shift'] is Map
        ? JsonParsers.asMap(json['shift'])
        : <String, dynamic>{};

    final staffFirst = JsonParsers.asString(staffMap['name']);
    final staffLast = JsonParsers.asString(staffMap['surname']);
    final combinedStaff = '$staffFirst $staffLast'.trim();

    final roleStr = JsonParsers.asString(
      json['role'] ??
          json['roleName'] ??
          json['role_name'] ??
          staffMap['role_name'] ??
          staffMap['role'] ??
          staffMap['designation'],
    );

    String resolvedStaffName = JsonParsers.asString(
      json['staff_name'] ??
          json['staffName'] ??
          json['member_name'] ??
          json['name'],
      fallback: combinedStaff,
    );
    if (resolvedStaffName.isNotEmpty &&
        roleStr.toLowerCase().contains('doctor')) {
      resolvedStaffName = AppFormatters.formatDoctorName(resolvedStaffName);
    }

    final rawDate = json['date'] ??
        json['duty_date'] ??
        json['dutyDate'] ??
        json['roster_date'] ??
        json['rosterDate'] ??
        json['shift_date'];
    final parsedDt = JsonParsers.asDateTime(rawDate);
    String dateStr = JsonParsers.asString(rawDate);
    if (dateStr.contains('T')) {
      dateStr = dateStr.split('T').first;
    } else if (dateStr.isEmpty && parsedDt != null) {
      dateStr = AppFormatters.formatIsoDate(parsedDt);
    }

    final startStr = JsonParsers.asString(
      json['shift_start'] ??
          json['shiftStart'] ??
          json['start_time'] ??
          json['startTime'] ??
          shiftMap['start_time'] ??
          shiftMap['startTime'] ??
          shiftMap['shift_start'],
    );
    final endStr = JsonParsers.asString(
      json['shift_end'] ??
          json['shiftEnd'] ??
          json['end_time'] ??
          json['endTime'] ??
          shiftMap['end_time'] ??
          shiftMap['endTime'] ??
          shiftMap['shift_end'],
    );

    final rawHours = json['shift_hour'] ??
        json['shiftHour'] ??
        json['shift_hours'] ??
        json['shiftHours'] ??
        json['hours'] ??
        json['total_hours'] ??
        json['totalHours'] ??
        shiftMap['hours'] ??
        shiftMap['shift_hour'];
    String hoursLabel = JsonParsers.asString(rawHours);
    if (hoursLabel.isNotEmpty) {
      if (!hoursLabel.toLowerCase().contains('hr')) {
        final numVal = double.tryParse(hoursLabel);
        hoursLabel = numVal != null
            ? '${numVal.toStringAsFixed(2)} Hrs'
            : '$hoursLabel Hrs';
      }
    } else {
      hoursLabel = _computeHours(startStr, endStr);
    }

    return DutyShiftAssignment(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      staffId: JsonParsers.asId(
        json['staff_id'] ??
            json['staffId'] ??
            staffMap['_id'] ??
            json['staff'],
      ),
      staffCode: JsonParsers.asString(
        json['employee_id'] ??
            json['employeeId'] ??
            json['staff_code'] ??
            json['staffCode'] ??
            staffMap['employee_id'] ??
            staffMap['staff_id'],
      ),
      staffName: resolvedStaffName.isNotEmpty ? resolvedStaffName : '—',
      role: roleStr,
      date: dateStr,
      parsedDate: parsedDt,
      shiftName: JsonParsers.asString(
        json['shift_name'] ??
            json['shiftName'] ??
            shiftMap['name'] ??
            json['shift_type'] ??
            json['shiftType'] ??
            json['shift'],
        fallback: 'Shift',
      ),
      shiftStart: startStr,
      shiftEnd: endStr,
      shiftHour: hoursLabel,
      department: JsonParsers.asString(
        json['department'] ?? staffMap['department'],
      ),
      floor: JsonParsers.asString(
        json['floor'] ??
            json['station'] ??
            json['assigned_station'] ??
            json['assignedStation'] ??
            json['location'] ??
            json['ward'] ??
            shiftMap['floor'],
      ),
    );
  }
}
