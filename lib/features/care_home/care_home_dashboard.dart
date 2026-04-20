import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';
import '../../services/auth_service.dart';
import '../ngo/create_post_screen.dart';

// ── Care Centre Dashboard ─────────────────────────────────────────────────────
// Used by old age homes, care centres, shelters — any welfare home.
// Internally stored as role = 'careHome' in Firestore.

class CareHomeDashboard extends StatefulWidget {
  const CareHomeDashboard({super.key});

  @override
  State<CareHomeDashboard> createState() => _CareHomeDashboardState();
}

class _CareHomeDashboardState extends State<CareHomeDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic> _profile = {};
  bool _loading = true;

  static const _purple = AidColors.ngoAccent;
  static const _purpleLight = Color(0xFF2ECCA5);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
      if (mounted) setState(() { _profile = doc.data() ?? {}; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final centreName = _profile['orgName'] ?? _profile['name'] ?? 'Care Centre';

    return Scaffold(
      backgroundColor: AidColors.ngoBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ).then((_) => setState(() {})),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Need', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(centreName),
            _buildQuickStats(uid),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _NeedsTab(uid: uid),
                  _ActivitiesTab(uid: uid),
                  _DonationsTab(uid: uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String centreName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🏠', style: TextStyle(fontSize: 22))),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AidBridge',
                  style: AidTextStyles.caption.copyWith(
                    color: _purple,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(centreName,
                    style: AidTextStyles.heading.copyWith(fontSize: 20),
                    overflow: TextOverflow.ellipsis),
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

  Widget _buildQuickStats(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ngoId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final posts = snap.data?.docs ?? [];
        final active = posts.where((d) => (d.data() as Map)['status'] == 'active').length;
        final fulfilled = posts.where((d) => (d.data() as Map)['status'] == 'fulfilled').length;

        // Sum donations received
        double totalReceived = 0;
        for (final doc in posts) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['requiredItems'] as List<dynamic>? ?? [];
          for (final item in items) {
            totalReceived += ((item as Map)['fulfilledQty'] ?? 0).toDouble();
          }
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple.withValues(alpha: 0.12), _purpleLight.withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _purple.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              _statBox('${posts.length}', 'Total\nPosts', _purple),
              _vDivider(),
              _statBox('$active', 'Active\nNeeds', AidColors.ngoAccent),
              _vDivider(),
              _statBox('$fulfilled', 'Fulfilled', AidColors.donorAccent),
              _vDivider(),
              _statBox(_fmtQty(totalReceived), 'Items\nReceived', AidColors.volunteerAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String v, String label, Color color) => Expanded(
    child: Column(
      children: [
        Text(v, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const Gap(2),
        Text(label, textAlign: TextAlign.center,
            style: AidTextStyles.labelSm.copyWith(color: AidColors.textSecondary, height: 1.3)),
      ],
    ),
  );

  Widget _vDivider() => Container(
    width: 1, height: 32,
    color: AidColors.borderDefault,
    margin: const EdgeInsets.symmetric(horizontal: 6),
  );

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(10)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AidColors.textMuted,
          tabs: const [
            Tab(text: 'Needs'),
            Tab(text: 'Activities'),
            Tab(text: 'Donations'),
          ],
        ),
      ),
    );
  }

  String _fmtQty(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toInt().toString();
  }
}

// ── Needs Tab ─────────────────────────────────────────────────────────────────
// Shows all posts made by this care centre + edit/delete controls

class _NeedsTab extends StatelessWidget {
  final String uid;
  const _NeedsTab({required this.uid});

  static const _purple = AidColors.ngoAccent;

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
        if (docs.isEmpty) {
          return _emptyState(
            '🙏',
            'No needs posted yet',
            'Tap "Post Need" to tell donors and volunteers what you need.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (_, i) => _NeedCard(doc: docs[i]),
        );
      },
    );
  }
}

class _NeedCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _NeedCard({required this.doc});

  static const _purple = AidColors.ngoAccent;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'active';
    final statusColor = status == 'active'
        ? AidColors.ngoAccent
        : status == 'fulfilled'
            ? AidColors.donorAccent
            : AidColors.textMuted;
    final items = (data['requiredItems'] as List<dynamic>? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data['title'] ?? '', style: AidTextStyles.headingSm),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AidTextStyles.labelSm.copyWith(
                    color: statusColor, fontWeight: FontWeight.w800, fontSize: 9,
                  ),
                ),
              ),
              const Gap(4),
              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AidColors.textMuted, size: 18),
                color: AidColors.surface,
                onSelected: (v) => _handleAction(context, v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('✏️  Edit')),
                  const PopupMenuItem(value: 'fulfill', child: Text('✅  Mark Fulfilled')),
                  const PopupMenuItem(value: 'delete', child: Text('🗑️  Delete', style: TextStyle(color: AidColors.error))),
                ],
              ),
            ],
          ),
          if ((data['description'] ?? '').isNotEmpty) ...[
            const Gap(6),
            Text(
              data['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AidTextStyles.bodySm,
            ),
          ],
          if (items.isNotEmpty) ...[
            const Gap(10),
            ...items.take(3).map((item) {
              final m = item as Map<String, dynamic>;
              final progress = m['targetQty'] > 0
                  ? ((m['fulfilledQty'] ?? 0) / m['targetQty']).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${m['name']} (${m['unit']})', style: AidTextStyles.labelMd),
                        Text(
                          '${(m['fulfilledQty'] ?? 0).toInt()} / ${m['targetQty']?.toInt()}',
                          style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                        ),
                      ],
                    ),
                    const Gap(3),
                    LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                      color: _purple,
                      backgroundColor: AidColors.elevated,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    final db = FirebaseFirestore.instance;
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AidColors.surface,
          title: const Text('Delete post?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AidColors.error)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await db.collection('posts').doc(doc.id).delete();
      }
    } else if (action == 'fulfill') {
      await db.collection('posts').doc(doc.id).update({'status': 'fulfilled'});
    } else if (action == 'edit') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit: coming soon — tap Post Need to create a new one')),
        );
      }
    }
  }
}

// ── Activities Tab ─────────────────────────────────────────────────────────────
// Internal activities for residents: walks, workshops, medical camps etc.

class _ActivitiesTab extends StatefulWidget {
  final String uid;
  const _ActivitiesTab({required this.uid});

  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  static const _purple = AidColors.ngoAccent;

  void _showAddActivitySheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    DateTime? picked;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
              const Gap(16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Activity Name', hintText: 'e.g. Morning Yoga, Medical Camp'),
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
              ),
              const Gap(12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description (optional)', hintText: 'Details about the activity…'),
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
              ),
              const Gap(12),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    picked = d;
                    dateCtrl.text = DateFormat('EEE, d MMM yyyy').format(d);
                    setS(() {});
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'Tap to pick a date',
                  suffixIcon: Icon(Icons.calendar_month_rounded, size: 18),
                ),
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
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
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Activity', style: TextStyle(fontWeight: FontWeight.w700)),
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
              .collection('users')
              .doc(widget.uid)
              .collection('activities')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return _emptyState(
                '📅',
                'No activities yet',
                'Schedule walks, workshops, medical camps and more for your residents.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (_, i) => _ActivityCard(
                doc: docs[i],
                careHomeUid: widget.uid,
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addActivity',
            onPressed: _showAddActivitySheet,
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String careHomeUid;
  const _ActivityCard({required this.doc, required this.careHomeUid});

  static const _purple = AidColors.ngoAccent;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : null;
    final status = data['status'] ?? 'upcoming';
    final isPast = date != null && date.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPast ? AidColors.borderDefault : _purple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isPast
                  ? AidColors.elevated
                  : _purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  date != null ? DateFormat('MMM').format(date) : '—',
                  style: TextStyle(
                    color: isPast ? AidColors.textMuted : _purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date != null ? DateFormat('d').format(date) : '?',
                  style: TextStyle(
                    color: isPast ? AidColors.textMuted : _purple,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
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
                  const Gap(3),
                  Text(data['description'], style: AidTextStyles.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          // Status + actions
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPast ? AidColors.textMuted : _purple).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPast ? 'DONE' : 'UPCOMING',
                  style: AidTextStyles.labelSm.copyWith(
                    color: isPast ? AidColors.textMuted : _purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AidColors.error),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(careHomeUid)
                      .collection('activities')
                      .doc(doc.id)
                      .delete();
                },
                style: IconButton.styleFrom(
                  backgroundColor: AidColors.error.withValues(alpha: 0.08),
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donations Tab ─────────────────────────────────────────────────────────────

class _DonationsTab extends StatelessWidget {
  final String uid;
  const _DonationsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    // Fetch all donations received across all posts made by this care home
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('ngoId', isEqualTo: uid)
          .snapshots(),
      builder: (context, postsSnap) {
        final postIds = postsSnap.data?.docs.map((d) => d.id).toList() ?? [];
        if (postIds.isEmpty) {
          return _emptyState('💝', 'No donations yet', 'Donations from donors will appear here once you post your needs.');
        }
        // Show donations across all posts (up to first 10 posts for now)
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(postIds.first)
              .collection('donations')
              .orderBy('donatedAt', descending: true)
              .snapshots(),
          builder: (context, donSnap) {
            final docs = donSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return _emptyState('💝', 'No donations yet', 'Donations from donors will appear here.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final name = d['donorName'] ?? 'Anonymous';
                final items = (d['donatedItems'] as List<dynamic>? ?? []);
                final money = (d['monetaryAmount'] ?? 0).toDouble();
                final status = d['status'] ?? 'pending';
                final statusColor = status == 'accepted'
                    ? AidColors.ngoAccent
                    : status == 'rejected'
                        ? AidColors.error
                        : AidColors.warning;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AidColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AidColors.ngoAccent.withValues(alpha: 0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AidColors.ngoAccent, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AidTextStyles.headingSm),
                            if (money > 0)
                              Text('₹${money.toInt()} monetary', style: AidTextStyles.bodySm.copyWith(color: AidColors.ngoAccent)),
                            if (items.isNotEmpty)
                              ...items.map((it) {
                                final m = it as Map<String, dynamic>;
                                return Text(
                                  '${m['quantity']?.toInt()} ${m['unit']} of ${m['name']}',
                                  style: AidTextStyles.bodySm,
                                );
                              }),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: AidTextStyles.labelSm.copyWith(
                                color: statusColor, fontWeight: FontWeight.w800, fontSize: 9,
                              ),
                            ),
                          ),
                          const Gap(4),
                          // Accept / Reject
                          if (status == 'pending')
                            Row(
                              children: [
                                _actionBtn(Icons.check_rounded, AidColors.ngoAccent, () async {
                                  await docs[i].reference.update({'status': 'accepted'});
                                }),
                                const Gap(4),
                                _actionBtn(Icons.close_rounded, AidColors.error, () async {
                                  await docs[i].reference.update({'status': 'rejected'});
                                }),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _emptyState(String emoji, String title, String sub) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const Gap(16),
          Text(title, style: AidTextStyles.headingMd, textAlign: TextAlign.center),
          const Gap(8),
          Text(sub, style: AidTextStyles.bodySm, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
