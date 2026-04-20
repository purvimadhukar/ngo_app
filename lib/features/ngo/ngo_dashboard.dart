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
import '../common/contact_us_screen.dart';
import '../common/theme_control_panel.dart';
import '../../models/resident.dart';
import 'add_resident_screen.dart';
import '../../services/notification_service.dart';
import '../common/notifications_screen.dart';
import 'ngo_analytics_screen.dart';

class NgoDashboard extends StatefulWidget {
  const NgoDashboard({super.key});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _ngoName = 'Your NGO';
  String _uid = '';
  bool _ngoVerified = false;
  String _verificationStatus = 'none'; // none | pending | rejected | approved

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _tab = TabController(length: 6, vsync: this);
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
    return Scaffold(
      backgroundColor: AidColors.ngoBackground,
      body: Column(
        children: [
          _buildHeroHeader(),
          if (!_ngoVerified) _buildVerificationBanner(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MyPostsTab(uid: _uid),
                _ActivitiesTab(uid: _uid, ngoName: _ngoName),
                _ImpactGroupsTab(uid: _uid, ngoName: _ngoName),
                _ResidentsTab(uid: _uid, careHomeName: _ngoName),
                const _ResourcesTab(),
                _ImpactTab(uid: _uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final parts = _ngoName.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : _ngoName.isNotEmpty ? _ngoName[0].toUpperCase() : 'N';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF200828), Color(0xFF1A3A6E), Color(0xFF2B8CE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _ngoName,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 18,
                                  fontWeight: FontWeight.w800, height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_ngoVerified) ...[
                              const Gap(6),
                              const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                            ],
                          ],
                        ),
                        Text(
                          'NGO Dashboard',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // New Post button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          Gap(5),
                          Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  // ── Notification bell ───────────────────────────────────
                  StreamBuilder<int>(
                    stream: NotificationService.unreadCount(_uid),
                    builder: (context, snap) {
                      final unread = snap.data ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(
                              unread > 0
                                  ? Icons.notifications_rounded
                                  : Icons.notifications_outlined,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 22,
                            ),
                            tooltip: 'Notifications',
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 6, right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8514A),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.bar_chart_rounded, color: Colors.white.withValues(alpha: 0.85), size: 22),
                    tooltip: 'Analytics',
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NgoAnalyticsScreen())),
                  ),
                  IconButton(
                    icon: Icon(Icons.palette_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
                    tooltip: 'Customise',
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ThemeControlPanel())),
                  ),
                  IconButton(
                    icon: Icon(Icons.contact_support_outlined, color: Colors.white.withValues(alpha: 0.6), size: 20),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ContactUsScreen())),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.6), size: 20),
                    onPressed: () => AuthService.instance.signOut(),
                  ),
                ],
              ),
            ),
            const Gap(18),

            // ── Stats row ───────────────────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('ngoId', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                final total     = docs.length;
                final active    = docs.where((d) => (d.data() as Map)['status'] == 'active').length;
                final fulfilled = docs.where((d) => (d.data() as Map)['status'] == 'fulfilled').length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      _HeroStat(value: '$total',     label: 'Total Posts'),
                      _heroDivider(),
                      _HeroStat(value: '$active',    label: 'Active'),
                      _heroDivider(),
                      _HeroStat(value: '$fulfilled', label: 'Fulfilled'),
                      _heroDivider(),
                      _HeroStat(
                        value: _ngoVerified ? 'Yes' : 'No',
                        label: 'Verified',
                        highlight: _ngoVerified,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroDivider() => Container(
    width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withValues(alpha: 0.2),
  );

  Widget _buildVerificationBanner(BuildContext context) {
    final isPending = _verificationStatus == 'pending';
    final isRejected = _verificationStatus == 'rejected';
    final color = isPending ? AidColors.warning : isRejected ? AidColors.error : AidColors.ngoAccent;
    final msg = isPending
        ? 'Verification under review'
        : isRejected
            ? 'Verification rejected — tap to resubmit'
            : 'Get verified to unlock full visibility';

    return GestureDetector(
      onTap: isPending ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NgoVerificationScreen()),
      ).then((_) => _loadProfile()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const Gap(10),
            Expanded(
              child: Text(msg, style: AidTextStyles.labelMd.copyWith(color: color)),
            ),
            if (!isPending) ...[
              const Gap(8),
              Text(
                isRejected ? 'Resubmit →' : 'Apply →',
                style: AidTextStyles.labelMd.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AidColors.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: AidColors.surface, borderRadius: BorderRadius.circular(12)),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(color: AidColors.ngoAccent, borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AidColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Events'),
            Tab(text: 'Groups'),
            Tab(text: 'Residents'),
            Tab(text: 'Resources'),
            Tab(text: 'Impact'),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Stat (inside gradient header) ──────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String value, label;
  final bool highlight;
  const _HeroStat({required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF80FFD0) : Colors.white,
            fontSize: 22, fontWeight: FontWeight.w900, height: 1,
          ),
        ),
        const Gap(3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ─── My Posts Tab ─────────────────────────────────────────────────────────────

class _MyPostsTab extends StatelessWidget {
  final String uid;
  const _MyPostsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    // No orderBy — avoids composite index requirement; sort client-side
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ngoId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AidColors.ngoAccent, strokeWidth: 2));
        }
        final rawDocs = snap.data?.docs ?? [];
        // Sort by createdAt descending, client-side
        final docs = [...rawDocs]..sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });
        if (docs.isEmpty) return const _EmptyState(icon: Icons.article_outlined, title: 'No posts yet', sub: 'Tap + New Post to create your first donation drive or volunteer event.');
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
      height: 56,
      decoration: BoxDecoration(
        color: _typeColor.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _typeColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
            ),
          ),
          const Gap(14),
          Text(
            _typeLabel.toUpperCase(),
            style: TextStyle(
              color: _typeColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
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
                      : t == ImpactGroupType.elderly ? AidColors.ngoAccent
                      : t == ImpactGroupType.women ? AidColors.ngoAccent
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
              return const _EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No beneficiary groups yet',
                sub: 'Create consent-based group profiles for children, elderly, or women to connect donors emotionally.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (_, i) {
                final g = ImpactGroup.fromFirestore(docs[i]);
                final col = g.type == ImpactGroupType.children ? const Color(0xFFFF9800)
                    : g.type == ImpactGroupType.elderly ? AidColors.ngoAccent
                    : g.type == ImpactGroupType.women ? AidColors.ngoAccent
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

class _ActivitiesTab extends StatefulWidget {
  final String uid;
  final String ngoName;
  const _ActivitiesTab({required this.uid, required this.ngoName});

  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  void _showAddSheet() {
    final titleCtrl    = TextEditingController();
    final descCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    final dateCtrl     = TextEditingController();
    DateTime? picked;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          bool saving = false;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AidColors.borderStrong, borderRadius: BorderRadius.circular(2)))),
                const Gap(18),

                // Header
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AidColors.ngoAccent, AidColors.ngoAccentMuted],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
                  ),
                  const Gap(12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('New Activity', style: AidTextStyles.headingMd),
                    Text('Visible to donors & volunteers', style: AidTextStyles.bodySm),
                  ]),
                ]),
                const Gap(20),

                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Activity title *',
                    hintText: 'e.g. Medical Camp, Food Drive, Yoga Session',
                    prefixIcon: Icon(Icons.title_rounded, size: 18),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: locationCtrl,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Where is it happening?',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    hintText: 'What to bring, volunteer instructions…',
                    alignLabelWithHint: true,
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    hintText: 'Tap to pick a date',
                    prefixIcon: Icon(Icons.calendar_month_rounded, size: 18),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      picked = d;
                      dateCtrl.text = '${d.day} ${_months[d.month - 1]} ${d.year}';
                      setS(() {});
                    }
                  },
                ),
                const Gap(24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (saving || titleCtrl.text.trim().isEmpty)
                        ? null
                        : () async {
                            setS(() => saving = true);
                            final now = DateTime.now();
                            final ts  = Timestamp.fromDate(now); // ← client timestamp, never null

                            final batch = FirebaseFirestore.instance.batch();

                            // 1️⃣ NGO's private calendar
                            final actRef = FirebaseFirestore.instance
                                .collection('users').doc(widget.uid)
                                .collection('activities').doc();
                            batch.set(actRef, {
                              'title':       titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'location':    locationCtrl.text.trim(),
                              'date':        picked != null ? Timestamp.fromDate(picked!) : ts,
                              'status':      'upcoming',
                              'createdAt':   ts,
                            });

                            // 2️⃣ Public posts collection → visible to donors & volunteers
                            final postRef = FirebaseFirestore.instance.collection('posts').doc();
                            batch.set(postRef, {
                              'ngoId':       widget.uid,
                              'ngoName':     widget.ngoName,
                              'ngoVerified': false,
                              'title':       titleCtrl.text.trim(),
                              'description': descCtrl.text.trim().isEmpty
                                  ? '${widget.ngoName} is hosting an activity. Join us!'
                                  : descCtrl.text.trim(),
                              'category':    'volunteer event',
                              'type':        'activity',
                              'status':      'active',
                              'mediaUrls':   [],
                              'proofUrls':   [],
                              'requiredItems': [],
                              'eventDetails': {
                                'eventDate':         picked != null
                                    ? Timestamp.fromDate(picked!)
                                    : ts,
                                'location':          locationCtrl.text.trim(),
                                'volunteersNeeded':  10,
                                'volunteersJoined':  0,
                                'contactName':       '',
                                'contactPhone':      '',
                              },
                              'urgencyScore':      0.4,
                              'flaggedForReview':  false,
                              'donationCount':     0,
                              'createdAt':         ts,
                              'updatedAt':         ts,
                            });

                            await batch.commit();
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AidColors.ngoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Publish Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteActivity(String docId, Map<String, dynamic> data) async {
    // Delete from private calendar
    await FirebaseFirestore.instance
        .collection('users').doc(widget.uid)
        .collection('activities').doc(docId).delete();

    // Also try to delete matching public post (best effort, match by title + ngoId)
    try {
      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .where('ngoId', isEqualTo: widget.uid)
          .where('type', isEqualTo: 'activity')
          .where('title', isEqualTo: data['title'])
          .limit(1)
          .get();
      for (final p in posts.docs) {
        await p.reference.delete();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          // No orderBy — sort client-side to avoid composite index requirement
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('activities')
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                  color: AidColors.ngoAccent, strokeWidth: 2));
            }

            final rawDocs = snap.data?.docs ?? [];
            // Sort by date ascending (upcoming first), then by createdAt
            final docs = [...rawDocs]..sort((a, b) {
                final aDate = (a.data() as Map)['date'] as Timestamp?;
                final bDate = (b.data() as Map)['date'] as Timestamp?;
                if (aDate == null && bDate == null) return 0;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return aDate.compareTo(bDate);
              });

            if (docs.isEmpty) {
              return const _EmptyState(
                icon: Icons.event_note_outlined,
                title: 'No activities yet',
                sub: 'Tap Publish Activity to schedule an event visible to donors and volunteers.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp?)?.toDate();
                final isPast = date != null && date.isBefore(DateTime.now());
                final accent = isPast ? AidColors.textMuted : AidColors.ngoAccent;

                return Container(
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPast
                          ? AidColors.borderSubtle
                          : AidColors.ngoAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Accent left bar
                      Container(
                        width: 4,
                        height: 80,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      const Gap(14),

                      // Date block
                      Container(
                        width: 46,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              date != null ? _months[date.month - 1].toUpperCase() : '—',
                              style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              date != null ? '${date.day}' : '?',
                              style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w900, height: 1),
                            ),
                            Text(
                              date != null ? '${date.year}' : '',
                              style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),

                      // Title + description + location
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? '', style: AidTextStyles.headingSm),
                              if ((data['location'] ?? '').toString().isNotEmpty) ...[
                                const Gap(3),
                                Row(children: [
                                  Icon(Icons.location_on_outlined, size: 11, color: AidColors.textMuted),
                                  const Gap(3),
                                  Expanded(
                                    child: Text(
                                      data['location'],
                                      style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]),
                              ],
                              if ((data['description'] ?? '').toString().isNotEmpty) ...[
                                const Gap(3),
                                Text(
                                  data['description'],
                                  style: AidTextStyles.bodySm,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Gap(8),

                      // Status pill + delete
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isPast ? 'DONE' : 'UPCOMING',
                                style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ),
                            const Gap(8),
                            GestureDetector(
                              onTap: () => _deleteActivity(docs[i].id, data),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AidColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, size: 14, color: AidColors.error),
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
          },
        ),

        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addActivity',
            onPressed: _showAddSheet,
            backgroundColor: AidColors.ngoAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Publish Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

// ─── Resources Tab ───────────────────────────────────────────────────────────

class _ResourcesTab extends StatefulWidget {
  const _ResourcesTab();

  @override
  State<_ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<_ResourcesTab> {
  int _expandedIndex = -1;

  static const _categories = <_ResCategory>[
    _ResCategory(
      icon: Icons.local_hospital_rounded,
      title: 'Government Hospitals',
      subtitle: 'Free & subsidized treatment centers',
      color: AidColors.ngoAccent,
      items: [
        _ResItem('AIIMS', 'All India Institute of Medical Sciences — free treatment for all citizens',
            '011-26588500', 'Delhi & multiple cities'),
        _ResItem('NIMHANS', 'National Institute of Mental Health & Neurosciences — psychiatric care',
            '080-46110007', 'Bangalore'),
        _ResItem('Ram Manohar Lohia Hospital', 'Government hospital — free OPD & emergency services',
            '011-23365525', 'New Delhi'),
        _ResItem('ESI Hospitals', 'Employee State Insurance — free treatment for ESI members',
            '1800-11-3839', 'Pan India (300+ hospitals)'),
      ],
    ),
    _ResCategory(
      icon: Icons.water_drop_rounded,
      title: 'Blood Banks',
      subtitle: 'Voluntary donation & emergency requests',
      color: Color(0xFFE8514A),
      items: [
        _ResItem('Indian Red Cross Society', 'Largest blood bank network — emergency blood requests',
            '1800-180-7999', 'Pan India (Toll Free)'),
        _ResItem('eBloodServices', 'Online blood request platform — connects 2,000+ banks nationwide',
            null, 'ebloodservices.org'),
        _ResItem('Sankalp India Foundation', 'Blood donation drives, thalassemia & patient support',
            '080-23568451', 'Bangalore & expanding'),
        _ResItem('National Blood Transfusion Council', 'Government blood coordination & emergency helpline',
            '011-23062300', 'New Delhi'),
      ],
    ),
    _ResCategory(
      icon: Icons.medical_services_rounded,
      title: 'Free Medicine Sources',
      subtitle: 'Subsidized & free medicine programs',
      color: Color(0xFF4CAF50),
      items: [
        _ResItem('Jan Aushadhi Kendras', 'PM Bhartiya Janaushadhi Pariyojana — medicines 50–90% cheaper',
            '1800-111-255', '9,000+ outlets across India'),
        _ResItem('Ayushman Bharat (PMJAY)', 'Free treatment up to ₹5 lakh per family per year at 25,000+ hospitals',
            '14555', 'pmjay.gov.in | Toll Free'),
        _ResItem('State Free Medicine Scheme', 'Free medicines at government PHCs, CHCs & district hospitals',
            null, 'Contact district CMO office'),
        _ResItem('NGO Medicine Banks', 'Organizations like iCall, Goonj distribute free medicines',
            '9152987821', 'Pan India'),
      ],
    ),
    _ResCategory(
      icon: Icons.airport_shuttle_rounded,
      title: 'Ambulance Services',
      subtitle: 'Emergency & patient transport',
      color: AidColors.ngoAccent,
      items: [
        _ResItem('108 — Emergency Ambulance', 'Free government advanced life support — 24/7 response',
            '108', 'Pan India (All states)'),
        _ResItem('102 — Janani Express', 'Free ambulance for pregnant women & newborn transport',
            '102', 'Pan India (Govt-funded)'),
        _ResItem('EMRI 1298 Ambulance', 'Emergency response — basic & advanced life support units',
            '1298', 'Andhra, Telangana, Gujarat, others'),
        _ResItem('Ziqitza Healthcare', 'Private ambulance — ICU on wheels & inter-hospital transfers',
            '1800-419-1122', 'Pan India'),
      ],
    ),
    _ResCategory(
      icon: Icons.home_rounded,
      title: 'Shelters & Welfare Homes',
      subtitle: 'Old age homes, orphanages & women shelters',
      color: AidColors.ngoAccent,
      items: [
        _ResItem('HelpAge India', 'Old age homes, elder helpline, legal aid & mobile health for seniors',
            '1800-180-1253', 'Pan India (Toll Free)'),
        _ResItem('Missionaries of Charity', 'Shelter homes for destitute, terminally ill & abandoned',
            '033-22271167', 'Kolkata & 250+ centres in India'),
        _ResItem('SOS Children\'s Villages India', 'Safe homes & holistic care for orphaned & abandoned children',
            '011-46556300', '32 villages across India'),
        _ResItem('SWADHAR Greh (Govt)', 'Government shelter homes for women in distress — free food & legal aid',
            '181', 'Women helpline — Pan India'),
      ],
    ),
    _ResCategory(
      icon: Icons.account_balance_rounded,
      title: 'Government Welfare Schemes',
      subtitle: 'Central & state support programs',
      color: Color(0xFFFF9800),
      items: [
        _ResItem('PM KISAN Samman Nidhi', 'Direct ₹6,000/year income support for small & marginal farmers',
            '155261', 'pmkisan.gov.in'),
        _ResItem('PM Ujjwala Yojana', 'Free LPG connections for BPL households — clean cooking fuel',
            '1800-233-3555', 'pmuy.gov.in'),
        _ResItem('MGNREGA', '100-day guaranteed rural employment — ₹220–300/day wages',
            null, 'nrega.nic.in | Block office'),
        _ResItem('National Social Assistance Programme', 'Old age, widow & disability pension for BPL families',
            null, 'nsap.nic.in | District SDO'),
        _ResItem('PM Awas Yojana', 'Affordable housing for economically weaker sections',
            '1800-11-6163', 'pmaymis.gov.in'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _categories.length + 1,
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (_, i) {
        if (i == 0) return _buildBanner();
        final cat = _categories[i - 1];
        final expanded = _expandedIndex == (i - 1);
        return _buildCard(cat, i - 1, expanded);
      },
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AidColors.ngoAccent.withValues(alpha: 0.15), AidColors.donorAccent.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AidColors.ngoAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.library_books_rounded, color: AidColors.ngoAccent, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welfare Resource Directory', style: AidTextStyles.headingMd),
                const Gap(2),
                Text('Hospitals · Blood banks · Govt schemes · Shelters',
                    style: AidTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_ResCategory cat, int index, bool expanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded ? cat.color.withValues(alpha: 0.45) : AidColors.borderSubtle,
          width: expanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandedIndex = expanded ? -1 : index),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.title, style: AidTextStyles.headingSm),
                        const Gap(1),
                        Text(cat.subtitle, style: AidTextStyles.bodySm),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat.items.length}',
                      style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Gap(8),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AidColors.textMuted, size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: AidColors.borderSubtle, height: 1, indent: 14, endIndent: 14),
            ...cat.items.asMap().entries.map((e) =>
              _buildItem(e.value, cat.color, e.key == cat.items.length - 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(_ResItem item, Color color, bool isLast) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 14 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AidTextStyles.headingSm),
                    const Gap(3),
                    Text(item.description, style: AidTextStyles.bodySm),
                    const Gap(6),
                    Wrap(
                      spacing: 12, runSpacing: 4,
                      children: [
                        if (item.phone != null)
                          _resChip(Icons.phone_rounded, item.phone!, color),
                        _resChip(Icons.location_on_outlined, item.location, AidColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const Gap(12),
            const Divider(color: AidColors.borderSubtle, height: 1),
          ],
        ],
      ),
    );
  }

  Widget _resChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const Gap(4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Resource data classes ────────────────────────────────────────────────────

class _ResCategory {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<_ResItem> items;
  const _ResCategory({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.items,
  });
}

class _ResItem {
  final String name;
  final String description;
  final String? phone;
  final String location;
  const _ResItem(this.name, this.description, this.phone, this.location);
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

// ─── Shared Empty State ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const _EmptyState({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AidColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AidColors.borderDefault),
              ),
              child: Icon(icon, size: 28, color: AidColors.textMuted),
            ),
            const Gap(20),
            Text(title, style: AidTextStyles.headingMd, textAlign: TextAlign.center),
            const Gap(8),
            Text(sub, style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _QuickStat({required this.value, required this.label, this.color = AidColors.textPrimary});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
        const Gap(3),
        Text(label, style: AidTextStyles.labelSm.copyWith(color: AidColors.textMuted), textAlign: TextAlign.center),
      ],
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
// ─── Residents Tab ─────────────────────────────────────────────────────────────

class _ResidentsTab extends StatelessWidget {
  final String uid;
  final String careHomeName;
  const _ResidentsTab({required this.uid, required this.careHomeName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('residents')
          .where('careHomeId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        final residents = (snap.data?.docs ?? [])
            .map((d) => Resident.fromDoc(d))
            .toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AidColors.ngoAccent,
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddResidentScreen(
                  careHomeId: uid,
                  careHomeName: careHomeName,
                ),
              ));
            },
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            label: Text('Add Resident',
              style: GoogleFonts.syne(
                color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          body: residents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 60, color: AidColors.textMuted),
                      const Gap(16),
                      Text('No residents yet',
                        style: AidTextStyles.headingMd),
                      const Gap(8),
                      Text(
                        'Tap "Add Resident" when you visit\na care home to create profiles.',
                        textAlign: TextAlign.center,
                        style: AidTextStyles.bodyMd.copyWith(
                            color: AidColors.textMuted)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: residents.length,
                  itemBuilder: (_, i) => _ResidentCard(r: residents[i]),
                ),
        );
      },
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final Resident r;
  const _ResidentCard({required this.r});

  Color get _urgencyColor => Color(
      Resident.urgencyColors[r.urgency] ?? 0xFF2B8CE6);

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: AidColors.borderDefault,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text(r.name, style: AidTextStyles.headingMd),
            const Gap(4),
            Text('${r.age} yrs · ${r.urgency}',
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
            const Gap(20),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AidColors.ngoAccent),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddResidentScreen(
                    careHomeId: r.careHomeId,
                    careHomeName: r.careHomeName,
                    existing: r,
                  ),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_rounded, color: AidColors.ngoAccent),
              title: const Text('View Public Profile'),
              onTap: () {
                Navigator.pop(context);
                // opens donor's detail view
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AidColors.surface,
                    title: Text(r.name),
                    content: Text('${r.story}\n\nNeeds: ${r.needs.join(", ")}'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.toggle_off_rounded,
                  color: r.isActive ? AidColors.error : AidColors.success),
              title: Text(r.isActive ? 'Deactivate' : 'Reactivate'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('residents')
                    .doc(r.id)
                    .update({'isActive': !r.isActive});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showActions(context),
      onLongPress: () => _showActions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              child: r.photoUrl.isNotEmpty
                  ? Image.network(
                      r.photoUrl,
                      height: 130, width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 130,
                      color: AidColors.elevated,
                      child: const Center(
                        child: Icon(Icons.person_rounded,
                            size: 48, color: AidColors.textMuted)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(r.name,
                        style: AidTextStyles.labelLg,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _urgencyColor, shape: BoxShape.circle),
                    ),
                  ]),
                  const Gap(2),
                  Text('${r.age} yrs',
                    style: AidTextStyles.caption.copyWith(
                        color: AidColors.textMuted)),
                  const Gap(6),
                  Wrap(
                    spacing: 4, runSpacing: 4,
                    children: r.needs.take(2).map((n) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AidColors.ngoAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(n,
                        style: GoogleFonts.spaceGrotesk(
                          color: AidColors.ngoAccent,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
