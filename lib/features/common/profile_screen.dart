import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    final profile = await UserService.getProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.name;
        _phoneCtrl.text = profile.phone ?? '';
        _bioCtrl.text = profile.bio ?? '';
        _addressCtrl.text = profile.address ?? '';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = AuthService.instance.currentUser?.uid ?? '';
    await UserService.updateProfile(uid, {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    });
    await _loadProfile();
    if (mounted) {
      setState(() {
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final uid = AuthService.instance.currentUser?.uid ?? '';
    await UserService.uploadAvatar(uid, file);
    await _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final accent = _roleAccent(profile.role);

    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AidColors.background,
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: Text('Edit', style: TextStyle(color: accent)),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel',
                  style: TextStyle(color: AidColors.textSecondary)),
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save', style: TextStyle(color: accent)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _editing ? _pickPhoto : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  if (_editing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(16),
            Text(profile.name, style: AidTextStyles.headingLg),
            const Gap(4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.role.toUpperCase(),
                style: AidTextStyles.labelMd.copyWith(color: accent),
              ),
            ),
            const Gap(24),

            // Stats (role-specific)
            _buildStats(profile, accent),
            const Gap(24),

            // Edit fields
            if (_editing) ...[
              _field(label: 'Name', ctrl: _nameCtrl, icon: Icons.person_outline_rounded),
              const Gap(14),
              _field(label: 'Phone', ctrl: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const Gap(14),
              _field(label: 'Address', ctrl: _addressCtrl, icon: Icons.location_on_outlined),
              const Gap(14),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About me',
                  hintText: 'Tell others about yourself...',
                  prefixIcon: Icon(Icons.info_outline_rounded, size: 20),
                  alignLabelWithHint: true,
                ),
              ),
            ] else ...[
              _InfoCard(profile: profile),
            ],

            const Gap(24),
            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AuthService.instance.signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.error,
                  side: BorderSide(color: AidColors.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(UserProfile p, Color accent) {
    List<_StatItem> items = [];
    switch (p.role) {
      case 'donor':
        items = [
          _StatItem(label: 'Donations', value: '${p.totalDonations}', icon: Icons.handshake_rounded),
          _StatItem(label: 'Contributed', value: '₹${p.totalMonetaryDonated.toStringAsFixed(0)}', icon: Icons.currency_rupee_rounded),
        ];
        break;
      case 'volunteer':
        items = [
          _StatItem(label: 'Activities', value: '${p.activitiesJoined}', icon: Icons.event_available_rounded),
          _StatItem(label: 'Points', value: '${p.rewardPoints}', icon: Icons.star_rounded),
          _StatItem(label: 'Badges', value: '${p.badges.length}', icon: Icons.military_tech_rounded),
        ];
        break;
      case 'ngo':
        items = [
          _StatItem(label: 'Verified', value: p.ngoVerified ? 'Yes ✅' : 'Pending', icon: Icons.verified_rounded),
        ];
        break;
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Row(
        children: items
            .map((item) => Expanded(
                  child: Column(
                    children: [
                      Icon(item.icon, color: accent, size: 22),
                      const Gap(6),
                      Text(item.value,
                          style: AidTextStyles.headingMd.copyWith(color: accent)),
                      Text(item.label, style: AidTextStyles.bodySm),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Color _roleAccent(String role) {
    switch (role) {
      case 'donor':
        return AidColors.donorAccent;
      case 'volunteer':
        return AidColors.volunteerAccent;
      default:
        return AidColors.ngoAccent;
    }
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  _StatItem({required this.label, required this.value, required this.icon});
}

class _InfoCard extends StatelessWidget {
  final UserProfile profile;
  const _InfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(icon: Icons.email_outlined, label: 'Email', value: profile.email),
          if (profile.phone != null && profile.phone!.isNotEmpty)
            _Row(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone!),
          if (profile.address != null && profile.address!.isNotEmpty)
            _Row(icon: Icons.location_on_outlined, label: 'Address', value: profile.address!),
          if (profile.bio != null && profile.bio!.isNotEmpty)
            _Row(icon: Icons.info_outline_rounded, label: 'About', value: profile.bio!),
          if (profile.role == 'ngo') ...[
            if (profile.orgName != null)
              _Row(icon: Icons.business_outlined, label: 'Organisation', value: profile.orgName!),
            if (profile.regNumber != null)
              _Row(icon: Icons.numbers_rounded, label: 'Reg No.', value: profile.regNumber!),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AidColors.textSecondary),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AidTextStyles.labelSm.copyWith(
                        color: AidColors.textTertiary)),
                Text(value, style: AidTextStyles.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
