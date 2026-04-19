import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const _email    = 'majorprojectclaude@gmail.com';
  static const _phone    = '+91 98765 43210'; // Update with real number
  static const _website  = 'https://aidbridge.in'; // Update when live
  static const _address  = 'AidBridge Platform, India';
  static const _instagram = 'https://instagram.com/aidbridge_in'; // Update
  static const _linkedin  = 'https://linkedin.com/company/aidbridge';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AidColors.ngoAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A3D), Color(0xFF4F46E5), Color(0xFF8B7FE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              '● LIVE PLATFORM',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      const Text(
                        'AidBridge',
                        style: TextStyle(
                          color: Colors.white, fontSize: 36,
                          fontWeight: FontWeight.w900, height: 1,
                        ),
                      ),
                      const Gap(6),
                      const Text(
                        'BRIDGE HEARTS · BUILD FUTURES',
                        style: TextStyle(
                          color: Colors.white60, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 2.5,
                        ),
                      ),
                      const Gap(16),
                      const Text(
                        'We connect NGOs, donors, and volunteers to create '
                        'real, measurable impact for communities across India.',
                        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Contact cards ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Reach Us ────────────────────────────────────────────────────
                _sectionLabel('Reach Us'),
                const Gap(10),
                _ContactCard(
                  icon: Icons.email_outlined,
                  color: AidColors.donorAccent,
                  title: 'Email',
                  subtitle: _email,
                  onTap: () => _launch('mailto:$_email'),
                  onLongPress: () => _copyToClipboard(context, _email, 'Email'),
                ),
                const Gap(10),
                _ContactCard(
                  icon: Icons.phone_outlined,
                  color: AidColors.ngoAccent,
                  title: 'Phone',
                  subtitle: _phone,
                  onTap: () => _launch('tel:${_phone.replaceAll(' ', '')}'),
                  onLongPress: () => _copyToClipboard(context, _phone, 'Phone number'),
                ),
                const Gap(10),
                _ContactCard(
                  icon: Icons.language_rounded,
                  color: const Color(0xFF4F46E5),
                  title: 'Website',
                  subtitle: _website,
                  onTap: () => _launch(_website),
                  onLongPress: () => _copyToClipboard(context, _website, 'Website URL'),
                ),
                const Gap(24),

                // ── Social ───────────────────────────────────────────────────────
                _sectionLabel('Social Media'),
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram',
                        color: const Color(0xFFE91E63),
                        onTap: () => _launch(_instagram),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.work_outline_rounded,
                        label: 'LinkedIn',
                        color: const Color(0xFF0077B5),
                        onTap: () => _launch(_linkedin),
                      ),
                    ),
                  ],
                ),
                const Gap(24),

                // ── NGO Onboarding ───────────────────────────────────────────────
                _sectionLabel('Register Your Organisation'),
                const Gap(10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AidColors.ngoAccent.withValues(alpha: 0.12),
                        AidColors.donorAccent.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AidColors.ngoAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_rounded, color: AidColors.ngoAccent, size: 22),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Is your NGO or Care Centre not listed?',
                                    style: AidTextStyles.headingSm),
                                Text('We\'d love to onboard you — it\'s free.',
                                    style: AidTextStyles.bodySm),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),
                      const Divider(color: AidColors.borderSubtle, height: 1),
                      const Gap(14),
                      _OnboardStep(step: '1', text: 'Download AidBridge and tap Sign Up'),
                      const Gap(8),
                      _OnboardStep(step: '2', text: 'Select "Organisation" → choose your type (NGO, Old Age Home, Orphanage, Shelter, etc.)'),
                      const Gap(8),
                      _OnboardStep(step: '3', text: 'Fill in your organisation name, mission, and category'),
                      const Gap(8),
                      _OnboardStep(step: '4', text: 'Submit verification documents from your dashboard → get verified badge'),
                      const Gap(8),
                      _OnboardStep(step: '5', text: 'Start posting donation drives, events, and connecting with donors!'),
                      const Gap(16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launch('mailto:$_email?subject=NGO Onboarding Request&body=Hello AidBridge team, I would like to register my organisation...'),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Request Onboarding via Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AidColors.ngoAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── About ────────────────────────────────────────────────────────
                _sectionLabel('About AidBridge'),
                const Gap(10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AidColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AboutRow(Icons.volunteer_activism_rounded, AidColors.donorAccent,
                          'Mission', 'Bridge the gap between NGOs, donors, and volunteers through technology'),
                      const Gap(14),
                      const Divider(color: AidColors.borderSubtle, height: 1),
                      const Gap(14),
                      _AboutRow(Icons.people_rounded, AidColors.volunteerAccent,
                          'Who we serve', 'NGOs, old age homes, orphanages, welfare centres, individual donors, corporate volunteers'),
                      const Gap(14),
                      const Divider(color: AidColors.borderSubtle, height: 1),
                      const Gap(14),
                      _AboutRow(Icons.verified_rounded, AidColors.ngoAccent,
                          'Transparency', 'All NGOs go through a verification process. Donations are tracked with proof-of-impact photos'),
                      const Gap(14),
                      const Divider(color: AidColors.borderSubtle, height: 1),
                      const Gap(14),
                      _AboutRow(Icons.lock_outline_rounded, AidColors.info,
                          'Privacy', 'Beneficiary data is consent-based and shown only as group profiles — never individual personal information'),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Footer ───────────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'AidBridge',
                        style: TextStyle(
                          color: AidColors.ngoAccent,
                          fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Making a difference, one bridge at a time',
                        style: AidTextStyles.bodySm,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        _address,
                        style: AidTextStyles.labelSm,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: AidTextStyles.headingMd,
  );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
                  const Gap(2),
                  Text(subtitle, style: AidTextStyles.headingSm),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const Gap(6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _OnboardStep extends StatelessWidget {
  final String step;
  final String text;
  const _OnboardStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: AidColors.ngoAccent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(step, style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800,
            )),
          ),
        ),
        const Gap(10),
        Expanded(
          child: Text(text, style: AidTextStyles.bodyMd.copyWith(height: 1.5)),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _AboutRow(this.icon, this.color, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
              const Gap(2),
              Text(value, style: AidTextStyles.bodyMd.copyWith(height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
