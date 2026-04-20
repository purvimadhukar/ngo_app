import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/donation.dart';
import '../../models/resident.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import 'resident_detail_screen.dart';

// ─── Public entry point ────────────────────────────────────────────────────────

class DonorImpactScreen extends StatelessWidget {
  const DonorImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<Donation>>(
      stream: DonationService.donorHistory(uid),
      builder: (ctx, snap) {
        final donations = snap.data ?? [];
        return _ImpactBody(uid: uid, donations: donations);
      },
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────

class _ImpactBody extends StatelessWidget {
  final String uid;
  final List<Donation> donations;

  const _ImpactBody({required this.uid, required this.donations});

  // Compute stats
  double get _totalMoney =>
      donations.fold(0.0, (s, d) => s + (d.monetaryAmount ?? 0));

  int get _itemCount =>
      donations.where((d) => d.monetaryAmount == null || d.monetaryAmount == 0).length;

  int get _completedCount =>
      donations.where((d) => d.status == DonationStatus.completed || d.status == DonationStatus.confirmed).length;

  int get _impactScore {
    // Simple formula: ₹1 = 1 pt, item = 20 pts, completed = bonus 10 pts each
    return (_totalMoney + _itemCount * 20 + _completedCount * 10).round();
  }

  Map<String, int> get _byCategory {
    final map = <String, int>{};
    for (final d in donations) {
      final key = d.type.name;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.donorBackground,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HeroHeader(score: _impactScore, totalMoney: _totalMoney)),

          // ── Quick stats row ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  _StatCard(value: '${donations.length}', label: 'Total\nDonations', icon: Icons.volunteer_activism_rounded),
                  const Gap(10),
                  _StatCard(value: '$_itemCount', label: 'Items\nDonated', icon: Icons.inventory_2_outlined),
                  const Gap(10),
                  _StatCard(value: '$_completedCount', label: 'Confirmed\nDeliveries', icon: Icons.check_circle_outline_rounded),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Gap(24)),

          // ── Sponsored residents ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _SponsoredResidentsSection(uid: uid)),

          const SliverToBoxAdapter(child: Gap(24)),

          // ── Category breakdown ───────────────────────────────────────────────
          if (_byCategory.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CategoryBreakdown(byCategory: _byCategory),
              ),
            ),

          const SliverToBoxAdapter(child: Gap(24)),

          // ── Recent activity ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Recent Activity', style: AidTextStyles.headingMd),
            ),
          ),

          if (donations.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('💛', style: TextStyle(fontSize: 48)),
                    const Gap(12),
                    Text('Your journey starts here',
                        style: AidTextStyles.headingMd),
                    const Gap(6),
                    Text(
                      'Make your first donation and watch your impact grow.',
                      textAlign: TextAlign.center,
                      style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _DonationRow(donation: donations[i]),
                ),
                childCount: donations.length,
              ),
            ),

          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }
}

// ─── Hero Header with animated impact score ────────────────────────────────────

class _HeroHeader extends StatefulWidget {
  final int score;
  final double totalMoney;
  const _HeroHeader({required this.score, required this.totalMoney});

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _tier(int score) {
    if (score >= 5000) return 'Champion';
    if (score >= 2000) return 'Advocate';
    if (score >= 500)  return 'Supporter';
    if (score >= 100)  return 'Helper';
    return 'Newcomer';
  }

  Color _tierColor(int score) {
    if (score >= 5000) return const Color(0xFFFFD700);
    if (score >= 2000) return const Color(0xFF9B4189);
    if (score >= 500)  return AidColors.ngoAccent;
    if (score >= 100)  return const Color(0xFF4CAF50);
    return AidColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final tier  = _tier(widget.score);
    final tColor = _tierColor(widget.score);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AidColors.donorBackground,
            AidColors.donorAccent.withValues(alpha: 0.25),
            AidColors.donorBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: tColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              '⭐ $tier',
              style: TextStyle(
                color: tColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Gap(16),
          // Animated score ring
          ScaleTransition(
            scale: _pulse,
            child: _ScoreRing(score: widget.score, color: tColor),
          ),
          const Gap(20),
          // Total raised
          Text(
            '₹${_fmt(widget.totalMoney)} raised',
            style: AidTextStyles.headingLg.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(4),
          Text(
            'Your generosity makes lives better',
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Score Ring painter ────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = math.min(score / 5000.0, 1.0);
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _RingPainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'pts',
                style: AidTextStyles.labelSm.copyWith(color: AidColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 10;

    // Track
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ─── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: AidColors.donorAccent, size: 20),
            const Gap(6),
            Text(value,
                style: AidTextStyles.headingMd.copyWith(fontWeight: FontWeight.w900)),
            const Gap(2),
            Text(label,
                style: AidTextStyles.labelSm.copyWith(
                    color: AidColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Sponsored residents section ───────────────────────────────────────────────

class _SponsoredResidentsSection extends StatelessWidget {
  final String uid;
  const _SponsoredResidentsSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('resident_sponsors')
          .where('donorId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final residentIds = docs
            .map((d) => (d.data() as Map)['residentId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text('People You Sponsor', style: AidTextStyles.headingMd),
                  const Spacer(),
                  Text('${residentIds.length} resident${residentIds.length != 1 ? "s" : ""}',
                      style: AidTextStyles.labelSm.copyWith(color: AidColors.textMuted)),
                ],
              ),
            ),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: residentIds.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (ctx, i) =>
                    _SponsoredResidentChip(residentId: residentIds[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SponsoredResidentChip extends StatelessWidget {
  final String residentId;
  const _SponsoredResidentChip({required this.residentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('residents').doc(residentId).get(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Container(
            width: 90,
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          );
        }
        if (!snap.data!.exists) return const SizedBox.shrink();

        final resident = Resident.fromDoc(snap.data!);
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ResidentDetailScreen(resident: resident)),
          ),
          child: Container(
            width: 90,
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Color(Resident.urgencyColors[resident.urgency] ?? 0xFF2B8CE6)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                  child: resident.photoUrl.isNotEmpty
                      ? Image.network(
                          resident.photoUrl,
                          height: 70,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoFallback(resident.name),
                        )
                      : _photoFallback(resident.name),
                ),
                const Gap(6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    resident.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AidTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Gap(2),
                Text(
                  '${resident.age} yrs',
                  style: AidTextStyles.labelSm.copyWith(
                      color: AidColors.textMuted, fontSize: 10),
                ),
                const Gap(6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoFallback(String name) => Container(
        height: 70,
        width: double.infinity,
        color: AidColors.donorAccent.withValues(alpha: 0.15),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AidColors.donorAccent,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ),
      );
}

// ─── Category Breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, int> byCategory;
  const _CategoryBreakdown({required this.byCategory});

  static const _catColors = {
    'monetary':  Color(0xFF2B8CE6),
    'food':      Color(0xFF4CAF50),
    'clothes':   Color(0xFF9B4189),
    'groceries': Color(0xFFF0A500),
    'medical':   Color(0xFFE8514A),
    'education': Color(0xFF00BCD4),
    'other':     Color(0xFF78909C),
  };

  @override
  Widget build(BuildContext context) {
    final total = byCategory.values.fold(0, (s, v) => s + v);
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Donation Breakdown', style: AidTextStyles.headingMd),
          const Gap(16),
          ...sorted.map((e) {
            final pct = total == 0 ? 0.0 : e.value / total;
            final color = _catColors[e.key] ?? AidColors.textSecondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const Gap(8),
                      Text(
                        _label(e.key),
                        style: AidTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: AidTextStyles.labelSm.copyWith(color: AidColors.textMuted),
                      ),
                    ],
                  ),
                  const Gap(4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _label(String key) {
    const labels = {
      'monetary':  'Monetary',
      'food':      'Food',
      'clothes':   'Clothes',
      'groceries': 'Groceries',
      'medical':   'Medical Supplies',
      'education': 'Education',
      'other':     'Other',
    };
    return labels[key] ?? key[0].toUpperCase() + key.substring(1);
  }
}

// ─── Donation Row ──────────────────────────────────────────────────────────────

class _DonationRow extends StatelessWidget {
  final Donation donation;
  const _DonationRow({required this.donation});

  Color get _statusColor {
    switch (donation.status) {
      case DonationStatus.completed:
      case DonationStatus.confirmed:  return const Color(0xFF4CAF50);
      case DonationStatus.cancelled:  return AidColors.error;
      default:                        return AidColors.warning;
    }
  }

  String get _statusLabel {
    switch (donation.status) {
      case DonationStatus.completed:  return 'Completed';
      case DonationStatus.confirmed:  return 'Confirmed';
      case DonationStatus.received:   return 'Received';
      case DonationStatus.cancelled:  return 'Cancelled';
      default:                        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMonetary = (donation.monetaryAmount ?? 0) > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AidColors.donorAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isMonetary ? '₹' : '📦',
                style: TextStyle(
                  fontSize: isMonetary ? 18 : 20,
                  color: AidColors.donorAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMonetary
                      ? '₹${donation.monetaryAmount!.toStringAsFixed(0)} to ${donation.ngoName ?? "NGO"}'
                      : '${donation.type.name[0].toUpperCase()}${donation.type.name.substring(1)} donation',
                  style: AidTextStyles.headingSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  DateFormat('d MMM yyyy').format(donation.createdAt),
                  style: AidTextStyles.labelSm.copyWith(color: AidColors.textMuted),
                ),
              ],
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
