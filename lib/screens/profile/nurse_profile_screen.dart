import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/server_config_sheet.dart';
import '../../widgets/status_badge.dart';
import '../beds/bed_status_screen.dart';
import '../modules/annual_calendar_screen.dart';
import '../modules/api_connections_screen.dart';
import '../modules/appointments_screen.dart';
import '../modules/blood_bank_screen.dart';
import '../modules/pharmacy_inventory_screen.dart';
import '../modules/staff_directory_screen.dart';
import '../opd/opd_triage_screen.dart';
import '../reports/reports_screen.dart';
import '../roster/duty_roster_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final user = controller.currentUser;
    final hospital = controller.hospitalInfo;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Nurse Profile'),
        actions: [
          IconButton(
            tooltip: 'Full Live API Links',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ApiConnectionsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.hub_rounded, color: AppColors.primary),
          ),
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
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
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
                    color: AppColors.primary,
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
                          : 'REST Connected',
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
                  icon: Icons.hub_rounded,
                  title: 'Full Live API Links & Status',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ApiConnectionsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.schedule_rounded,
                  title: 'My Duty Roster & Shifts',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DutyRosterScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.bed_rounded,
                  title: 'Ward & Bed Occupancy',
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
                  icon: Icons.medical_information_rounded,
                  title: 'OPD Triage Queue',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OpdTriageScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.event_available_rounded,
                  title: 'Hospital Appointments',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.badge_rounded,
                  title: 'Doctors & Staff Directory',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StaffDirectoryScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.medication_liquid_rounded,
                  title: 'Pharmacy & Ward Supplies',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PharmacyInventoryScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.biotech_rounded,
                  title: 'Diagnostic & Lab Reports',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.water_drop_rounded,
                  title: 'Blood Bank Status',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BloodBankScreen(),
                      ),
                    );
                  },
                ),
                const Divider(indent: 54),
                _MenuRow(
                  icon: Icons.calendar_month_rounded,
                  title: 'Annual Holiday Calendar',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AnnualCalendarScreen(),
                      ),
                    );
                  },
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
                    'Your active ward session and live Socket.IO clinical alerts will be disconnected.',
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
          Icon(icon, size: 17, color: AppColors.primary),
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
        child: Icon(icon, color: AppColors.primary, size: 20),
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
