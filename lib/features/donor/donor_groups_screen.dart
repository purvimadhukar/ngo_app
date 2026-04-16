import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';
import 'create_group_screen.dart';

class DonorGroupsScreen extends StatefulWidget {
  const DonorGroupsScreen({super.key});

  @override
  State<DonorGroupsScreen> createState() => _DonorGroupsScreenState();
}

class _DonorGroupsScreenState extends State<DonorGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        title: const Text('Donor Groups'),
        backgroundColor: AidColors.background,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create'),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AidColors.donorAccent,
          unselectedLabelColor: AidColors.textSecondary,
          indicatorColor: AidColors.donorAccent,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _MyGroupsTab(uid: uid),
          _DiscoverGroupsTab(uid: uid),
        ],
      ),
    );
  }
}

class _MyGroupsTab extends StatelessWidget {
  final String uid;
  const _MyGroupsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DonorGroup>>(
      stream: GroupService.myGroups(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👥', style: TextStyle(fontSize: 52)),
                const Gap(16),
                Text("You haven't joined any groups yet",
                    style: AidTextStyles.headingMd),
                const Gap(8),
                Text('Create or join a group to donate together.',
                    style: AidTextStyles.bodyMd
                        .copyWith(color: AidColors.textSecondary),
                    textAlign: TextAlign.center),
                const Gap(20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AidColors.donorAccent,
                  ),
                  child: const Text('Create a Group'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, i) => _GroupCard(
            group: groups[i],
            uid: uid,
            isMine: true,
          ),
        );
      },
    );
  }
}

class _DiscoverGroupsTab extends StatelessWidget {
  final String uid;
  const _DiscoverGroupsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DonorGroup>>(
      stream: GroupService.publicGroups(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Text('No public groups yet', style: AidTextStyles.bodyMd),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, i) {
            final group = groups[i];
            final isMember = group.memberIds.contains(uid);
            return _GroupCard(group: group, uid: uid, isMine: isMember);
          },
        );
      },
    );
  }
}

class _GroupCard extends StatefulWidget {
  final DonorGroup group;
  final String uid;
  final bool isMine;

  const _GroupCard({
    required this.group,
    required this.uid,
    required this.isMine,
  });

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _loading = false;

  Future<void> _join() async {
    setState(() => _loading = true);
    final profile = await UserService.getProfile(widget.uid);
    await GroupService.joinGroup(
        widget.group.id, widget.uid, profile?.name ?? 'Unknown');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _leave() async {
    setState(() => _loading = true);
    final profile = await UserService.getProfile(widget.uid);
    await GroupService.leaveGroup(
        widget.group.id, widget.uid, profile?.name ?? 'Unknown');
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final isMember = group.memberIds.contains(widget.uid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMember
              ? AidColors.donorAccent.withValues(alpha: 0.3)
              : AidColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AidColors.donorAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_rounded,
                    color: AidColors.donorAccent, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: AidTextStyles.headingSm),
                    Text('Created by ${group.creatorName}',
                        style: AidTextStyles.bodySm),
                  ],
                ),
              ),
              if (isMember)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AidColors.donorAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Member',
                    style:
                        AidTextStyles.labelSm.copyWith(color: AidColors.donorAccent),
                  ),
                ),
            ],
          ),
          const Gap(10),
          Text(
            group.description,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(12),

          // Stats row
          Row(
            children: [
              _Stat(
                icon: Icons.people_outline_rounded,
                value: '${group.memberCount}',
                label: 'members',
              ),
              const Gap(16),
              _Stat(
                icon: Icons.volunteer_activism_rounded,
                value: '${group.donationCount}',
                label: 'donations',
              ),
              const Gap(16),
              _Stat(
                icon: Icons.currency_rupee_rounded,
                value: group.totalContributed.toStringAsFixed(0),
                label: 'contributed',
              ),
            ],
          ),
          const Gap(14),

          // Action
          if (!isMember)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AidColors.donorAccent,
                  foregroundColor: AidColors.background,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join Group'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : _leave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.error,
                  side: BorderSide(color: AidColors.error.withValues(alpha: 0.4)),
                ),
                child: const Text('Leave Group'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AidColors.textSecondary),
        const Gap(4),
        Text('$value $label', style: AidTextStyles.bodySm),
      ],
    );
  }
}
