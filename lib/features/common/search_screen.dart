import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search NGOs, posts, events...',
            hintStyle: AidTextStyles.bodyMd.copyWith(color: AidColors.textTertiary),
            border: InputBorder.none,
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
        bottom: TabBar(
          controller: _tab,
          labelColor: AidColors.ngoAccent,
          unselectedLabelColor: AidColors.textSecondary,
          indicatorColor: AidColors.ngoAccent,
          tabs: const [
            Tab(text: 'NGOs'),
            Tab(text: 'Posts'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: _query.isEmpty
          ? _buildEmptyState()
          : TabBarView(
              controller: _tab,
              children: [
                _NgoResults(query: _query),
                _PostResults(query: _query),
                _EventResults(query: _query),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_rounded, size: 64, color: AidColors.textTertiary),
          const Gap(16),
          Text('Search for NGOs, posts, or events',
              style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── NGO results ───────────────────────────────────────────────────────────────

class _NgoResults extends StatelessWidget {
  final String query;
  const _NgoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserProfile>>(
      future: UserService.searchUsers(query),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = (snap.data ?? [])
            .where((u) => u.role == 'ngo')
            .toList();

        if (users.isEmpty) {
          return _NoResults(query: query, type: 'NGOs');
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Gap(10),
          itemBuilder: (context, i) => _NgoTile(profile: users[i]),
        );
      },
    );
  }
}

class _NgoTile extends StatelessWidget {
  final UserProfile profile;
  const _NgoTile({required this.profile});

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
            radius: 24,
            backgroundColor: AidColors.ngoAccent.withValues(alpha: 0.15),
            backgroundImage:
                profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
            child: profile.photoUrl == null
                ? Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'N',
                    style: const TextStyle(
                        color: AidColors.ngoAccent, fontWeight: FontWeight.w600),
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
                    Text(profile.orgName ?? profile.name, style: AidTextStyles.headingSm),
                    const Gap(4),
                    if (profile.ngoVerified)
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AidColors.ngoAccent),
                  ],
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Text(profile.bio!,
                      style: AidTextStyles.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AidColors.textSecondary),
        ],
      ),
    );
  }
}

// ── Post results ──────────────────────────────────────────────────────────────

class _PostResults extends StatelessWidget {
  final String query;
  const _PostResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final title = (data['title'] as String? ?? '').toLowerCase();
          final desc = (data['description'] as String? ?? '').toLowerCase();
          return title.contains(query.toLowerCase()) ||
              desc.contains(query.toLowerCase());
        }).toList();

        if (docs.isEmpty) return _NoResults(query: query, type: 'posts');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(10),
          itemBuilder: (context, i) {
            final post = NgoPost.fromFirestore(docs[i]);
            return _PostTile(post: post);
          },
        );
      },
    );
  }
}

class _PostTile extends StatelessWidget {
  final NgoPost post;
  const _PostTile({required this.post});

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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _categoryColor(post.category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(_categoryIcon(post.category),
                  color: _categoryColor(post.category), size: 22),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: AidTextStyles.headingSm),
                Text(post.ngoName,
                    style: AidTextStyles.bodySm.copyWith(
                        color: AidColors.ngoAccent)),
                Text(
                  post.description,
                  style: AidTextStyles.bodySm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    const colors = {
      'food': Color(0xFFF0A500),
      'clothes': AidColors.donorAccent,
      'medical': Color(0xFFE8514A),
      'education': AidColors.donorAccent,
      'funds': AidColors.donorAccent,
    };
    return colors[cat] ?? AidColors.textSecondary;
  }

  IconData _categoryIcon(String cat) {
    const icons = {
      'food': Icons.restaurant_rounded,
      'clothes': Icons.checkroom_rounded,
      'medical': Icons.medical_services_rounded,
      'education': Icons.school_rounded,
      'funds': Icons.currency_rupee_rounded,
    };
    return icons[cat] ?? Icons.volunteer_activism_rounded;
  }
}

// ── Event results ─────────────────────────────────────────────────────────────

class _EventResults extends StatelessWidget {
  final String query;
  const _EventResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('type', isEqualTo: 'activity')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final title = (data['title'] as String? ?? '').toLowerCase();
          final loc = ((data['eventDetails'] as Map?)?['location'] as String? ?? '').toLowerCase();
          return title.contains(query.toLowerCase()) ||
              loc.contains(query.toLowerCase());
        }).toList();

        if (docs.isEmpty) return _NoResults(query: query, type: 'events');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(10),
          itemBuilder: (context, i) {
            final post = NgoPost.fromFirestore(docs[i]);
            return _EventTile(post: post);
          },
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final NgoPost post;
  const _EventTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final ev = post.eventDetails;
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AidColors.volunteerAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_rounded,
                color: AidColors.volunteerAccent, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: AidTextStyles.headingSm),
                Text(post.ngoName,
                    style: AidTextStyles.bodySm.copyWith(
                        color: AidColors.ngoAccent)),
                if (ev != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AidColors.textSecondary),
                      const Gap(3),
                      Text(ev.location,
                          style: AidTextStyles.bodySm,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
              ],
            ),
          ),
          if (ev != null)
            Column(
              children: [
                Text(
                  '${ev.eventDate.day}',
                  style: AidTextStyles.headingMd
                      .copyWith(color: AidColors.volunteerAccent),
                ),
                Text(
                  _monthShort(ev.eventDate.month),
                  style: AidTextStyles.labelSm,
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _monthShort(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final String type;
  const _NoResults({required this.query, required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: AidColors.textTertiary),
          const Gap(12),
          Text('No $type found for "$query"',
              style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
