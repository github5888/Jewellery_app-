import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/status_badge.dart';

class PatientDirectoryScreen extends StatefulWidget {
  const PatientDirectoryScreen({super.key});

  @override
  State<PatientDirectoryScreen> createState() => _PatientDirectoryScreenState();
}

class _PatientDirectoryScreenState extends State<PatientDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _genderFilter = 'All';
  String _bloodFilter = 'All';

  List<PatientDirectoryRecord> _patients = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await NursePortalScope.read(context)
          .api
          .fetchPatientDirectory();
      if (mounted) {
        setState(() {
          _patients = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = NursePortalScope.of(context).baseUrl;
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = _patients.where((p) {
      if (_genderFilter != 'All' &&
          p.gender.toLowerCase() != _genderFilter.toLowerCase()) {
        return false;
      }
      if (_bloodFilter != 'All' &&
          p.bloodGroup.toUpperCase() != _bloodFilter.toUpperCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      return p.patientName.toLowerCase().contains(query) ||
          p.patientUniqueId.toLowerCase().contains(query) ||
          p.phone.toLowerCase().contains(query) ||
          p.guardianName.toLowerCase().contains(query) ||
          p.abhaNumber.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text('Patient Directory (${_patients.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by name, UHID, mobile, ABHA...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _genderFilter,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Genders')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _genderFilter = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bloodFilter,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Groups')),
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    ],
                    onChanged: (v) => setState(() => _bloodFilter = v ?? 'All'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ClinicalErrorState(message: _error!, onRetry: _load)
                    : filtered.isEmpty
                        ? ClinicalEmptyState(
                            icon: Icons.person_search_rounded,
                            title: 'No Registered Patients Found',
                            subtitle:
                                'No patient records matched your current filter.',
                            actionLabel: 'Refresh',
                            onAction: _load,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, idx) {
                                final p = filtered[idx];
                                return SoftSurfaceCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          PatientAvatar(
                                            name: p.patientName,
                                            imagePath: p.image,
                                            baseUrl: baseUrl,
                                            radius: 23,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.patientName,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  [
                                                    if (p.patientUniqueId
                                                        .isNotEmpty)
                                                      p.patientUniqueId,
                                                    if (p.age > 0)
                                                      '${p.age} Yrs',
                                                    p.gender,
                                                  ].join(' • '),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (p.bloodGroup.isNotEmpty)
                                            StatusBadge(label: p.bloodGroup),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 6,
                                        children: [
                                          if (p.phone.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.phone_rounded,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  p.phone,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (p.abhaNumber.isNotEmpty)
                                            StatusBadge(
                                              label: 'ABHA: ${p.abhaNumber}',
                                            ),
                                          StatusBadge(
                                            label:
                                                'Due: ${AppFormatters.formatCurrencyInr(p.dueBalance)}',
                                          ),
                                        ],
                                      ),
                                      if (p.address.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          p.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
