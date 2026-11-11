import '../core/utils/json_parsers.dart';

/// Section 10: Nurse Shift & Duty Roster Variables (`GET /api/dutyroster` / `/api/duty-rosters/assignments`)
class DutyShiftAssignment {
  final String id;
  final String staffId;
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

  String get timeRangeLabel {
    if (shiftStart.isNotEmpty && shiftEnd.isNotEmpty) {
      return '$shiftStart - $shiftEnd';
    }
    if (shiftStart.isNotEmpty) return shiftStart;
    return shiftHour;
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

    final dateStr = JsonParsers.asString(
      json['date'] ?? json['duty_date'] ?? json['roster_date'],
    );

    return DutyShiftAssignment(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      staffId: JsonParsers.asId(
        json['staff_id'] ?? staffMap['_id'] ?? json['staff'],
      ),
      staffName: JsonParsers.asString(
        json['staff_name'],
        fallback: combinedStaff.isNotEmpty ? combinedStaff : 'Duty Staff',
      ),
      role: JsonParsers.asString(
        json['role'] ?? json['role_name'] ?? staffMap['role_name'] ?? staffMap['designation'],
        fallback: 'Nurse',
      ),
      date: dateStr,
      parsedDate: JsonParsers.asDateTime(dateStr),
      shiftName: JsonParsers.asString(
        json['shift_name'] ?? shiftMap['name'] ?? json['shift_type'] ?? json['shift'],
        fallback: 'General Shift',
      ),
      shiftStart: JsonParsers.asString(
        json['shift_start'] ?? shiftMap['start_time'] ?? json['start_time'],
      ),
      shiftEnd: JsonParsers.asString(
        json['shift_end'] ?? shiftMap['end_time'] ?? json['end_time'],
      ),
      shiftHour: JsonParsers.asString(
        json['shift_hour'] ?? json['shift_hours'] ?? shiftMap['hours'],
      ),
      department: JsonParsers.asString(
        json['department'] ?? staffMap['department'],
        fallback: 'Ward',
      ),
      floor: JsonParsers.asString(
        json['floor'] ?? json['station'] ?? json['assigned_station'],
      ),
    );
  }
}
