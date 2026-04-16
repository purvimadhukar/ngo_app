import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AidColors.background,
      ),
      body: FutureBuilder<UserProfile?>(
        future: UserService.getProfile(uid),
        builder: (context, snap) {
          final profile = snap.data;
          final accent = profile != null ? _roleAccent(profile.role) : AidColors.ngoAccent;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile section
              if (profile != null) ...[
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AidColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AidColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
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
                                    fontSize: 20,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name, style: AidTextStyles.headingMd),
                              Text(profile.email, style: AidTextStyles.bodySm),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  profile.role.toUpperCase(),
                                  style: AidTextStyles.labelSm.copyWith(color: accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AidColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
              ],

              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              const Gap(24),

              _SectionHeader(title: 'Notifications'),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: accent,
                ),
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Email Updates',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                  activeThumbColor: accent,
                ),
              ),
              const Gap(24),

              _SectionHeader(title: 'About'),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About AidBridge',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'AidBridge',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 AidBridge. All rights reserved.',
                ),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
              const Gap(24),

              _SectionHeader(title: 'Account Actions'),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                titleColor: AidColors.error,
                iconColor: AidColors.error,
                onTap: () => _confirmSignOut(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final emailCtrl = TextEditingController(
      text: AuthService.instance.currentUser?.email ?? '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'We\'ll send a password reset link to your email.'),
            const Gap(12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // sendPasswordResetEmail would go here
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AidColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.signOut();
    }
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AidTextStyles.labelSm.copyWith(
          color: AidColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.titleColor,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: iconColor ?? AidColors.textSecondary),
        title: Text(
          title,
          style: AidTextStyles.bodyMd.copyWith(
              color: titleColor ?? AidColors.textPrimary),
        ),
        trailing: trailing ?? (onTap != null
            ? const Icon(Icons.chevron_right_rounded, size: 18)
            : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
