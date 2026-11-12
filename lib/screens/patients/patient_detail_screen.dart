import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/clinical_report_model.dart';
import '../../models/ipd_models.dart';
import '../../models/patient_directory_model.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';
import '../reports/report_viewer_screen.dart';
import 'ipd_patient_detail_screen.dart';
import 'patient_abha_modal.dart';

/// Complete 6-Tab Patient Profile / Details Screen (`/patients/:id` — image-29..34).
/// Tabs:
///  0. Overview (ABHA status + 3 financial cards + Recent Invoices)
///  1. Lab & Radiology (N) (`All Investigations`, `Pathology`, `Radiology` + PDF viewer)
///  2. Appointments (N) (`Appointments History`)
///  3. Visits / OPD & IPD (N) (`OPD Consultations & Encounters` + `IPD Admissions`)
///  4. Services & Orders (`Linked Orders & Investigation Services`)
///  5. Patient Demographics (`Complete Demographic Record` — all 14 fields)
class PatientDetailScreen extends StatefulWidget {
  final PatientDirectoryRecord initialPatient;
  final int initialTabIndex;

  const PatientDetailScreen({
    super.key,
    required this.initialPatient,
    this.initialTabIndex = 0,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late PatientDirectoryRecord _patient;
  PatientFullDossier? _dossier;
  bool _loading = true;
  String? _error;

  late int _activeTab;
  int _labSubFilter = 0; // 0 = All, 1 = Pathology, 2 = Radiology
  bool _didInitLoad = false;

  @override
  void initState() {
    super.initState();
    _patient = widget.initialPatient;
    _activeTab = widget.initialTabIndex.clamp(0, 5);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitLoad) {
      _didInitLoad = true;
      _loadDossier();
    }
  }

  Future<void> _loadDossier({bool silent = false}) async {
    final ctrl = NursePortalScope.read(context);
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final fetched = await ctrl.api.fetchFullPatientDossier(_patient);
      if (!mounted) return;
      setState(() {
        _dossier = fetched;
        _patient = fetched.patient;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openAbhaModal() async {
    final updated = await showPatientAbhaModal(
      context,
      patient: _patient,
    );
    if (updated != null && mounted) {
      setState(() => _patient = updated);
      await _loadDossier(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = NursePortalScope.of(context);
    final primary = ctrl.personalTheme.primaryColor;
    final d = _dossier;
    final labCount = d?.labAndRadiology.length ?? 0;
    final apptCount = d?.appointments.length ?? 0;
    final visitsCount = d?.totalVisitsCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: PremiumScreenBackground(
        accentColor: primary,
        child: SafeArea(
          child: RefreshIndicator(
            color: primary,
            onRefresh: () => _loadDossier(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                _buildTopBackBar(),
                const SizedBox(height: 10),
                _buildPatientHeroCard(ctrl),
                const SizedBox(height: 14),
                _buildSixTabsStrip(
                  labCount: labCount,
                  apptCount: apptCount,
                  visitsCount: visitsCount,
                ),
                const SizedBox(height: 14),
                if (_loading && d == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && d == null)
                  _buildErrorBanner()
                else
                  _buildActiveTabContent(ctrl, d),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBackBar() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => Navigator.of(context).pop(_patient),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 6),
                Text(
                  'Back to Patients',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh Patient Profile',
          onPressed: _loading ? null : () => _loadDossier(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
        ),
      ],
    );
  }

  Widget _buildPatientHeroCard(NursePortalController ctrl) {
    final p = _patient;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PatientAvatar(
            name: p.patientName,
            imagePath: p.image,
            baseUrl: ctrl.baseUrl,
            radius: 26,
            backgroundColor: const Color(0xFF00779E),
            textColor: Colors.white,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p.patientUniqueId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'UHID: ${p.patientUniqueId}',
                          style: const TextStyle(
                            color: Color(0xFF0369A1),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularNums,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${p.gender} • ${p.age > 0 ? "${p.age} Yrs" : "-"}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (p.phone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13.5,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.phone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTheme.tabularNums,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixTabsStrip({
    required int labCount,
    required int apptCount,
    required int visitsCount,
  }) {
    final tabs = <({IconData icon, String label})>[
      (icon: Icons.person_outline_rounded, label: 'Overview'),
      (
        icon: Icons.science_outlined,
        label: 'Lab & Radiology ($labCount)',
      ),
      (
        icon: Icons.calendar_today_outlined,
        label: 'Appointments ($apptCount)',
      ),
      (
        icon: Icons.monitor_heart_outlined,
        label: 'Visits / OPD & IPD ($visitsCount)',
      ),
      (icon: Icons.medication_outlined, label: 'Services & Orders'),
      (icon: Icons.description_outlined, label: 'Patient Demographics'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final t = tabs[idx];
            final selected = _activeTab == idx;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _activeTab = idx),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? const Color(0xFF00779E)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.icon,
                      size: 16,
                      color: selected
                          ? const Color(0xFF00779E)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF00779E)
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            _error ?? 'Unable to load patient profile.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadDossier,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(
    NursePortalController ctrl,
    PatientFullDossier? d,
  ) {
    switch (_activeTab) {
      case 0:
        return _buildOverviewTab(d);
      case 1:
        return _buildLabAndRadiologyTab(d);
      case 2:
        return _buildAppointmentsTab(d);
      case 3:
        return _buildVisitsOpdIpdTab(d);
      case 4:
        return _buildServicesAndOrdersTab(d);
      case 5:
        return _buildDemographicsTab();
      default:
        return _buildOverviewTab(d);
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 0 — OVERVIEW (image-29)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(PatientFullDossier? d) {
    final p = _patient;
    final totalInv = d?.totalInvoicedAmount ?? p.totalInvoiced;
    final totalPaid = d?.totalPaymentsReceived ?? p.totalPaid;
    final dueBal = d?.currentOutstandingBalance ?? p.dueBalance;
    final invCount = d?.invoiceCount ?? 0;
    final payCount = d?.paymentTransactionCount ?? 0;
    final invoices = d?.invoices ?? const <PatientInvoiceSummaryItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ABHA Banner Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0F9FF), Color(0xFFF8FDFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
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
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF0369A1),
                      size: 20,
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
                              'Ayushman Bharat Health Account (ABHA)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.hasAbha
                                    ? AppColors.successSoft
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.hasAbha ? 'Linked' : 'Not Linked',
                                style: TextStyle(
                                  color: p.hasAbha
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFB45309),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        if (p.hasAbha)
                          Text(
                            'ABHA No: ${p.abhaNumber.isEmpty ? "—" : p.abhaNumber}'
                            '${p.abhaAddress.isNotEmpty ? "  •  ${p.abhaAddress}" : ""}',
                            style: const TextStyle(
                              color: Color(0xFF0369A1),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularNums,
                            ),
                          )
                        else
                          const Text(
                            'Link patient\'s Aadhaar or mobile number to issue official 14-digit ABHA number and enable ABDM nationwide health record exchange.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.38,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _openAbhaModal,
                  icon: const Icon(Icons.badge_outlined, size: 15),
                  label: Text(p.hasAbha ? 'ABHA Card' : '+ ABHA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0369A1),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF7DD3FC)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 3 Financial Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            final cards = [
              _FinancialMetricCard(
                label: 'TOTAL INVOICED AMOUNT',
                amount: AppFormatters.formatCurrencyInr(totalInv),
                subtitle: 'Across $invCount invoices generated',
                amountColor: AppColors.textPrimary,
                icon: Icons.description_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
              ),
              _FinancialMetricCard(
                label: 'TOTAL PAYMENTS RECEIVED',
                amount: AppFormatters.formatCurrencyInr(totalPaid),
                subtitle: 'Recorded in $payCount transactions',
                amountColor: const Color(0xFF059669),
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
              ),
              _FinancialMetricCard(
                label: 'CURRENT OUTSTANDING BALANCE',
                amount: AppFormatters.formatCurrencyInr(dueBal),
                subtitle:
                    dueBal > 0 ? 'Outstanding balance due' : 'No outstanding dues',
                amountColor:
                    dueBal > 0 ? AppColors.danger : AppColors.textPrimary,
                icon: Icons.currency_rupee_rounded,
                iconBg: dueBal > 0
                    ? AppColors.dangerSoft
                    : const Color(0xFFF1F5F9),
                iconColor:
                    dueBal > 0 ? AppColors.danger : AppColors.textSecondary,
              ),
            ];
            if (wide) {
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[2]),
                ],
              );
            }
            return Column(
              children: [
                cards[0],
                const SizedBox(height: 10),
                cards[1],
                const SizedBox(height: 10),
                cards[2],
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        // Recent Invoices Card
        _SectionCard(
          title: 'Recent Invoices',
          child: invoices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'No invoices generated for this patient yet.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: invoices
                      .take(10)
                      .map(
                        (inv) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inv.invoiceNo,
                                      style: const TextStyle(
                                        color: Color(0xFF00779E),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${inv.module} • ${AppFormatters.formatSlashDate(inv.date)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrencyInr(
                                      inv.totalAmount,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: AppTheme.tabularNums,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    inv.status,
                                    style: TextStyle(
                                      color: inv.dueAmount <= 0
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFD97706),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1 — LAB & RADIOLOGY (image-30)
  // ---------------------------------------------------------------------------
  Widget _buildLabAndRadiologyTab(PatientFullDossier? d) {
    final all = d?.labAndRadiology ?? const <ClinicalReportRecord>[];
    final pathList = d?.pathologyReports ?? const <ClinicalReportRecord>[];
    final radList = d?.radiologyReports ?? const <ClinicalReportRecord>[];

    final filtered = _labSubFilter == 1
        ? pathList
        : (_labSubFilter == 2 ? radList : all);

    return _SectionCard(
      title: 'Patient Diagnostic Investigations & Uploaded Reports',
      subtitle:
          'Complete history of Pathology laboratory tests and Radiology imaging scans with downloadable official PDF reports.',
      trailingHeader: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _FilterChipBtn(
            label: 'All Investigations (${all.length})',
            selected: _labSubFilter == 0,
            onTap: () => setState(() => _labSubFilter = 0),
          ),
          _FilterChipBtn(
            label: 'Pathology (${pathList.length})',
            selected: _labSubFilter == 1,
            onTap: () => setState(() => _labSubFilter = 1),
          ),
          _FilterChipBtn(
            label: 'Radiology (${radList.length})',
            selected: _labSubFilter == 2,
            onTap: () => setState(() => _labSubFilter = 2),
          ),
        ],
      ),
      child: filtered.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 34),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppColors.textMuted,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Diagnostic Tests Found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This patient has not undergone any pathology or radiology investigations yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: filtered
                  .map(
                    (r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: r.category ==
                                                ClinicalReportCategory.lab
                                            ? const Color(0xFFE0F2FE)
                                            : const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        r.category == ClinicalReportCategory.lab
                                            ? 'Pathology'
                                            : 'Radiology',
                                        style: TextStyle(
                                          color: r.category ==
                                                  ClinicalReportCategory.lab
                                              ? const Color(0xFF0369A1)
                                              : const Color(0xFF6D28D9),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (r.billNo.isNotEmpty)
                                      Text(
                                        r.billNo,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: AppTheme.tabularNums,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  r.title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${AppFormatters.formatSlashDate(r.date)}  •  ${r.status}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (r.hasDownloadableFile)
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportViewerScreen(report: r),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 15,
                              ),
                              label: const Text('PDF'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00779E),
                                side: const BorderSide(
                                  color: Color(0xFF7DD3FC),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2 — APPOINTMENTS (image-31)
  // ---------------------------------------------------------------------------
  Widget _buildAppointmentsTab(PatientFullDossier? d) {
    final list = d?.appointments ?? const <PatientAppointmentItem>[];
    return _SectionCard(
      title: 'Appointments History',
      child: list.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No appointments booked for this patient.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : Column(
              children: list
                  .map(
                    (a) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a.appointmentNo} • ${a.doctorName}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${AppFormatters.formatSlashDate(a.date)}'
                                  '${a.timeSlot.isNotEmpty ? " • ${a.timeSlot}" : ""}'
                                  '${a.department.isNotEmpty ? " • ${a.department}" : ""}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a.status,
                              style: const TextStyle(
                                color: Color(0xFF0369A1),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3 — VISITS / OPD & IPD (image-32)
  // ---------------------------------------------------------------------------
  Widget _buildVisitsOpdIpdTab(PatientFullDossier? d) {
    final opdList = d?.opdEncounters ?? const <PatientOpdEncounter>[];
    final ipdList = d?.ipdAdmissions ?? const <IpdAdmission>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'OPD Consultations & Encounters',
          child: opdList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: Text(
                      'No OPD consultations recorded.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 580),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 95,
                                child: Text('OPD NO', style: _tableHeaderStyle),
                              ),
                              SizedBox(
                                width: 115,
                                child: Text('CASE REF', style: _tableHeaderStyle),
                              ),
                              SizedBox(
                                width: 95,
                                child: Text('DATE', style: _tableHeaderStyle),
                              ),
                              Expanded(
                                child: Text('DOCTOR', style: _tableHeaderStyle),
                              ),
                              SizedBox(
                                width: 85,
                                child: Text('CHARGE', style: _tableHeaderStyle),
                              ),
                              SizedBox(
                                width: 85,
                                child: Text('PAID', style: _tableHeaderStyle),
                              ),
                            ],
                          ),
                        ),
                        ...opdList.map(
                          (o) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.divider),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    o.opdNo,
                                    style: const TextStyle(
                                      color: Color(0xFF00779E),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: AppTheme.tabularNums,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 115,
                                  child: Text(
                                    o.caseRef.isEmpty ? '—' : o.caseRef,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: AppTheme.tabularNums,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    AppFormatters.formatSlashDate(o.date),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: AppTheme.tabularNums,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    o.doctorName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 85,
                                  child: Text(
                                    AppFormatters.formatCurrencyInr(o.charge),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: AppTheme.tabularNums,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 85,
                                  child: Text(
                                    AppFormatters.formatCurrencyInr(o.paid),
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: AppTheme.tabularNums,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'IPD Admissions',
          child: ipdList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: Text(
                      'No IPD admissions recorded.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: ipdList
                      .map(
                        (ipd) => InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (ipd.id.isEmpty) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => IpdPatientDetailScreen(
                                  ipdId: ipd.id,
                                  initialAdmission: ipd,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ipd.ipdNo}  •  ${ipd.bedDisplayLabel}',
                                        style: const TextStyle(
                                          color: Color(0xFF00779E),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${ipd.doctor.displayName}  •  ${AppFormatters.formatSlashDate(ipd.admissionDate)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ipd.isDischarged
                                        ? const Color(0xFFF1F5F9)
                                        : AppColors.successSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ipd.isDischarged ? 'Discharged' : 'Admitted',
                                    style: TextStyle(
                                      color: ipd.isDischarged
                                          ? AppColors.textSecondary
                                          : const Color(0xFF059669),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4 — SERVICES & ORDERS (image-33)
  // ---------------------------------------------------------------------------
  Widget _buildServicesAndOrdersTab(PatientFullDossier? d) {
    final orders = d?.serviceOrders ?? const <PatientServiceOrderItem>[];
    return _SectionCard(
      title: 'Linked Orders & Investigation Services',
      subtitle:
          'All tests, medicine prescriptions and blood bank issues linked to this patient.',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        'SERVICE TYPE',
                        style: _tableHeaderStyle,
                      ),
                    ),
                    SizedBox(
                      width: 145,
                      child: Text(
                        'INVOICE / BILL REFERENCE',
                        style: _tableHeaderStyle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'DESCRIPTION / TEST NAME',
                        style: _tableHeaderStyle,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'AMOUNT',
                        style: _tableHeaderStyle,
                      ),
                    ),
                    SizedBox(
                      width: 85,
                      child: Text(
                        'STATUS',
                        style: _tableHeaderStyle,
                      ),
                    ),
                  ],
                ),
              ),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: Text(
                      'No linked orders or investigation services recorded.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ...orders.map(
                  (o) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            o.serviceType,
                            style: const TextStyle(
                              color: Color(0xFF00779E),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: Text(
                            o.billReference,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTheme.tabularNums,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            o.description,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            AppFormatters.formatCurrencyInr(o.amount),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularNums,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text(
                            o.status,
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );

  // ---------------------------------------------------------------------------
  // TAB 5 — PATIENT DEMOGRAPHICS (image-34 — all 14 exact fields)
  // ---------------------------------------------------------------------------
  Widget _buildDemographicsTab() {
    final p = _patient;
    String dashOr(String s) => s.trim().isEmpty ? '-' : s.trim();
    String noneOr(String s) => s.trim().isEmpty ? 'None' : s.trim();

    final leftFields = <(String, String)>[
      ('Patient Full Name:', dashOr(p.patientName)),
      ('Unique Hospital ID (UHID):', dashOr(p.patientUniqueId)),
      ('Mobile Number:', dashOr(p.phone)),
      ('Email Address:', dashOr(p.email)),
      ('Gender:', dashOr(p.gender)),
      ('Age:', p.age > 0 ? '${p.age} Years' : '-'),
      (
        'Date of Birth:',
        p.dob != null ? AppFormatters.formatSlashDate(p.dob) : '-',
      ),
    ];

    final rightFields = <(String, String)>[
      ('Guardian / Parent Name:', dashOr(p.guardianName)),
      ('Guardian Relationship:', dashOr(p.guardianRelation)),
      ('Blood Group:', dashOr(p.bloodGroup)),
      ('Marital Status:', dashOr(p.maritalStatus)),
      ('Residential Address:', dashOr(p.address)),
      ('Known Allergies:', noneOr(p.knownAllergies)),
      ('TPA / Insurance:', noneOr(p.tpaInsurance)),
    ];

    return _SectionCard(
      title: 'Complete Demographic Record',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 620;
          if (twoCol) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: leftFields
                        .map((f) => _DemographicRow(label: f.$1, value: f.$2))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    children: rightFields
                        .map((f) => _DemographicRow(label: f.$1, value: f.$2))
                        .toList(),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              ...leftFields
                  .map((f) => _DemographicRow(label: f.$1, value: f.$2)),
              ...rightFields
                  .map((f) => _DemographicRow(label: f.$1, value: f.$2)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailingHeader;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    this.trailingHeader,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
          if (trailingHeader != null) ...[
            const SizedBox(height: 10),
            trailingHeader!,
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          child,
        ],
      ),
    );
  }
}

class _FinancialMetricCard extends StatelessWidget {
  final String label;
  final String amount;
  final String subtitle;
  final Color amountColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _FinancialMetricCard({
    required this.label,
    required this.amount,
    required this.subtitle,
    required this.amountColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amount,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFeatures: AppTheme.tabularNums,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00779E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DemographicRow extends StatelessWidget {
  final String label;
  final String value;

  const _DemographicRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
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
