import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';
import '../../models/reward.dart';
import '../../services/auth_service.dart';
import '../volunteer/volunteer_events_screen.dart';
import '../volunteer/invite_screen.dart';
import '../volunteer/rewards_screen.dart';

class VolunteerHome extends StatefulWidget {
  const VolunteerHome({super.key});

  @override
  State<VolunteerHome> createState() => _VolunteerHomeState();
}

class _VolunteerHomeState extends State<VolunteerHome> {
  Map<String, dynamic> _profile = {};
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _profile = doc.data() ?? {};
        _loadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final name = (_profile['name'] as String? ?? 'Volunteer').split(' ').first;
    final points = (_profile['rewardPoints'] as num? ?? 0).toInt();
    final activitiesJoined = (_profile['activitiesJoined'] as num? ?? 0).toInt();
    final badges = List<String>.from(_profile['badges'] ?? []);

    // Find next badge
    final sorted = [...BadgeCatalog.all]..sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));
    RewardBadge? nextBadge;
    int prevPoints = 0;
    for (final b in sorted) {
      if (points < b.pointsRequired) { nextBadge = b; break; }
      prevPoints = b.pointsRequired;
    }
    final progressToNext = nextBadge == null
        ? 1.0
        : ((points - prevPoints) / (nextBadge.pointsRequired - prevPoints)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AidColors.background,
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: AidColors.volunteerAccent))
          : RefreshIndicator(
              color: AidColors.volunteerAccent,
              onRefresh: _loadProfile,
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ────────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 160,
                    pinned: true,
                    backgroundColor: AidColors.background,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AidColors.volunteerAccentDim,
                              AidColors.background,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AidBridge',
                                            style: AidTextStyles.labelMd.copyWith(
                                              color: AidColors.volunteerAccent,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          Text(
                                            'Hey, $name 👋',
                                            style: AidTextStyles.displaySm,
                                          ),
                                          Text(
                                            'Ready to make a difference today?',
                                            style: AidTextStyles.bodyMd.copyWith(
                                              color: AidColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => AuthService.instance.signOut(),
                                      child: Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: AidColors.surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AidColors.borderDefault),
                                        ),
                                        child: const Icon(
                                          Icons.person_outline_rounded,
                                          color: AidColors.textMuted, size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AidColors.textMuted, size: 20),
                        onPressed: () => AuthService.instance.signOut(),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Stats Row ──────────────────────────────────────
                          _buildStatsRow(points, activitiesJoined, badges.length),
                          const Gap(20),

                          // ── Next Badge Progress ────────────────────────────
                          if (nextBadge != null) ...[
                            _buildBadgeProgress(points, nextBadge, progressToNext),
                            const Gap(20),
                          ],

                          // ── Quick Actions ──────────────────────────────────
                          Text('Quick Actions', style: AidTextStyles.headingMd),
                          const Gap(12),
                          _buildQuickActions(context),
                          const Gap(24),

                          // ── Upcoming Events ────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Upcoming Events', style: AidTextStyles.headingMd),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const VolunteerEventsScreen()),
                                ),
                                child: Text(
                                  'See all',
                                  style: TextStyle(color: AidColors.volunteerAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                        ],
                      ),
                    ),
                  ),

                  // ── Events Feed ────────────────────────────────────────────
                  _buildEventsFeed(uid),

                  // ── Donation Drives ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('Donation Drives', style: AidTextStyles.headingMd),
                    ),
                  ),
                  _buildDonationDrives(),

                  const SliverToBoxAdapter(child: Gap(100)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow(int points, int activitiesJoined, int badgesCount) {
    return Row(
      children: [
        _StatCard(
          value: '$points',
          label: 'Points',
          icon: Icons.star_rounded,
          color: AidColors.volunteerAccent,
        ),
        const Gap(10),
        _StatCard(
          value: '$activitiesJoined',
          label: 'Activities',
          icon: Icons.event_available_rounded,
          color: AidColors.success,
        ),
        const Gap(10),
        _StatCard(
          value: '$badgesCount',
          label: 'Badges',
          icon: Icons.military_tech_rounded,
          color: AidColors.donorAccent,
        ),
      ],
    );
  }

  Widget _buildBadgeProgress(int points, RewardBadge next, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.volunteerAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(next.icon, style: const TextStyle(fontSize: 24)),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next: ${next.name}',
                      style: AidTextStyles.headingSm,
                    ),
                    Text(
                      '${next.pointsRequired - points} pts to go · ${next.description}',
                      style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: AidColors.volunteerAccent,
              backgroundColor: AidColors.elevated,
            ),
          ),
          const Gap(6),
          Text(
            '${(progress * 100).toInt()}% complete',
            style: AidTextStyles.labelSm.copyWith(color: AidColors.volunteerAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickActionCard(
          icon: Icons.event_outlined,
          label: 'Find\nActivities',
          color: AidColors.volunteerAccent,
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VolunteerEventsScreen()),
          ),
        ),
        const Gap(10),
        _QuickActionCard(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Invite\nFriends',
          color: AidColors.donorAccent,
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const InviteScreen()),
          ),
        ),
        const Gap(10),
        _QuickActionCard(
          icon: Icons.military_tech_outlined,
          label: 'My\nRewards',
          color: AidColors.success,
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RewardsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsFeed(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: 'activity')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator(color: AidColors.volunteerAccent)),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmptyCard(
                icon: Icons.event_busy_rounded,
                message: 'No events right now.\nCheck back soon!',
                color: AidColors.volunteerAccent,
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final post = NgoPost.fromFirestore(docs[i]);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _EventCard(post: post, uid: uid),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }

  Widget _buildDonationDrives() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: 'donation')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _EmptyCard(
                icon: Icons.volunteer_activism_outlined,
                message: 'No donation drives yet',
                color: AidColors.donorAccent,
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final post = NgoPost.fromFirestore(docs[i]);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _DonationDriveCard(post: post),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const Gap(8),
              Text(value, style: AidTextStyles.displaySm.copyWith(color: color, fontSize: 22)),
              Text(label, style: AidTextStyles.labelMd),
            ],
          ),
        ),
      );
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Gap(8),
                Text(
                  label,
                  style: AidTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  final NgoPost post;
  final String uid;
  const _EventCard({required this.post, required this.uid});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _joining = false;

  Future<void> _toggleJoin(bool hasJoined) async {
    if (widget.uid.isEmpty) return;
    setState(() => _joining = true);
    try {
      final ref = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
      if (hasJoined) {
        await ref.collection('volunteers').doc(widget.uid).delete();
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'activitiesJoined': FieldValue.increment(-1),
          'rewardPoints': FieldValue.increment(-10),
        });
      } else {
        await ref.collection('volunteers').doc(widget.uid).set({
          'uid': widget.uid,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
          'activitiesJoined': FieldValue.increment(1),
          'rewardPoints': FieldValue.increment(10),
        });
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.post.eventDetails;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .collection('volunteers')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snap) {
        final hasJoined = snap.data?.exists ?? false;
        return Container(
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasJoined
                  ? AidColors.volunteerAccent.withValues(alpha: 0.4)
                  : AidColors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image banner
              if (widget.post.mediaUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    widget.post.mediaUrls.first,
                    height: 120, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                )
              else
                _placeholder(),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NGO name + verified
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AidColors.ngoAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.post.ngoVerified)
                                const Icon(Icons.verified_rounded, size: 10, color: AidColors.ngoAccent),
                              if (widget.post.ngoVerified) const Gap(3),
                              Text(
                                widget.post.ngoName,
                                style: AidTextStyles.labelSm.copyWith(color: AidColors.ngoAccent),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (hasJoined)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AidColors.volunteerAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AidColors.volunteerAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Joined ✓',
                              style: AidTextStyles.labelSm.copyWith(
                                color: AidColors.volunteerAccent, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Gap(8),
                    Text(widget.post.title, style: AidTextStyles.headingSm),
                    const Gap(4),
                    Text(
                      widget.post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
                    ),

                    if (ev != null) ...[
                      const Gap(10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AidColors.elevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: AidColors.textMuted),
                            const Gap(6),
                            Text(
                              '${ev.eventDate.day}/${ev.eventDate.month}/${ev.eventDate.year}',
                              style: AidTextStyles.labelMd,
                            ),
                            const Gap(16),
                            const Icon(Icons.location_on_outlined, size: 13, color: AidColors.textMuted),
                            const Gap(4),
                            Expanded(
                              child: Text(
                                ev.location,
                                style: AidTextStyles.labelMd,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 13, color: AidColors.textMuted),
                          const Gap(4),
                          Text(
                            '${ev.volunteersJoined} / ${ev.volunteersNeeded} volunteers',
                            style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                          ),
                        ],
                      ),
                    ],

                    const Gap(12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _joining ? null : () => _toggleJoin(hasJoined),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasJoined
                              ? AidColors.elevated
                              : AidColors.volunteerAccent,
                          foregroundColor: hasJoined ? AidColors.textMuted : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _joining
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                hasJoined ? 'Leave Activity' : 'Join Activity',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        height: 70,
        decoration: BoxDecoration(
          color: AidColors.volunteerAccentDim,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const Center(
          child: Icon(Icons.event_rounded, color: AidColors.volunteerAccentMuted, size: 30),
        ),
      );
}

// ─── Donation Drive Card ──────────────────────────────────────────────────────

class _DonationDriveCard extends StatelessWidget {
  final NgoPost post;
  const _DonationDriveCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AidColors.donorAccentDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: AidColors.donorAccent, size: 20),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title, style: AidTextStyles.headingSm),
                    Text(post.ngoName, style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AidColors.donorAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  post.category.toUpperCase(),
                  style: AidTextStyles.labelSm.copyWith(
                    color: AidColors.donorAccent, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (post.requiredItems.isNotEmpty) ...[
            const Gap(12),
            ...post.requiredItems.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.name} (${item.unit})', style: AidTextStyles.labelMd),
                          Text(
                            '${item.fulfilledQty.toInt()} / ${item.targetQty.toInt()}',
                            style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                          ),
                        ],
                      ),
                      const Gap(4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.progressPercent,
                          minHeight: 5,
                          color: AidColors.donorAccent,
                          backgroundColor: AidColors.elevated,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State Card ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _EmptyCard({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.4), size: 36),
            const Gap(10),
            Text(
              message,
              style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
