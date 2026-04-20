import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'featured_cause_screen.dart';
import 'impact_group_screen.dart';
import '../../models/impact_group.dart';
import '../common/welfare_resources_screen.dart';
import '../common/contact_us_screen.dart';
import '../common/theme_control_panel.dart';
import '../../models/resident.dart';
import 'resident_detail_screen.dart';
import 'donor_impact_screen.dart';
import 'resident_browse_screen.dart';

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
      const DonorImpactScreen(),
      const DonorGroupsScreen(),
      const _DonorMoreTab(),
    ];

    return Scaffold(
      backgroundColor: AidColors.donorBackground,
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
                icon: Icon(Icons.auto_graph_outlined),
                selectedIcon: Icon(Icons.auto_graph_rounded),
                label: 'My Impact',
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
    'All', 'food', 'medical', 'clothes', 'education', 'funds',
    'old age home', 'disaster relief', 'environment', 'women', 'children', 'animals', 'shelter',
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
                    aidRoute(const SearchScreen()),
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
      backgroundColor: AidColors.donorBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('More', style: AidTextStyles.displaySm),
              const Gap(24),
              _Tile(
                icon: Icons.auto_graph_rounded,
                title: 'My Impact',
                subtitle: 'Your giving history, score & sponsored residents',
                color: AidColors.donorAccent,
                onTap: () => Navigator.push(context,
                    aidRoute(const DonorImpactScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.elderly_rounded,
                title: 'Browse Residents',
                subtitle: 'Find people who need your help',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(context,
                    aidRoute(const ResidentBrowseScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.search_rounded,
                title: 'Search',
                subtitle: 'Find NGOs, posts and events',
                color: AidColors.ngoAccent,
                onTap: () => Navigator.push(context,
                    aidRoute(const SearchScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'View your alerts',
                color: AidColors.warning,
                onTap: () => Navigator.push(context,
                    aidRoute(const NotificationsScreen())),
                badgeStream: NotificationService.unreadCount(uid),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                subtitle: 'View and edit your profile',
                color: AidColors.donorAccent,
                onTap: () => Navigator.push(context,
                    aidRoute(const ProfileScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Account, notifications, privacy',
                color: AidColors.textSecondary,
                onTap: () => Navigator.push(context,
                    aidRoute(const SettingsScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.library_books_rounded,
                title: 'Welfare Resources',
                subtitle: 'Hospitals, blood banks, govt schemes & more',
                color: AidColors.ngoAccent,
                onTap: () => Navigator.push(context,
                    aidRoute(const WelfareResourcesScreen())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.palette_outlined,
                title: 'Customise App',
                subtitle: 'Change colours, background, style',
                color: AidColors.donorAccent,
                onTap: () => Navigator.push(context,
                    aidRoute(const ThemeControlPanel())),
              ),
              const Gap(10),
              _Tile(
                icon: Icons.contact_support_outlined,
                title: 'Contact Us',
                subtitle: 'Get in touch, onboard your NGO',
                color: AidColors.donorAccent,
                onTap: () => Navigator.push(context,
                    aidRoute(const ContactUsScreen())),
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
    // No orderBy — avoids silently dropping posts without createdAt field.
    // Sort client-side instead. All active posts always show.
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        // ── Client-side filter + sort ──────────────────────────────
        final allDocs = snap.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          // Show active OR any post without a status (legacy data)
          final status = data['status'] as String?;
          if (status != null && status != 'active') return false;
          if (filterCategory != 'All' &&
              (data['category'] as String?) != filterCategory) return false;
          return true;
        }).toList();

        // Sort newest first client-side
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['createdAt'];
          final bTs = bData['createdAt'];
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return (bTs as dynamic).compareTo(aTs as dynamic);
        });

        return CustomScrollView(
          slivers: [
            // ── Platform Impact Stats ────────────────────────────────
            const SliverToBoxAdapter(child: _ImpactStatsCard()),
            // ── Services Grid ────────────────────────────────────────
            SliverToBoxAdapter(child: _ServicesGrid(onCategoryTap: onFilterChanged)),
            // ── Welfare Resource Directory ───────────────────────────
            const SliverToBoxAdapter(child: WelfareResourcesPreview()),
            // ── See → Feel → Act Impact Groups ──────────────────────
            const SliverToBoxAdapter(child: _ImpactGroupsRow()),
            // ── Partner NGOs (Manasa first + others) ─────────────────
            const SliverToBoxAdapter(child: _PartnerNgosRow()),
            const SliverToBoxAdapter(child: _ResidentProfilesRow()),

            // ── Browse Residents CTA ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ResidentBrowseScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withValues(alpha: 0.9),
                          const Color(0xFF2E7D32),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.elderly_rounded,
                            color: Colors.white, size: 28),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Browse Residents',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                'Find people in care homes who need your direct support',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Category filter chips (sticky) ───────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyChipsDelegate(
                categories: categories,
                selected: filterCategory,
                onTap: onFilterChanged,
              ),
            ),

            // ── Posts ────────────────────────────────────────────────
            if (snap.connectionState == ConnectionState.waiting && docs.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AidColors.donorAccent)),
              )
            else if (snap.hasError)
              SliverFillRemaining(
                child: _EmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'Could not load posts',
                  sub: snap.error.toString(),
                ),
              )
            else if (docs.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  icon: Icons.volunteer_activism_outlined,
                  message: 'No posts yet',
                  sub: filterCategory == 'All'
                      ? 'NGOs haven\'t posted yet — check back soon!'
                      : 'No $filterCategory posts right now.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _DonorPostCard(post: NgoPost.fromFirestore(docs[i])),
                    ),
                    childCount: docs.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Sticky category chips delegate ──────────────────────────────────────────

class _StickyChipsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final void Function(String) onTap;

  const _StickyChipsDelegate({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  @override double get minExtent => 52;
  @override double get maxExtent => 52;

  @override
  bool shouldRebuild(_StickyChipsDelegate old) =>
      old.selected != selected || old.categories != categories;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AidColors.background,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (_, i) {
          final c = categories[i];
          final isSelected = selected == c;
          return GestureDetector(
            onTap: () => onTap(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AidColors.donorAccent : AidColors.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: isSelected ? AidColors.donorAccent : AidColors.borderDefault),
              ),
              child: Text(
                c[0].toUpperCase() + c.substring(1),
                style: AidTextStyles.labelMd.copyWith(
                  color: isSelected ? Colors.white : AidColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
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
        aidRoute(DonationDetailScreen(post: post)),
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

                  // Raised progress circle
                  const Gap(12),
                  _RaisedProgress(post: post),

                  // Item progress bars
                  if (post.requiredItems.isNotEmpty) ...[
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
                          aidRoute(DonationDetailScreen(post: post)),
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

// ─── Partner NGOs Row ─────────────────────────────────────────────────────────

class _PartnerNgosRow extends StatelessWidget {
  const _PartnerNgosRow();

  static const _ngos = [
    {
      'name': 'Manasa Medical Trust',
      'desc': 'Old age home & medical welfare',
      'location': 'Bangalore',
      'url': 'https://www.manasamedicaltrust.org',
      'color': 0xFF9B4189,
      'icon': Icons.elderly_rounded,
      'featured': true,
    },
    {
      'name': 'HelpAge India',
      'desc': 'Empowering older persons since 1978',
      'location': 'Pan India',
      'url': 'https://www.helpageindia.org',
      'color': 0xFF9B4189,
      'icon': Icons.favorite_rounded,
      'featured': false,
    },
    {
      'name': 'CRY India',
      'desc': 'Child Rights and You',
      'location': 'Pan India',
      'url': 'https://www.cry.org',
      'color': 0xFFFF5722,
      'icon': Icons.child_care_rounded,
      'featured': false,
    },
    {
      'name': 'Goonj',
      'desc': 'Urban to rural resource transfer',
      'location': 'Delhi',
      'url': 'https://goonj.org',
      'color': 0xFFFF9800,
      'icon': Icons.volunteer_activism_rounded,
      'featured': false,
    },
    {
      'name': 'Akshaya Patra',
      'desc': 'Mid-day meal programme for children',
      'location': 'Pan India',
      'url': 'https://www.akshayapatra.org',
      'color': 0xFF9B4189,
      'icon': Icons.restaurant_rounded,
      'featured': false,
    },
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text('Partner Organisations', style: AidTextStyles.headingMd),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _ngos.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (_, i) {
              final n = _ngos[i];
              final color = Color(n['color'] as int);
              final icon  = n['icon'] as IconData;
              final isFeatured = n['featured'] as bool;
              return GestureDetector(
                onTap: () => _open(n['url'] as String),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 10, offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: Colors.white, size: 16),
                          ),
                          const Spacer(),
                          if (isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('FEATURED',
                                  style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(n['name'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.2)),
                      const Gap(3),
                      Text(n['desc'] as String,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Gap(2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.6), size: 10),
                          const Gap(2),
                          Text(n['location'] as String,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
                          const Spacer(),
                          Icon(Icons.open_in_new_rounded, color: Colors.white.withValues(alpha: 0.6), size: 11),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Gap(4),
      ],
    );
  }
}

// ─── Platform Impact Stats Card ───────────────────────────────────────────────

class _ImpactStatsCard extends StatelessWidget {
  const _ImpactStatsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, postsSnap) {
        final posts = postsSnap.data?.docs ?? [];

        // Aggregate totals across all active posts
        double totalFulfilled = 0;
        int activeCauses = posts.length;
        int volunteerEvents = 0;

        for (final doc in posts) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['type'] == 'activity') volunteerEvents++;
          final items = data['requiredItems'] as List<dynamic>? ?? [];
          for (final item in items) {
            final m = item as Map<String, dynamic>;
            totalFulfilled += (m['fulfilledQty'] ?? 0).toDouble();
          }
        }

        // Use posts.length as proxy for donations count (no collectionGroup needed)
        final totalDonations = posts.fold<int>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + ((data['donationCount'] ?? 0) as num).toInt();
        });

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AidColors.donorAccent.withValues(alpha: 0.15),
                    AidColors.ngoAccent.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AidColors.donorAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AidColors.donorAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🌍  PLATFORM IMPACT',
                          style: AidTextStyles.labelSm.copyWith(
                            color: AidColors.donorAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Text(
                    'Together, we\'re making a difference',
                    style: AidTextStyles.headingMd,
                  ),
                  const Gap(2),
                  Text(
                    'Live numbers across all causes on AidBridge',
                    style: AidTextStyles.bodySm,
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      _stat('$activeCauses', 'Active\nCauses', AidColors.donorAccent),
                      _divider(),
                      _stat('$totalDonations', 'Donations\nMade', AidColors.ngoAccent),
                      _divider(),
                      _stat(_fmtQty(totalFulfilled), 'Items\nCollected', AidColors.volunteerAccent),
                      _divider(),
                      _stat('$volunteerEvents', 'Volunteer\nEvents', AidColors.donorAccent),
                    ],
                  ),
                ],
              ),
            );
      },
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const Gap(4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AidTextStyles.labelSm.copyWith(color: AidColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 36,
    color: AidColors.borderDefault,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  String _fmtQty(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toInt().toString();
  }
}

// ─── Impact Groups Row ────────────────────────────────────────────────────────

class _ImpactGroupsRow extends StatelessWidget {
  const _ImpactGroupsRow();

  static const _typeColors = {
    'children': Color(0xFFFF9800),
    'elderly':  AidColors.donorAccent,
    'women':    AidColors.donorAccent,
    'general':  AidColors.donorAccent,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('impactGroups')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final groups = docs.map((d) => ImpactGroup.fromFirestore(d)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Text('See · Feel · Act', style: AidTextStyles.headingMd),
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AidColors.donorAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('LIVE', style: AidTextStyles.labelSm.copyWith(
                      color: AidColors.donorAccent, fontWeight: FontWeight.w800, fontSize: 9,
                    )),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (_, i) => _ImpactGroupCard(group: groups[i]),
              ),
            ),
            const Gap(6),
          ],
        );
      },
    );
  }
}

class _ImpactGroupCard extends StatelessWidget {
  final ImpactGroup group;
  const _ImpactGroupCard({required this.group});

  Color get _color {
    switch (group.type) {
      case ImpactGroupType.children: return const Color(0xFFFF9800);
      case ImpactGroupType.elderly:  return AidColors.donorAccent;
      case ImpactGroupType.women:    return AidColors.donorAccent;
      case ImpactGroupType.general:  return AidColors.ngoAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          aidRoute(ImpactGroupScreen(group: group))),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: AidColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or color hero
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: group.imageUrls.isNotEmpty
                    ? Image.network(group.imageUrls.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _colorHero())
                    : _colorHero(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${group.type.emoji} ${group.type.label}',
                      style: AidTextStyles.labelSm.copyWith(
                        color: _color, fontWeight: FontWeight.w700, fontSize: 9,
                      ),
                    ),
                  ),
                  const Gap(5),
                  Text(
                    group.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AidTextStyles.headingSm.copyWith(fontSize: 12, height: 1.3),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Icon(Icons.people_rounded, size: 11, color: _color),
                      const Gap(3),
                      Text('${group.beneficiaryCount} people',
                          style: AidTextStyles.labelSm.copyWith(color: _color, fontSize: 10)),
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

  Widget _colorHero() => Container(
    color: _color.withValues(alpha: 0.15),
    child: Center(child: Text(group.type.emoji, style: const TextStyle(fontSize: 40))),
  );
}

// ─── Services Grid ────────────────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  final void Function(String) onCategoryTap;
  const _ServicesGrid({required this.onCategoryTap});

  static const _services = [
    {'icon': Icons.restaurant_rounded,     'label': 'Food',        'cat': 'food',           'color': 0xFFFF9800},
    {'icon': Icons.local_hospital_rounded, 'label': 'Medical',     'cat': 'medical',         'color': 0xFF9B4189},
    {'icon': Icons.checkroom_rounded,      'label': 'Clothes',     'cat': 'clothes',         'color': 0xFF9B4189},
    {'icon': Icons.menu_book_rounded,      'label': 'Education',   'cat': 'education',       'color': 0xFF9C27B0},
    {'icon': Icons.elderly_rounded,        'label': 'Old Age',     'cat': 'old age home',    'color': 0xFF9B4189},
    {'icon': Icons.crisis_alert_rounded,   'label': 'Disaster',    'cat': 'disaster relief', 'color': 0xFF00BCD4},
    {'icon': Icons.child_care_rounded,     'label': 'Children',    'cat': 'children',        'color': 0xFFFF5722},
    {'icon': Icons.eco_rounded,            'label': 'Environment', 'cat': 'environment',     'color': 0xFF4CAF50},
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final itemW = (w - 32 - 21) / 4; // 4 per row, 16px padding each side, 3×7px gaps

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Text('Causes', style: AidTextStyles.headingMd),
              const Spacer(),
              GestureDetector(
                onTap: () => onCategoryTap('All'),
                child: Text('See all',
                    style: AidTextStyles.labelMd.copyWith(color: AidColors.donorAccent)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.05,
            ),
            itemCount: _services.length,
            itemBuilder: (_, i) {
              final s = _services[i];
              final color = Color(s['color'] as int);
              final icon  = s['icon'] as IconData;
              return GestureDetector(
                onTap: () => onCategoryTap(s['cat'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 24),
                      const Gap(5),
                      Text(
                        s['label'] as String,
                        style: AidTextStyles.labelSm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Gap(8),
      ],
    );
  }
}

// ─── Circular Raised Progress ────────────────────────────────────────────────

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _CirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2 - 3;

    // Track
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.5707963, // -π/2 (start at top)
      progress * 6.2831853, // full circle = 2π
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress;
}

class _RaisedProgress extends StatelessWidget {
  final NgoPost post;
  const _RaisedProgress({required this.post});

  @override
  Widget build(BuildContext context) {
    // Activity → volunteer count
    if (post.type == PostType.activity && post.eventDetails != null) {
      final ed = post.eventDetails!;
      final pct = ed.volunteersNeeded > 0
          ? (ed.volunteersJoined / ed.volunteersNeeded).clamp(0.0, 1.0)
          : 0.0;
      return _buildRow(
        pct: pct,
        mainLabel: '${ed.volunteersJoined} / ${ed.volunteersNeeded} volunteers',
        subLabel: 'joined',
        color: AidColors.volunteerAccent,
      );
    }

    // Monetary target → show raised %
    if (post.targetAmount > 0) {
      final pct = (post.raisedAmount / post.targetAmount).clamp(0.0, 1.0);
      return _buildRow(
        pct: pct,
        mainLabel: '₹${_fmt(post.raisedAmount)} raised',
        subLabel: 'of ₹${_fmt(post.targetAmount)} goal',
        color: AidColors.donorAccent,
      );
    }

    // Item-based drives → aggregate across all items
    if (post.requiredItems.isNotEmpty) {
      double fulfilled = post.requiredItems.fold(0, (s, i) => s + i.fulfilledQty);
      double target    = post.requiredItems.fold(0, (s, i) => s + i.targetQty);
      final pct = target > 0 ? (fulfilled / target).clamp(0.0, 1.0) : 0.0;
      return _buildRow(
        pct: pct,
        mainLabel: '${fulfilled.toInt()} / ${target.toInt()} items',
        subLabel: 'collected',
        color: AidColors.ngoAccent,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRow({
    required double pct,
    required String mainLabel,
    required String subLabel,
    required Color color,
  }) {
    final pctInt = (pct * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Circle progress
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(48, 48),
                  painter: _CirclePainter(progress: pct, color: color),
                ),
                Text(
                  '$pctInt%',
                  style: TextStyle(
                    color: color, fontSize: 11,
                    fontWeight: FontWeight.w800, height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mainLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(subLabel, style: const TextStyle(color: AidColors.textMuted, fontSize: 11)),
            ],
          ),
          const Spacer(),
          if (pct >= 1.0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AidColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'GOAL MET',
                style: TextStyle(color: AidColors.success, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
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

// ─── Resident Profiles Row (donor feed) ────────────────────────────────────────

class _ResidentProfilesRow extends StatelessWidget {
  const _ResidentProfilesRow();

  static const _urgencyColors = {
    'normal':   Color(0xFF2B8CE6),
    'urgent':   Color(0xFFF0A500),
    'critical': Color(0xFFE8514A),
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('residents')
          .where('isActive', isEqualTo: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        final residents = (snap.data?.docs ?? [])
            .map((d) => Resident.fromDoc(d))
            .toList();
        if (residents.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Text('People Who Need You',
                  style: AidTextStyles.headingMd),
                const Spacer(),
                Text('${residents.length} profiles',
                  style: AidTextStyles.caption.copyWith(
                      color: AidColors.textMuted)),
              ]),
            ),
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: residents.length,
                itemBuilder: (_, i) {
                  final r = residents[i];
                  final urgencyColor =
                      _urgencyColors[r.urgency] ?? const Color(0xFF2B8CE6);
                  return GestureDetector(
                    onTap: () => Navigator.push(context, aidRoute(
                        ResidentDetailScreen(resident: r))),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
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
                            child: Stack(
                              children: [
                                r.photoUrl.isNotEmpty
                                    ? Image.network(r.photoUrl,
                                        height: 110, width: 140,
                                        fit: BoxFit.cover)
                                    : Container(
                                        height: 110, width: 140,
                                        color: AidColors.elevated,
                                        child: const Icon(Icons.person_rounded,
                                            size: 40,
                                            color: AidColors.textMuted)),
                                // Urgency dot
                                Positioned(top: 8, right: 8,
                                  child: Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(
                                      color: urgencyColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5)),
                                  )),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                  style: AidTextStyles.labelMd,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                                const Gap(2),
                                Text('${r.age} yrs · ${r.careHomeName}',
                                  style: AidTextStyles.caption.copyWith(
                                      color: AidColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                                const Gap(6),
                                if (r.needs.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AidColors.donorAccent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(r.needs.first,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AidColors.donorAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(8),
          ],
        );
      },
    );
  }
}
