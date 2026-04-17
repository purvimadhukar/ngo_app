import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/impact_group.dart';
import '../../models/ngo_post.dart';
import 'donation_detail_screen.dart';

class ImpactGroupScreen extends StatefulWidget {
  final ImpactGroup group;
  const ImpactGroupScreen({super.key, required this.group});

  @override
  State<ImpactGroupScreen> createState() => _ImpactGroupScreenState();
}

class _ImpactGroupScreenState extends State<ImpactGroupScreen> {
  int _imageIndex = 0;

  Color get _typeColor {
    switch (widget.group.type) {
      case ImpactGroupType.children: return const Color(0xFFFF9800);
      case ImpactGroupType.elderly:  return const Color(0xFF7C3AED);
      case ImpactGroupType.women:    return const Color(0xFFE91E63);
      case ImpactGroupType.general:  return AidColors.ngoAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      backgroundColor: AidColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: g.imageUrls.isNotEmpty ? 300 : 160,
            pinned: true,
            backgroundColor: AidColors.background,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: g.imageUrls.isNotEmpty
                  ? _buildImageCarousel()
                  : _buildColorHero(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(g),
                  const Gap(20),
                  _buildStory(g),
                  const Gap(20),
                  _buildNeeds(g),
                  const Gap(20),
                  _buildImpactNumbers(g),
                  if (g.updates.isNotEmpty) ...[
                    const Gap(20),
                    _buildUpdates(g),
                  ],
                  const Gap(20),
                  _buildConsentNote(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(g),
    );
  }

  Widget _buildImageCarousel() {
    final g = widget.group;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: g.imageUrls.length,
          onPageChanged: (i) => setState(() => _imageIndex = i),
          itemBuilder: (_, i) => Image.network(
            g.imageUrls[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildColorHero(),
          ),
        ),
        // Bottom fade
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AidColors.background],
              ),
            ),
          ),
        ),
        // Consent badge
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 12),
                Gap(4),
                Text('Consent verified', style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ),
        // Page dots
        if (g.imageUrls.length > 1)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(g.imageUrls.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _imageIndex == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _imageIndex == i ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }

  Widget _buildColorHero() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_typeColor.withValues(alpha: 0.8), _typeColor.withValues(alpha: 0.4)],
        ),
      ),
      child: Center(
        child: Text(widget.group.type.emoji, style: const TextStyle(fontSize: 72)),
      ),
    );
  }

  Widget _buildHeader(ImpactGroup g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(g.type.emoji, style: const TextStyle(fontSize: 12)),
                  const Gap(4),
                  Text(
                    g.type.label.toUpperCase(),
                    style: AidTextStyles.labelSm.copyWith(
                      color: _typeColor, fontWeight: FontWeight.w800, fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              g.ngoName,
              style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
            ),
          ],
        ),
        const Gap(12),
        Text(g.title, style: AidTextStyles.displaySm),
        const Gap(6),
        Row(
          children: [
            Icon(Icons.people_rounded, size: 14, color: _typeColor),
            const Gap(5),
            Text(
              '${g.beneficiaryCount} ${g.type == ImpactGroupType.elderly ? 'residents' : g.type == ImpactGroupType.children ? 'children' : 'individuals'} need your help',
              style: AidTextStyles.bodyMd.copyWith(color: _typeColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStory(ImpactGroup g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('📖', 'Their Story'),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AidColors.borderDefault),
          ),
          child: Text(
            g.story,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary, height: 1.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNeeds(ImpactGroup g) {
    if (g.needs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('🙏', 'What They Need'),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: g.needs.map((need) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _typeColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              need,
              style: AidTextStyles.bodyMd.copyWith(
                color: _typeColor, fontWeight: FontWeight.w600,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildImpactNumbers(ImpactGroup g) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_typeColor.withValues(alpha: 0.1), _typeColor.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _typeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _numStat('${g.beneficiaryCount}', 'Beneficiaries'),
          _vDivider(),
          _numStat('${g.updates.length}', 'Updates Posted'),
          _vDivider(),
          _numStat('₹${_fmt(g.totalRaised)}', 'Raised'),
        ],
      ),
    );
  }

  Widget _numStat(String v, String label) => Expanded(
    child: Column(
      children: [
        Text(v, style: TextStyle(color: _typeColor, fontSize: 20, fontWeight: FontWeight.w800)),
        const Gap(2),
        Text(label, style: AidTextStyles.labelSm.copyWith(color: AidColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _vDivider() => Container(width: 1, height: 30, color: AidColors.borderDefault, margin: const EdgeInsets.symmetric(horizontal: 6));

  Widget _buildUpdates(ImpactGroup g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('📸', 'Impact Updates'),
        const Gap(10),
        ...g.updates.map((u) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AidColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (u.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(u.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
              if (u.imageUrl != null) const Gap(10),
              Text(u.text, style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary, height: 1.6)),
              const Gap(6),
              Text(
                DateFormat('d MMM yyyy').format(u.date),
                style: AidTextStyles.labelSm.copyWith(color: AidColors.textSecondary),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildConsentNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.ngoAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AidColors.ngoAccent, size: 16),
          const Gap(10),
          Expanded(
            child: Text(
              'All images and stories are shared with informed consent. No personally identifiable information is disclosed. Group-level data only.',
              style: AidTextStyles.bodySm.copyWith(color: AidColors.ngoAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ImpactGroup g) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            // Volunteer button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                label: const Text('Volunteer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.volunteerAccent,
                  side: const BorderSide(color: AidColors.volunteerAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const Gap(12),
            // Donate button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showDonateSheet(g),
                icon: Icon(g.type.emoji.isEmpty ? Icons.favorite_rounded : null,
                    size: 18),
                label: Text('Donate to ${g.type == ImpactGroupType.children ? "Children" : g.type == ImpactGroupType.elderly ? "Elders" : "Women"}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
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
    );
  }

  void _showDonateSheet(ImpactGroup g) {
    if (g.linkedPostId != null) {
      // Navigate to the linked post's donation screen
      FirebaseFirestore.instance.collection('posts').doc(g.linkedPostId).get().then((doc) {
        if (doc.exists && mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DonationDetailScreen(post: NgoPost.fromFirestore(doc)),
          ));
        }
      });
      return;
    }

    // Quick donate sheet for groups without a linked post
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AidColors.borderDefault, borderRadius: BorderRadius.circular(2)))),
            const Gap(16),
            Text('Donate to ${g.title}', style: AidTextStyles.headingMd),
            const Gap(4),
            Text('Your contribution goes directly to ${g.beneficiaryCount} ${g.type.label.toLowerCase()}',
                style: AidTextStyles.bodySm),
            const Gap(16),
            // Preset amounts
            Row(
              children: ['₹100', '₹500', '₹1000', '₹5000'].map((amt) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: OutlinedButton(
                    onPressed: () => amountCtrl.text = amt.replaceAll('₹', ''),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _typeColor,
                      side: BorderSide(color: _typeColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(amt, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              )).toList(),
            ),
            const Gap(12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18)),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text) ?? 0;
                  if (amt <= 0) return;
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  await FirebaseFirestore.instance.collection('impactGroups').doc(g.id)
                      .collection('donations').add({
                    'donorId': user.uid,
                    'donorName': user.displayName ?? user.email ?? 'Anonymous',
                    'amount': amt,
                    'donatedAt': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance.collection('impactGroups').doc(g.id)
                      .update({'totalRaised': FieldValue.increment(amt)});
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Donation submitted! Thank you 💜'),
                      backgroundColor: _typeColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Donate Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title) => Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const Gap(8),
      Text(title, style: AidTextStyles.headingMd),
    ],
  );

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toInt().toString();
  }
}
