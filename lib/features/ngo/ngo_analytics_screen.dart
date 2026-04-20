import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';

// ─── Public entry point ────────────────────────────────────────────────────────

class NgoAnalyticsScreen extends StatefulWidget {
  const NgoAnalyticsScreen({super.key});

  @override
  State<NgoAnalyticsScreen> createState() => _NgoAnalyticsScreenState();
}

class _NgoAnalyticsScreenState extends State<NgoAnalyticsScreen> {
  final _db  = FirebaseFirestore.instance;
  final _uid = AuthService.instance.currentUser?.uid ?? '';

  // Loaded data
  bool _loading = true;
  double _totalRaised = 0;
  int _totalDonors = 0;
  int _itemDonations = 0;
  int _activeResidents = 0;
  int _sponsoredResidents = 0;
  double _residentsMonthlyTarget = 0;
  double _residentsMonthlyRaised = 0;
  List<_DailyTotal> _last7Days = [];
  Map<String, int> _categoryBreakdown = {};
  List<_TopDonor> _topDonors = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await Future.wait([
        _loadPostStats(),
        _loadResidentStats(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPostStats() async {
    final postsSnap = await _db
        .collection('posts')
        .where('ngoId', isEqualTo: _uid)
        .get();

    double money = 0;
    final donorEmails = <String>{};
    int itemCount = 0;
    final catMap = <String, int>{};
    final donorMap = <String, double>{};
    final dayMap = <String, double>{};

    // Initialise last 7 days keys
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      dayMap[DateFormat('MMM d').format(d)] = 0;
    }

    for (final post in postsSnap.docs) {
      final postData = post.data();
      final cat = (postData['category'] as String? ?? 'Other').toLowerCase();
      catMap[cat] = (catMap[cat] ?? 0) + 1;

      try {
        final donSnap = await _db
            .collection('posts')
            .doc(post.id)
            .collection('donations')
            .get()
            .timeout(const Duration(seconds: 10));

        for (final d in donSnap.docs) {
          final dd = d.data();
          final amount = (dd['amount'] ?? 0) as num;
          final email  = dd['donorEmail'] as String? ?? '';
          final item   = dd['item'] as String? ?? '';
          final createdAt = (dd['createdAt'] as dynamic)?.toDate() as DateTime?;

          if (amount > 0) {
            money += amount.toDouble();
            if (email.isNotEmpty) {
              donorEmails.add(email);
              donorMap[email] = (donorMap[email] ?? 0) + amount.toDouble();
            }
            // Last 7 days
            if (createdAt != null) {
              final diff = DateTime.now().difference(createdAt).inDays;
              if (diff <= 6) {
                final key = DateFormat('MMM d').format(createdAt);
                dayMap[key] = (dayMap[key] ?? 0) + amount.toDouble();
              }
            }
          }
          if (item.isNotEmpty) itemCount++;
        }
      } catch (_) {}
    }

    // Top donors (sorted by total)
    final sorted = donorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDonors = sorted.take(5).map((e) => _TopDonor(
          email: e.key,
          name: e.key.split('@').first,
          total: e.value,
        )).toList();

    final last7 = dayMap.entries
        .map((e) => _DailyTotal(label: e.key, amount: e.value))
        .toList();

    _totalRaised   = money;
    _totalDonors   = donorEmails.length;
    _itemDonations = itemCount;
    _last7Days     = last7;
    _categoryBreakdown = catMap;
    _topDonors     = topDonors;
  }

  Future<void> _loadResidentStats() async {
    final resSnap = await _db
        .collection('residents')
        .where('careHomeId', isEqualTo: _uid)
        .get();

    int active = 0;
    int sponsored = 0;
    double target = 0;
    double raised = 0;

    for (final d in resSnap.docs) {
      final data = d.data();
      if (data['isActive'] == true) active++;
      if ((data['sponsorsCount'] ?? 0) > 0) sponsored++;
      target += ((data['monthlyTarget'] ?? 0) as num).toDouble();
      raised += ((data['monthlyRaised'] ?? 0) as num).toDouble();
    }

    _activeResidents        = active;
    _sponsoredResidents     = sponsored;
    _residentsMonthlyTarget = target;
    _residentsMonthlyRaised = raised;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.ngoBackground,
      appBar: AppBar(
        backgroundColor: AidColors.ngoBackground,
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AidColors.ngoAccent))
          : RefreshIndicator(
              color: AidColors.ngoAccent,
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // ── Top stats grid ──────────────────────────────────────────
                  _sectionHeader('Overview'),
                  const Gap(10),
                  _StatsGrid(
                    totalRaised: _totalRaised,
                    totalDonors: _totalDonors,
                    itemDonations: _itemDonations,
                    activeResidents: _activeResidents,
                  ),

                  const Gap(24),

                  // ── Last 7 days bar chart ───────────────────────────────────
                  _sectionHeader('Last 7 Days — Donations (₹)'),
                  const Gap(10),
                  _BarChartCard(data: _last7Days),

                  const Gap(24),

                  // ── Resident sponsorship ────────────────────────────────────
                  if (_activeResidents > 0) ...[
                    _sectionHeader('Resident Sponsorship'),
                    const Gap(10),
                    _ResidentFundCard(
                      activeResidents: _activeResidents,
                      sponsoredResidents: _sponsoredResidents,
                      monthlyTarget: _residentsMonthlyTarget,
                      monthlyRaised: _residentsMonthlyRaised,
                    ),
                    const Gap(24),
                  ],

                  // ── Category breakdown ──────────────────────────────────────
                  if (_categoryBreakdown.isNotEmpty) ...[
                    _sectionHeader('Posts by Category'),
                    const Gap(10),
                    _CategoryBars(data: _categoryBreakdown),
                    const Gap(24),
                  ],

                  // ── Top donors ──────────────────────────────────────────────
                  if (_topDonors.isNotEmpty) ...[
                    _sectionHeader('Top Donors'),
                    const Gap(10),
                    _TopDonorsList(donors: _topDonors, maxAmount: _totalRaised),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) => Text(title, style: AidTextStyles.headingMd);
}

// ─── Stats grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final double totalRaised;
  final int totalDonors;
  final int itemDonations;
  final int activeResidents;

  const _StatsGrid({
    required this.totalRaised,
    required this.totalDonors,
    required this.itemDonations,
    required this.activeResidents,
  });

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (_fmt(totalRaised), 'Total Raised', Icons.currency_rupee_rounded, AidColors.ngoAccent),
      ('$totalDonors', 'Unique Donors', Icons.people_rounded, const Color(0xFF9B4189)),
      ('$itemDonations', 'Item Donations', Icons.inventory_2_rounded, const Color(0xFFF0A500)),
      ('$activeResidents', 'Residents', Icons.elderly_rounded, const Color(0xFF4CAF50)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final (val, label, icon, color) = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(val,
                      style: AidTextStyles.headingMd.copyWith(
                          fontWeight: FontWeight.w900, color: color)),
                  Text(label,
                      style: AidTextStyles.labelSm
                          .copyWith(color: AidColors.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Bar Chart Card ────────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  final List<_DailyTotal> data;
  const _BarChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: data.isEmpty
                ? const Center(child: Text('No donations yet', style: TextStyle(color: AidColors.textMuted)))
                : _BarChart(data: data),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_DailyTotal> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final max = data.fold(0.0, (m, d) => math.max(m, d.amount));
    if (max == 0) {
      return const Center(
        child: Text('No monetary donations in last 7 days',
            style: TextStyle(color: AidColors.textMuted, fontSize: 13)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final pct = max == 0 ? 0.0 : d.amount / max;
        final isToday = d.label == DateFormat('MMM d').format(DateTime.now());
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (d.amount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _compact(d.amount),
                      style: TextStyle(
                        fontSize: 9,
                        color: isToday ? AidColors.ngoAccent : AidColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: math.max(pct * 120, d.amount > 0 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AidColors.ngoAccent
                        : AidColors.ngoAccent.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                ),
                const Gap(6),
                Text(
                  d.label.split(' ').last, // just the day number
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday ? AidColors.ngoAccent : AidColors.textMuted,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Resident Fund Card ────────────────────────────────────────────────────────

class _ResidentFundCard extends StatelessWidget {
  final int activeResidents;
  final int sponsoredResidents;
  final double monthlyTarget;
  final double monthlyRaised;

  const _ResidentFundCard({
    required this.activeResidents,
    required this.sponsoredResidents,
    required this.monthlyTarget,
    required this.monthlyRaised,
  });

  @override
  Widget build(BuildContext context) {
    final pct = monthlyTarget == 0 ? 0.0 : math.min(monthlyRaised / monthlyTarget, 1.0);
    final pctInt = (pct * 100).round();

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
          Row(
            children: [
              _InfoPill(label: '$activeResidents Active', color: const Color(0xFF4CAF50)),
              const Gap(8),
              _InfoPill(label: '$sponsoredResidents Sponsored', color: AidColors.ngoAccent),
            ],
          ),
          if (monthlyTarget > 0) ...[
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monthly Funding', style: AidTextStyles.headingSm),
                Text('$pctInt%',
                    style: AidTextStyles.headingSm.copyWith(
                        color: AidColors.ngoAccent, fontWeight: FontWeight.w900)),
              ],
            ),
            const Gap(8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AidColors.ngoAccent.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AidColors.ngoAccent),
                minHeight: 10,
              ),
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${_fmt(monthlyRaised)} raised',
                    style: AidTextStyles.bodyMd.copyWith(
                        color: AidColors.ngoAccent, fontWeight: FontWeight.w700)),
                Text('of ₹${_fmt(monthlyTarget)} target',
                    style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
              ],
            ),
          ],
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

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
}

// ─── Category Bars ─────────────────────────────────────────────────────────────

class _CategoryBars extends StatelessWidget {
  final Map<String, int> data;
  const _CategoryBars({required this.data});

  static const _colors = [
    Color(0xFF2B8CE6), Color(0xFF9B4189), Color(0xFF4CAF50),
    Color(0xFFF0A500), Color(0xFFE8514A), Color(0xFF00BCD4),
    Color(0xFFFF7043), Color(0xFF78909C),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isEmpty ? 1 : sorted.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = e.value / maxVal;
          final color = _colors[i % _colors.length];
          final label = e.key[0].toUpperCase() + e.key.substring(1);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AidTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
                ),
                const Gap(8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const Gap(8),
                SizedBox(
                  width: 24,
                  child: Text('${e.value}',
                      textAlign: TextAlign.right,
                      style: AidTextStyles.labelSm.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Top Donors ────────────────────────────────────────────────────────────────

class _TopDonorsList extends StatelessWidget {
  final List<_TopDonor> donors;
  final double maxAmount;
  const _TopDonorsList({required this.donors, required this.maxAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        children: donors.asMap().entries.map((entry) {
          final i   = entry.key;
          final d   = entry.value;
          final medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(medals[i], style: const TextStyle(fontSize: 18)),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                          style: AidTextStyles.headingSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(d.email,
                          style: AidTextStyles.labelSm.copyWith(
                              color: AidColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Gap(8),
                Text(
                  '₹${_fmt(d.total)}',
                  style: AidTextStyles.headingSm.copyWith(
                      color: AidColors.ngoAccent, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Data models ───────────────────────────────────────────────────────────────

class _DailyTotal {
  final String label;
  final double amount;
  _DailyTotal({required this.label, required this.amount});
}

class _TopDonor {
  final String email;
  final String name;
  final double total;
  _TopDonor({required this.email, required this.name, required this.total});
}
