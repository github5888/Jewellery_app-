import '../core/utils/json_parsers.dart';

class BloodBankGroupItem {
  final String id;
  final String bloodGroup;
  final String componentType;
  final int availableBags;
  final String status;

  const BloodBankGroupItem({
    required this.id,
    required this.bloodGroup,
    required this.componentType,
    required this.availableBags,
    required this.status,
  });

  factory BloodBankGroupItem.fromJson(Map<String, dynamic> json) {
    final bags = JsonParsers.asInt(
      json['available_bags'] ??
          json['bags'] ??
          json['qty'] ??
          json['quantity'] ??
          json['units'] ??
          json['count'],
    );
    return BloodBankGroupItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? json['group'] ?? json['name'],
        fallback: 'Unknown',
      ),
      componentType: JsonParsers.asString(
        json['component'] ?? json['type'] ?? json['bag_type'],
        fallback: 'Whole Blood / PRBC',
      ),
      availableBags: bags,
      status: JsonParsers.asString(
        json['status'],
        fallback: bags > 0 ? 'Available' : 'Out of Stock',
      ),
    );
  }
}

class HospitalHolidayItem {
  final String id;
  final String title;
  final String type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String createdBy;
  final bool frontSite;

  const HospitalHolidayItem({
    required this.id,
    required this.title,
    required this.type,
    this.fromDate,
    this.toDate,
    required this.createdBy,
    required this.frontSite,
  });

  factory HospitalHolidayItem.fromJson(Map<String, dynamic> json) {
    return HospitalHolidayItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      title: JsonParsers.asString(
        json['description'] ?? json['title'] ?? json['name'],
        fallback: 'Hospital Event',
      ),
      type: JsonParsers.asString(json['type'], fallback: 'Holiday'),
      fromDate: JsonParsers.asDateTime(
        json['from_date'] ?? json['date'] ?? json['holiday_date'],
      ),
      toDate: JsonParsers.asDateTime(json['to_date']),
      createdBy: JsonParsers.asString(
        json['created_by_name'] ?? json['created_by'],
        fallback: 'Hospital Administration',
      ),
      frontSite: JsonParsers.asBool(json['front_site'], fallback: true),
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
      chargeType: JsonParsers.asString(json['charge_type'], fallback: 'IPD'),
      chargeCategory: JsonParsers.asString(
        json['charge_category'],
        fallback: 'Nursing Charges',
      ),
      standardCharge: JsonParsers.asDouble(
        json['standard_charge'] ?? json['applied_charge'] ?? json['amount'],
      ),
    );
  }
}
