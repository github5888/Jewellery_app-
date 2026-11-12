import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/ipd_models.dart';
import '../models/opd_models.dart';
import '../models/patient_directory_model.dart';
import '../screens/patients/ipd_patient_detail_screen.dart';
import '../screens/patients/patient_detail_screen.dart';
import '../screens/vitals/record_vitals_screen.dart';
import '../state/nurse_portal_controller.dart';
import 'patient_avatar.dart';
import 'status_badge.dart';

/// Opens the live Global Search (`Search Name / Mobile / UHID...`) matching the
/// top header search bar & Dashboard search box on `https://hospital.hrpocket.in`.
Future<void> showGlobalHospitalSearchSheet(
  BuildContext context, {
  String initialQuery = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _GlobalSearchSheetBody(initialQuery: initialQuery),
  );
}

class _GlobalSearchSheetBody extends StatefulWidget {
  final String initialQuery;

  const _GlobalSearchSheetBody({required this.initialQuery});

  @override
  State<_GlobalSearchSheetBody> createState() => _GlobalSearchSheetBodyState();
}

class _GlobalSearchSheetBodyState extends State<_GlobalSearchSheetBody> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final q = _ctrl.text.trim().toLowerCase();

    final matchedIpd = controller.admittedPatients.where((ipd) {
      if (q.isEmpty) return true;
      return ipd.patient.patientName.toLowerCase().contains(q) ||
          ipd.patient.patientUniqueId.toLowerCase().contains(q) ||
          ipd.patient.mobileNo.toLowerCase().contains(q) ||
          ipd.ipdNo.toLowerCase().contains(q) ||
          ipd.bed.toLowerCase().contains(q) ||
          ipd.bedGroup.toLowerCase().contains(q) ||
          ipd.doctor.displayName.toLowerCase().contains(q);
    }).toList();

    final matchedOpd = controller.opdQueue.where((opd) {
      if (q.isEmpty) return false;
      return opd.patient.patientName.toLowerCase().contains(q) ||
          opd.patient.patientUniqueId.toLowerCase().contains(q) ||
          opd.patient.mobileNo.toLowerCase().contains(q) ||
          opd.opdNo.toLowerCase().contains(q) ||
          opd.caseReferenceId.toLowerCase().contains(q) ||
          opd.doctorName.toLowerCase().contains(q);
    }).toList();

    final matchedPatients = controller.patientDirectory.where((p) {
      if (q.isEmpty) return true;
      return p.patientName.toLowerCase().contains(q) ||
          p.patientUniqueId.toLowerCase().contains(q) ||
          p.phone.toLowerCase().contains(q) ||
          p.abhaNumber.toLowerCase().contains(q);
    }).take(15).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search Name / Mobile / UHID / IPD / OPD / Doctor...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (matchedIpd.isNotEmpty) ...[
                    _SectionLabel('Admitted In-Patients (${matchedIpd.length})'),
                    ...matchedIpd.map(
                      (IpdAdmission ipd) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        leading: PatientAvatar(
                          name: ipd.patient.patientName,
                          imagePath: ipd.patient.image,
                          baseUrl: controller.baseUrl,
                          radius: 20,
                        ),
                        title: Text(
                          ipd.patient.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${ipd.ipdNo} • ${ipd.patient.patientUniqueId} • ${ipd.wardAndBedLabel}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const StatusBadge(label: 'IPD Chart'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IpdPatientDetailScreen(
                                ipdId: ipd.id,
                                initialAdmission: ipd,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (matchedOpd.isNotEmpty) ...[
                    _SectionLabel('OPD Consultations (${matchedOpd.length})'),
                    ...matchedOpd.take(10).map(
                      (OpdVisitRecord opd) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        leading: PatientAvatar(
                          name: opd.patient.patientName,
                          imagePath: opd.patient.image,
                          baseUrl: controller.baseUrl,
                          radius: 20,
                        ),
                        title: Text(
                          opd.patient.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${opd.opdNo} • ${opd.doctorName} • ${opd.statusCategory}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const StatusBadge(label: 'OPD Vitals'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecordVitalsScreen(opdVisit: opd),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (matchedPatients.isNotEmpty) ...[
                    _SectionLabel(
                      'Patient Directory (${matchedPatients.length})',
                    ),
                    ...matchedPatients.map(
                      (PatientDirectoryRecord p) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        leading: PatientAvatar(
                          name: p.patientName,
                          imagePath: p.image,
                          baseUrl: controller.baseUrl,
                          radius: 20,
                        ),
                        title: Text(
                          p.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (p.patientUniqueId.isNotEmpty) p.patientUniqueId,
                            if (p.phone.isNotEmpty) p.phone,
                            if (p.age > 0) '${p.age} Yrs',
                            p.gender,
                          ].join(' • '),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          nav.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientDetailScreen(initialPatient: p),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (matchedIpd.isEmpty &&
                      matchedOpd.isEmpty &&
                      matchedPatients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'No matching patients, IPD, or OPD records found.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
