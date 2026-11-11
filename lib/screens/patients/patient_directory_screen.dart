import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Native Mobile Patient Directory Screen (`GET /api/patients`):
/// - Clean `MobileScreenHeader` (`Patient Directory`, `N Patients`, `Disabled List` toggle)
/// - Tactile search bar (`Search by name, UHID, mobile, guardian...`)
/// - Filter pills (`All Genders`, `All Blood Groups`, `Sort: Default`)
/// - Crisp floating white cards with `#1` index, initials, UHID, ABHA pill, Age/Gender,
///   Phone + `Shared (N)` detection, Address, `₹0.00` Due Balance, `View` & `ABHA` status.
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
    final primary = controller.personalTheme.primaryColor;
    final allPatients = controller.patientDirectory;

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
      if (_selectedGender != 'All Genders' &&
          p.gender.toLowerCase() != _selectedGender.toLowerCase()) {
        return false;
      }
      if (_selectedBloodGroup != 'All Blood Groups' &&
          p.bloodGroup.toUpperCase() != _selectedBloodGroup.toUpperCase()) {
        return false;
      }
      if (q.isNotEmpty) {
        return p.patientName.toLowerCase().contains(q) ||
            p.patientUniqueId.toLowerCase().contains(q) ||
            p.phone.toLowerCase().contains(q) ||
            p.guardianName.toLowerCase().contains(q) ||
            p.abhaNumber.toLowerCase().contains(q);
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

    final listContent = RefreshIndicator(
      color: primary,
      onRefresh: () => controller.refreshWorkspace(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (widget.isEmbeddedInShell)
            MobileScreenHeader(
              title: _showDisabled ? 'Disabled Patients' : 'Patients',
              subtitle: 'UHID directory, ABHA & patient records',
              countBadge: '${filtered.length}',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _showDisabled = !_showDisabled),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: _showDisabled ? primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showDisabled ? primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 16,
                        color: _showDisabled
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showDisabled ? 'Active' : 'Disabled',
                        style: TextStyle(
                          color: _showDisabled
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Search Box
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, UHID, mobile, guardian...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: primary),
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

          // Filter Dropdown Pills
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
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
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
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.groups_outlined,
                title: _showDisabled
                    ? 'No Disabled Patients'
                    : 'No Patients Found',
                subtitle: 'Try clearing filters or search terms.',
              ),
            )
          else
            ...List.generate(filtered.length, (idx) {
              final patient = filtered[idx];
              final sharedCount = phoneCounts[patient.phone.trim()] ?? 0;
              return _PatientDirectoryCard(
                index: idx + 1,
                patient: patient,
                sharedPhoneCount: sharedCount,
                primaryColor: primary,
                onView: () => _showPatientDetailSheet(context, patient),
              );
            }),
        ],
      ),
    );

    if (widget.isEmbeddedInShell) {
      return SafeArea(bottom: false, child: listContent);
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Patient Directory')),
      body: listContent,
    );
  }

  void _showPatientDetailSheet(
    BuildContext context,
    PatientDirectoryRecord patient,
  ) {
    final controller = NursePortalScope.read(context);
    final primary = controller.personalTheme.primaryColor;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return FutureBuilder<PatientDirectoryRecord>(
          future: controller.api.fetchPatientDetail(patient.id),
          builder: (context, snapshot) {
            final p = snapshot.data ?? patient;

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primary.withAlpha(22),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            p.initials,
                            style: TextStyle(
                              color: primary,
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
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${p.patientUniqueId}  •  ${p.age > 0 ? "${p.age} Yrs" : "-"}  •  ${p.gender}',
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
                );
              },
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
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
          style: const TextStyle(
            color: AppColors.textPrimary,
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
  final Color primaryColor;
  final VoidCallback onView;

  const _PatientDirectoryCard({
    required this.index,
    required this.patient,
    required this.sharedPhoneCount,
    required this.primaryColor,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftSurfaceCard(
        onTap: onView,
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    patient.initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$index  ',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              patient.patientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                patient.patientUniqueId,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
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
                                color: AppColors.successSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ABHA • ${patient.abhaNumber}',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: patient.dueBalance > 0
                        ? AppColors.dangerSoft
                        : AppColors.successSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppFormatters.formatCurrencyTwoDecimals(patient.dueBalance),
                    style: TextStyle(
                      color: patient.dueBalance > 0
                          ? AppColors.danger
                          : const Color(0xFF059669),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Text(
                    '${patient.age > 0 ? "${patient.age} Yrs" : "-"} • ${patient.gender}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (patient.phone.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        patient.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (sharedPhoneCount > 1) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Shared ($sharedPhoneCount)',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const Spacer(),
                  Text(
                    'View ›',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _DetailFieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailFieldRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
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
