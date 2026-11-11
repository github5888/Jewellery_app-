import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Executive Mobile Patient Directory Screen (`GET /api/patients`):
/// - Studio-lit `PremiumScreenBackground` + `MobileScreenHeader`
/// - `PremiumSearchField` (`Search by name, UHID, mobile, guardian...`)
/// - Elevated pill filter selectors (`All Genders`, `All Blood Groups`, `Sort`)
/// - Sculpted Patient Pass Cards with monogram avatar, UHID pill, Blood Group ruby badge,
///   ABHA verification pill, Shared-Phone detection, Due Balance pill, and Profile Sheet.
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
              title: _showDisabled ? 'Archived Patients' : 'Patient Registry',
              subtitle: 'UHID directory, ABHA & clinical records',
              countBadge: '${filtered.length}',
              trailingAction: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _showDisabled = !_showDisabled),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _showDisabled ? primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _showDisabled ? primary : AppColors.border,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showDisabled
                            ? Icons.check_circle_outline_rounded
                            : Icons.person_off_outlined,
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Elevated Pill Search Bar
          PremiumSearchField(
            controller: _searchCtrl,
            accentColor: primary,
            hintText: 'Search name, UHID, mobile or guardian...',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Elevated Filter Dropdown Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterDropdownChip(
                  icon: Icons.wc_rounded,
                  value: _selectedGender,
                  options: _genderOptions,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(width: 8),
                _FilterDropdownChip(
                  icon: Icons.water_drop_outlined,
                  value: _selectedBloodGroup,
                  options: _bloodGroupOptions,
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                ),
                const SizedBox(width: 8),
                _FilterDropdownChip(
                  icon: Icons.swap_vert_rounded,
                  prefix: 'Sort: ',
                  value: _selectedSort,
                  options: _sortOptions,
                  onChanged: (v) => setState(() => _selectedSort = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            SoftSurfaceCard(
              child: ClinicalEmptyState(
                icon: Icons.groups_outlined,
                title: _showDisabled
                    ? 'No Disabled Patient Records'
                    : 'No Matching Patients Found',
                subtitle: 'Try clearing active filters or search terms.',
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
      return PremiumScreenBackground(
        accentColor: primary,
        child: SafeArea(bottom: false, child: listContent),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Patient Registry')),
      body: PremiumScreenBackground(
        accentColor: primary,
        child: listContent,
      ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: FutureBuilder<PatientDirectoryRecord>(
            future: controller.api.fetchPatientDetail(patient.id),
            builder: (context, snapshot) {
              final p = snapshot.data ?? patient;

              return DraggableScrollableSheet(
                initialChildSize: 0.74,
                minChildSize: 0.5,
                maxChildSize: 0.92,
                expand: false,
                builder: (_, scrollCtrl) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary, primary.withAlpha(190)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                p.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.patientName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${p.patientUniqueId}  •  ${p.age > 0 ? "${p.age} Yrs" : "-"}  •  ${p.gender}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
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
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(),
                        ),
                      const SizedBox(height: 16),
                      _DetailFieldRow('UHID', p.patientUniqueId),
                      _DetailFieldRow(
                        'Mobile Number',
                        p.phone.isEmpty ? '—' : p.phone,
                      ),
                      _DetailFieldRow(
                        'Blood Group',
                        p.bloodGroup.isEmpty ? '—' : p.bloodGroup,
                      ),
                      _DetailFieldRow(
                        'Guardian Name',
                        p.guardianName.trim().isEmpty ? '—' : p.guardianName,
                      ),
                      _DetailFieldRow(
                        'Residential Address',
                        p.address.trim().isEmpty ? '—' : p.address,
                      ),
                      _DetailFieldRow(
                        'ABHA Health ID',
                        p.hasAbha ? p.abhaNumber : 'Not Linked',
                      ),
                      if (p.abhaAddress.isNotEmpty)
                        _DetailFieldRow('ABHA Address', p.abhaAddress),
                      if (p.knownAllergies.isNotEmpty)
                        _DetailFieldRow('Known Allergies', p.knownAllergies),
                      _DetailFieldRow(
                        'Outstanding Balance',
                        AppFormatters.formatCurrencyTwoDecimals(p.dueBalance),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterDropdownChip extends StatelessWidget {
  final IconData icon;
  final String? prefix;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterDropdownChip({
    required this.icon,
    this.prefix,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = NursePortalScope.of(context).personalTheme.primaryColor;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: primary),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 17),
              ),
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
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftSurfaceCard(
        onTap: onView,
        padding: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withAlpha(32),
                        primaryColor.withAlpha(12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withAlpha(38)),
                  ),
                  child: Text(
                    patient.initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$index ',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularNums,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              patient.patientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (patient.patientUniqueId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7.5,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha(16),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                patient.patientUniqueId,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: AppTheme.tabularNums,
                                ),
                              ),
                            ),
                          if (patient.bloodGroup.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                patient.bloodGroup,
                                style: const TextStyle(
                                  color: Color(0xFFBE123C),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          if (patient.hasAbha)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successSoft,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                '✓ ABHA Linked',
                                style: TextStyle(
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: patient.dueBalance > 0
                        ? AppColors.dangerSoft
                        : AppColors.successSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppFormatters.formatCurrencyTwoDecimals(patient.dueBalance),
                    style: TextStyle(
                      color: patient.dueBalance > 0
                          ? AppColors.danger
                          : const Color(0xFF059669),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: AppTheme.tabularNums,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
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
                      Icons.phone_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        patient.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularNums,
                        ),
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
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(6),
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
                    'Details ›',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
