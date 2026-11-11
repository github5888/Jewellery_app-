import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Patient Directory Screen (`https://hospital.hrpocket.in/patients` — matches image-6 1-to-1):
/// - `Patient Directory` + `N Patients` green pill + `Disabled List` toggle
/// - Search box: `Search by name, UHID, mobile, guardian...`
/// - Filters: `All Genders`, `All Blood Groups`, `Sort: Default`
/// - Rows/Cards: `#1` index, initials circle, Patient Name, `PAT-1010` UHID, ABHA number pill if linked,
///   `32 Yrs • Male`, `8948355982` + `Shared (N)` detection, Address (`-` if empty),
///   `₹0.00` Due Balance pill, `[View]` & `[ABHA Card]` / `[ABHA]` actions.
class PatientDirectoryScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const PatientDirectoryScreen({
    super.key,
    this.isEmbeddedInShell = false,
  });

  @override
  State<PatientDirectoryScreen> createState() => _PatientDirectoryScreenState();
}

class _PatientDirectoryScreenState extends State<PatientDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedGender = 'All Genders';
  String _selectedBloodGroup = 'All Blood Groups';
  String _selectedSort = 'Default';
  bool _showDisabled = false;

  static const _genderOptions = ['All Genders', 'Male', 'Female', 'Other'];
  static const _bloodGroupOptions = [
    'All Blood Groups',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  static const _sortOptions = ['Default', 'Name (A-Z)', 'UHID', 'Age'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final allPatients = controller.patientDirectory;

    // Count shared phone numbers across all patients (matches `Shared (2)` in image-6!)
    final phoneCounts = <String, int>{};
    for (final p in allPatients) {
      final phone = p.phone.trim();
      if (phone.isNotEmpty) {
        phoneCounts[phone] = (phoneCounts[phone] ?? 0) + 1;
      }
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = allPatients.where((p) {
      if (_showDisabled != p.isDisabled) return false;

      if (_selectedGender != 'All Genders') {
        if (p.gender.toLowerCase() != _selectedGender.toLowerCase()) {
          return false;
        }
      }

      if (_selectedBloodGroup != 'All Blood Groups') {
        if (p.bloodGroup.toUpperCase() != _selectedBloodGroup.toUpperCase()) {
          return false;
        }
      }

      if (q.isNotEmpty) {
        final matches = p.patientName.toLowerCase().contains(q) ||
            p.patientUniqueId.toLowerCase().contains(q) ||
            p.phone.toLowerCase().contains(q) ||
            p.guardianName.toLowerCase().contains(q) ||
            p.abhaNumber.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    if (_selectedSort == 'Name (A-Z)') {
      filtered.sort(
        (a, b) => a.patientName.toLowerCase().compareTo(
              b.patientName.toLowerCase(),
            ),
      );
    } else if (_selectedSort == 'UHID') {
      filtered.sort((a, b) => a.patientUniqueId.compareTo(b.patientUniqueId));
    } else if (_selectedSort == 'Age') {
      filtered.sort((a, b) => b.age.compareTo(a.age));
    }

    final body = RefreshIndicator(
      color: const Color(0xFF0A4D78),
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          SoftSurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (matching image-6)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A4D78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _showDisabled
                                    ? 'Disabled Patient List'
                                    : 'Patient Directory',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${filtered.length} Patients',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Centralized hospital patient registration, UHID & ABHA records',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Disabled List toggle button (matching image-6)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _showDisabled
                          ? Colors.white
                          : const Color(0xFF334155),
                      backgroundColor: _showDisabled
                          ? const Color(0xFF0A4D78)
                          : Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () =>
                        setState(() => _showDisabled = !_showDisabled),
                    icon: Icon(
                      Icons.person_off_outlined,
                      size: 15,
                      color: _showDisabled
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                    label: Text(
                      _showDisabled ? 'Active Directory' : 'Disabled List',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Search Box (`Search by name, UHID, mobile, guardian...` — image-6)
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name, UHID, mobile, guardian...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 10),

                // Dropdown Filters Row (`All Genders`, `All Blood Groups`, `Sort: Default` — image-6)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterDropdownChip(
                        value: _selectedGender,
                        options: _genderOptions,
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                      const SizedBox(width: 8),
                      _FilterDropdownChip(
                        value: _selectedBloodGroup,
                        options: _bloodGroupOptions,
                        onChanged: (v) =>
                            setState(() => _selectedBloodGroup = v),
                      ),
                      const SizedBox(width: 8),
                      _FilterDropdownChip(
                        prefix: 'Sort: ',
                        value: _selectedSort,
                        options: _sortOptions,
                        onChanged: (v) => setState(() => _selectedSort = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  ClinicalEmptyState(
                    icon: Icons.groups_outlined,
                    title: _showDisabled
                        ? 'No Disabled Patients'
                        : 'No Patients Found',
                    subtitle: 'Try clearing filters or search terms.',
                  )
                else
                  ...List.generate(filtered.length, (idx) {
                    final patient = filtered[idx];
                    final sharedCount = phoneCounts[patient.phone.trim()] ?? 0;
                    return _PatientDirectoryCard(
                      index: idx + 1,
                      patient: patient,
                      sharedPhoneCount: sharedCount,
                      onView: () => _showPatientDetailSheet(context, patient),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) return body;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Patient Directory')),
      body: body,
    );
  }

  void _showPatientDetailSheet(
    BuildContext context,
    PatientDirectoryRecord patient,
  ) {
    final controller = NursePortalScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<PatientDirectoryRecord>(
          future: controller.api.fetchPatientDetail(patient.id),
          builder: (context, snapshot) {
            final p = snapshot.data ?? patient;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: Text(
                            p.initials,
                            style: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.patientName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${p.patientUniqueId} • ${p.age > 0 ? "${p.age} Yrs" : "-"} • ${p.gender}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    _DetailFieldRow('UHID', p.patientUniqueId),
                    _DetailFieldRow(
                      'Phone Number',
                      p.phone.isEmpty ? '-' : p.phone,
                    ),
                    _DetailFieldRow(
                      'Blood Group',
                      p.bloodGroup.isEmpty ? '-' : p.bloodGroup,
                    ),
                    _DetailFieldRow(
                      'Guardian Name',
                      p.guardianName.trim().isEmpty ? '-' : p.guardianName,
                    ),
                    _DetailFieldRow(
                      'Address',
                      p.address.trim().isEmpty ? '-' : p.address,
                    ),
                    _DetailFieldRow(
                      'ABHA Number',
                      p.hasAbha ? p.abhaNumber : 'Not Linked',
                    ),
                    if (p.abhaAddress.isNotEmpty)
                      _DetailFieldRow('ABHA Address', p.abhaAddress),
                    if (p.knownAllergies.isNotEmpty)
                      _DetailFieldRow('Known Allergies', p.knownAllergies),
                    _DetailFieldRow(
                      'Due Balance',
                      AppFormatters.formatCurrencyTwoDecimals(p.dueBalance),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterDropdownChip extends StatelessWidget {
  final String? prefix;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterDropdownChip({
    this.prefix,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: options
              .map(
                (opt) => DropdownMenuItem<String>(
                  value: opt,
                  child: Text('${prefix ?? ""}$opt'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PatientDirectoryCard extends StatelessWidget {
  final int index;
  final PatientDirectoryRecord patient;
  final int sharedPhoneCount;
  final VoidCallback onView;

  const _PatientDirectoryCard({
    required this.index,
    required this.patient,
    required this.sharedPhoneCount,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (patient.patientUniqueId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              patient.patientUniqueId,
                              style: const TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (patient.hasAbha)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '✓ ${patient.abhaNumber}',
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Due Balance Pill (`₹0.00` — image-6)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: patient.dueBalance > 0
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppFormatters.formatCurrencyTwoDecimals(patient.dueBalance),
                  style: TextStyle(
                    color: patient.dueBalance > 0
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF15803D),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Age & Gender + Phone (`Shared (2)`) + Blood Group
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${patient.age > 0 ? "${patient.age} Yrs" : "-"} • ${patient.gender}',
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (patient.phone.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      patient.phone,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sharedPhoneCount > 1) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Shared ($sharedPhoneCount)',
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (patient.bloodGroup.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    patient.bloodGroup,
                    style: const TextStyle(
                      color: Color(0xFFBE123C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Address (`-` if empty — image-6)
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13.5,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  patient.address.trim().isEmpty ? '-' : patient.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Row (`View` + `ABHA Card` / `ABHA` — image-6)
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0369A1),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  minimumSize: const Size(0, 33),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text(
                  'View',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: patient.hasAbha
                      ? const Color(0xFFDCFCE7)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: patient.hasAbha
                        ? const Color(0xFF86EFAC)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      patient.hasAbha
                          ? Icons.verified_user_outlined
                          : Icons.shield_outlined,
                      size: 14,
                      color: patient.hasAbha
                          ? const Color(0xFF15803D)
                          : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      patient.hasAbha ? 'ABHA Card' : 'ABHA Unlinked',
                      style: TextStyle(
                        color: patient.hasAbha
                            ? const Color(0xFF15803D)
                            : const Color(0xFF475569),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailFieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailFieldRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
