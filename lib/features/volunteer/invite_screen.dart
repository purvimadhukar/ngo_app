import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/volunteer_service.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _inviteSent = false;
  final _shareLink = 'https://aidbridge.app/invite';

  Future<void> _recordInvite() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    await VolunteerService.recordInviteSent(uid);
    setState(() => _inviteSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        title: const Text('Invite Friends'),
        backgroundColor: AidColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AidColors.volunteerAccent.withValues(alpha: 0.3),
                      AidColors.volunteerAccent.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📣', style: TextStyle(fontSize: 52)),
                ),
              ),
            ),
            const Gap(24),
            Center(
              child: Text(
                'Spread the impact!',
                style: AidTextStyles.displaySm,
                textAlign: TextAlign.center,
              ),
            ),
            const Gap(8),
            Center(
              child: Text(
                'Invite friends to volunteer and earn reward points for each person who joins AidBridge.',
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const Gap(32),

            // Reward info cards
            _RewardCard(
              icon: '🎯',
              title: 'You invite a friend',
              subtitle: '+${15} pts instantly',
              color: AidColors.volunteerAccent,
            ),
            const Gap(10),
            _RewardCard(
              icon: '🤝',
              title: 'Friend joins and volunteers',
              subtitle: '+30 pts bonus for you',
              color: AidColors.ngoAccent,
            ),
            const Gap(10),
            _RewardCard(
              icon: '📣',
              title: 'Invite 5 friends',
              subtitle: 'Earn Recruiter badge',
              color: AidColors.donorAccent,
            ),
            const Gap(32),

            // Share link
            Text('Your invite link', style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary)),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AidColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AidColors.borderDefault),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _shareLink,
                      style: AidTextStyles.bodyMd.copyWith(color: AidColors.volunteerAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: AidColors.textSecondary,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _shareLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Share buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _recordInvite,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share via WhatsApp / SMS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AidColors.volunteerAccent,
                  foregroundColor: AidColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _shareLink));
                  _recordInvite();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')),
                  );
                },
                icon: const Icon(Icons.link_rounded),
                label: const Text('Copy Invite Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.volunteerAccent,
                  side: BorderSide(
                      color: AidColors.volunteerAccent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (_inviteSent) ...[
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AidColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AidColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AidColors.success, size: 20),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'Invite recorded! +15 points added to your account.',
                        style: AidTextStyles.bodySm.copyWith(color: AidColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _RewardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AidTextStyles.headingSm),
                Text(subtitle, style: AidTextStyles.bodySm.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
