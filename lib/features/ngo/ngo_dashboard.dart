import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';
import '../../models/impact_group.dart';
import '../../services/auth_service.dart';
import 'create_post_screen.dart';
import 'add_proof_screen.dart';
import 'ngo_verification_screen.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _ngoName = 'Your NGO';
  bool _ngoVerified = false;
  String _verificationStatus = 'none'; // none | pending | rejected | approved

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final data = doc.data() ?? {};

      // Try verifications — may not exist yet, so catch any error
      String vStatus = 'none';
      try {
        final vSnap = await FirebaseFirestore.instance
            .collection('verifications')
            .where('ngoId', isEqualTo: uid)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));
        if (vSnap.docs.isNotEmpty) {
          vStatus = vSnap.docs.first.data()['status'] ?? 'pending';
        }
      } catch (_) {
        // verifications collection not set up yet — ignore
      }

      if (mounted) {
        setState(() {
          _ngoName = data['orgName'] ?? data['name'] ?? data['email'] ?? 'Your NGO';
          _ngoVerified = data['ngoVerified'] ?? false;
          _verificationStatus = vStatus;
        });
      }
    } catch (e) {
      // Silently handle timeout / permission error — dashboard still loads
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AidColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        backgroundColor: AidColors.ngoAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (!_ngoVerified) _buildVerificationBanner(context),
            _buildStats(uid),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _MyPostsTab(uid: uid),
                  _ActivitiesTab(uid: uid),
                  _ImpactGroupsTab(uid: uid, ngoName: _ngoName),
                  _ImpactTab(uid: uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AidBridge NGO',
                      style: AidTextStyles.caption.copyWith(
                        color: AidColors.ngoAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (_ngoVerified) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AidColors.ngoAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 10, color: AidColors.ngoAccent),
                            const Gap(3),
                            Text(
                              'VERIFIED',
                              style: AidTextStyles.labelSm.copyWith(
                                color: AidColors.ngoAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(_ngoName, style: AidTextStyles.heading.copyWith(fontSize: 22)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AidColors.textMuted, size: 22),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context) {
    final isPending = _verificationStatus == 'pending';
    final isRejected = _verificationStatus == 'rejected';
    final color = isPending ? AidColors.warning : isRejected ? AidColors.error : AidColors.info;
    final icon = isPending ? Icons.hourglass_top_rounded : isRejected ? Icons.cancel_rounded : Icons.verified_user_outlined;
    final msg = isPending
        ? 'Verification under review — we\'ll notify you when approved'
        : isRejected
            ? 'Verification rejected. Tap to re-submit with correct documents'
            : 'Verify your NGO to build donor trust and unlock more visibility';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NgoVerificationScreen()),
      ).then((_) => _loadProfile()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const Gap(10),
            Expanded(child: Text(msg, style: AidTextStyles.caption.copyWith(color: color))),
            if (!isPending) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  isRejected ? 'Re-apply' : 'Apply',
                  style: AidTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('ngoId', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final total = docs.length;
        final active = docs.where((d) => (d.data() as Map)['status'] == 'active').length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              _StatChip(label: 'Posts', value: '$total', icon: Icons.article_outlined, color: AidColors.ngoAccent),
              const Gap(8),
              _StatChip(label: 'Active', value: '$active', icon: Icons.radio_button_checked, color: AidColors.success),
              const Gap(8),
              _StatChip(
                label: 'Status',
                value: _ngoVerified ? 'Verified' : 'Unverified',
                icon: Icons.verified_outlined,
                color: _ngoVerified ? AidColors.ngoAccent : AidColors.textMuted,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: AidColors.surface, borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(color: AidColors.ngoAccent, borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AidColors.textMuted,
          labelStyle: AidTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AidTextStyles.caption,
          tabs: const [Tab(text: 'Posts'), Tab(text: 'Activities'), Tab(text: 'Groups'), Tab(text: 'Impact')],
        ),
      ),
    );
  }
}

// ─── My Posts Tab ─────────────────────────────────────────────────────────────

class _MyPostsTab extends StatelessWidget {
  final String uid;
  const _MyPostsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ngoId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AidColors.ngoAccent));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _EmptyPosts();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (_, i) => _NgoPostCard(post: NgoPost.fromFirestore(docs[i])),
        );
      },
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AidColors.ngoAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.post_add_rounded, size: 40, color: AidColors.ngoAccent),
            ),
            const Gap(20),
            Text('No posts yet', style: AidTextStyles.headingMd),
            const Gap(8),
            Text(
              'Tap + New Post to create your first donation drive or volunteer event.',
              style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NGO Post Card ────────────────────────────────────────────────────────────

class _NgoPostCard extends StatelessWidget {
  final NgoPost post;
  const _NgoPostCard({required this.post});

  Color get _typeColor => post.type == PostType.donation
      ? AidColors.donorAccent
      : post.type == PostType.activity
          ? AidColors.volunteerAccent
          : AidColors.error;

  String get _typeLabel => post.type == PostType.donation
      ? 'Donation Drive'
      : post.type == PostType.activity
          ? 'Volunteer Event'
          : 'Emergency';

  Color get _statusColor => post.status == PostStatus.active
      ? AidColors.success
      : post.status == PostStatus.fulfilled
          ? AidColors.ngoAccent
          : AidColors.textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media / placeholder
          if (post.mediaUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                post.mediaUrls.first,
                height: 150, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderBanner(),
              ),
            )
          else
            _placeholderBanner(),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(label: _typeLabel, color: _typeColor),
                    const Gap(8),
                    _Badge(label: post.status.name.toUpperCase(), color: _statusColor),
                    const Spacer(),
                    Text(post.category, style: AidTextStyles.labelSm.copyWith(color: AidColors.textMuted)),
                  ],
                ),
                const Gap(8),
                Text(post.title, style: AidTextStyles.headingMd),
                const Gap(4),
                Text(
                  post.description,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Item progress
                if (post.requiredItems.isNotEmpty) ...[
                  const Gap(12),
                  ...post.requiredItems.take(2).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
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
                            LinearProgressIndicator(
                              value: item.progressPercent,
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(3),
                              color: AidColors.ngoAccent,
                              backgroundColor: AidColors.elevated,
                            ),
                          ],
                        ),
                      )),
                ],

                // Event details
                if (post.eventDetails != null) ...[
                  const Gap(10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AidColors.textMuted),
                      const Gap(4),
                      Text(
                        '${post.eventDetails!.eventDate.day}/${post.eventDetails!.eventDate.month}/${post.eventDetails!.eventDate.year}',
                        style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                      ),
                      const Gap(12),
                      const Icon(Icons.location_on_outlined, size: 13, color: AidColors.textMuted),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          post.eventDetails!.location,
                          style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const Gap(14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddProofScreen(post: post)),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                        label: const Text('Add Proof'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AidColors.ngoAccent,
                          side: BorderSide(color: AidColors.ngoAccent.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: AidTextStyles.labelMd,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showActivity(context),
                        icon: const Icon(Icons.bar_chart_rounded, size: 16),
                        label: const Text('Activity'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AidColors.ngoAccent.withValues(alpha: 0.15),
                          foregroundColor: AidColors.ngoAccent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: AidTextStyles.labelMd,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const Gap(8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AidColors.textMuted, size: 20),
                      color: AidColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) => _handleMenu(context, value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'fulfill',
                          child: Row(children: [
                            Icon(Icons.check_circle_outline, size: 16, color: AidColors.success),
                            Gap(8),
                            Text('Mark Fulfilled'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(children: [
                            Icon(Icons.cancel_outlined, size: 16, color: AidColors.warning),
                            Gap(8),
                            Text('Cancel Post'),
                          ]),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: AidColors.error),
                            Gap(8),
                            Text('Delete', style: TextStyle(color: AidColors.error)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBanner() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _typeColor.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          post.type == PostType.activity ? Icons.event_rounded : Icons.volunteer_activism_rounded,
          color: _typeColor.withValues(alpha: 0.4),
          size: 30,
        ),
      ),
    );
  }

  void _handleMenu(BuildContext context, String value) async {
    if (value == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AidColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete post?', style: AidTextStyles.headingMd),
          content: Text(
            'This will permanently delete "${post.title}" and all associated data.',
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AidColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted'), backgroundColor: AidColors.error),
          );
        }
      }
    } else {
      final newStatus = value == 'fulfill' ? 'fulfilled' : 'cancelled';
      await FirebaseFirestore.instance.collection('posts').doc(post.id).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post marked as $newStatus'),
            backgroundColor: value == 'fulfill' ? AidColors.success : AidColors.warning,
          ),
        );
      }
    }
  }

  void _showActivity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PostActivitySheet(postId: post.id, postTitle: post.title),
    );
  }
}

// ─── Post Activity Sheet ──────────────────────────────────────────────────────

class _PostActivitySheet extends StatelessWidget {
  final String postId;
  final String postTitle;
  const _PostActivitySheet({required this.postId, required this.postTitle});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: AidColors.borderStrong, borderRadius: BorderRadius.circular(2))),
                ),
                const Gap(14),
                Text('Activity', style: AidTextStyles.headingMd),
                Text(postTitle, style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('donations')
                  .orderBy('donatedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AidColors.ngoAccent));
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_rounded, size: 48, color: AidColors.textMuted),
                          const Gap(12),
                          Text('No donations yet', style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(color: AidColors.borderSubtle, height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final hasItem = (d['item'] as String?)?.isNotEmpty == true;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AidColors.donorAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: AidColors.donorAccent, size: 18),
                      ),
                      title: Text(d['donorEmail'] ?? 'Anonymous', style: AidTextStyles.bodyMd),
                      subtitle: Text(
                        hasItem ? d['item'] : '₹${(d['amount'] ?? 0).toStringAsFixed(0)}',
                        style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                      ),
                      trailing: _StatusChip(status: d['status'] ?? 'pending'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Impact Groups Tab ────────────────────────────────────────────────────────

class _ImpactGroupsTab extends StatefulWidget {
  final String uid;
  final String ngoName;
  const _ImpactGroupsTab({required this.uid, required this.ngoName});

  @override
  State<_ImpactGroupsTab> createState() => _ImpactGroupsTabState();
}

class _ImpactGroupsTabState extends State<_ImpactGroupsTab> {
  void _showCreateSheet() {
    ImpactGroupType _type = ImpactGroupType.elderly;
    final titleCtrl = TextEditingController();
    final storyCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '10');
    final needCtrl  = TextEditingController();
    final needs     = <String>[];
    bool consent    = false;
    bool saving     = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AidColors.borderDefault, borderRadius: BorderRadius.circular(2)))),
              const Gap(16),
              Text('Create Impact Group', style: AidTextStyles.headingMd),
              const Gap(4),
              Text('Consent-based group profile — no personal data', style: AidTextStyles.bodySm),
              const Gap(16),

              // Type selector
              Text('Group Type', style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary)),
              const Gap(8),
              Row(
                children: ImpactGroupType.values.map((t) {
                  final sel = _type == t;
                  final col = t == ImpactGroupType.children ? const Color(0xFFFF9800)
                      : t == ImpactGroupType.elderly ? const Color(0xFF7C3AED)
                      : t == ImpactGroupType.women ? const Color(0xFFE91E63)
                      : AidColors.ngoAccent;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? col.withValues(alpha: 0.15) : AidColors.elevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? col : AidColors.borderDefault, width: sel ? 1.5 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(t.emoji, style: const TextStyle(fontSize: 18)),
                            Text(t.label.split(' ').first, style: AidTextStyles.labelSm.copyWith(
                              color: sel ? col : AidColors.textSecondary, fontSize: 9,
                            )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(14),

              TextField(
                controller: titleCtrl,
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Headline *',
                  hintText: 'e.g. "12 elderly residents need winter care"',
                ),
              ),
              const Gap(10),
              TextField(
                controller: storyCtrl,
                maxLines: 3,
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Their Story *',
                  hintText: 'Tell donors who these people are and what they need…',
                  alignLabelWithHint: true,
                ),
              ),
              const Gap(10),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Number of Beneficiaries',
                  prefixIcon: Icon(Icons.people_rounded, size: 18),
                ),
              ),
              const Gap(10),

              // Needs chips
              Text('Needs', style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary)),
              const Gap(6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: needCtrl,
                      style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Add a need (e.g. Daily meals)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: () {
                      if (needCtrl.text.trim().isNotEmpty) {
                        setS(() { needs.add(needCtrl.text.trim()); needCtrl.clear(); });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AidColors.ngoAccent, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              if (needs.isNotEmpty) ...[
                const Gap(8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: needs.map((n) => GestureDetector(
                    onTap: () => setS(() => needs.remove(n)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AidColors.ngoAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(n, style: AidTextStyles.labelMd.copyWith(color: AidColors.ngoAccent)),
                          const Gap(4),
                          const Icon(Icons.close_rounded, size: 12, color: AidColors.ngoAccent),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ],
              const Gap(12),

              // Consent checkbox
              GestureDetector(
                onTap: () => setS(() => consent = !consent),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: consent ? AidColors.ngoAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: consent ? AidColors.ngoAccent : AidColors.borderDefault, width: 1.5),
                      ),
                      child: consent ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'I confirm all beneficiaries have given consent for group-level representation. No personal data will be disclosed.',
                        style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (saving || !consent || titleCtrl.text.trim().isEmpty)
                      ? null
                      : () async {
                          setS(() => saving = true);
                          final group = ImpactGroup(
                            id: '',
                            ngoId: widget.uid,
                            ngoName: widget.ngoName,
                            type: _type,
                            title: titleCtrl.text.trim(),
                            story: storyCtrl.text.trim(),
                            beneficiaryCount: int.tryParse(countCtrl.text) ?? 0,
                            needs: List.from(needs),
                            imageUrls: [],
                            updates: [],
                            consentConfirmed: true,
                            createdAt: DateTime.now(),
                          );
                          await FirebaseFirestore.instance
                              .collection('impactGroups')
                              .add(group.toFirestore());
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AidColors.ngoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Group', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('impactGroups')
              .where('ngoId', isEqualTo: widget.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👥', style: TextStyle(fontSize: 48)),
                      const Gap(16),
                      Text('No impact groups yet', style: AidTextStyles.headingMd, textAlign: TextAlign.center),
                      const Gap(8),
                      Text(
                        'Create consent-based group profiles for children, elderly, or women to help donors connect emotionally.',
                        style: AidTextStyles.bodySm,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (_, i) {
                final g = ImpactGroup.fromFirestore(docs[i]);
                final col = g.type == ImpactGroupType.children ? const Color(0xFFFF9800)
                    : g.type == ImpactGroupType.elderly ? const Color(0xFF7C3AED)
                    : g.type == ImpactGroupType.women ? const Color(0xFFE91E63)
                    : AidColors.ngoAccent;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: col.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(g.type.emoji, style: const TextStyle(fontSize: 24))),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.title, style: AidTextStyles.headingSm, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Gap(2),
                            Text('${g.beneficiaryCount} ${g.type.label} · ${g.needs.length} needs',
                                style: AidTextStyles.bodySm),
                          ],
                        ),
                      ),
                      const Gap(8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AidColors.error),
                        onPressed: () => FirebaseFirestore.instance.collection('impactGroups').doc(docs[i].id).delete(),
                        style: IconButton.styleFrom(backgroundColor: AidColors.error.withValues(alpha: 0.08)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addGroup',
            onPressed: _showCreateSheet,
            backgroundColor: AidColors.ngoAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.group_add_rounded, size: 18),
            label: const Text('Add Group', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

// ─── Activities Tab ───────────────────────────────────────────────────────────
// For both NGOs and Welfare Homes — schedule events, camps, resident activities

class _ActivitiesTab extends StatefulWidget {
  final String uid;
  const _ActivitiesTab({required this.uid});

  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  void _showAddSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final dateCtrl  = TextEditingController();
    DateTime? picked;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          bool saving = false;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AidColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(16),
                Text('Add Activity', style: AidTextStyles.headingMd),
                const Gap(4),
                Text('Schedule events, camps, drives, or resident activities',
                    style: AidTextStyles.bodySm),
                const Gap(16),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Activity name *',
                    hintText: 'e.g. Morning Yoga, Medical Camp, Food Drive',
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    hintText: 'Location, instructions, what to bring…',
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'Tap to pick',
                    suffixIcon: Icon(Icons.calendar_month_rounded, size: 18),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      picked = d;
                      dateCtrl.text = '${d.day}/${d.month}/${d.year}';
                      setS(() {});
                    }
                  },
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (titleCtrl.text.trim().isEmpty) return;
                            setS(() => saving = true);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.uid)
                                .collection('activities')
                                .add({
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'date': picked != null ? Timestamp.fromDate(picked!) : null,
                              'status': 'upcoming',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AidColors.ngoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('activities')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AidColors.ngoAccent));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 48)),
                      const Gap(16),
                      Text('No activities yet', style: AidTextStyles.headingMd),
                      const Gap(8),
                      Text(
                        'Tap the button below to schedule a drive, camp, event or resident activity.',
                        style: AidTextStyles.bodySm,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final date = data['date'] != null
                    ? (data['date'] as Timestamp).toDate()
                    : null;
                final isPast = date != null && date.isBefore(DateTime.now());

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPast
                          ? AidColors.borderDefault
                          : AidColors.ngoAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Date badge
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isPast
                              ? AidColors.elevated
                              : AidColors.ngoAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              date != null
                                  ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][date.month - 1]
                                  : '—',
                              style: TextStyle(
                                color: isPast ? AidColors.textMuted : AidColors.ngoAccent,
                                fontSize: 10, fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              date != null ? '${date.day}' : '?',
                              style: TextStyle(
                                color: isPast ? AidColors.textMuted : AidColors.ngoAccent,
                                fontSize: 20, fontWeight: FontWeight.w800, height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['title'] ?? '', style: AidTextStyles.headingSm),
                            if ((data['description'] ?? '').isNotEmpty) ...[
                              const Gap(2),
                              Text(
                                data['description'],
                                style: AidTextStyles.bodySm,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Gap(8),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isPast ? AidColors.textMuted : AidColors.ngoAccent)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isPast ? 'DONE' : 'UPCOMING',
                              style: AidTextStyles.labelSm.copyWith(
                                color: isPast ? AidColors.textMuted : AidColors.ngoAccent,
                                fontWeight: FontWeight.w800, fontSize: 8,
                              ),
                            ),
                          ),
                          const Gap(6),
                          GestureDetector(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.uid)
                                  .collection('activities')
                                  .doc(docs[i].id)
                                  .delete();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AidColors.error.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  size: 14, color: AidColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addActivity',
            onPressed: _showAddSheet,
            backgroundColor: AidColors.ngoAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: const Text('Add Activity',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

// ─── Impact Tab ───────────────────────────────────────────────────────────────

class _ImpactTab extends StatefulWidget {
  final String uid;
  const _ImpactTab({required this.uid});

  @override
  State<_ImpactTab> createState() => _ImpactTabState();
}

class _ImpactTabState extends State<_ImpactTab> {
  double _totalMoneyRaised = 0;
  int _totalDonorCount = 0;
  int _itemDonationCount = 0;
  bool _statsLoaded = false;
  bool _refreshing = false;
  List<String> _lastPostIds = [];

  Future<void> _refreshDonationStats(List<QueryDocumentSnapshot> posts) async {
    if (_refreshing) return;
    if (mounted) setState(() => _refreshing = true);

    try {
      final futures = posts.map((p) async {
        try {
          return await FirebaseFirestore.instance
              .collection('posts')
              .doc(p.id)
              .collection('donations')
              .get()
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);

      double money = 0;
      final emails = <String>{};
      int itemCount = 0;

      for (final snap in results) {
        if (snap == null) continue;
        for (final doc in snap.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final amount = (d['amount'] ?? 0) as num;
          if (amount > 0) money += amount.toDouble();
          if ((d['item'] as String?)?.isNotEmpty == true) itemCount++;
          final email = d['donorEmail'] as String?;
          if (email != null && email.isNotEmpty) emails.add(email);
        }
      }

      if (mounted) {
        setState(() {
          _totalMoneyRaised = money;
          _totalDonorCount = emails.length;
          _itemDonationCount = itemCount;
          _statsLoaded = true;
          _refreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ngoId', isEqualTo: widget.uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // Trigger donation stats refresh when post list changes
        final currentIds = docs.map((d) => d.id).toList()..sort();
        final idsStr = currentIds.join(',');
        final lastStr = _lastPostIds.join(',');
        if (idsStr != lastStr) {
          _lastPostIds = currentIds;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _refreshDonationStats(docs);
          });
        }

        final total  = docs.length;
        final active = docs.where((d) => (d.data() as Map)['status'] == 'active').length;
        final events = docs.where((d) => (d.data() as Map)['type'] == 'activity').length;

        // Category breakdown
        final catMap = <String, int>{};
        for (final d in docs) {
          final cat = (d.data() as Map)['category'] as String? ?? 'Other';
          catMap[cat] = (catMap[cat] ?? 0) + 1;
        }

        // Posts with items for drive progress
        final drivesDocs = docs
            .where((d) => ((d.data() as Map)['requiredItems'] as List? ?? []).isNotEmpty)
            .toList();

        // Proof photos
        final proofUrls = docs
            .expand((d) => ((d.data() as Map)['proofUrls'] as List? ?? []).cast<String>())
            .toList();

        return RefreshIndicator(
          color: AidColors.ngoAccent,
          onRefresh: () => _refreshDonationStats(docs),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Impact', style: AidTextStyles.headingLg),
                        Text('Live fundraising & contribution stats',
                            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
                      ],
                    ),
                  ),
                  if (_refreshing)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AidColors.ngoAccent),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: AidColors.textMuted),
                      onPressed: () => _refreshDonationStats(docs),
                      tooltip: 'Refresh stats',
                    ),
                ],
              ),
              const Gap(16),

              // ── TOTAL RAISED HERO ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AidColors.ngoAccent, Color(0xFF1A7A6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AidColors.ngoAccent.withValues(alpha: 0.35),
                      blurRadius: 16, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volunteer_activism_rounded, color: Colors.white70, size: 16),
                        const Gap(6),
                        const Text(
                          'TOTAL FUNDS RAISED',
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4),
                        ),
                      ],
                    ),
                    const Gap(6),
                    _statsLoaded
                        ? Text(
                            '₹${_formatNum(_totalMoneyRaised)}',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 38,
                              fontWeight: FontWeight.w900, height: 1,
                            ),
                          )
                        : Container(
                            height: 38,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                    const Gap(16),
                    Row(
                      children: [
                        _MiniStat(label: 'Donors', value: _statsLoaded ? '$_totalDonorCount' : '—', icon: Icons.people_rounded),
                        const Gap(24),
                        _MiniStat(label: 'Item Gifts', value: _statsLoaded ? '$_itemDonationCount' : '—', icon: Icons.inventory_2_rounded),
                        const Gap(24),
                        _MiniStat(label: 'Active Posts', value: '$active', icon: Icons.article_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // ── QUICK STATS GRID ─────────────────────────────────────────────
              Row(children: [
                Expanded(child: _ImpactCard(value: '$total', label: 'Total Posts', icon: Icons.article_rounded, color: AidColors.ngoAccent)),
                const Gap(12),
                Expanded(child: _ImpactCard(value: '$events', label: 'Events Held', icon: Icons.event_rounded, color: AidColors.volunteerAccent)),
              ]),
              const Gap(24),

              // ── DONATION DRIVE PROGRESS ──────────────────────────────────────
              if (drivesDocs.isNotEmpty) ...[
                Text('Donation Drive Progress', style: AidTextStyles.headingMd),
                const Gap(4),
                Text('Item fulfillment across all your drives',
                    style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
                const Gap(12),
                ...drivesDocs.take(6).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final items = (data['requiredItems'] as List? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList();
                  final totalTarget   = items.fold<double>(0, (s, i) => s + ((i['targetQty']   ?? 0) as num).toDouble());
                  final totalFulfilled = items.fold<double>(0, (s, i) => s + ((i['fulfilledQty'] ?? 0) as num).toDouble());
                  final progress = totalTarget > 0 ? (totalFulfilled / totalTarget).clamp(0.0, 1.0) : 0.0;
                  final pct = (progress * 100).toInt();
                  final isActive = data['status'] == 'active';
                  final statusColor = isActive ? AidColors.success : AidColors.textMuted;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AidColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AidColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['title'] ?? '',
                                style: AidTextStyles.headingSm,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                (data['status'] as String? ?? 'unknown').toUpperCase(),
                                style: AidTextStyles.labelSm.copyWith(
                                  color: statusColor, fontSize: 9, fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${totalFulfilled.toInt()} / ${totalTarget.toInt()} items collected',
                              style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary),
                            ),
                            Text(
                              '$pct%',
                              style: AidTextStyles.labelMd.copyWith(
                                color: pct >= 100 ? AidColors.success : AidColors.ngoAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Gap(6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            color: pct >= 100 ? AidColors.success : AidColors.ngoAccent,
                            backgroundColor: AidColors.elevated,
                          ),
                        ),
                        if (items.length > 1) ...[
                          const Gap(8),
                          Wrap(
                            spacing: 6, runSpacing: 4,
                            children: items.map((item) {
                              final f = ((item['fulfilledQty'] ?? 0) as num).toDouble();
                              final t = ((item['targetQty']   ?? 1) as num).toDouble();
                              final p = t > 0 ? (f / t * 100).clamp(0, 100).toInt() : 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AidColors.elevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item['name'] ?? '?'}: $p%',
                                  style: AidTextStyles.labelSm.copyWith(fontSize: 10),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const Gap(8),
              ],

              // ── CATEGORY BREAKDOWN ───────────────────────────────────────────
              if (catMap.isNotEmpty && total > 0) ...[
                Text('Category Breakdown', style: AidTextStyles.headingMd),
                const Gap(4),
                Text('Posts by cause area', style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
                const Gap(12),
                ...() {
                  final sorted = catMap.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return sorted.take(8).map((e) {
                    final pct = e.value / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: AidTextStyles.labelMd),
                              Text(
                                '${e.value} post${e.value != 1 ? "s" : ""}',
                                style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                              ),
                            ],
                          ),
                          const Gap(4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              color: AidColors.donorAccent,
                              backgroundColor: AidColors.elevated,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                }(),
                const Gap(16),
              ],

              // ── PROOF OF IMPACT ──────────────────────────────────────────────
              Text('Proof of Impact', style: AidTextStyles.headingMd),
              const Gap(4),
              Text('Photos uploaded after events as proof',
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
              const Gap(12),
              if (proofUrls.isEmpty)
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AidColors.borderSubtle),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined, color: AidColors.textMuted, size: 30),
                        const Gap(8),
                        Text('No proof photos yet',
                            style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
                  ),
                  itemCount: proofUrls.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(proofUrls[i], fit: BoxFit.cover),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatNum(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000)   return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)     return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 11),
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: color),
              const Gap(5),
              Text(value, style: AidTextStyles.headingSm.copyWith(color: color)),
              Text(label, style: AidTextStyles.labelSm),
            ],
          ),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const Gap(4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.1)),
        ],
      ),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ],
  );
}

class _ImpactCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _ImpactCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(10),
            Text(value, style: AidTextStyles.displaySm.copyWith(color: color)),
            Text(label, style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: AidTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => status == 'accepted'
      ? AidColors.success
      : status == 'rejected'
          ? AidColors.error
          : AidColors.warning;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Text(
          status.toUpperCase(),
          style: AidTextStyles.labelSm.copyWith(color: _color, fontWeight: FontWeight.w700, fontSize: 9),
        ),
      );
}