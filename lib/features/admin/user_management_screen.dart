import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/user_profile.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AidColors.background,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User Management', style: AidTextStyles.displaySm),
              const Gap(16),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
              const Gap(12),
              TabBar(
                controller: _tab,
                isScrollable: true,
                labelColor: AidColors.info,
                unselectedLabelColor: AidColors.textSecondary,
                indicatorColor: AidColors.info,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'NGOs'),
                  Tab(text: 'Donors'),
                  Tab(text: 'Volunteers'),
                  Tab(text: 'Staff'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _UserList(roleFilter: null, query: _query),
              _UserList(roleFilter: 'ngo', query: _query),
              _UserList(roleFilter: 'donor', query: _query),
              _UserList(roleFilter: 'volunteer', query: _query),
              _UserList(roleFilter: 'admin', query: _query),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  final String? roleFilter;
  final String query;

  const _UserList({this.roleFilter, required this.query});

  @override
  Widget build(BuildContext context) {
    Query q = FirebaseFirestore.instance.collection('users');
    if (roleFilter != null) q = q.where('role', isEqualTo: roleFilter);

    return StreamBuilder<QuerySnapshot>(
      stream: q.orderBy('createdAt', descending: true).limit(50).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snap.data!.docs;

        // Filter by query
        if (query.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final name = (data['name'] as String? ?? '').toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Text('No users found', style: AidTextStyles.bodyMd),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(8),
          itemBuilder: (context, i) {
            final profile = UserProfile.fromFirestore(docs[i]);
            return _UserTile(profile: profile);
          },
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserProfile profile;
  const _UserTile({required this.profile});

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
            backgroundColor: _roleColor(profile.role).withValues(alpha: 0.15),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _roleColor(profile.role),
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
                    const Gap(6),
                    if (profile.role == 'ngo' && profile.ngoVerified)
                      const Icon(Icons.verified_rounded, size: 14, color: AidColors.ngoAccent),
                  ],
                ),
                Text(profile.email,
                    style: AidTextStyles.bodySm,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor(profile.role).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              profile.role.toUpperCase(),
              style: AidTextStyles.labelSm.copyWith(
                color: _roleColor(profile.role),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Gap(8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            color: AidColors.elevated,
            onSelected: (value) => _handleAction(context, value, profile),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'view',
                child: Text('View Profile'),
              ),
              if (profile.role != 'admin')
                const PopupMenuItem(
                  value: 'makeAdmin',
                  child: Text('Make Admin'),
                ),
              if (profile.role != 'manager')
                const PopupMenuItem(
                  value: 'makeManager',
                  child: Text('Make Manager'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, String action, UserProfile profile) async {
    switch (action) {
      case 'makeAdmin':
        await FirebaseFirestore.instance
            .collection('users')
            .doc(profile.uid)
            .update({'role': 'admin'});
        break;
      case 'makeManager':
        await FirebaseFirestore.instance
            .collection('users')
            .doc(profile.uid)
            .update({'role': 'manager'});
        break;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'donor':
        return AidColors.donorAccent;
      case 'volunteer':
        return AidColors.volunteerAccent;
      case 'ngo':
        return AidColors.ngoAccent;
      default:
        return AidColors.info;
    }
  }
}
