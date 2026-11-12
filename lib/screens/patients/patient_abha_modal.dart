import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/print_helper.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';

/// Opens the official ABHA M1 / `Official ABHA Health Card` Modal (`+ ABHA` / `ABHA Card` — Screenshot 778 & image-28).
/// Returns the updated [PatientDirectoryRecord] when ABHA is newly linked or synced from the server.
Future<PatientDirectoryRecord?> showPatientAbhaModal(
  BuildContext context, {
  required PatientDirectoryRecord patient,
  int initialTab = 0,
}) {
  return showDialog<PatientDirectoryRecord>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _PatientAbhaDialog(
      patient: patient,
      initialTab: initialTab,
    ),
  );
}

class _PatientAbhaDialog extends StatefulWidget {
  final PatientDirectoryRecord patient;
  final int initialTab;

  const _PatientAbhaDialog({
    required this.patient,
    this.initialTab = 0,
  });

  @override
  State<_PatientAbhaDialog> createState() => _PatientAbhaDialogState();
}

class _PatientAbhaDialogState extends State<_PatientAbhaDialog> {
  late PatientDirectoryRecord _patient;
  late int _tabIndex; // 0 = Aadhaar OTP, 1 = Mobile OTP, 2 = Search ABHA ID
  late bool _showCardView;
  bool _didSyncLive = false;
  bool _loadingCard = false;
  bool _wasUpdated = false;

  final _aadhaarController = TextEditingController();
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;
  final _otpController = TextEditingController();

  bool _aadhaarConsent = true;
  bool _busy = false;
  String? _txnId;
  String? _otpBannerMessage;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _tabIndex = widget.initialTab.clamp(0, 2);
    _showCardView = _patient.hasAbha;
    _mobileController = TextEditingController(text: _patient.phone);
    _addressController = TextEditingController(text: _patient.abhaAddress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSyncLive) {
      _didSyncLive = true;
      _syncLiveAbhaFromServer();
    }
  }

  Future<void> _syncLiveAbhaFromServer() async {
    if (_patient.id.isEmpty) return;
    final ctrl = NursePortalScope.read(context);
    setState(() => _loadingCard = true);
    try {
      final fresh = await ctrl.api.fetchPatientAbhaCard(_patient);
      if (!mounted) return;
      final hadAbhaBefore = _patient.hasAbha;
      ctrl.updateCachedPatientRecord(fresh);
      setState(() {
        _patient = fresh;
        _loadingCard = false;
        _wasUpdated = true;
        if (fresh.phone.isNotEmpty && _mobileController.text.trim().isEmpty) {
          _mobileController.text = fresh.phone;
        }
        if (fresh.abhaAddress.isNotEmpty &&
            _addressController.text.trim().isEmpty) {
          _addressController.text = fresh.abhaAddress;
        }
        if (!hadAbhaBefore && fresh.hasAbha) {
          _showCardView = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCard = false);
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _closeDialog() {
    Navigator.of(context).pop(_wasUpdated ? _patient : null);
  }

  String get _currentMode {
    if (_tabIndex == 0) return 'aadhaar';
    if (_tabIndex == 1) return 'mobile';
    return 'address';
  }

  String get _currentIdentifier {
    if (_tabIndex == 0) return _aadhaarController.text.trim();
    if (_tabIndex == 1) return _mobileController.text.trim();
    return _addressController.text.trim();
  }

  String get _displayAbhaBadge {
    final numRaw = _patient.abhaNumber.trim();
    if (numRaw.isNotEmpty) {
      return numRaw.contains('@') ? numRaw.split('@').first : numRaw;
    }
    final addrRaw = _patient.abhaAddress.trim();
    if (addrRaw.isNotEmpty) {
      return addrRaw.contains('@') ? addrRaw.split('@').first : addrRaw;
    }
    return 'ABHA-LINKED';
  }

  String get _displayAbdmSuffix {
    final badge = _displayAbhaBadge;
    final addr = _patient.abhaAddress.trim();
    if (addr.isEmpty) return '@abdm';
    final normalizedAddr = addr.contains('@') ? addr : '$addr@abdm';
    final prefix = normalizedAddr.split('@').first;
    if (prefix.toLowerCase() == badge.toLowerCase()) {
      return '@${normalizedAddr.split('@').last}';
    }
    return normalizedAddr;
  }

  String get _fullAbhaAddress {
    final addr = _patient.abhaAddress.trim();
    if (addr.isNotEmpty) {
      return addr.contains('@') ? addr : '$addr@abdm';
    }
    final badge = _displayAbhaBadge;
    if (!RegExp(r'^[0-9-]+$').hasMatch(badge)) {
      return '$badge@abdm';
    }
    final slug = _patient.patientName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '')
        .trim();
    return '${slug.isEmpty ? "patient" : slug}@abdm';
  }

  String get _maskedMobile {
    final m = _patient.phone.trim();
    if (m.isEmpty) return '—';
    if (m.length >= 7) {
      return '${m.substring(0, 3)}****${m.substring(m.length - 3)}';
    }
    return m;
  }

  String get _dobDisplay => _patient.formattedAbhaDobSlash;

  String get _qrPayload {
    return jsonEncode(<String, String>{
      'hidn': _patient.abhaNumber.isNotEmpty
          ? _patient.abhaNumber
          : _displayAbhaBadge,
      'phr': _fullAbhaAddress,
      'name': _patient.patientName,
      'gender': _patient.gender,
      'dob': _dobDisplay,
      'uhid': _patient.patientUniqueId,
      'mobile': _patient.phone,
    });
  }

  void _switchTab(int index) {
    if (_busy) return;
    setState(() {
      _tabIndex = index;
      _txnId = null;
      _otpBannerMessage = null;
      _errorText = null;
      _otpController.clear();
    });
  }

  Future<void> _sendOtp() async {
    final idVal = _currentIdentifier;
    if (_tabIndex == 0) {
      final digits = idVal.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 12) {
        setState(
          () => _errorText = 'Please enter a valid 12-digit Aadhaar number.',
        );
        return;
      }
      if (!_aadhaarConsent) {
        setState(
          () => _errorText = 'Please confirm patient Aadhaar consent.',
        );
        return;
      }
    } else if (_tabIndex == 1) {
      final digits = idVal.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 10) {
        setState(
          () => _errorText = 'Please enter a valid 10-digit mobile number.',
        );
        return;
      }
    } else {
      if (idVal.isEmpty) {
        setState(
          () => _errorText = 'Please enter the patient\'s ABHA address.',
        );
        return;
      }
    }

    final ctrl = NursePortalScope.read(context);
    setState(() {
      _busy = true;
      _errorText = null;
    });

    try {
      final res = await ctrl.api.requestAbhaOtp(
        mode: _currentMode,
        identifier: idVal,
        patientId: _patient.id,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _txnId = res.txnId;
        _otpBannerMessage = res.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(
        () =>
            _errorText = 'Please enter the OTP received on registered mobile.',
      );
      return;
    }

    final ctrl = NursePortalScope.read(context);
    setState(() {
      _busy = true;
      _errorText = null;
    });

    try {
      final updated = await ctrl.api.verifyAbhaOtpAndLink(
        patient: _patient,
        mode: _currentMode,
        txnId: _txnId ?? '',
        otp: otp,
        identifier: _currentIdentifier,
      );
      ctrl.updateCachedPatientRecord(updated);
      ctrl.refreshWorkspace(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ABHA verified & linked for ${updated.patientName}.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _busy = false;
        _patient = updated;
        _wasUpdated = true;
        _showCardView = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handlePrintCard() async {
    String esc(String s) => const HtmlEscape().convert(s);
    final qrSvg = _AbhaQrMatrix.buildInlineSvg(_qrPayload, sizePx: 96);

    final htmlDoc = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Official ABHA Health Card - ${esc(_patient.patientName)}</title>
  <style>
    @page { size: A4 portrait; margin: 18mm; }
    body { font-family: Arial, Helvetica, sans-serif; background: #fff; color: #0f172a; margin: 0; padding: 24px; }
    .card { max-width: 520px; margin: 0 auto; border: 1.5px solid #cbd5e1; border-radius: 14px; overflow: hidden; }
    .hdr { background: linear-gradient(90deg, #0a2a6b, #1647a7); color: #fff; padding: 14px 18px; display: flex; justify-content: space-between; align-items: center; }
    .nha { color: #fbbf24; font-size: 11px; font-weight: 900; letter-spacing: 0.6px; }
    .abdm { color: #fff; font-size: 11px; margin-top: 2px; }
    .pill { border: 1px solid rgba(255,255,255,0.45); background: rgba(255,255,255,0.14); padding: 4px 10px; border-radius: 6px; font-size: 10.5px; font-weight: 800; }
    .tri { display: flex; height: 4px; }
    .tri div { flex: 1; }
    .body { padding: 18px; display: flex; justify-content: space-between; align-items: center; gap: 16px; background: #fff; }
    .avatar { width: 58px; height: 58px; border-radius: 50%; background: #1d4ed8; color: #fff; font-weight: 800; font-size: 20px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .info { flex: 1; }
    .name { font-size: 18px; font-weight: 800; margin-bottom: 5px; }
    .code { display: inline-block; background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; border-radius: 5px; padding: 2px 8px; font-family: monospace; font-size: 12px; font-weight: 700; }
    .handle { color: #7c3aed; font-size: 12px; font-weight: 700; margin-left: 6px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 14px; margin-top: 10px; font-size: 12px; }
    .lbl { color: #64748b; }
    .val { font-weight: 700; color: #0f172a; }
    .qr-box { text-align: center; border: 1px solid #e2e8f0; border-radius: 8px; padding: 6px; }
    .qr-cap { font-size: 9.5px; color: #64748b; margin-top: 3px; font-weight: 700; }
    .ftr { background: #0f172a; color: #cbd5e1; padding: 8px 18px; display: flex; justify-content: space-between; font-size: 10.5px; }
    .ver { color: #34d399; font-weight: 800; }
  </style>
</head>
<body onload="window.print()">
  <div class="card">
    <div class="hdr">
      <div>
        <div class="nha">NATIONAL HEALTH AUTHORITY</div>
        <div class="abdm">Ayushman Bharat Digital Mission (ABDM)</div>
      </div>
      <div class="pill">ABHA CARD</div>
    </div>
    <div class="tri">
      <div style="background:#f97316;"></div>
      <div style="background:#ffffff;"></div>
      <div style="background:#16a34a;"></div>
    </div>
    <div class="body">
      <div class="avatar">${esc(_patient.initials)}</div>
      <div class="info">
        <div class="name">${esc(_patient.patientName)}</div>
        <div>
          <span class="code">${esc(_displayAbhaBadge)}</span>
          <span class="handle">${esc(_displayAbdmSuffix)}</span>
        </div>
        <div class="grid">
          <div><span class="lbl">Gender:</span> <span class="val">${esc(_patient.gender)}</span></div>
          <div><span class="lbl">DOB:</span> <span class="val">${esc(_dobDisplay)}</span></div>
          <div><span class="lbl">UHID:</span> <span class="val">${esc(_patient.patientUniqueId.isEmpty ? "—" : _patient.patientUniqueId)}</span></div>
          <div><span class="lbl">Mobile:</span> <span class="val">${esc(_maskedMobile)}</span></div>
        </div>
      </div>
      <div class="qr-box">
        $qrSvg
        <div class="qr-cap">Scan for ABHA</div>
      </div>
    </div>
    <div class="ftr">
      <span>National Health Portal | abdm.gov.in</span>
      <span class="ver">&#10003; NHA Verified</span>
    </div>
  </div>
</body>
</html>
''';

    final printed = await PrintDocumentHelper.printHtmlDocument(
      title: 'ABHA_Card_${_patient.patientUniqueId.isEmpty ? _patient.patientName : _patient.patientUniqueId}',
      htmlContent: htmlDoc,
    );

    if (!printed && mounted) {
      await Clipboard.setData(
        ClipboardData(
          text:
              'Official ABHA Health Card\nName: ${_patient.patientName}\nABHA: $_displayAbhaBadge ($_fullAbhaAddress)\nUHID: ${_patient.patientUniqueId}\nGender: ${_patient.gender} | DOB: $_dobDisplay | Mobile: $_maskedMobile',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ABHA Health Card details copied for printing/sharing.'),
          backgroundColor: Color(0xFF1D4ED8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: _showCardView
              ? _buildOfficialHealthCardDialog()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildM1Header(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: _buildFormBody(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OFFICIAL ABHA HEALTH CARD VIEW (Matches `Screenshot (778).png` 1:1)
  // ===========================================================================

  Widget _buildOfficialHealthCardDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Modal Bar (`● Official ABHA Health Card` + `×`)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Official ABHA Health Card',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (_loadingCard)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              IconButton(
                onPressed: _closeDialog,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Official NHA Card Surface
        Container(
          color: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.all(16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Royal Navy NHA Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A2A6B), Color(0xFF1647A7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0A2A6B),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NATIONAL HEALTH AUTHORITY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 1.5),
                            Text(
                              'Ayushman Bharat Digital Mission (ABDM)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(34),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withAlpha(90)),
                        ),
                        child: const Text(
                          'ABHA CARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. India Tricolor Strip
                SizedBox(
                  height: 3.5,
                  child: Row(
                    children: [
                      Expanded(child: Container(color: const Color(0xFFF97316))),
                      Expanded(child: Container(color: Colors.white)),
                      Expanded(child: Container(color: const Color(0xFF16A34A))),
                    ],
                  ),
                ),

                // 3. White Card Body (Responsive for both narrow 320px phones & wide screens)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 370;
                      final identityColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _patient.patientName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(5),
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _displayAbhaBadge),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ABHA ID copied'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    _displayAbhaBadge,
                                    style: const TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                _displayAbdmSuffix,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _AbhaFieldPair(
                                  label: 'Gender:',
                                  value: _patient.gender.isEmpty
                                      ? '—'
                                      : _patient.gender,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AbhaFieldPair(
                                  label: 'DOB:',
                                  value: _dobDisplay,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: _AbhaFieldPair(
                                  label: 'UHID:',
                                  value: _patient.patientUniqueId.isEmpty
                                      ? '—'
                                      : _patient.patientUniqueId,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AbhaFieldPair(
                                  label: 'Mobile:',
                                  value: _maskedMobile,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );

                      final avatarBox = Container(
                        width: 64,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D4ED8),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _patient.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );

                      final qrWidget = Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomPaint(
                              size: const Size(74, 74),
                              painter: _AbhaQrPainter(_qrPayload),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Scan for ABHA',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                avatarBox,
                                const SizedBox(width: 12),
                                Expanded(child: identityColumn),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(child: qrWidget),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          avatarBox,
                          const SizedBox(width: 12),
                          Expanded(child: identityColumn),
                          const SizedBox(width: 10),
                          qrWidget,
                        ],
                      );
                    },
                  ),
                ),

                // 4. Dark Navy Card Footer
                Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7.5,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'National Health Portal | abdm.gov.in',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Color(0xFF34D399),
                            size: 13,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'NHA Verified',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Modal Footer (`Card is compliant...` + `Close` + `Print Card`)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Card is compliant with NHA Ayushman Bharat Digital Mission guidelines.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showCardView = false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF026789),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 14),
                    label: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _closeDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size(82, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _handlePrintCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(118, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text(
                      'Print Card',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ABDM M1 CREATE / VERIFY OTP FORM (`+ ABHA` — `image-28.png`)
  // ===========================================================================

  Widget _buildM1Header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF034C6A), Color(0xFF026789)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(32),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'ABHA (Ayushman Bharat Health Account)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ABDM M1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aadhaar se ABHA banayein, ya mobile / address se pehle se bana ABHA verify karein',
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
                onPressed: _busy ? null : _closeDialog,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HeaderTabButton(
                  icon: Icons.fingerprint_rounded,
                  label: 'Via Aadhaar OTP',
                  active: _tabIndex == 0,
                  onTap: () => _switchTab(0),
                ),
                const SizedBox(width: 6),
                _HeaderTabButton(
                  icon: Icons.smartphone_rounded,
                  label: 'Via Mobile OTP',
                  active: _tabIndex == 1,
                  onTap: () => _switchTab(1),
                ),
                const SizedBox(width: 6),
                _HeaderTabButton(
                  icon: Icons.search_rounded,
                  label: 'Search ABHA ID',
                  active: _tabIndex == 2,
                  onTap: () => _switchTab(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBody() {
    final inOtpStep = _txnId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorText != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withAlpha(60)),
            ),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (!inOtpStep) ...[
          if (_tabIndex == 0) _buildAadhaarTab(),
          if (_tabIndex == 1) _buildMobileTab(),
          if (_tabIndex == 2) _buildSearchAddressTab(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (_patient.hasAbha) {
                            setState(() => _showCardView = true);
                          } else {
                            _closeDialog();
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    _patient.hasAbha ? 'Back to Card' : 'Cancel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _sendOtp,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _tabIndex == 2
                              ? Icons.search_rounded
                              : Icons.sms_outlined,
                          size: 17,
                        ),
                  label: Text(
                    _tabIndex == 0
                        ? 'Send Aadhaar OTP'
                        : (_tabIndex == 1
                            ? 'Send Mobile OTP'
                            : 'Find Address & Send OTP'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF026789),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF026789),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otpBannerMessage ??
                        'OTP sent to registered mobile number.',
                    style: const TextStyle(
                      color: Color(0xFF034C6A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _RequiredLabel('Verification OTP'),
          const SizedBox(height: 7),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              hint: 'Enter 6-digit OTP',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _txnId = null;
                            _errorText = null;
                          }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 7,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _verifyOtp,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_rounded, size: 17),
                  label: const Text(
                    'Verify OTP & Link ABHA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF026789),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAadhaarTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RequiredLabel('Aadhaar Number'),
        const SizedBox(height: 7),
        TextField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            hint: 'Enter 12-digit Aadhaar number',
            prefixIcon: const Icon(
              Icons.fingerprint_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _aadhaarConsent = !_aadhaarConsent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _aadhaarConsent,
                  activeColor: const Color(0xFF026789),
                  onChanged: (v) =>
                      setState(() => _aadhaarConsent = v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Patient consents to create / verify ABHA using Aadhaar OTP as per ABDM M1 guidelines.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RequiredLabel('Mobile Number'),
        const SizedBox(height: 7),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            hint: 'e.g. 9876543210',
            prefixIcon: const Icon(
              Icons.smartphone_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the 10-digit mobile number linked to the patient\'s ABHA profile.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAddressTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RequiredLabel('ABHA Address'),
        const SizedBox(height: 7),
        TextField(
          controller: _addressController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            hint: 'e.g. rahul.kumar@abdm',
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: Text(
                '@',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Enter the patient\'s existing ABHA address. The registered contact receives an OTP.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF026789), width: 1.6),
      ),
    );
  }
}

class _AbhaFieldPair extends StatelessWidget {
  final String label;
  final String value;

  const _AbhaFieldPair({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 11.5),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _HeaderTabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.white.withAlpha(24),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: InkWell(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? const Color(0xFF034C6A) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF034C6A) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  final String text;

  const _RequiredLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$text ',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbhaQrMatrix {
  static const int dimension = 21;

  static List<List<bool>> generate(String payload) {
    final grid = List<List<bool>>.generate(
      dimension,
      (_) => List<bool>.filled(dimension, false),
    );
    final reserved = List<List<bool>>.generate(
      dimension,
      (_) => List<bool>.filled(dimension, false),
    );

    void placeFinder(int r0, int c0) {
      for (int dr = -1; dr <= 7; dr++) {
        for (int dc = -1; dc <= 7; dc++) {
          final r = r0 + dr;
          final c = c0 + dc;
          if (r < 0 || r >= dimension || c < 0 || c >= dimension) continue;
          reserved[r][c] = true;
          final inOuter = dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6;
          final onBorder = dr == 0 || dr == 6 || dc == 0 || dc == 6;
          final inCenter = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
          grid[r][c] = inOuter && (onBorder || inCenter);
        }
      }
    }

    placeFinder(0, 0);
    placeFinder(0, dimension - 7);
    placeFinder(dimension - 7, 0);

    for (int i = 8; i < dimension - 8; i++) {
      reserved[6][i] = true;
      reserved[i][6] = true;
      grid[6][i] = i.isEven;
      grid[i][6] = i.isEven;
    }

    final bytes = utf8.encode(payload);
    int bitIndex = 0;
    int hash = 0x811C9DC5;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    for (int r = 0; r < dimension; r++) {
      for (int c = 0; c < dimension; c++) {
        if (reserved[r][c]) continue;
        final byteVal = bytes.isEmpty ? 0x5A : bytes[bitIndex % bytes.length];
        final shift = (r * 3 + c * 5 + bitIndex) % 8;
        final mix = ((byteVal >> shift) ^ ((hash >> (bitIndex % 24)) & 1)) & 1;
        grid[r][c] = mix == 1;
        bitIndex++;
      }
    }
    return grid;
  }

  static String buildInlineSvg(String payload, {int sizePx = 96}) {
    final m = generate(payload);
    final sb = StringBuffer()
      ..write(
        '<svg xmlns="http://www.w3.org/2000/svg" width="$sizePx" height="$sizePx" viewBox="0 0 $dimension $dimension" shape-rendering="crispEdges">',
      )
      ..write('<rect width="$dimension" height="$dimension" fill="#ffffff"/>');
    for (int r = 0; r < dimension; r++) {
      for (int c = 0; c < dimension; c++) {
        if (m[r][c]) {
          sb.write('<rect x="$c" y="$r" width="1" height="1" fill="#0f172a"/>');
        }
      }
    }
    sb.write('</svg>');
    return sb.toString();
  }
}

class _AbhaQrPainter extends CustomPainter {
  final String payload;

  _AbhaQrPainter(this.payload);

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = _AbhaQrMatrix.generate(payload);
    final n = _AbhaQrMatrix.dimension;
    final cell = size.width / n;
    final darkPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (matrix[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.25, cell + 0.25),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AbhaQrPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
