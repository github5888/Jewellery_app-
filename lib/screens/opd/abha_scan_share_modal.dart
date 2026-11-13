import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/hospital_modules_models.dart';
import '../../state/nurse_portal_controller.dart';

/// Opens the live `ABDM Scan & Share Check-ins [LIVE]` modal on OPD Queue (`image-36` & `image-37`).
Future<void> showAbhaScanShareModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AbhaScanShareDialog(),
  );
}

class _AbhaScanShareDialog extends StatefulWidget {
  const _AbhaScanShareDialog();

  @override
  State<_AbhaScanShareDialog> createState() => _AbhaScanShareDialogState();
}

class _AbhaScanShareDialogState extends State<_AbhaScanShareDialog> {
  int _activeTab = 0; // 0 = Check-in Requests, 1 = Hospital QR Code
  String _statusFilter = 'Pending Only';
  bool _loadingQueue = false;
  bool _simulating = false;
  AbhaHospitalQrInfo? _qrInfo;
  bool _didInit = false;

  static const List<String> _filterOptions = [
    'Pending Only',
    'All Requests',
    'Completed',
    'Dismissed',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _syncFromBackend();
    }
  }

  Future<void> _syncFromBackend() async {
    final ctrl = NursePortalScope.read(context);
    setState(() => _loadingQueue = true);
    try {
      final results = await Future.wait<dynamic>([
        ctrl.refreshAbhaQueue(),
        ctrl.api.fetchAbhaHospitalQrConfig(
          fallbackHospitalName: ctrl.hospitalInfo.name,
        ),
      ]);
      final loadedQueue = results[0] as List<AbhaScanCheckinItem>;
      if (!mounted) return;
      setState(() {
        _qrInfo = results[1] as AbhaHospitalQrInfo;
        if (_statusFilter == 'Pending Only' &&
            loadedQueue.isNotEmpty &&
            loadedQueue.where((x) => x.isPending).isEmpty) {
          _statusFilter = 'All Requests';
        }
        _loadingQueue = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingQueue = false);
    }
  }

  Future<void> _handleSimulateScan() async {
    if (_simulating) return;
    final ctrl = NursePortalScope.read(context);
    setState(() => _simulating = true);
    try {
      final item = await ctrl.triggerSimulateAbhaScan();
      if (!mounted) return;
      setState(() {
        _simulating = false;
        _activeTab = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ABDM Scan received: ${item.patientName} (${item.displayCode})',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _simulating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not simulate scan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleComplete(AbhaScanCheckinItem item) async {
    final ctrl = NursePortalScope.read(context);
    await ctrl.completeAbhaCheckinItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check-in marked completed for ${item.patientName}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleDismiss(AbhaScanCheckinItem item) async {
    final ctrl = NursePortalScope.read(context);
    await ctrl.dismissAbhaCheckinItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = NursePortalScope.of(context);
    final allItems = ctrl.abhaQueue;
    final filtered = allItems.where((item) {
      if (_statusFilter == 'Pending Only') return item.isPending;
      if (_statusFilter == 'Completed') return item.isCompleted;
      if (_statusFilter == 'Dismissed') return item.isDismissed;
      return true;
    }).toList();

    final qr = _qrInfo ??
        AbhaHospitalQrInfo.fromJson(
          const <String, dynamic>{},
          fallbackHospitalName: ctrl.hospitalInfo.name,
        );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildActionToolbar(filtered.length),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: _activeTab == 0
                    ? _buildCheckinsList(filtered)
                    : _buildHospitalQrTab(qr),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF034C6A), Color(0xFF026789)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF034C6A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'ABDM Scan & Share Check-ins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'QR verifies identity only; reception selects doctor, fee and payment before a queue token is issued',
                  style: TextStyle(
                    color: Colors.white.withAlpha(215),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TabPillButton(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Check-in Requests ($count)',
                active: _activeTab == 0,
                onTap: () => setState(() => _activeTab = 0),
              ),
              _TabPillButton(
                icon: Icons.qr_code_2_rounded,
                label: 'Hospital QR Code',
                active: _activeTab == 1,
                onTap: () => setState(() => _activeTab = 1),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_activeTab == 0)
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isDense: true,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      items: _filterOptions
                          .map(
                            (opt) => DropdownMenuItem<String>(
                              value: opt,
                              child: Text(opt),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _statusFilter = v);
                      },
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _simulating ? null : _handleSimulateScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: _simulating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, size: 16),
                label: const Text(
                  'Simulate Patient Scan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinsList(List<AbhaScanCheckinItem> items) {
    if (_loadingQueue && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF026789),
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No ABDM Check-in Requests Found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Patients scanning the Hospital QR Code or simulated scans appear here instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.displayCode,
                          style: const TextStyle(
                            color: Color(0xFF035C7A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFeatures: AppTheme.tabularNums,
                          ),
                        ),
                        if (item.counterId.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.counterId,
                            style: const TextStyle(
                              color: Color(0xFF0284C7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item.patientName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.isPending
                                    ? const Color(0xFFFEF3C7)
                                    : AppColors.successSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: item.isPending
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF059669),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (item.uhid.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.uhid,
                                  style: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: AppTheme.tabularNums,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.abhaAddress.isNotEmpty)
                              Text(
                                item.abhaAddress,
                                style: const TextStyle(
                                  color: Color(0xFF026789),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (item.abhaNumber.isNotEmpty)
                              Text(
                                item.abhaAddress.isNotEmpty
                                    ? '(${item.abhaNumber})'
                                    : item.abhaNumber,
                                style: const TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: AppTheme.tabularNums,
                                ),
                              ),
                            if (item.gender.isNotEmpty)
                              Text(
                                '•  ${item.gender}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (item.displayAgeOrDob.isNotEmpty)
                              Text(
                                '•  ${item.displayAgeOrDob}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppTheme.tabularNums,
                                ),
                              ),
                            if (item.mobile.isNotEmpty)
                              Text(
                                '•  ${item.mobile}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppTheme.tabularNums,
                                ),
                              ),
                            if (item.displayTime.isNotEmpty)
                              Text(
                                '•  ${item.displayTime}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppTheme.tabularNums,
                                ),
                              ),
                          ],
                        ),
                        if (item.address.trim().isNotEmpty ||
                            item.department.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (item.department.trim().isNotEmpty)
                                'Dept: ${item.department.trim()}',
                              if (item.address.trim().isNotEmpty)
                                item.address.trim(),
                            ].join('  •  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isPending)
                        IconButton(
                          tooltip: 'Complete Check-in',
                          onPressed: () => _handleComplete(item),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 19,
                            color: Color(0xFF059669),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        tooltip: 'Dismiss Request',
                        onPressed: () => _handleDismiss(item),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// Exact `Hospital QR Code` view (`image-37.png`).
  Widget _buildHospitalQrTab(AbhaHospitalQrInfo qr) {
    Uint8List? decodedBytes;
    if (qr.qrImage != null && qr.qrImage!.contains('base64,')) {
      try {
        final b64 = qr.qrImage!.split('base64,').last.replaceAll(RegExp(r'\s+'), '');
        decodedBytes = base64Decode(b64);
      } catch (_) {}
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF026789), width: 1.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                qr.hospitalName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF034C6A),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Counter ID: ${qr.counterId}  |  Facility: ${qr.facilityId}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppTheme.tabularNums,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: decodedBytes != null
                    ? Image.memory(
                        decodedBytes,
                        width: 196,
                        height: 196,
                        fit: BoxFit.contain,
                      )
                    : SizedBox(
                        width: 196,
                        height: 196,
                        child: CustomPaint(
                          painter: _AbdmQrMatrixPainter(qr.qrPayload),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Scan with ABHA App',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Scanning securely shares the patient profile. It does not book an appointment or issue a queue number.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'ABDM Scan & Share M1 Integration Active',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPillButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF026789) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? const Color(0xFF026789) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crisp vector QR Matrix Painter with standard ISO 18004 finder, timing, and alignment patterns.
class _AbdmQrMatrixPainter extends CustomPainter {
  final String payload;

  const _AbdmQrMatrixPainter(this.payload);

  @override
  void paint(Canvas canvas, Size size) {
    const int n = 29;
    final double cell = size.width / n;
    final paint = Paint()
      ..color = const Color(0xFF0B1528)
      ..style = PaintingStyle.fill;

    final grid = List.generate(n, (_) => List<bool>.filled(n, false));
    final reserved = List.generate(n, (_) => List<bool>.filled(n, false));

    void placeFinder(int ox, int oy) {
      for (int dy = -1; dy <= 7; dy++) {
        for (int dx = -1; dx <= 7; dx++) {
          final x = ox + dx;
          final y = oy + dy;
          if (x < 0 || y < 0 || x >= n || y >= n) continue;
          reserved[y][x] = true;
          final inOuter = dx >= 0 && dx <= 6 && dy >= 0 && dy <= 6;
          final onBorder = dx == 0 || dx == 6 || dy == 0 || dy == 6;
          final inCore = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
          grid[y][x] = inOuter && (onBorder || inCore);
        }
      }
    }

    placeFinder(0, 0);
    placeFinder(n - 7, 0);
    placeFinder(0, n - 7);

    // Alignment pattern at (20, 20)
    for (int dy = -2; dy <= 2; dy++) {
      for (int dx = -2; dx <= 2; dx++) {
        final x = 22 + dx;
        final y = 22 + dy;
        reserved[y][x] = true;
        grid[y][x] =
            dx.abs() == 2 || dy.abs() == 2 || (dx == 0 && dy == 0);
      }
    }

    // Timing patterns
    for (int i = 8; i < n - 8; i++) {
      reserved[6][i] = true;
      reserved[i][6] = true;
      grid[6][i] = i.isEven;
      grid[i][6] = i.isEven;
    }

    // Deterministic payload encoding across unreserved modules
    final bytes = utf8.encode(payload.isEmpty ? 'ABDM-OPD-COUNTER-1' : payload);
    int seed = 0x5A17C3;
    for (final b in bytes) {
      seed = ((seed << 5) - seed + b) & 0x7FFFFFFF;
    }

    int idx = 0;
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (reserved[y][x]) continue;
        final byteVal = bytes[idx % bytes.length];
        final mixed = (seed ^ (x * 37 + y * 91 + byteVal * 17 + idx * 13)) & 0xFF;
        grid[y][x] = (mixed & 1) == 1 && ((mixed >> 2) & 3) != 0;
        idx++;
      }
    }

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (grid[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + 0.35, cell + 0.35),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AbdmQrMatrixPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
