import '../core/utils/json_parsers.dart';

class WardBedGroup {
  final String id;
  final String name;
  final String floor;
  final String description;

  const WardBedGroup({
    required this.id,
    required this.name,
    required this.floor,
    required this.description,
  });

  factory WardBedGroup.fromJson(Map<String, dynamic> json) {
    return WardBedGroup(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      name: JsonParsers.asString(
        json['name'] ?? json['group_name'] ?? json['ward_name'],
        fallback: 'General Ward',
      ),
      floor: JsonParsers.asString(json['floor'] ?? json['floor_name']),
      description: JsonParsers.asString(json['description']),
    );
  }
}

class HospitalBed {
  final String id;
  final String name;
  final String bedGroupId;
  final String bedGroupName;
  final String bedType;
  final bool isOccupied;
  final String status;
  final String currentPatientName;
  final String currentPatientUhid;

  const HospitalBed({
    required this.id,
    required this.name,
    required this.bedGroupId,
    required this.bedGroupName,
    required this.bedType,
    required this.isOccupied,
    required this.status,
    required this.currentPatientName,
    required this.currentPatientUhid,
  });

  factory HospitalBed.fromJson(Map<String, dynamic> json) {
    final rawGroup = json['bed_group'] ?? json['bed_group_id'] ?? json['ward'];
    String groupId = '';
    String groupName = '';
    if (rawGroup is Map) {
      final gm = JsonParsers.asMap(rawGroup);
      groupId = JsonParsers.asId(gm['_id'] ?? gm['id']);
      groupName = JsonParsers.asString(gm['name'] ?? gm['group_name']);
    } else {
      groupName = JsonParsers.asString(
        json['bed_group_name'] ?? rawGroup,
        fallback: 'General Ward',
      );
      groupId = JsonParsers.asString(json['bed_group_id']);
    }

    final statusStr = JsonParsers.asString(json['status']);
    final occupiedFlag = json.containsKey('is_occupied')
        ? JsonParsers.asBool(json['is_occupied'])
        : (statusStr.toLowerCase() == 'occupied' ||
            statusStr.toLowerCase() == 'allotted' ||
            JsonParsers.asBool(json['is_active_admission']));

    final rawPatient = json['patient'] ?? json['current_patient'];
    String patName = JsonParsers.asString(json['patient_name']);
    String patUhid = JsonParsers.asString(json['patient_unique_id']);
    if (rawPatient is Map) {
      final pm = JsonParsers.asMap(rawPatient);
      if (patName.isEmpty) {
        patName = JsonParsers.asString(pm['patient_name'] ?? pm['name']);
      }
      if (patUhid.isEmpty) {
        patUhid = JsonParsers.asString(pm['patient_unique_id']);
      }
    }

    return HospitalBed(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      name: JsonParsers.asString(
        json['name'] ?? json['bed_number'] ?? json['bed_no'],
        fallback: 'Bed',
      ),
      bedGroupId: groupId,
      bedGroupName: groupName.isEmpty ? 'General Ward' : groupName,
      bedType: JsonParsers.asString(json['bed_type'] ?? json['type']),
      isOccupied: occupiedFlag,
      status: statusStr.isNotEmpty
          ? statusStr
          : (occupiedFlag ? 'Occupied' : 'Available'),
      currentPatientName: patName,
      currentPatientUhid: patUhid,
    );
  }
}
