import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/reward.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/volunteer_service.dart';
import '../../services/user_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AidColors.background,
      body: Column(
        children: [
          _buildHeader(uid),
          TabBar(
            controller: _tab,
            labelColor: AidColors.volunteerAccent,
            unselectedLabelColor: AidColors.textSecondary,
            indicatorColor: AidColors.volunteerAccent,
            tabs: const [
              Tab(text: 'My Badges'),
              Tab(text: 'History'),
              Tab(text: 'Leaderboard'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BadgesTab(uid: uid),
                _HistoryTab(uid: uid),
                const _LeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String uid) {
    return StreamBuilder<UserProfile?>(
      stream: UserService.watchProfile(uid),
      builder: (context, snap) {
        final profile = snap.data;
        return SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AidColors.volunteerAccent.withValues(alpha: 0.2),
                  AidColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Rewards', style: AidTextStyles.displaySm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AidColors.volunteerAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AidColors.volunteerAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AidColors.volunteerAccent, size: 16),
                          const Gap(4),
                          Text(
                            '${profile?.rewardPoints ?? 0} pts',
                            style: AidTextStyles.labelLg
                                .copyWith(color: AidColors.volunteerAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                _ProgressBar(profile: profile),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final UserProfile? profile;
  const _ProgressBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final points = profile?.rewardPoints ?? 0;

    // Find current and next badge tier
    final sorted = BadgeCatalog.all
        .where((b) => b.pointsRequired > 0)
        .toList()
      ..sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));

    RewardRewardBadge? nextBadge;
    int prevPoints = 0;
    for (final badge in sorted) {
      if (points < badge.pointsRequired) {
        nextBadge = badge;
        break;
      }
      prevPoints = badge.pointsRequired;
    }

    if (nextBadge == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AidColors.volunteerAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 24)),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maximum level reached!', style: AidTextStyles.headingSm),
                Text('You are a Legend.', style: AidTextStyles.bodySm),
              ],
            ),
          ],
        ),
      );
    }

    final progress = (points - prevPoints) /
        (nextBadge.pointsRequired - prevPoints).clamp(1, double.infinity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(nextBadge.icon, style: const TextStyle(fontSize: 24)),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next: ${nextBadge.name}', style: AidTextStyles.headingSm),
                    Text(
                      '${nextBadge.pointsRequired - points} pts to go',
                      style: AidTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AidTextStyles.labelLg
                    .copyWith(color: AidColors.volunteerAccent),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AidColors.elevated,
              color: AidColors.volunteerAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badges tab ────────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final String uid;
  const _BadgesTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: UserService.watchProfile(uid),
      builder: (context, snap) {
        final profile = snap.data;
        final earned = profile?.badges ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: BadgeCatalog.all.length,
          itemBuilder: (context, i) {
            final badge = BadgeCatalog.all[i];
            final isEarned = earned.contains(badge.id);
            return _BadgeTile(badge: badge, earned: isEarned);
          },
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final RewardBadge badge;
  final bool earned;

  const _BadgeTile({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    Color tierColor;
    switch (badge.tier) {
      case 'bronze':
        tierColor = const Color(0xFFCD7F32);
        break;
      case 'silver':
        tierColor = const Color(0xFFC0C0C0);
        break;
      case 'gold':
        tierColor = const Color(0xFFFFD700);
        break;
      default:
        tierColor = const Color(0xFFB9F2FF); // platinum
    }

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${badge.icon} ${badge.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge.description),
              const Gap(8),
              Text(
                earned ? '✅ Earned!' : '${badge.pointsRequired} pts required',
                style: TextStyle(
                  color: earned ? AidColors.success : AidColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: earned
              ? tierColor.withValues(alpha: 0.12)
              : AidColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? tierColor.withValues(alpha: 0.5)
                : AidColors.borderSubtle,
            width: earned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 36,
                    color: earned ? null : Colors.grey,
                  ),
                ),
                if (!earned)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AidColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        size: 12, color: AidColors.textTertiary),
                  ),
              ],
            ),
            const Gap(6),
            Text(
              badge.name,
              style: AidTextStyles.labelSm.copyWith(
                color: earned ? AidColors.textPrimary : AidColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final String uid;
  const _HistoryTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RewardEvent>>(
      stream: VolunteerService.rewardHistory(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snap.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 48)),
                const Gap(16),
                Text('No points yet!', style: AidTextStyles.headingMd),
                const Gap(8),
                Text('Join activities to earn your first points.',
                    style: AidTextStyles.bodyMd.copyWith(
                        color: AidColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (context, i) => _EventTile(event: events[i]),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final RewardEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: AidColors.volunteerAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star_rounded,
                color: AidColors.volunteerAccent, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.description, style: AidTextStyles.bodyMd),
                Text(
                  '${event.createdAt.day}/${event.createdAt.month}/${event.createdAt.year}',
                  style: AidTextStyles.bodySm,
                ),
              ],
            ),
          ),
          Text(
            '+${event.points} pts',
            style: AidTextStyles.headingSm
                .copyWith(color: AidColors.volunteerAccent),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard tab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<UserProfile>>(
      stream: VolunteerService.leaderboard(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Text('No volunteers yet', style: AidTextStyles.bodyMd),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (context, i) {
            final user = users[i];
            final isMe = user.uid == myUid;
            return _LeaderboardTile(
              rank: i + 1,
              profile: user,
              isMe: isMe,
            );
          },
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final UserProfile profile;
  final bool isMe;

  const _LeaderboardTile({
    required this.rank,
    required this.profile,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final medalEmoji = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe
            ? AidColors.volunteerAccent.withValues(alpha: 0.1)
            : AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AidColors.volunteerAccent.withValues(alpha: 0.4)
              : AidColors.borderSubtle,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Center(
              child: medalEmoji != null
                  ? Text(medalEmoji, style: const TextStyle(fontSize: 22))
                  : Text(
                      '#$rank',
                      style: AidTextStyles.labelLg.copyWith(
                          color: AidColors.textTertiary),
                    ),
            ),
          ),
          const Gap(10),
          CircleAvatar(
            radius: 20,
            backgroundColor: AidColors.volunteerAccent.withValues(alpha: 0.15),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AidColors.volunteerAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(profile.name, style: AidTextStyles.headingSm),
                    if (isMe) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AidColors.volunteerAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: AidTextStyles.labelSm.copyWith(
                              color: AidColors.background),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${profile.activitiesJoined} activities',
                  style: AidTextStyles.bodySm,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${profile.rewardPoints}',
                style: AidTextStyles.headingMd
                    .copyWith(color: AidColors.volunteerAccent),
              ),
              Text('pts', style: AidTextStyles.bodySm),
            ],
          ),
        ],
      ),
    );
  }
}
