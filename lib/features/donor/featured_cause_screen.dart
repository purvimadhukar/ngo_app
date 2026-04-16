import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';

/// Dedicated campaign page for Manasa Medical Trust (and any featured cause).
/// Reads from Firestore: campaigns/{campaignId}
class FeaturedCauseScreen extends StatefulWidget {
  final String campaignId;
  const FeaturedCauseScreen({super.key, this.campaignId = 'manasa_medical_trust'});

  @override
  State<FeaturedCauseScreen> createState() => _FeaturedCauseScreenState();
}

class _FeaturedCauseScreenState extends State<FeaturedCauseScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  bool _donated = false;
  String? _selectedPreset;

  static const _presets = ['₹100', '₹500', '₹1,000', '₹5,000'];
  static const _presetValues = [100.0, 500.0, 1000.0, 5000.0];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _donate(Map<String, dynamic> campaign) async {
    final amtStr = _amountCtrl.text.replaceAll(',', '').replaceAll('₹', '').trim();
    final amount = double.tryParse(amtStr) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid donation amount'),
          backgroundColor: AidColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Write donation to campaign subcollection
      final donRef = db
          .collection('campaigns')
          .doc(widget.campaignId)
          .collection('donations')
          .doc();
      batch.set(donRef, {
        'donorId': user.uid,
        'donorName': user.displayName ?? user.email ?? 'Anonymous',
        'donorEmail': user.email ?? '',
        'amount': amount,
        'note': _noteCtrl.text.trim(),
        'status': 'pending',
        'donatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment totalRaised on campaign doc
      final campRef = db.collection('campaigns').doc(widget.campaignId);
      batch.update(campRef, {
        'totalRaised': FieldValue.increment(amount),
        'donorCount': FieldValue.increment(1),
      });

      // 3. Update user stats
      batch.update(db.collection('users').doc(user.uid), {
        'totalMonetaryDonated': FieldValue.increment(amount),
        'totalDonations': FieldValue.increment(1),
        'rewardPoints': FieldValue.increment(20),
      });

      await batch.commit();

      if (mounted) {
        setState(() { _loading = false; _donated = true; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AidColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .doc(widget.campaignId)
          .snapshots(),
      builder: (context, snap) {
        final campaign = snap.data?.data() as Map<String, dynamic>? ?? _defaultCampaign;
        return _buildPage(campaign);
      },
    );
  }

  Widget _buildPage(Map<String, dynamic> campaign) {
    final totalRaised = (campaign['totalRaised'] ?? 0).toDouble();
    final goal = (campaign['goal'] ?? 1000000).toDouble();
    final progress = (totalRaised / goal).clamp(0.0, 1.0);
    final donorCount = campaign['donorCount'] ?? 0;

    return Scaffold(
      backgroundColor: AidColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AidColors.background,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background (placeholder until real image added)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1a1060), Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                    ),
                  ),
                  // Pattern overlay
                  Opacity(
                    opacity: 0.06,
                    child: Image.network(
                      'https://www.transparenttextures.com/patterns/cubes.png',
                      repeat: ImageRepeat.repeat,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  // Content
                  Positioned(
                    bottom: 28,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            '⭐  FEATURED CAUSE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Gap(10),
                        Text(
                          campaign['name'] ?? 'Manasa Medical Trust',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          campaign['tagline'] ?? 'Caring for those who cared for us',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gradient bottom fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AidColors.background],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Fundraising Progress ───────────────────────────
                  _buildFundraisingCard(totalRaised, goal, progress, donorCount),
                  const Gap(24),

                  // ── Quick Stats ────────────────────────────────────
                  _buildImpactStats(campaign),
                  const Gap(24),

                  // ── About ──────────────────────────────────────────
                  _buildAboutSection(campaign),
                  const Gap(24),

                  // ── What We Need ───────────────────────────────────
                  _buildNeedsSection(campaign),
                  const Gap(24),

                  // ── Donate Section ─────────────────────────────────
                  if (_donated)
                    _buildSuccessCard()
                  else ...[
                    _buildDonateSection(),
                  ],
                  const Gap(24),

                  // ── Website Link ───────────────────────────────────
                  _buildWebsiteCard(campaign),
                  const Gap(24),

                  // ── Recent Donors ──────────────────────────────────
                  _buildRecentDonors(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _donated ? null : _buildBottomBar(campaign),
    );
  }

  Widget _buildFundraisingCard(double raised, double goal, double progress, int donorCount) {
    final pct = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.12),
            const Color(0xFF4F46E5).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatMoney(raised)}',
                style: AidTextStyles.displaySm.copyWith(color: const Color(0xFF7C3AED)),
              ),
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'raised of ₹${_formatMoney(goal)} goal',
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AidColors.borderDefault,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              Text(
                '$pct% funded',
                style: AidTextStyles.labelMd.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.people_rounded, size: 14, color: AidColors.textSecondary),
              const Gap(4),
              Text(
                '$donorCount donors',
                style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStats(Map<String, dynamic> campaign) {
    final stats = [
      {'icon': '👴', 'value': campaign['residentsCount']?.toString() ?? '45+', 'label': 'Residents'},
      {'icon': '🏥', 'value': campaign['yearsActive']?.toString() ?? '12+', 'label': 'Years Active'},
      {'icon': '👩‍⚕️', 'value': campaign['staffCount']?.toString() ?? '20+', 'label': 'Caregivers'},
      {'icon': '❤️', 'value': campaign['livesImpacted']?.toString() ?? '500+', 'label': 'Lives Touched'},
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AidColors.borderDefault),
            ),
            child: Column(
              children: [
                Text(s['icon']!, style: const TextStyle(fontSize: 20)),
                const Gap(4),
                Text(
                  s['value']!,
                  style: AidTextStyles.headingMd.copyWith(color: AidColors.textPrimary),
                ),
                Text(
                  s['label']!,
                  style: AidTextStyles.labelSm.copyWith(color: AidColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> campaign) {
    final story = campaign['story'] as String? ??
        'Manasa Medical Trust runs a dedicated old age home providing shelter, medical care, and compassionate support to senior citizens who need it most. Every resident receives dignified care, nutritious meals, regular medical check-ups, and a warm community — because everyone deserves to age with grace.\n\nYour donation directly funds medicines, daily meals, caregiver salaries, and facility maintenance for our beloved residents.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('🏡', 'Our Story'),
        const Gap(12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AidColors.borderDefault),
          ),
          child: Text(
            story,
            style: AidTextStyles.bodyMd.copyWith(
              color: AidColors.textSecondary,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsSection(Map<String, dynamic> campaign) {
    final needs = (campaign['needs'] as List<dynamic>?) ??
        [
          {'icon': '💊', 'title': 'Monthly Medicines', 'desc': 'Regular medication for 45+ residents with chronic conditions', 'cost': '₹35,000/month'},
          {'icon': '🍱', 'title': 'Daily Nutrition', 'desc': 'Three nutritious meals a day for every resident', 'cost': '₹45,000/month'},
          {'icon': '👩‍⚕️', 'title': 'Caregiver Salaries', 'desc': 'Trained, compassionate staff who care round-the-clock', 'cost': '₹80,000/month'},
          {'icon': '🏠', 'title': 'Facility Upkeep', 'desc': 'Maintenance, utilities, hygiene, and safety equipment', 'cost': '₹25,000/month'},
          {'icon': '🩺', 'title': 'Medical Checkups', 'desc': 'Monthly doctor visits and specialist consultations', 'cost': '₹20,000/month'},
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('🙏', 'Where Your Money Goes'),
        const Gap(12),
        ...needs.map((n) {
          final need = n is Map ? n : {};
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AidColors.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(need['icon']?.toString() ?? '📦',
                    style: const TextStyle(fontSize: 24)),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        need['title']?.toString() ?? '',
                        style: AidTextStyles.headingSm,
                      ),
                      const Gap(2),
                      Text(
                        need['desc']?.toString() ?? '',
                        style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    need['cost']?.toString() ?? '',
                    style: AidTextStyles.labelSm.copyWith(
                      color: const Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDonateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('💜', 'Make a Donation'),
        const Gap(12),
        // Preset amounts
        Row(
          children: List.generate(_presets.length, (i) {
            final selected = _selectedPreset == _presets[i];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPreset = _presets[i];
                    _amountCtrl.text = _presetValues[i].toInt().toString();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF7C3AED)
                        : AidColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF7C3AED)
                          : AidColors.borderDefault,
                    ),
                  ),
                  child: Text(
                    _presets[i],
                    textAlign: TextAlign.center,
                    style: AidTextStyles.labelMd.copyWith(
                      color: selected ? Colors.white : AidColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const Gap(12),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
          onChanged: (_) => setState(() => _selectedPreset = null),
          decoration: const InputDecoration(
            labelText: 'Custom Amount (₹)',
            hintText: 'Enter any amount',
            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
          ),
        ),
        const Gap(12),
        TextFormField(
          controller: _noteCtrl,
          maxLines: 2,
          style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Message (optional)',
            hintText: 'A kind word for the residents…',
            prefixIcon: Icon(Icons.message_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.12),
            AidColors.ngoAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const Gap(12),
          Text(
            'Thank you!',
            style: AidTextStyles.displaySm.copyWith(color: const Color(0xFF7C3AED)),
          ),
          const Gap(6),
          Text(
            'Your donation has been submitted.\nManasa Medical Trust will receive it and confirm shortly.',
            textAlign: TextAlign.center,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary, height: 1.6),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF7C3AED), size: 18),
              const Gap(6),
              Text(
                '+20 reward points earned',
                style: AidTextStyles.bodyMd.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCard(Map<String, dynamic> campaign) {
    final url = campaign['website'] ?? 'https://www.manasamedicaltrust.org';
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AidColors.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AidColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: AidColors.info, size: 20),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visit our website', style: AidTextStyles.headingSm),
                  Text(url, style: AidTextStyles.bodySm.copyWith(color: AidColors.info)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AidColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDonors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('💝', 'Recent Supporters'),
        const Gap(12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('campaigns')
              .doc(widget.campaignId)
              .collection('donations')
              .orderBy('donatedAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AidColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AidColors.borderDefault),
                ),
                child: Center(
                  child: Text(
                    'Be the first to donate 💜',
                    style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: AidColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AidColors.borderDefault),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AidColors.borderDefault,
                  indent: 16,
                ),
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final name = d['donorName'] as String? ?? 'Anonymous';
                  final amount = (d['amount'] ?? 0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            name,
                            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                          ),
                        ),
                        Text(
                          '₹${amount.toInt()}',
                          style: AidTextStyles.headingSm.copyWith(color: const Color(0xFF7C3AED)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> campaign) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF7C3AED), size: 15),
                const Gap(5),
                Text(
                  'Earn +20 reward points with your donation',
                  style: AidTextStyles.bodySm.copyWith(color: const Color(0xFF7C3AED)),
                ),
              ],
            ),
            const Gap(10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _donate(campaign),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_rounded, size: 18),
                          Gap(8),
                          Text(
                            'Donate to Manasa Medical Trust',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

  Widget _sectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const Gap(8),
        Text(title, style: AidTextStyles.headingMd),
      ],
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toInt().toString();
  }

  static const _defaultCampaign = <String, dynamic>{};
}
