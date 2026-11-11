import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/photo_picker.dart';
import '../../models/nurse_user.dart';
import '../../state/nurse_portal_controller.dart';
import '../../widgets/common_states.dart';
import '../../widgets/patient_avatar.dart';

/// Nurse `/profile` Screen matching `https://hospital.hrpocket.in/profile` (image-12, image-13, image-14, image-15):
/// - Hero Banner: Avatar with online dot & camera badge, `Sunita Rao`, `Nurse`, `ID: 9008`,
///   `nurse@gmail.com`, `Nursing`, `← Back to Dashboard`, `↑ Change Profile Photo`
/// - Exact 4 Tabs:
///   0. `Edit Profile Details` (`Personal & Contact Information`)
///   1. `Change Password` (`Update Account Password`)
///   2. `Professional Info` (`Hospital Employment & Role Details`)
///   3. `My Theme` (`Personal Theme` — 6 live themes)
class NurseProfileScreen extends StatefulWidget {
  final int initialTabIndex;

  const NurseProfileScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  late int _selectedTab;
  bool _uploadingPhoto = false;
  bool _savingProfile = false;
  bool _savingPassword = false;

  // Tab 0: Edit Profile Details controllers
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _currentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  String _selectedGender = '';
  String _selectedBloodGroup = '';
  bool _hydratedForm = false;

  // Tab 1: Change Password controllers
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _obscureCurrentPwd = true;
  bool _obscureNewPwd = true;
  bool _obscureConfirmPwd = true;

  static const List<String> _genderItems = ['', 'Male', 'Female', 'Other'];
  static const List<String> _bloodGroupItems = [
    '',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = NursePortalScope.read(context);
      _populateFromUser(controller.currentUser);
      final fresh = await controller.refreshCurrentUserProfile();
      if (mounted && fresh != null) {
        _populateFromUser(fresh, force: true);
      }
    });
  }

  void _populateFromUser(NurseUser? user, {bool force = false}) {
    if (user == null) return;
    if (_hydratedForm && !force) return;
    _firstNameCtrl.text = user.name;
    _surnameCtrl.text = user.surname;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone;
    _emergencyCtrl.text = user.emergencyContact;
    _dobCtrl.text = user.dobDdMmYyyy;
    _currentAddressCtrl.text = user.currentAddress;
    _permanentAddressCtrl.text = user.permanentAddress;

    final g = user.gender.trim();
    _selectedGender = _genderItems.firstWhere(
      (opt) => opt.toLowerCase() == g.toLowerCase(),
      orElse: () => '',
    );

    final bg = user.bloodGroup.trim().toUpperCase();
    _selectedBloodGroup = _bloodGroupItems.contains(bg) ? bg : '';
    _hydratedForm = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _dobCtrl.dispose();
    _currentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    DateTime initial = DateTime(1995, 1, 1);
    final existingUser = NursePortalScope.read(context).currentUser;
    if (existingUser?.dob != null) {
      initial = existingUser!.dob!;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1945),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      setState(() {
        _dobCtrl.text = '$dd-$mm-${picked.year}';
      });
    }
  }

  Future<void> _handleChangeProfilePhoto() async {
    final controller = NursePortalScope.read(context);
    if (ProfilePhotoPicker.supportsNativePicker) {
      final picked = await ProfilePhotoPicker.pickImage();
      if (picked == null || !mounted) return;
      setState(() => _uploadingPhoto = true);
      try {
        await controller.uploadAndSaveProfilePhoto(
          bytes: picked.bytes,
          filename: picked.filename,
          mimeType: picked.mimeType,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update profile photo: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      } finally {
        if (mounted) setState(() => _uploadingPhoto = false);
      }
      return;
    }

    // Mobile/Desktop fallback dialog for entering/updating image URL
    final urlCtrl = TextEditingController(
      text: controller.currentUser?.image ?? '',
    );
    final enteredUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            labelText: 'Profile Image URL or /uploads/... path',
            hintText: 'https://hospital.hrpocket.in/uploads/...',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 42)),
            onPressed: () => Navigator.of(ctx).pop(urlCtrl.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (enteredUrl == null || enteredUrl.isEmpty || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      await controller.uploadAndSaveProfilePhoto(directImageUrl: enteredUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile photo: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    FocusScope.of(context).unfocus();
    if (_firstNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First Name is required.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email Address (Login Username) is required.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final controller = NursePortalScope.read(context);
      // Convert `dd-mm-yyyy` to `yyyy-mm-dd` if entered in dd-mm-yyyy format
      String normalizedDob = _dobCtrl.text.trim();
      final dmyMatch =
          RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(normalizedDob);
      if (dmyMatch != null) {
        normalizedDob =
            '${dmyMatch.group(3)}-${dmyMatch.group(2)}-${dmyMatch.group(1)}';
      }

      await controller.updateCurrentUserProfile(
        name: _firstNameCtrl.text.trim(),
        surname: _surnameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        emergencyContact: _emergencyCtrl.text.trim(),
        gender: _selectedGender,
        dob: normalizedDob,
        bloodGroup: _selectedBloodGroup,
        currentAddress: _currentAddressCtrl.text.trim(),
        permanentAddress: _permanentAddressCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save profile: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _submitPasswordUpdate() async {
    FocusScope.of(context).unfocus();
    final cur = _currentPwdCtrl.text;
    final next = _newPwdCtrl.text;
    final confirm = _confirmPwdCtrl.text;

    if (cur.trim().isEmpty || next.trim().isEmpty || confirm.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all password fields.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New Password and Confirm New Password do not match.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await NursePortalScope.read(context).api.changePassword(
            currentPassword: cur,
            newPassword: next,
            confirmPassword: confirm,
          );
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account password updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update password: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _confirmLogout(NursePortalController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout from Nurse Portal?'),
        content: const Text(
          'Your active ward session will be closed safely.',
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
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      await controller.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = NursePortalScope.of(context);
    final user = controller.currentUser;
    final themePreset = controller.personalTheme;
    final isLightBanner = themePreset.id == 'glacier_blue';
    final bannerFg = isLightBanner ? const Color(0xFF0F172A) : Colors.white;
    final bannerSubFg =
        isLightBanner ? const Color(0xFF475569) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: themePreset.scaffoldColor,
      appBar: AppBar(
        backgroundColor: themePreset.appBarColor,
        foregroundColor: themePreset.appBarForeground,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: themePreset.appBarForeground,
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(controller),
            icon: Icon(
              Icons.logout_rounded,
              color: themePreset.appBarForeground,
              size: 20,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: themePreset.primaryColor,
        onRefresh: () async {
          final fresh = await controller.refreshCurrentUserProfile();
          if (fresh != null) _populateFromUser(fresh, force: true);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            // 1. HERO PROFILE BANNER (matches image-13, image-14, image-15)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themePreset.bannerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: isLightBanner
                    ? Border.all(color: AppColors.border)
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x180F172A),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar + Camera Icon + Green Online Dot (matching image-13..15)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLightBanner
                                    ? themePreset.primaryColor
                                    : Colors.white,
                                width: 2.2,
                              ),
                            ),
                            child: PatientAvatar(
                              name: user?.fullName ?? 'Sunita Rao',
                              imagePath: user?.image,
                              baseUrl: controller.baseUrl,
                              radius: 33,
                            ),
                          ),
                          // Top-right camera button
                          Positioned(
                            top: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: _uploadingPhoto
                                  ? null
                                  : _handleChangeProfilePhoto,
                              child: Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: themePreset.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Bottom-right green online dot
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  user?.fullName ?? 'Duty Nurse',
                                  style: TextStyle(
                                    color: bannerFg,
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                _BannerPill(
                                  text: user?.roleName ?? 'Nurse',
                                  isLight: isLightBanner,
                                ),
                                if (user != null &&
                                    user.staffCode.trim().isNotEmpty)
                                  _BannerPill(
                                    text: 'ID: ${user.staffCode}',
                                    isLight: isLightBanner,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                if (user != null && user.email.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: bannerSubFg,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: bannerSubFg,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (user != null && user.department.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.apartment_rounded,
                                        size: 14,
                                        color: bannerSubFg,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.department,
                                        style: TextStyle(
                                          color: bannerSubFg,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _BannerActionBtn(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back to Dashboard',
                        isLight: isLightBanner,
                        onTap: () {
                          controller
                              .setSelectedNavIndex(NurseNavIndex.dashboard);
                          Navigator.of(context).pop();
                        },
                      ),
                      _BannerActionBtn(
                        icon: Icons.upload_rounded,
                        label: _uploadingPhoto
                            ? 'Uploading...'
                            : 'Change Profile Photo',
                        isLight: isLightBanner,
                        onTap:
                            _uploadingPhoto ? null : _handleChangeProfilePhoto,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. EXACT 4-TAB BAR (`Edit Profile Details`, `Change Password`, `Professional Info`, `My Theme`)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ProfileTabChip(
                      icon: Icons.person_rounded,
                      label: 'Edit Profile Details',
                      selected: _selectedTab == 0,
                      activeColor: themePreset.primaryColor,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    const SizedBox(width: 6),
                    _ProfileTabChip(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      selected: _selectedTab == 1,
                      activeColor: themePreset.primaryColor,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                    const SizedBox(width: 6),
                    _ProfileTabChip(
                      icon: Icons.badge_outlined,
                      label: 'Professional Info',
                      selected: _selectedTab == 2,
                      activeColor: themePreset.primaryColor,
                      onTap: () => setState(() => _selectedTab = 2),
                    ),
                    const SizedBox(width: 6),
                    _ProfileTabChip(
                      icon: Icons.brush_rounded,
                      label: 'My Theme',
                      selected: _selectedTab == 3,
                      activeColor: themePreset.primaryColor,
                      onTap: () => setState(() => _selectedTab = 3),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. ACTIVE TAB CONTENT CARD
            if (_selectedTab == 0) _buildEditProfileTab(themePreset),
            if (_selectedTab == 1) _buildChangePasswordTab(themePreset),
            if (_selectedTab == 2)
              _buildProfessionalInfoTab(user, themePreset),
            if (_selectedTab == 3) _buildPersonalThemeTab(controller),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: Edit Profile Details (`Personal & Contact Information` — image-15)
  // ---------------------------------------------------------------------------
  Widget _buildEditProfileTab(NursePersonalTheme themePreset) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal & Contact Information',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('First Name', requiredField: true),
          TextField(
            controller: _firstNameCtrl,
            decoration: const InputDecoration(hintText: 'First Name'),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Surname / Last Name'),
          TextField(
            controller: _surnameCtrl,
            decoration: const InputDecoration(hintText: 'Surname / Last Name'),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Email Address (Login Username)', requiredField: true),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'nurse@gmail.com'),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Phone Number'),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+91 9876543210'),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Emergency Contact'),
          TextField(
            controller: _emergencyCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+91 9876543211'),
          ),
          const SizedBox(height: 12),

          // Gender & Date of Birth row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Gender'),
                    _StyledDropdownBox(
                      value: _selectedGender,
                      items: _genderItems
                          .map(
                            (g) => DropdownMenuItem<String>(
                              value: g,
                              child: Text(g.isEmpty ? 'Select Gender' : g),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedGender = v ?? ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Date of Birth'),
                    TextField(
                      controller: _dobCtrl,
                      readOnly: true,
                      onTap: _pickDob,
                      decoration: InputDecoration(
                        hintText: 'dd-mm-yyyy',
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                          ),
                          onPressed: _pickDob,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _FieldLabel('Blood Group'),
          _StyledDropdownBox(
            value: _selectedBloodGroup,
            items: _bloodGroupItems
                .map(
                  (bg) => DropdownMenuItem<String>(
                    value: bg,
                    child: Text(bg.isEmpty ? 'Select Blood Group' : bg),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedBloodGroup = v ?? ''),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Current Address'),
          TextField(
            controller: _currentAddressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Street address, City, State',
            ),
          ),
          const SizedBox(height: 12),

          _FieldLabel('Permanent Address'),
          TextField(
            controller: _permanentAddressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Permanent residential address',
            ),
          ),
          const SizedBox(height: 18),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: themePreset.primaryColor,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _savingProfile ? null : _saveProfileDetails,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              _savingProfile ? 'Saving Changes...' : 'Save Profile Details',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Change Password (`Update Account Password` — image-14)
  // ---------------------------------------------------------------------------
  Widget _buildChangePasswordTab(NursePersonalTheme themePreset) {
    return SoftSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Account Password',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ensure your account is using a strong password. You will need your current password to authorize this change.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          _FieldLabel('Current Password', requiredField: true),
          TextField(
            controller: _currentPwdCtrl,
            obscureText: _obscureCurrentPwd,
            decoration: InputDecoration(
              hintText: 'Enter your current password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPwd
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrentPwd = !_obscureCurrentPwd),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _FieldLabel('New Password', requiredField: true),
          TextField(
            controller: _newPwdCtrl,
            obscureText: _obscureNewPwd,
            decoration: InputDecoration(
              hintText: 'Enter new strong password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPwd
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                ),
                onPressed: () =>
                    setState(() => _obscureNewPwd = !_obscureNewPwd),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _FieldLabel('Confirm New Password', requiredField: true),
          TextField(
            controller: _confirmPwdCtrl,
            obscureText: _obscureConfirmPwd,
            decoration: InputDecoration(
              hintText: 'Re-enter new password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPwd
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 19,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: themePreset.primaryColor,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _savingPassword ? null : _submitPasswordUpdate,
            icon: const Icon(Icons.lock_reset_rounded, size: 18),
            label: Text(
              _savingPassword ? 'Updating Password...' : 'Update Password',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Professional Info (`Hospital Employment & Role Details` — image-13)
  // ---------------------------------------------------------------------------
  Widget _buildProfessionalInfoTab(
    NurseUser? user,
    NursePersonalTheme themePreset,
  ) {
    String valOrDash(String? v) =>
        (v != null && v.trim().isNotEmpty) ? v.trim() : '—';

    return SoftSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hospital Employment & Role Details',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'EMPLOYEE ID',
                        value: valOrDash(user?.staffCode),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'ASSIGNED ROLE',
                        value: valOrDash(user?.roleName),
                        valueColor: themePreset.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'DEPARTMENT',
                        value: valOrDash(user?.department),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'DESIGNATION',
                        value: valOrDash(user?.designation),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'SPECIALIST',
                        value: valOrDash(user?.specialist),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'QUALIFICATION',
                        value: valOrDash(user?.qualification),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'DATE OF JOINING',
                        value: user?.dateOfJoiningDisplay ?? '—',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProfMetaCell(
                        label: 'WORK SHIFT',
                        value: valOrDash(user?.workShift),
                      ),
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

  // ---------------------------------------------------------------------------
  // TAB 3: My Theme (`Personal Theme` — image-12)
  // ---------------------------------------------------------------------------
  Widget _buildPersonalThemeTab(NursePortalController controller) {
    final activeId = controller.personalThemeId;

    return SoftSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Theme',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This preference changes only your own device/browser and does not require Settings permission.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: NursePersonalTheme.presets.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (context, index) {
              final item = NursePersonalTheme.presets[index];
              final selected = item.id == activeId;
              return _PersonalThemeCard(
                preset: item,
                selected: selected,
                onTap: () => controller.setPersonalTheme(item.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final String text;
  final bool isLight;

  const _BannerPill({required this.text, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFE0F2FE) : const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? const Color(0xFFBAE6FD) : const Color(0x45FFFFFF),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isLight ? const Color(0xFF0369A1) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BannerActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLight;
  final VoidCallback? onTap;

  const _BannerActionBtn({
    required this.icon,
    required this.label,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0x28FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLight ? AppColors.border : const Color(0x45FFFFFF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isLight ? const Color(0xFF0F172A) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ProfileTabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFBFDBFE) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              icon,
              size: 16,
              color: selected ? activeColor : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? activeColor : const Color(0xFF475569),
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledDropdownBox extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool requiredField;

  const _FieldLabel(this.text, {this.requiredField = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          children: requiredField
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }
}

class _ProfMetaCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfMetaCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PersonalThemeCard extends StatelessWidget {
  final NursePersonalTheme preset;
  final bool selected;
  final VoidCallback onTap;

  const _PersonalThemeCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkCard = preset.isDarkBody;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkCard ? const Color(0xFF0B0D14) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? preset.primaryColor : AppColors.border,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Gradient Swatch (matching image-12)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: preset.bannerGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: preset.id == 'glacier_blue'
                      ? const Border(
                          bottom: BorderSide(color: AppColors.border),
                        )
                      : null,
                ),
              ),
            ),
            // Bottom Title + Subtitle + Selected Checkmark
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDarkCard
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: isDarkCard
                                ? const Color(0xFF818CF8)
                                : preset.primaryColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkCard
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
