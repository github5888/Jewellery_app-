import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../state/nurse_portal_controller.dart';

Future<void> showServerConfigSheet(BuildContext context) async {
  final controller = NursePortalScope.read(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ServerConfigSheetBody(controller: controller),
  );
}

class _ServerConfigSheetBody extends StatefulWidget {
  final NursePortalController controller;

  const _ServerConfigSheetBody({required this.controller});

  @override
  State<_ServerConfigSheetBody> createState() => _ServerConfigSheetBodyState();
}

class _ServerConfigSheetBodyState extends State<_ServerConfigSheetBody> {
  late final TextEditingController _urlCtrl;
  bool _saving = false;
  String? _statusMessage;
  bool? _healthOk;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.controller.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndVerify() async {
    setState(() {
      _saving = true;
      _statusMessage = null;
    });
    await widget.controller.updateServerBaseUrl(_urlCtrl.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _healthOk = widget.controller.serverReachable;
      _statusMessage = widget.controller.serverReachable
          ? 'Connected to ${widget.controller.baseUrl} (/api/health OK)'
          : 'Saved ${widget.controller.baseUrl} — /api/health did not respond yet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.dns_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Hospital API Server Endpoint',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Connected directly to your live Smart Hospital MERN API & Socket.IO server.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Server Base URL',
              hintText: 'https://hospital.hrpocket.in',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Live Portal (hospital.hrpocket.in)'),
                onPressed: () {
                  _urlCtrl.text = AppConfig.defaultBaseUrl;
                },
              ),
              ActionChip(
                label: const Text('Android Emulator (10.0.2.2:5000)'),
                onPressed: () {
                  _urlCtrl.text = 'http://10.0.2.2:5000';
                },
              ),
              ActionChip(
                label: const Text('Localhost (localhost:5000)'),
                onPressed: () {
                  _urlCtrl.text = 'http://localhost:5000';
                },
              ),
            ],
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _healthOk == true
                    ? AppColors.successSoft
                    : AppColors.warningSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _healthOk == true
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: _healthOk == true
                        ? AppColors.success
                        : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _healthOk == true
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _saveAndVerify,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save & Test Connection'),
          ),
        ],
      ),
    );
  }
}
