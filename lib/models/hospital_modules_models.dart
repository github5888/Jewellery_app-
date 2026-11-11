import '../core/utils/formatters.dart';
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

class HospitalAppointmentItem {
  final String id;
  final String appointmentNo;
  final String patientName;
  final String patientUniqueId;
  final String doctorName;
  final String department;
  final DateTime? date;
  final String slot;
  final String status;
  final String message;

  const HospitalAppointmentItem({
    required this.id,
    required this.appointmentNo,
    required this.patientName,
    required this.patientUniqueId,
    required this.doctorName,
    required this.department,
    this.date,
    required this.slot,
    required this.status,
    required this.message,
  });

  factory HospitalAppointmentItem.fromJson(Map<String, dynamic> json) {
    final patMap = json['patient'] is Map
        ? JsonParsers.asMap(json['patient'])
        : <String, dynamic>{};
    final docMap = json['doctor'] is Map
        ? JsonParsers.asMap(json['doctor'])
        : <String, dynamic>{};

    final rawDoc = JsonParsers.asString(
      docMap['name'] ?? json['doctor_name'] ?? json['doctor'],
    );
    final rawDocSur = JsonParsers.asString(docMap['surname']);

    return HospitalAppointmentItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      appointmentNo: JsonParsers.asString(
        json['appointment_no'] ?? json['app_no'],
      ),
      patientName: JsonParsers.asString(
        json['patient_name'] ?? patMap['patient_name'] ?? patMap['name'],
        fallback: 'Patient',
      ),
      patientUniqueId: JsonParsers.asString(
        json['patient_unique_id'] ?? patMap['patient_unique_id'],
      ),
      doctorName: rawDoc.isNotEmpty
          ? AppFormatters.formatDoctorName(rawDoc, rawDocSur)
          : 'Consultant',
      department: JsonParsers.asString(
        json['department'] ?? docMap['department'],
      ),
      date: JsonParsers.asDateTime(
        json['date'] ?? json['appointment_date'] ?? json['createdAt'],
      ),
      slot: JsonParsers.asString(
        json['slot'] ?? json['time_slot'] ?? json['shift'],
      ),
      status: JsonParsers.asString(
        json['appointment_status'] ?? json['status'],
        fallback: 'Scheduled',
      ),
      message: JsonParsers.asString(json['message'] ?? json['symptoms']),
    );
  }
}

class StaffDirectoryMember {
  final String id;
  final String employeeId;
  final String fullName;
  final String role;
  final String designation;
  final String department;
  final String specialist;
  final String phone;
  final String email;
  final String? image;

  const StaffDirectoryMember({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.role,
    required this.designation,
    required this.department,
    required this.specialist,
    required this.phone,
    required this.email,
    this.image,
  });

  factory StaffDirectoryMember.fromJson(Map<String, dynamic> json) {
    final first = JsonParsers.asString(json['name']);
    final last = JsonParsers.asString(json['surname']);
    final role = JsonParsers.asString(
      json['role_name'] ?? json['role'],
      fallback: 'Staff',
    );
    final rawFull = '$first $last'.trim();
    final formattedName = role.toLowerCase().contains('doctor')
        ? AppFormatters.formatDoctorName(first, last)
        : (rawFull.isNotEmpty ? rawFull : 'Hospital Staff');
    final img = JsonParsers.asString(json['image'] ?? json['photo']);

    return StaffDirectoryMember(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      employeeId: JsonParsers.asString(
        json['employee_id'] ?? json['staff_id'],
      ),
      fullName: formattedName,
      role: role,
      designation: JsonParsers.asString(json['designation']),
      department: JsonParsers.asString(json['department']),
      specialist: JsonParsers.asString(json['specialist']),
      phone: JsonParsers.asString(
        json['contact_no'] ?? json['mobileno'] ?? json['phone'],
      ),
      email: JsonParsers.asString(json['email']),
      image: img.isEmpty ? null : img,
    );
  }
}

class PharmacyMedicineItem {
  final String id;
  final String medicineName;
  final String category;
  final String company;
  final String unit;
  final int availableQty;
  final double salePrice;

  const PharmacyMedicineItem({
    required this.id,
    required this.medicineName,
    required this.category,
    required this.company,
    required this.unit,
    required this.availableQty,
    required this.salePrice,
  });

  factory PharmacyMedicineItem.fromJson(Map<String, dynamic> json) {
    return PharmacyMedicineItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      medicineName: JsonParsers.asString(
        json['medicine_name'] ?? json['name'] ?? json['bill_no'],
        fallback: 'Pharmacy Item',
      ),
      category: JsonParsers.asString(
        json['medicine_category'] ?? json['category'],
        fallback: 'General',
      ),
      company: JsonParsers.asString(
        json['medicine_company'] ?? json['company'],
      ),
      unit: JsonParsers.asString(json['unit'], fallback: 'Units'),
      availableQty: JsonParsers.asInt(
        json['available_qty'] ?? json['total_qty'] ?? json['quantity'] ?? json['qty'],
      ),
      salePrice: JsonParsers.asDouble(
        json['sale_price'] ?? json['mrp'] ?? json['net_amount'] ?? json['total'],
      ),
    );
  }
}

class InventoryStockItem {
  final String id;
  final String itemName;
  final String category;
  final int quantity;
  final String supplier;

  const InventoryStockItem({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.supplier,
  });

  factory InventoryStockItem.fromJson(Map<String, dynamic> json) {
    return InventoryStockItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      itemName: JsonParsers.asString(
        json['item_name'] ?? json['name'] ?? json['item'],
        fallback: 'Ward Supply',
      ),
      category: JsonParsers.asString(
        json['item_category'] ?? json['category'],
        fallback: 'Consumables',
      ),
      quantity: JsonParsers.asInt(
        json['available_quantity'] ?? json['quantity'] ?? json['qty'],
      ),
      supplier: JsonParsers.asString(json['supplier'] ?? json['store']),
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
      isRead: JsonParsers.asBool(json['is_read'] ?? json['read']),
      createdAt: JsonParsers.asDateTime(json['createdAt'] ?? json['date']),
    );
  }
}
