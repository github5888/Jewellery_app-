import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/bed_models.dart';
import '../../models/ipd_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';
import '../patients/ipd_patient_detail_screen.dart';

/// Executive Ward Bed Matrix Screen (`GET /api/beds` & `GET /api/beds/groups`)
/// Includes live `+ Add Ward` (`POST /api/beds/groups` — image-24) and
/// `+ Add Bed` (`POST /api/beds` — image-25) modals.
class BedStatusScreen extends StatefulWidget {
  const BedStatusScreen({super.key});

  @override
  State<BedStatusScreen> createState() => _BedStatusScreenState();
}

class _BedStatusScreenState extends State<BedStatusScreen> {
  String _selectedGroup = 'All';
  String _availabilityFilter = 'All';

  Future<void> _openAddWardModal() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddWardDialog(),
    );
    if (created == true && mounted) {
      await NursePortalScope.read(context).refreshWorkspace();
    }
  }

  Future<void> _openAddBedModal() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddHospitalBedDialog(),
    );
    if (created == true && mounted) {
      await NursePortalScope.read(context).refreshWorkspace();
    }
  }

  IpdAdmission? _findAdmittedPatientForBed(
    HospitalBed bed,
    List<IpdAdmission> admittedPatients,
  ) {
    if (!bed.isOccupied) return null;
    for (final ipd in admittedPatients) {
      if (bed.id.isNotEmpty && ipd.bedId == bed.id) return ipd;
      if (bed.name.isNotEmpty &&
          ipd.bed.trim().toLowerCase() == bed.name.trim().toLowerCase()) {
        return ipd;
      }
      if (bed.currentPatientUhid.isNotEmpty &&
          ipd.patient.patientUniqueId.trim().toLowerCase() ==
              bed.currentPatientUhid.trim().toLowerCase()) {
        return ipd;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final primary = controller.personalTheme.primaryColor;
    final beds = controller.beds;

    final groupNames = <String>{
      'All',
      ...controller.bedGroups.map((g) => g.name),
      ...beds.map((b) => b.bedGroupName),
    }.where((n) => n.trim().isNotEmpty).toList();

    if (!groupNames.contains(_selectedGroup)) {
      _selectedGroup = 'All';
    }

    final filtered = beds.where((b) {
      if (_selectedGroup != 'All' && b.bedGroupName != _selectedGroup) {
        return false;
      }
      if (_availabilityFilter == 'Vacant' && b.isOccupied) return false;
      if (_availabilityFilter == 'Occupied' && !b.isOccupied) return false;
      return true;
    }).toList();

    final totalCount =
        beds.isNotEmpty ? beds.length : controller.totalBedsCount;
    final occCount = beds.isNotEmpty
        ? beds.where((b) => b.isOccupied).length
        : controller.occupiedBedsCount;
    final vacCount = beds.isNotEmpty
        ? beds.where((b) => !b.isOccupied).length
        : controller.availableBedsCount;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Ward Bed Matrix')),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: RefreshIndicator(
          color: primary,
          onRefresh: () => controller.refreshWorkspace(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              // 3-Up Sculpted Bed Telemetry Strip
              Row(
                children: [
                  Expanded(
                    child: _BedStatTile(
                      label: 'Total Beds',
                      value: '$totalCount',
                      colors: [primary, primary.withAlpha(200)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BedStatTile(
                      label: 'Vacant',
                      value: '$vacCount',
                      colors: const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BedStatTile(
                      label: 'Occupied',
                      value: '$occCount',
                      colors: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // `+ Add Ward` & `+ Add Bed` Action Row (matches Website `/bed-status` image-24 & 25)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        side: BorderSide(color: primary.withAlpha(90)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: _openAddWardModal,
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text(
                        'Add Ward',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: _openAddBedModal,
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text(
                        'Add Bed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Ward Filter Capsule Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: groupNames.map((g) {
                    final active = _selectedGroup == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _selectedGroup = g),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active ? primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color:
                                  active ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: ['All', 'Vacant', 'Occupied'].map((f) {
                  final active = _availabilityFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _availabilityFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6.5,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? primary.withAlpha(20)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: active ? primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              if (filtered.isEmpty)
                const SoftSurfaceCard(
                  child: ClinicalEmptyState(
                    icon: Icons.bed_outlined,
                    title: 'No Beds Matched Filter',
                    subtitle:
                        'No hospital beds matched your current ward/status selection.',
                  ),
                )
              else
                ...filtered.map((HospitalBed b) {
                  final matchedIpd = _findAdmittedPatientForBed(
                    b,
                    controller.admittedPatients,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftSurfaceCard(
                      padding: const EdgeInsets.all(15),
                      borderRadius: BorderRadius.circular(20),
                      onTap: matchedIpd == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => IpdPatientDetailScreen(
                                    ipdId: matchedIpd.id,
                                    initialAdmission: matchedIpd,
                                  ),
                                ),
                              );
                            },
                      child: Row(
                        children: [
                          GradientIconBadge(
                            icon: Icons.hotel_rounded,
                            colors: b.isOccupied
                                ? const [Color(0xFFF43F5E), Color(0xFFBE123C)]
                                : const [Color(0xFF10B981), Color(0xFF047857)],
                            size: 42,
                            iconSize: 20,
                            radius: 13,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    b.bedGroupName,
                                    if (b.bedType.isNotEmpty) b.bedType,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (b.currentPatientName.isNotEmpty ||
                                    matchedIpd != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Patient: ${b.currentPatientName.isNotEmpty ? b.currentPatientName : matchedIpd!.patient.patientName}'
                                    '${(b.currentPatientUhid.isNotEmpty ? b.currentPatientUhid : matchedIpd?.patient.patientUniqueId ?? "").isNotEmpty ? " (${b.currentPatientUhid.isNotEmpty ? b.currentPatientUhid : matchedIpd!.patient.patientUniqueId})" : ""}',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: b.isOccupied ? 'Occupied' : 'Available',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _BedStatTile extends StatelessWidget {
  final String label;
  final String value;
  final List<Color> colors;

  const _BedStatTile({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GradientIconBadge(
                icon: Icons.hotel_rounded,
                colors: colors,
                size: 32,
                iconSize: 16,
                radius: 10,
              ),
              Text(
                value,
                style: TextStyle(
                  color: colors.last,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  fontFeatures: AppTheme.tabularNums,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL 1: `+ Add Ward / Bed Group` (matches Website image-24)
// =============================================================================

class _AddWardDialog extends StatefulWidget {
  const _AddWardDialog();

  @override
  State<_AddWardDialog> createState() => _AddWardDialogState();
}

class _AddWardDialogState extends State<_AddWardDialog> {
  final _wardNameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController(text: 'Ground Floor');
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _wardNameCtrl.dispose();
    _floorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final wardName = _wardNameCtrl.text.trim();
    final floor = _floorCtrl.text.trim();

    if (wardName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Ward Name.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (floor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Floor / Wing.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await NursePortalScope.read(context).api.createWardBedGroup(
            name: wardName,
            floor: floor,
            description: _descCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ward "$wardName" added successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save ward: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerTeal = Color(0xFF005B7F);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner (`+ Add Ward / Bed Group`)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              color: headerTeal,
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Add Ward / Bed Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ward Name *',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _wardNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'e.g. VIP Ward or Pediatric Ward',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Floor / Wing *',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _floorCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Ground Floor',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Optional ward notes or unit details...',
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(84, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(112, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Ward',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MODAL 2: `+ Add Hospital Bed` (matches Website image-25)
// =============================================================================

class _AddHospitalBedDialog extends StatefulWidget {
  const _AddHospitalBedDialog();

  @override
  State<_AddHospitalBedDialog> createState() => _AddHospitalBedDialogState();
}

class _AddHospitalBedDialogState extends State<_AddHospitalBedDialog> {
  static const List<String> _defaultBedTypes = [
    'Standard',
    'ICU',
    'Ventilator',
    'VIP',
    'Private',
    'Semi-Private',
    'Emergency',
    'General',
  ];

  final _bedNameCtrl = TextEditingController();
  String _selectedBedType = 'Standard';
  String? _selectedWardKey;
  List<WardBedGroup> _liveWards = const [];
  bool _loadingWards = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWards());
  }

  @override
  void dispose() {
    _bedNameCtrl.dispose();
    super.dispose();
  }

  String _wardKey(WardBedGroup g) => g.id.isNotEmpty ? g.id : g.name;

  Future<void> _loadWards() async {
    final controller = NursePortalScope.read(context);
    List<WardBedGroup> wards = List<WardBedGroup>.from(controller.bedGroups);
    try {
      final fresh = await controller.api.fetchBedGroups();
      if (fresh.isNotEmpty) {
        wards = fresh;
      }
    } catch (_) {}

    // Fallback to wards derived from existing beds if `bedGroups` endpoint returned empty
    if (wards.isEmpty) {
      final seen = <String>{};
      for (final b in controller.beds) {
        final name = b.bedGroupName.trim();
        if (name.isNotEmpty && seen.add(name.toLowerCase())) {
          wards.add(
            WardBedGroup(
              id: b.bedGroupId,
              name: name,
              floor: '',
              description: '',
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _liveWards = wards;
        _loadingWards = false;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final bedName = _bedNameCtrl.text.trim();

    if (bedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Bed Name / Code.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    WardBedGroup? chosenWard;
    if (_selectedWardKey != null) {
      for (final w in _liveWards) {
        if (_wardKey(w) == _selectedWardKey) {
          chosenWard = w;
          break;
        }
      }
    }

    if (chosenWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Bed Group / Ward.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await NursePortalScope.read(context).api.createHospitalBed(
            name: bedName,
            bedType: _selectedBedType,
            ward: chosenWard,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hospital bed "$bedName" saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save bed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerTeal = Color(0xFF005B7F);
    final controller = NursePortalScope.of(context);

    final bedTypeSet = <String>{
      ..._defaultBedTypes,
      ...controller.beds.map((b) => b.bedType.trim()).where((s) => s.isNotEmpty),
    }.toList();
    if (!bedTypeSet.contains(_selectedBedType)) {
      _selectedBedType = bedTypeSet.first;
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner (`+ Add Hospital Bed`)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
              color: headerTeal,
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Add Hospital Bed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bed Name / Code *',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bedNameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ICU-Bed-05 or GMW-105',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Bed Type',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedBedType,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    items: bedTypeSet
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedBedType = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bed Group / Ward *',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!_loadingWards && _liveWards.isEmpty)
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () async {
                            final added = await showDialog<bool>(
                              context: context,
                              builder: (_) => const _AddWardDialog(),
                            );
                            if (added == true) {
                              await _loadWards();
                            }
                          },
                          child: const Text('+ Add Ward First'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_loadingWards)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(minHeight: 2.5),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedWardKey,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      hint: const Text('-- Select Ward --'),
                      items: _liveWards
                          .map(
                            (w) => DropdownMenuItem<String>(
                              value: _wardKey(w),
                              child: Text(
                                w.floor.isNotEmpty
                                    ? '${w.name} (${w.floor})'
                                    : w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedWardKey = v),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(84, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(112, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Bed',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
