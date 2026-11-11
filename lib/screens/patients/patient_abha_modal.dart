import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';

/// Opens the official ABHA M1 Modal (`+ ABHA` / `ABHA Card` — image-28).
/// Returns the updated [PatientDirectoryRecord] when ABHA is newly linked/updated.
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
  void dispose() {
    _aadhaarController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _otpController.dispose();
    super.dispose();
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
        setState(() => _errorText = 'Please enter a valid 12-digit Aadhaar number.');
        return;
      }
      if (!_aadhaarConsent) {
        setState(() => _errorText = 'Please confirm patient Aadhaar consent.');
        return;
      }
    } else if (_tabIndex == 1) {
      final digits = idVal.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 10) {
        setState(() => _errorText = 'Please enter a valid 10-digit mobile number.');
        return;
      }
    } else {
      if (idVal.isEmpty) {
        setState(() => _errorText = 'Please enter the patient\'s ABHA address.');
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
      setState(() => _errorText = 'Please enter the OTP received on registered mobile.');
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
            'ABHA linked for ${updated.patientName} (${updated.abhaNumber}).',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _showCardView ? _buildAbhaCardBody() : _buildFormBody(),
              ),
            ],
          ),
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
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_showCardView)
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
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildAbhaCardBody() {
    final addr = _patient.abhaAddress.trim().isNotEmpty
        ? _patient.abhaAddress.trim()
        : '${_patient.patientName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}@abdm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0369A1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NATIONAL HEALTH AUTHORITY • ABHA CARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '✓ Verified',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _patient.patientName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'UHID: ${_patient.patientUniqueId.isEmpty ? "-" : _patient.patientUniqueId}  •  ${_patient.gender}  •  ${_patient.age > 0 ? "${_patient.age} Yrs" : "-"}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: 22),
              _CardInfoRow(
                label: 'ABHA Number',
                value: _patient.abhaNumber.isEmpty ? '—' : _patient.abhaNumber,
                canCopy: _patient.abhaNumber.isNotEmpty,
              ),
              const SizedBox(height: 8),
              _CardInfoRow(
                label: 'ABHA Address',
                value: addr,
                canCopy: true,
              ),
              if (_patient.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                _CardInfoRow(
                  label: 'Mobile Number',
                  value: _patient.phone,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showCardView = false),
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Re-verify / Update'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF026789),
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF026789),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
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
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF026789),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF026789),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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

  /// Exact `Search ABHA ID` tab from `image-28.png`.
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

class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _CardInfoRow({
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
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
              fontFeatures: AppTheme.tabularNums,
            ),
          ),
        ),
        if (canCopy)
          IconButton(
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.copy_rounded,
              size: 15,
              color: Color(0xFF026789),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
      ],
    );
  }
}
