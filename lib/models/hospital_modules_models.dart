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
          json['count'] ??
          json['available'],
    );
    return BloodBankGroupItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      bloodGroup: JsonParsers.asString(
        json['blood_group'] ?? json['group'] ?? json['name'],
        fallback: 'Unknown',
      ),
      componentType: JsonParsers.asString(
        json['component'] ?? json['type'] ?? json['bag_type'],
        fallback: 'Blood / PRBC',
      ),
      availableBags: bags,
      status: JsonParsers.asString(
        json['status'],
        fallback: bags > 0 ? 'Available' : '0 Bags',
      ),
    );
  }

  /// Parses any real backend `/api/blood-bank` response shape:
  /// 1. List of group summaries (`[{ blood_group: 'A+', available_bags: 4 }]`)
  /// 2. List of individual blood bag records (`[{ blood_group: 'A+', bag_no: '101', status: 'Available' }]`)
  /// 3. Key-value summary map (`{ "A+": 4, "B+": 2, ... }`)
  static List<BloodBankGroupItem> parseFlexible(dynamic raw) {
    final list = JsonParsers.extractList(raw);
    if (list.isNotEmpty) {
      // Check if items represent individual bags (have bag_no/donor and no aggregate count field)
      final looksLikeIndividualBags = list.any(
        (m) =>
            (m.containsKey('bag_no') || m.containsKey('donor')) &&
            !m.containsKey('available_bags') &&
            !m.containsKey('bags') &&
            !m.containsKey('count'),
      );
      if (looksLikeIndividualBags) {
        final grouped = <String, int>{};
        for (final bag in list) {
          final grp = JsonParsers.asString(
            bag['blood_group'] ?? bag['group'],
          );
          if (grp.isEmpty) continue;
          final st = JsonParsers.asString(bag['status']).toLowerCase();
          final available = st.isEmpty ||
              st == 'available' ||
              st == 'in stock' ||
              st == 'active';
          grouped[grp] = (grouped[grp] ?? 0) + (available ? 1 : 0);
        }
        return grouped.entries
            .map(
              (e) => BloodBankGroupItem(
                id: e.key,
                bloodGroup: e.key,
                componentType: 'Blood / Component Bags',
                availableBags: e.value,
                status: e.value > 0 ? 'Available' : '0 Bags',
              ),
            )
            .toList();
      }
      return list.map(BloodBankGroupItem.fromJson).toList();
    }

    final obj = JsonParsers.extractObject(raw);
    const stdGroups = <String>[
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
    ];
    final mapSource = obj['stock'] is Map
        ? JsonParsers.asMap(obj['stock'])
        : (obj['groups'] is Map ? JsonParsers.asMap(obj['groups']) : obj);
    final extracted = <BloodBankGroupItem>[];
    for (final grp in stdGroups) {
      if (mapSource.containsKey(grp)) {
        final v = mapSource[grp];
        final cnt = v is Map
            ? JsonParsers.asInt(v['available'] ?? v['bags'] ?? v['count'])
            : JsonParsers.asInt(v);
        extracted.add(
          BloodBankGroupItem(
            id: grp,
            bloodGroup: grp,
            componentType: 'Blood Units',
            availableBags: cnt,
            status: cnt > 0 ? 'Available' : '0 Bags',
          ),
        );
      }
    }
    return extracted;
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

class AbhaScanCheckinItem {
  final String id;
  final String tokenNumber;
  final String patientName;
  final String abhaNumber;
  final String abhaAddress;
  final String gender;
  final String mobile;
  final String status; // pending | checked_in | completed
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
    return AbhaScanCheckinItem(
      id: JsonParsers.asId(json['_id'] ?? json['id']),
      tokenNumber: JsonParsers.asString(
        json['token_no'] ?? json['token'] ?? json['queue_no'],
      ),
      patientName: JsonParsers.asString(
        json['patient_name'] ?? json['name'],
        fallback: 'ABHA Patient',
      ),
      abhaNumber: JsonParsers.asString(json['abha_number'] ?? json['abha_no']),
      abhaAddress: JsonParsers.asString(json['abha_address']),
      gender: JsonParsers.asString(json['gender']),
      mobile: JsonParsers.asString(
        json['mobile'] ?? json['mobileno'] ?? json['phone'],
      ),
      status: JsonParsers.asString(json['status'], fallback: 'pending'),
      createdAt: JsonParsers.asDateTime(json['createdAt'] ?? json['date']),
    );
  }
}
