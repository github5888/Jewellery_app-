import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/status_badge.dart';

/// Doctors & Nursing Staff Directory (`GET https://hospital.hrpocket.in/api/staff`)
class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  List<StaffDirectoryMember> _staff = const [];
  String _roleFilter = 'All'; // All | Doctor | Nurse
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
      final list =
          await NursePortalScope.read(context).api.fetchStaffDirectory();
      if (mounted) {
        setState(() {
          _staff = list;
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
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = _staff.where((s) {
      if (_roleFilter != 'All' &&
          !s.role.toLowerCase().contains(_roleFilter.toLowerCase())) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.fullName.toLowerCase().contains(q) ||
          s.department.toLowerCase().contains(q) ||
          s.specialist.toLowerCase().contains(q) ||
          s.employeeId.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Doctors & Staff (${_staff.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search doctors, nurses, department...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: ['All', 'Doctor', 'Nurse'].map((r) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r),
                    selected: _roleFilter == r,
                    onSelected: (_) => setState(() => _roleFilter = r),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ClinicalErrorState(message: _error!, onRetry: _load)
                    : filtered.isEmpty
                        ? ClinicalEmptyState(
                            icon: Icons.badge_outlined,
                            title: 'No Staff Members Found',
                            subtitle:
                                'Hospital doctors and nursing staff from /api/staff appear here.',
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
                                final m = filtered[idx];
                                return SoftSurfaceCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      PatientAvatar(
                                        name: m.fullName,
                                        imagePath: m.image,
                                        baseUrl: baseUrl,
                                        radius: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.fullName,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              [
                                                if (m.department.isNotEmpty)
                                                  m.department,
                                                if (m.specialist.isNotEmpty)
                                                  m.specialist,
                                              ].join(' • '),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            if (m.phone.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                'Phone: ${m.phone}',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      StatusBadge(label: m.role),
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
