import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../../models/resident.dart';

class ResidentDetailScreen extends StatefulWidget {
  final Resident resident;
  const ResidentDetailScreen({super.key, required this.resident});

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  Resident get r => widget.resident;

  static const _needIcons = {
    'medical':       Icons.medical_services_rounded,
    'food':          Icons.restaurant_rounded,
    'clothing':      Icons.checkroom_rounded,
    'companionship': Icons.favorite_rounded,
    'education':     Icons.school_rounded,
    'physiotherapy': Icons.self_improvement_rounded,
    'shelter':       Icons.home_rounded,
    'mental health': Icons.psychology_rounded,
  };

  Color get _urgencyColor => Color(
    Resident.urgencyColors[r.urgency] ?? 0xFF2B8CE6);

  @override
  Widget build(BuildContext context) {
    final accent = AidColors.donorAccent;

    return Scaffold(
      backgroundColor: AidColors.background,
      body: CustomScrollView(
        slivers: [

          // ── Photo hero header ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AidColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  r.photoUrl.isNotEmpty
                      ? Image.network(r.photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: AidColors.elevated,
                          child: const Icon(Icons.person_rounded,
                              size: 80, color: AidColors.textMuted),
                        ),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF07070A)],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Urgency badge
                  Positioned(
                    top: 100, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _urgencyColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle)),
                        const Gap(6),
                        Text(
                          r.urgency[0].toUpperCase() +
                              r.urgency.substring(1),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  // Name + care home at bottom
                  Positioned(
                    bottom: 16, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                          style: GoogleFonts.bricolageGrotesque(
                            color: Colors.white, fontSize: 32,
                            fontWeight: FontWeight.w800, letterSpacing: -1)),
                        const Gap(4),
                        Text(
                          '${r.age} years old  ·  ${r.careHomeName}',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70, fontSize: 13)),
                        if (r.careHomeLocation.isNotEmpty) ...[
                          const Gap(2),
                          Row(children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white54, size: 12),
                            const Gap(4),
                            Text(r.careHomeLocation,
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white54, fontSize: 12)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Stats row ──────────────────────────────────────────
                  Row(children: [
                    _StatChip(
                      icon: Icons.volunteer_activism_rounded,
                      label: '${r.totalDonations}',
                      sub: 'donations',
                      color: accent,
                    ),
                    const Gap(10),
                    _StatChip(
                      icon: Icons.people_rounded,
                      label: '${r.sponsorsCount}',
                      sub: 'sponsors',
                      color: AidColors.ngoAccent,
                    ),
                  ]),
                  const Gap(20),

                  // ── Monthly progress ───────────────────────────────────
                  if (r.monthlyTarget > 0) ...[
                    _SectionTitle('Monthly Sponsorship'),
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AidColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AidColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹${r.monthlyRaised.toStringAsFixed(0)} raised',
                                style: GoogleFonts.syne(
                                  color: AidColors.textPrimary,
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                              Text('of ₹${r.monthlyTarget.toStringAsFixed(0)}/mo',
                                style: GoogleFonts.spaceGrotesk(
                                    color: AidColors.textMuted, fontSize: 13)),
                            ],
                          ),
                          const Gap(10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (r.monthlyRaised / r.monthlyTarget)
                                  .clamp(0.0, 1.0),
                              color: accent,
                              backgroundColor: AidColors.elevated,
                              minHeight: 6,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            '${((r.monthlyRaised / r.monthlyTarget) * 100).clamp(0, 100).round()}% of monthly goal funded',
                            style: GoogleFonts.spaceGrotesk(
                                color: AidColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Gap(20),
                  ],

                  // ── Story ──────────────────────────────────────────────
                  _SectionTitle('Their Story'),
                  const Gap(10),
                  Text(r.story,
                    style: GoogleFonts.spaceGrotesk(
                      color: AidColors.textSecondary,
                      fontSize: 14, height: 1.7)),
                  const Gap(20),

                  // ── Needs ──────────────────────────────────────────────
                  _SectionTitle('What They Need'),
                  const Gap(12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: r.needs.map((need) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          _needIcons[need] ?? Icons.circle_rounded,
                          color: accent, size: 14),
                        const Gap(6),
                        Text(
                          need[0].toUpperCase() + need.substring(1),
                          style: GoogleFonts.spaceGrotesk(
                            color: AidColors.textPrimary,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    )).toList(),
                  ),
                  const Gap(32),

                  // ── Action buttons ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _showDonateSheet(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.volunteer_activism_rounded,
                          size: 18),
                      label: Text('Donate to ${r.name}',
                        style: GoogleFonts.syne(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const Gap(10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: r.monthlyTarget > 0
                            ? () => _showSponsorSheet(context)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AidColors.ngoAccent,
                          side: BorderSide(color: AidColors.ngoAccent
                              .withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.repeat_rounded, size: 16),
                        label: Text('Sponsor Monthly',
                          style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showMessageSheet(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AidColors.textSecondary,
                          side: BorderSide(
                              color: AidColors.borderDefault),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded, size: 16),
                        label: Text('Send a Message',
                          style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ]),
                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDonateSheet(BuildContext context) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String donationType = 'money';
    final accent = AidColors.donorAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: AidColors.borderStrong,
                borderRadius: BorderRadius.circular(2)))),
            const Gap(20),
            Text('Donate to ${r.name}',
              style: GoogleFonts.syne(color: AidColors.textPrimary,
                  fontSize: 20, fontWeight: FontWeight.w700)),
            const Gap(6),
            Text('Your donation goes directly to ${r.careHomeName}',
              style: GoogleFonts.spaceGrotesk(
                  color: AidColors.textMuted, fontSize: 13)),
            const Gap(20),
            // Type toggle
            Row(children: [
              _typeBtn(setSt, donationType, 'money', '₹ Money', accent),
              const Gap(8),
              _typeBtn(setSt, donationType, 'items', '📦 Items', accent),
            ]),
            const Gap(16),
            if (donationType == 'money') ...[
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.spaceGrotesk(
                    color: AidColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Amount in ₹',
                  hintStyle: GoogleFonts.spaceGrotesk(
                      color: AidColors.textMuted),
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: AidColors.textMuted, size: 18),
                  filled: true,
                  fillColor: AidColors.elevated,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ] else ...[
              TextField(
                controller: noteCtrl,
                style: GoogleFonts.spaceGrotesk(
                    color: AidColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'What are you donating? (e.g. 5kg rice, 2 blankets)',
                  hintStyle: GoogleFonts.spaceGrotesk(
                      color: AidColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AidColors.elevated,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
            const Gap(20),
            SizedBox(width: double.infinity, height: 50,
              child: FilledButton(
                onPressed: () async {
                  await _recordDonation(
                    type: donationType,
                    amount: double.tryParse(amtCtrl.text) ?? 0,
                    items: noteCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _showThanks();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Confirm Donation',
                  style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700)),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _typeBtn(StateSetter setSt, String current, String value,
      String label, Color accent) {
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSt(() {}),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? accent.withValues(alpha: 0.15) : AidColors.elevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? accent : AidColors.borderDefault,
              width: sel ? 1.5 : 1),
          ),
          child: Center(child: Text(label,
            style: GoogleFonts.spaceGrotesk(
              color: sel ? AidColors.textPrimary : AidColors.textMuted,
              fontWeight: FontWeight.w600, fontSize: 13))),
        ),
      ),
    );
  }

  void _showSponsorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AidColors.borderStrong,
              borderRadius: BorderRadius.circular(2)))),
          const Gap(20),
          Text('Sponsor ${r.name} Monthly',
            style: GoogleFonts.syne(color: AidColors.textPrimary,
                fontSize: 20, fontWeight: FontWeight.w700)),
          const Gap(8),
          Text(
            'Your monthly contribution helps ensure ${r.name} receives consistent support of ₹${r.monthlyTarget.toStringAsFixed(0)} every month.',
            style: GoogleFonts.spaceGrotesk(
                color: AidColors.textMuted, fontSize: 13, height: 1.5)),
          const Gap(24),
          SizedBox(width: double.infinity, height: 50,
            child: FilledButton(
              onPressed: () async {
                await _recordSponsorship();
                if (context.mounted) Navigator.pop(context);
                if (mounted) _showThanks(isSponsor: true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AidColors.ngoAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Sponsor ₹${r.monthlyTarget.toStringAsFixed(0)}/month',
                style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
            )),
          const Gap(8),
          Center(child: Text('You can cancel anytime from your profile.',
            style: GoogleFonts.spaceGrotesk(
                color: AidColors.textMuted, fontSize: 11))),
          const Gap(8),
        ]),
      ),
    );
  }

  void _showMessageSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AidColors.borderStrong,
              borderRadius: BorderRadius.circular(2)))),
          const Gap(20),
          Text('Send a Message',
            style: GoogleFonts.syne(color: AidColors.textPrimary,
                fontSize: 20, fontWeight: FontWeight.w700)),
          const Gap(6),
          Text(
            'Your message will be passed to ${r.careHomeName} for ${r.name}.',
            style: GoogleFonts.spaceGrotesk(
                color: AidColors.textMuted, fontSize: 13)),
          const Gap(20),
          TextField(
            controller: ctrl,
            maxLines: 4,
            style: GoogleFonts.spaceGrotesk(
                color: AidColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write your message here...',
              hintStyle: GoogleFonts.spaceGrotesk(
                  color: AidColors.textMuted),
              filled: true,
              fillColor: AidColors.elevated,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const Gap(16),
          SizedBox(width: double.infinity, height: 50,
            child: FilledButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await _sendMessage(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message sent to ${r.careHomeName}!',
                        style: GoogleFonts.spaceGrotesk()),
                      backgroundColor: AidColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AidColors.donorAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Send Message',
                style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
            )),
        ]),
      ),
    );
  }

  Future<void> _recordDonation({
    required String type, double amount = 0, String items = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    final donRef = FirebaseFirestore.instance
        .collection('resident_donations').doc();
    batch.set(donRef, {
      'residentId': r.id,
      'donorId':    uid,
      'type':       type,
      'amount':     amount,
      'items':      items,
      'createdAt':  FieldValue.serverTimestamp(),
    });

    // Increment counters on resident doc
    final resRef = FirebaseFirestore.instance
        .collection('residents').doc(r.id);
    batch.update(resRef, {
      'totalDonations': FieldValue.increment(1),
      if (type == 'money') 'monthlyRaised': FieldValue.increment(amount),
    });

    await batch.commit();
  }

  Future<void> _recordSponsorship() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('resident_sponsors').add({
      'residentId':   r.id,
      'donorId':      uid,
      'monthlyAmount': r.monthlyTarget,
      'createdAt':    FieldValue.serverTimestamp(),
      'active':       true,
    });
    await FirebaseFirestore.instance
        .collection('residents').doc(r.id)
        .update({'sponsorsCount': FieldValue.increment(1)});
  }

  Future<void> _sendMessage(String text) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('resident_messages').add({
      'residentId':  r.id,
      'careHomeId':  r.careHomeId,
      'donorId':     uid,
      'message':     text,
      'read':        false,
      'createdAt':   FieldValue.serverTimestamp(),
    });
  }

  void _showThanks({bool isSponsor = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSponsor
              ? '🙏 You are now sponsoring ${r.name}!'
              : '❤️ Thank you! Your donation is recorded.',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        backgroundColor: AidColors.donorAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.syne(
      color: AidColors.textPrimary,
      fontSize: 16, fontWeight: FontWeight.w700));
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  const _StatChip({required this.icon, required this.label,
      required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const Gap(10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
            style: GoogleFonts.syne(color: AidColors.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w700)),
          Text(sub,
            style: GoogleFonts.spaceGrotesk(
                color: AidColors.textMuted, fontSize: 11)),
        ]),
      ]),
    ),
  );
}
