import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ipd_models.dart';
import '../../models/opd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/status_badge.dart';
import '../vitals/record_vitals_screen.dart';
import 'ipd_patient_detail_screen.dart';
import 'patient_directory_screen.dart';

enum _PatientsFilter { all, inWard, consultation, discharged }

class MyPatientsScreen extends StatefulWidget {
  final bool isEmbeddedInTab;

  const MyPatientsScreen({
    super.key,
    this.isEmbeddedInTab = false,
  });

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  final _searchCtrl = TextEditingController();
  _PatientsFilter _filter = _PatientsFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();

    final inWardList = controller.admittedPatients.where((ipd) {
      if (query.isEmpty) return true;
      return ipd.patient.patientName.toLowerCase().contains(query) ||
          ipd.patient.patientUniqueId.toLowerCase().contains(query) ||
          ipd.ipdNo.toLowerCase().contains(query) ||
          ipd.bed.toLowerCase().contains(query) ||
          ipd.bedGroup.toLowerCase().contains(query) ||
          ipd.doctor.displayName.toLowerCase().contains(query);
    }).toList();

    final consultationList = controller.opdQueue.where((opd) {
      if (query.isEmpty) return true;
      return opd.patient.patientName.toLowerCase().contains(query) ||
          opd.patient.patientUniqueId.toLowerCase().contains(query) ||
          opd.opdNo.toLowerCase().contains(query) ||
          opd.doctorName.toLowerCase().contains(query);
    }).toList();

    final dischargedFiltered = controller.dischargedPatients.where((ipd) {
      if (query.isEmpty) return true;
      return ipd.patient.patientName.toLowerCase().contains(query) ||
          ipd.patient.patientUniqueId.toLowerCase().contains(query) ||
          ipd.ipdNo.toLowerCase().contains(query);
    }).toList();

    final totalCombinedCount =
        controller.admittedPatients.length + controller.opdQueue.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedInTab,
        title: const Text('My Patients'),
        actions: [
          IconButton(
            tooltip: 'Hospital Patient Directory',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PatientDirectoryScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.recent_actors_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (matching image-2.png)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search patient, UHID, bed, doctor...',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded, size: 18),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Filter Chips (`All (N)`, `In Ward`, `Consultation`, `Discharged`)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                _FilterPill(
                  label: 'All ($totalCombinedCount)',
                  selected: _filter == _PatientsFilter.all,
                  onTap: () => setState(() => _filter = _PatientsFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'In Ward (${controller.admittedPatients.length})',
                  selected: _filter == _PatientsFilter.inWard,
                  onTap: () => setState(() => _filter = _PatientsFilter.inWard),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Consultation (${controller.opdQueue.length})',
                  selected: _filter == _PatientsFilter.consultation,
                  onTap: () =>
                      setState(() => _filter = _PatientsFilter.consultation),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Discharged (${controller.dischargedPatients.length})',
                  selected: _filter == _PatientsFilter.discharged,
                  onTap: () =>
                      setState(() => _filter = _PatientsFilter.discharged),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Patient Cards List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.refreshWorkspace(),
              child: _buildFilteredList(
                context: context,
                controller: controller,
                inWard: inWardList,
                consultations: consultationList,
                discharged: dischargedFiltered,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList({
    required BuildContext context,
    required NursePortalController controller,
    required List<IpdAdmission> inWard,
    required List<OpdVisitRecord> consultations,
    required List<IpdAdmission> discharged,
  }) {
    if (_filter == _PatientsFilter.discharged) {
      if (discharged.isEmpty) {
        return ListView(
          children: [
            ClinicalEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No Discharged IPD Records Found',
              subtitle:
                  'Discharged in-patient records from /api/ipd will appear here.',
              actionLabel: 'Refresh',
              onAction: () => controller.refreshWorkspace(),
            ),
          ],
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        itemCount: discharged.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) => _IpdPatientCard(
          ipd: discharged[idx],
          baseUrl: controller.baseUrl,
        ),
      );
    }

    final showInWard =
        _filter == _PatientsFilter.all || _filter == _PatientsFilter.inWard;
    final showConsult = _filter == _PatientsFilter.all ||
        _filter == _PatientsFilter.consultation;

    final items = <Widget>[];
    if (showInWard) {
      for (final ipd in inWard) {
        items.add(
          _IpdPatientCard(ipd: ipd, baseUrl: controller.baseUrl),
        );
      }
    }
    if (showConsult) {
      for (final opd in consultations) {
        items.add(
          _OpdPatientCard(opd: opd, baseUrl: controller.baseUrl),
        );
      }
    }

    if (items.isEmpty) {
      return ListView(
        children: [
          ClinicalEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No Matching Patients',
            subtitle: _searchCtrl.text.isNotEmpty
                ? 'Try clearing your search filter.'
                : 'No active patients returned in this category right now.',
            actionLabel: 'Refresh Live Data',
            onAction: () => controller.refreshWorkspace(),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) => items[idx],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IpdPatientCard extends StatelessWidget {
  final IpdAdmission ipd;
  final String baseUrl;

  const _IpdPatientCard({required this.ipd, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IpdPatientDetailScreen(
              ipdId: ipd.id,
              initialAdmission: ipd,
            ),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          PatientAvatar(
            name: ipd.patient.patientName,
            imagePath: ipd.patient.image,
            baseUrl: baseUrl,
            radius: 25,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ipd.patient.patientName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ipd.patient.patientUniqueId.isNotEmpty
                      ? ipd.patient.patientUniqueId
                      : ipd.ipdNo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ipd.wardAndBedLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (ipd.patient.hasAllergyAlert) ...[
                  const SizedBox(height: 4),
                  StatusBadge(
                    label: 'Allergy: ${ipd.patient.knownAllergies}',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(label: ipd.clinicalStatusLabel),
              const SizedBox(height: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 21,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpdPatientCard extends StatelessWidget {
  final OpdVisitRecord opd;
  final String baseUrl;

  const _OpdPatientCard({required this.opd, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecordVitalsScreen(opdVisit: opd),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          PatientAvatar(
            name: opd.patient.patientName,
            imagePath: opd.patient.image,
            baseUrl: baseUrl,
            radius: 25,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opd.patient.patientName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (opd.patient.patientUniqueId.isNotEmpty)
                      opd.patient.patientUniqueId,
                    opd.opdNo,
                  ].join(' • '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'OPD • ${opd.doctorName}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                label: opd.hasVitalsRecorded ? 'Vitals Done' : 'Vitals Pending',
              ),
              const SizedBox(height: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 21,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
