import '../core/utils/formatters.dart';
import '../core/utils/json_parsers.dart';

/// Section 10: Nurse Shift & Duty Roster Variables (`GET /api/dutyroster`)
/// Matches Website `/duty-roster` Screenshot 725 (`Dr. Ajay Verma`, `#9002`, `Doctor`, `2026-11-11`, `morning`, `08:00 AM - 02:00 PM`, `6.00 Hrs`, `Cardiology`, `Ground Floor`).
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

    final roleStr = JsonParsers.asString(
      json['role'] ??
          json['role_name'] ??
          staffMap['role_name'] ??
          staffMap['role'] ??
          staffMap['designation'],
    );

    String resolvedStaffName = JsonParsers.asString(
      json['staff_name'] ?? json['member_name'] ?? json['name'],
      fallback: combinedStaff,
    );
    if (resolvedStaffName.isNotEmpty &&
        roleStr.toLowerCase().contains('doctor')) {
      resolvedStaffName = AppFormatters.formatDoctorName(resolvedStaffName);
    }

    final rawDate =
        json['date'] ?? json['duty_date'] ?? json['roster_date'] ?? json['shift_date'];
    final parsedDt = JsonParsers.asDateTime(rawDate);
    String dateStr = JsonParsers.asString(rawDate);
    if (dateStr.contains('T')) {
      dateStr = dateStr.split('T').first;
    }

    final rawHours = json['shift_hour'] ??
        json['shift_hours'] ??
        json['hours'] ??
        json['total_hours'] ??
        shiftMap['hours'] ??
        shiftMap['shift_hour'];
    String hoursLabel = JsonParsers.asString(rawHours);
    if (hoursLabel.isNotEmpty &&
        !hoursLabel.toLowerCase().contains('hr')) {
      final numVal = double.tryParse(hoursLabel);
      hoursLabel = numVal != null
          ? '${numVal.toStringAsFixed(2)} Hrs'
          : '$hoursLabel Hrs';
    }

    return DutyShiftAssignment(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      staffId: JsonParsers.asId(
        json['staff_id'] ?? staffMap['_id'] ?? json['staff'],
      ),
      staffCode: JsonParsers.asString(
        json['employee_id'] ??
            json['staff_code'] ??
            staffMap['employee_id'] ??
            staffMap['staff_id'],
      ),
      staffName: resolvedStaffName.isNotEmpty ? resolvedStaffName : 'Staff Member',
      role: roleStr,
      date: dateStr,
      parsedDate: parsedDt,
      shiftName: JsonParsers.asString(
        json['shift_name'] ??
            shiftMap['name'] ??
            json['shift_type'] ??
            json['shift'],
        fallback: 'Shift',
      ),
      shiftStart: JsonParsers.asString(
        json['shift_start'] ??
            shiftMap['start_time'] ??
            shiftMap['shift_start'] ??
            json['start_time'],
      ),
      shiftEnd: JsonParsers.asString(
        json['shift_end'] ??
            shiftMap['end_time'] ??
            shiftMap['shift_end'] ??
            json['end_time'],
      ),
      shiftHour: hoursLabel,
      department: JsonParsers.asString(
        json['department'] ?? staffMap['department'],
      ),
      floor: JsonParsers.asString(
        json['floor'] ??
            json['station'] ??
            json['assigned_station'] ??
            json['ward'] ??
            shiftMap['floor'],
      ),
    );
  }
}
