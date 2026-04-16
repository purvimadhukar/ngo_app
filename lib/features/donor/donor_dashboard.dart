import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../common/notifications_screen.dart';
import '../common/search_screen.dart';
import '../common/profile_screen.dart';
import '../common/settings_screen.dart';
import 'donation_detail_screen.dart';
import 'donation_history_screen.dart';
import 'donor_groups_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';

    final pages = [
      const _FeedPage(),
      const DonationHistoryScreen(),
      const DonorGroupsScreen(),
      const _DonorMoreTab(),
    ];

    return Scaffold(
      backgroundColor: AidColors.background,
      body: pages[_selectedIndex],
      bottomNavigationBar: StreamBuilder<int>(
        stream: NotificationService.unreadCount(uid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism),
                label: 'Donate',
              ),
              const NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.menu_outlined),
                ),
                selectedIcon: const Icon(Icons.menu),
                label: 'More',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Feed Page (wraps original feed tab + my donations) ──────────────────────

class _FeedPage extends StatefulWidget {
  const _FeedPage();

  @override
  State<_FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<_FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _filterCategory = 'All';

  static const _categories = [
    'All', 'food', 'clothes', 'medical', 'education', 'funds', 'other'
  ];

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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AidBridge',
                      style: AidTextStyles.caption.copyWith(
                        color: AidColors.donorAccent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text('Donor Portal',
                        style: AidTextStyles.heading.copyWith(fontSize: 22)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: AidColors.textMuted, size: 22),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                  color: AidColors.surface,
                  borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                    color: AidColors.donorAccent,
                    borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AidColors.textMuted,
                tabs: const [Tab(text: 'Donate'), Tab(text: 'My Donations')],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _FeedTab(
                  filterCategory: _filterCategory,
                  onFilterChanged: (c) => setState(() => _filterCategory = c),
                  categories: _categories,
                ),
                const _MyDonationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── More Tab ─────────────────────────────────────────────────────────────────

class _DonorMoreTab extends StatelessWidget {
  const _DonorMoreTab();

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AidColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('More', style: AidTextStyles.displaySm),
              const Gap(24),
              _Tile(
                icon: Icons.search_rounded,
                title: 'Search',
                subtitle: 'Find NGOs, posts and events',
                color: AidColors.ngoAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'View your alerts',
                color: AidColors.warning,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                badgeStream: NotificationService.unreadCount(uid),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                subtitle: 'View and edit your profile',
                color: AidColors.donorAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Account, notifications, privacy',
                color: AidColors.textSecondary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: '',
                color: AidColors.error,
                onTap: () => AuthService.instance.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Stream<int>? badgeStream;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeStream,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AidTextStyles.headingSm),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: AidTextStyles.bodySm),
                ],
              ),
            ),
            if (badgeStream != null)
              StreamBuilder<int>(
                stream: badgeStream,
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  if (count == 0) {
                    return const Icon(Icons.chevron_right_rounded,
                        color: AidColors.textSecondary);
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AidColors.error,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  );
                },
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AidColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Feed Tab ─────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final String filterCategory;
  final void Function(String) onFilterChanged;
  final List<String> categories;

  const _FeedTab({
    required this.filterCategory,
    required this.onFilterChanged,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('status', isEqualTo: 'active')
        .where('flaggedForReview', isEqualTo: false)
        .orderBy('urgencyScore', descending: true);

    if (filterCategory != 'All') {
      query = query.where('category', isEqualTo: filterCategory);
    }

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (_, i) {
              final c = categories[i];
              final selected = filterCategory == c;
              return GestureDetector(
                onTap: () => onFilterChanged(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AidColors.donorAccent : AidColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: selected ? AidColors.donorAccent : AidColors.borderDefault),
                  ),
                  child: Text(
                    c[0].toUpperCase() + c.substring(1),
                    style: AidTextStyles.labelMd.copyWith(
                      color: selected ? Colors.white : AidColors.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AidColors.donorAccent));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return _EmptyState(
                  icon: Icons.volunteer_activism_outlined,
                  message: 'No posts right now',
                  sub: filterCategory == 'All'
                      ? 'Verified NGOs haven\'t posted yet. Check back soon!'
                      : 'No $filterCategory requests. Try a different category.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Gap(14),
                itemBuilder: (_, i) => _DonorPostCard(post: NgoPost.fromFirestore(docs[i])),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Donor Post Card ──────────────────────────────────────────────────────────

class _DonorPostCard extends StatelessWidget {
  final NgoPost post;
  const _DonorPostCard({required this.post});

  Color get _urgencyColor {
    if (post.urgencyScore >= 0.8) return AidColors.error;
    if (post.urgencyScore >= 0.5) return AidColors.warning;
    return AidColors.success;
  }

  String get _urgencyLabel {
    if (post.urgencyScore >= 0.8) return 'URGENT';
    if (post.urgencyScore >= 0.5) return 'MODERATE';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DonationDetailScreen(post: post)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AidColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media carousel
            if (post.mediaUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 190,
                  child: PageView.builder(
                    itemCount: post.mediaUrls.length,
                    itemBuilder: (_, i) => Image.network(
                      post.mediaUrls[i],
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(color: AidColors.elevated, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(color: AidColors.elevated, child: const Icon(Icons.broken_image_outlined, color: AidColors.textMuted)),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AidColors.donorAccent.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(child: Icon(Icons.volunteer_activism_outlined, color: AidColors.donorAccent, size: 36)),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NGO + urgency
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                      const Gap(4),
                      Expanded(
                        child: Text(
                          post.ngoName,
                          style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _urgencyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _urgencyLabel,
                          style: AidTextStyles.labelSm.copyWith(color: _urgencyColor, fontWeight: FontWeight.w800, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(post.title, style: AidTextStyles.headingMd),
                  const Gap(4),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
                  ),

                  // Item progress bars
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
                                  Text('${item.fulfilledQty.toInt()}/${item.targetQty.toInt()}', style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
                                ],
                              ),
                              const Gap(4),
                              LinearProgressIndicator(
                                value: item.progressPercent,
                                minHeight: 5,
                                borderRadius: BorderRadius.circular(3),
                                color: AidColors.donorAccent,
                                backgroundColor: AidColors.elevated,
                              ),
                            ],
                          ),
                        )),
                    if (post.requiredItems.length > 2)
                      Text('+${post.requiredItems.length - 2} more', style: AidTextStyles.labelSm),
                  ],

                  const Gap(12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AidColors.elevated, borderRadius: BorderRadius.circular(99)),
                        child: Text(post.category, style: AidTextStyles.labelMd),
                      ),
                      const Gap(8),
                      // Share button
                      IconButton(
                        onPressed: () {
                          final shareText = '🤝 Help needed: ${post.title}\n'
                              'By ${post.ngoName}\n\n'
                              '${post.description}\n\n'
                              'Join AidBridge to donate or volunteer!';
                          Clipboard.setData(ClipboardData(text: shareText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share text copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        color: AidColors.textMuted,
                        style: IconButton.styleFrom(
                          backgroundColor: AidColors.elevated,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DonationDetailScreen(post: post)),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AidColors.donorAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: AidTextStyles.labelMd,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        ),
                        child: const Text('Donate now'),
                      ),
                    ],
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

// ─── My Donations Tab ─────────────────────────────────────────────────────────

class _MyDonationsTab extends StatelessWidget {
  const _MyDonationsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('donations')
          .where('donorId', isEqualTo: uid)
          .orderBy('donatedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AidColors.donorAccent));
        }
        if (snap.hasError) {
          return _EmptyState(
            icon: Icons.history_rounded,
            message: 'Donation history',
            sub: 'Your past donations will appear here.',
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyState(
            icon: Icons.favorite_outline_rounded,
            message: 'No donations yet',
            sub: 'Your donation history will appear here after your first contribution.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final hasItem = (d['item'] as String?)?.isNotEmpty == true;
            final status = d['status'] ?? 'pending';
            final statusColor = status == 'accepted'
                ? AidColors.success
                : status == 'rejected'
                    ? AidColors.error
                    : AidColors.warning;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AidColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AidColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: AidColors.donorAccent.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_rounded, color: AidColors.donorAccent, size: 22),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hasItem ? d['item'] : '₹${(d['amount'] ?? 0).toStringAsFixed(0)}', style: AidTextStyles.headingSm),
                        Text(d['donorEmail'] ?? '', style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      status.toUpperCase(),
                      style: AidTextStyles.labelSm.copyWith(color: statusColor, fontWeight: FontWeight.w800, fontSize: 9),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message, sub;
  const _EmptyState({required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AidColors.textMuted.withValues(alpha: 0.4)),
            const Gap(16),
            Text(message, style: AidTextStyles.headingMd, textAlign: TextAlign.center),
            const Gap(8),
            Text(sub, style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
