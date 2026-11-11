import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

class _EndpointSpec {
  final String method;
  final String label;
  final String fullUrl;
  final bool canProbeGet;

  const _EndpointSpec({
    required this.method,
    required this.label,
    required this.fullUrl,
    this.canProbeGet = true,
  });
}

/// Displays every full Smart Hospital Nurse Portal API URL (`https://hospital.hrpocket.in/api/...`)
/// and runs live diagnostic checks against the authenticated backend.
class ApiConnectionsScreen extends StatefulWidget {
  const ApiConnectionsScreen({super.key});

  @override
  State<ApiConnectionsScreen> createState() => _ApiConnectionsScreenState();
}

class _ApiConnectionsScreenState extends State<ApiConnectionsScreen> {
  final Map<String, ({bool ok, String detail})> _results = {};
  bool _testing = false;

  List<_EndpointSpec> _buildSpecs(BuildContext context) {
    final ep = NursePortalScope.read(context).api.endpoints;
    final sampleIpdId = NursePortalScope.read(context).admittedPatients.isNotEmpty
        ? NursePortalScope.read(context).admittedPatients.first.id
        : ':id';

    return [
      _EndpointSpec(method: 'GET', label: 'Server Healthcheck', fullUrl: ep.health),
      _EndpointSpec(
        method: 'POST',
        label: 'Nurse Login',
        fullUrl: ep.authLogin,
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Nurse Profile & Hospital',
        fullUrl: ep.authMe,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Nurse Home Census Dashboard',
        fullUrl: ep.dashboard,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'All IPD Admissions & Discharges',
        fullUrl: ep.ipdList,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Bedside Digital Patient Chart',
        fullUrl: ep.ipdDetail(sampleIpdId),
        canProbeGet: sampleIpdId != ':id',
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Record IPD Bedside Vitals',
        fullUrl: ep.ipdVitals(sampleIpdId),
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Daily Shift Nurse Progress Note',
        fullUrl: ep.ipdNurseNotes(sampleIpdId),
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Medication Administration (MAR)',
        fullUrl: ep.ipdAdministerPrescription(sampleIpdId, ':prescriptionId'),
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Patient Bed Transfer / Shift',
        fullUrl: ep.ipdTransferBed(sampleIpdId),
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'PUT',
        label: 'Pre-Discharge Nursing Checklist',
        fullUrl: ep.ipdDischargeChecklist(sampleIpdId),
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Nursing Procedures / Charge Log',
        fullUrl: ep.ipdCharges(sampleIpdId),
        canProbeGet: false,
      ),
      _EndpointSpec(method: 'GET', label: 'All Hospital Beds', fullUrl: ep.beds),
      _EndpointSpec(
        method: 'GET',
        label: 'Wards / Bed Groups',
        fullUrl: ep.bedGroups,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'OPD Waiting Triage Queue',
        fullUrl: ep.opdList,
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Record OPD Triage Vitals',
        fullUrl: ep.opdVitals(':id'),
        canProbeGet: false,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Nurse Duty Roster & Shifts',
        fullUrl: ep.dutyRoster,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Patient Master Directory',
        fullUrl: ep.patients,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'ABHA Scan & Share Check-ins',
        fullUrl: ep.abhaScanShare,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Pathology Lab Reports',
        fullUrl: ep.pathology,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Radiology Scan Reports',
        fullUrl: ep.radiology,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Appointments Schedule',
        fullUrl: ep.appointments,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Doctors & Staff Directory',
        fullUrl: ep.staff,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Pharmacy Stock',
        fullUrl: ep.pharmacy,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Ward Consumables Inventory',
        fullUrl: ep.inventory,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Blood Bank Status',
        fullUrl: ep.bloodBank,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Annual Holiday Calendar',
        fullUrl: ep.holidays,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Hospital Charge Master',
        fullUrl: ep.charges,
      ),
      _EndpointSpec(
        method: 'GET',
        label: 'Notifications & Alerts',
        fullUrl: ep.notifications,
      ),
      _EndpointSpec(
        method: 'POST',
        label: 'Clinical Attachment Upload',
        fullUrl: ep.uploads,
        canProbeGet: false,
      ),
    ];
  }

  Future<void> _runDiagnostics() async {
    final specs = _buildSpecs(context);
    final api = NursePortalScope.read(context).api;
    setState(() => _testing = true);

    for (final spec in specs) {
      if (!spec.canProbeGet) {
        _results[spec.fullUrl] = (ok: true, detail: 'Action Endpoint Linked');
        continue;
      }
      final res = await api.probeEndpoint(spec.fullUrl);
      if (!mounted) return;
      setState(() {
        _results[spec.fullUrl] = res;
      });
    }

    if (mounted) {
      setState(() => _testing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDiagnostics());
  }

  @override
  Widget build(BuildContext context) {
    final specs = _buildSpecs(context);
    final controller = NursePortalScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Full Live API Links'),
        actions: [
          IconButton(
            tooltip: 'Re-test All Endpoints',
            onPressed: _testing ? null : _runDiagnostics,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        itemCount: specs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) {
          if (idx == 0) {
            return SoftSurfaceCard(
              color: const Color(0xFFEAF3FE),
              child: Row(
                children: [
                  const Icon(Icons.hub_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected Server: ${controller.baseUrl}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Socket.IO Events: ipd:new_admission • ipd:vitals_recorded • ipd:medication_administered (${controller.socketConnected ? "Live" : "Standby"})',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final spec = specs[idx - 1];
          final probe = _results[spec.fullUrl];

          return SoftSurfaceCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: spec.method == 'GET'
                            ? AppColors.infoSoft
                            : (spec.method == 'PUT'
                                ? AppColors.warningSoft
                                : AppColors.successSoft),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        spec.method,
                        style: TextStyle(
                          color: spec.method == 'GET'
                              ? AppColors.primary
                              : (spec.method == 'PUT'
                                  ? AppColors.warning
                                  : AppColors.success),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spec.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (probe != null)
                      StatusBadge(label: probe.ok ? 'Linked' : 'Error'),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  spec.fullUrl,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (probe != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    probe.detail,
                    style: TextStyle(
                      color:
                          probe.ok ? AppColors.textSecondary : AppColors.danger,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
