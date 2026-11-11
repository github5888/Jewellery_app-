import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';

/// Real-Time Socket.IO Live Clinical Alerts + `GET https://hospital.hrpocket.in/api/notifications`
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NursePortalScope.read(context).markAllAlertsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final liveAlerts = controller.liveAlerts;
    final serverAlerts = controller.serverNotifications;
    final dashActivities = controller.dashboard?.recentActivity ?? const [];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Live Ward Alerts')),
      body: liveAlerts.isEmpty && serverAlerts.isEmpty && dashActivities.isEmpty
          ? ClinicalEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Live Ward Alerts Yet',
              subtitle: controller.socketConnected
                  ? 'Socket.IO & /api/notifications connected. Real-time admissions, vitals, and MAR updates will stream here.'
                  : 'Real-time clinical updates from the ward will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                if (liveAlerts.isNotEmpty) ...[
                  const Text(
                    'Real-Time Socket.IO Events',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...liveAlerts.map(
                    (ev) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.infoSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ev.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ev.subtitle,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.formatTime12h(ev.timestamp),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (serverAlerts.isNotEmpty) ...[
                  const Text(
                    'Hospital Notifications (/api/notifications)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...serverAlerts.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  AppFormatters.timeAgo(n.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            if (n.message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (dashActivities.isNotEmpty) ...[
                  const Text(
                    'Recent Ward Clinical Stream',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...dashActivities.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  AppFormatters.timeAgo(a.timestamp),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            if (a.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                a.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
