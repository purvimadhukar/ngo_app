import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/donation_service.dart';
import '../../models/user_profile.dart';
import '../../models/donation.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      body: SafeArea(
        child: [
          const _StatsTab(),
          const _DonorsTab(),
          const _VolunteersTab(),
        ][_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Donors',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Volunteers',
          ),
        ],
      ),
    );
  }
}

// ── Stats tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manager Dashboard', style: AidTextStyles.displaySm),
                  Text('Platform overview', style: AidTextStyles.bodySm),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: AidColors.error,
                onPressed: () => AuthService.instance.signOut(),
              ),
            ],
          ),
          const Gap(24),

          // Platform stats cards
          FutureBuilder<Map<String, int>>(
            future: UserService.platformUserStats(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final s = snap.data!;
              return Column(
                children: [
                  Row(
                    children: [
                      _BigStat(
                        label: 'Registered Donors',
                        value: '${s['donors']}',
                        icon: Icons.favorite_rounded,
                        color: AidColors.donorAccent,
                      ),
                      const Gap(12),
                      _BigStat(
                        label: 'Active Volunteers',
                        value: '${s['volunteers']}',
                        icon: Icons.volunteer_activism_rounded,
                        color: AidColors.volunteerAccent,
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      _BigStat(
                        label: 'Verified NGOs',
                        value: '${s['ngos']}',
                        icon: Icons.business_rounded,
                        color: AidColors.ngoAccent,
                      ),
                      const Gap(12),
                      _BigStat(
                        label: 'Total Users',
                        value: '${s['total']}',
                        icon: Icons.people_rounded,
                        color: AidColors.info,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Gap(28),

          // Donation stats
          FutureBuilder<Map<String, dynamic>>(
            future: DonationService.platformStats(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final s = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Donation Stats', style: AidTextStyles.headingMd),
                  const Gap(12),
                  Row(
                    children: [
                      _BigStat(
                        label: 'Total Donations',
                        value: '${s['totalDonations']}',
                        icon: Icons.handshake_rounded,
                        color: AidColors.success,
                      ),
                      const Gap(12),
                      _BigStat(
                        label: 'Monetary (₹)',
                        value:
                            (s['totalMonetaryAmount'] as double).toStringAsFixed(0),
                        icon: Icons.currency_rupee_rounded,
                        color: AidColors.warning,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Gap(28),

          // Recent donations feed
          Text('Recent Donations', style: AidTextStyles.headingMd),
          const Gap(12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donations')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text('No donations yet', style: AidTextStyles.bodyMd),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (context, i) {
                  final d = Donation.fromFirestore(docs[i]);
                  return _DonationMiniCard(donation: d);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BigStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Text(value, style: AidTextStyles.displaySm.copyWith(fontSize: 24)),
            const Gap(4),
            Text(label,
                style: AidTextStyles.bodySm, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _DonationMiniCard extends StatelessWidget {
  final Donation donation;
  const _DonationMiniCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AidColors.donorAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: AidColors.donorAccent, size: 16),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donation.donorName, style: AidTextStyles.headingSm),
                Text(
                  '${donation.typeLabel}${donation.monetaryAmount != null ? ' · ₹${donation.monetaryAmount!.toStringAsFixed(0)}' : ''}',
                  style: AidTextStyles.bodySm,
                ),
              ],
            ),
          ),
          _StatusChip(status: donation.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DonationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case DonationStatus.pending:
        color = AidColors.warning;
        break;
      case DonationStatus.confirmed:
      case DonationStatus.received:
        color = AidColors.info;
        break;
      case DonationStatus.completed:
        color = AidColors.success;
        break;
      case DonationStatus.cancelled:
        color = AidColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: AidTextStyles.labelSm.copyWith(color: color),
      ),
    );
  }
}

// ── Donors tab ────────────────────────────────────────────────────────────────

class _DonorsTab extends StatelessWidget {
  const _DonorsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('All Donors', style: AidTextStyles.displaySm),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'donor')
                .orderBy('totalDonations', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (context, i) {
                  final p = UserProfile.fromFirestore(docs[i]);
                  return _PersonTile(
                    profile: p,
                    stat: '${p.totalDonations} donations',
                    statIcon: Icons.volunteer_activism_rounded,
                    color: AidColors.donorAccent,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Volunteers tab ────────────────────────────────────────────────────────────

class _VolunteersTab extends StatelessWidget {
  const _VolunteersTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('All Volunteers', style: AidTextStyles.displaySm),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'volunteer')
                .orderBy('activitiesJoined', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (context, i) {
                  final p = UserProfile.fromFirestore(docs[i]);
                  return _PersonTile(
                    profile: p,
                    stat:
                        '${p.activitiesJoined} activities · ${p.rewardPoints} pts',
                    statIcon: Icons.star_rounded,
                    color: AidColors.volunteerAccent,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  final UserProfile profile;
  final String stat;
  final IconData statIcon;
  final Color color;

  const _PersonTile({
    required this.profile,
    required this.stat,
    required this.statIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            backgroundImage:
                profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
            child: profile.photoUrl == null
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  )
                : null,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AidTextStyles.headingSm),
                const Gap(2),
                Row(
                  children: [
                    Icon(statIcon, size: 12, color: color),
                    const Gap(4),
                    Text(stat, style: AidTextStyles.bodySm),
                  ],
                ),
              ],
            ),
          ),
          Text(
            profile.email,
            style: AidTextStyles.labelSm,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
