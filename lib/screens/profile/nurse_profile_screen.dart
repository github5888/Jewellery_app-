import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/server_config_sheet.dart';
import '../../widgets/status_badge.dart';
import '../beds/bed_status_screen.dart';

class NurseProfileScreen extends StatelessWidget {
  const NurseProfileScreen({super.key});

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Change Nurse Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 42),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          if (currentCtrl.text.trim().isEmpty ||
                              newCtrl.text.trim().isEmpty) {
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            await NursePortalScope.read(context)
                                .api
                                .changePassword(
                                  currentPassword: currentCtrl.text,
                                  newPassword: newCtrl.text,
                                );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Password updated successfully.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not change password: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToShellSection(BuildContext context, int navIndex) {
    final controller = NursePortalScope.read(context);
    controller.setSelectedNavIndex(navIndex);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final user = controller.currentUser;
    final hospital = controller.hospitalInfo;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Nurse Profile'),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
            onPressed: () => showServerConfigSheet(context),
            icon: const Icon(
              Icons.settings_ethernet_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          SoftSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                PatientAvatar(
                  name: user?.fullName ?? 'Nurse',
                  imagePath: user?.image,
                  baseUrl: controller.baseUrl,
                  radius: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Duty Nurse',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    user?.roleName ?? 'Nurse',
                    if (user != null && user.staffCode.isNotEmpty)
                      user.staffCode,
                  ].join(' • '),
                  style: const TextStyle(
                    color: Color(0xFF0A4D78),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    StatusBadge(
                      label: controller.socketConnected
                          ? 'Socket Live'
                          : 'Online & Ready',
                      showDot: true,
                    ),
                    if (user != null && user.department.isNotEmpty)
                      StatusBadge(label: user.department),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _ProfileMetaRow(
                  icon: Icons.local_hospital_rounded,
                  label: 'Hospital',
                  value: hospital.name,
                ),
                if (user != null && user.email.isNotEmpty)
                  _ProfileMetaRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                if (user != null && user.phone.isNotEmpty)
                  _ProfileMetaRow(
                    icon: Icons.phone_outlined,
                    label: 'Mobile',
                    value: user.phone,
                  ),
                _ProfileMetaRow(
                  icon: Icons.dns_outlined,
                  label: 'Server',
                  value: controller.baseUrl,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SoftSurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _MenuRow(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.dashboard,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.groups_rounded,
                  title: 'Patient Directory',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.patients,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.medical_information_rounded,
                  title: 'OPD - Out Patient',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.opd,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.hotel_rounded,
                  title: 'IPD - In Patient',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.ipd,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.bed_rounded,
                  title: 'Ward Bed Status',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BedStatusScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.water_drop_rounded,
                  title: 'Blood Bank Status',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.bloodBank,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.schedule_rounded,
                  title: 'Duty Roster',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.dutyRoster,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Annual Calendar',
                  onTap: () => _navigateToShellSection(
                    context,
                    NurseNavIndex.annualCalendar,
                  ),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.settings_ethernet_rounded,
                  title: 'Hospital API Endpoint Config',
                  onTap: () => showServerConfigSheet(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.3),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout from Nurse Portal?'),
                  content: const Text(
                    'Your active ward session and live Socket.IO clinical stream will be disconnected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        minimumSize: const Size(100, 42),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
                await controller.logout();
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF0A4D78)),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.skySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0A4D78), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
    );
  }
}
