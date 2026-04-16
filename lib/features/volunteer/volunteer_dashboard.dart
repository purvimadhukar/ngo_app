import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../common/notifications_screen.dart';
import '../common/search_screen.dart';
import '../common/profile_screen.dart';
import '../common/settings_screen.dart';
import 'volunteer_home.dart';
import 'volunteer_events_screen.dart';
import 'rewards_screen.dart';
import 'invite_screen.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    VolunteerHome(),
    VolunteerEventsScreen(),
    RewardsScreen(),
    _MoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AidColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: StreamBuilder<int>(
        stream: NotificationService.unreadCount(uid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Events',
              ),
              const NavigationDestination(
                icon: Icon(Icons.star_outline_rounded),
                selectedIcon: Icon(Icons.star_rounded),
                label: 'Rewards',
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

class _MoreTab extends StatelessWidget {
  const _MoreTab();

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
              _MenuTile(
                icon: Icons.search_rounded,
                title: 'Search',
                subtitle: 'Find NGOs, posts and events',
                color: AidColors.ngoAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              const Gap(10),
              _MenuTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'View your alerts',
                color: AidColors.warning,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                badgeStream: NotificationService.unreadCount(uid),
              ),
              const Gap(10),
              _MenuTile(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                subtitle: 'View and edit your profile',
                color: AidColors.volunteerAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              const Gap(10),
              _MenuTile(
                icon: Icons.share_rounded,
                title: 'Invite Friends',
                subtitle: 'Earn reward points for inviting',
                color: AidColors.donorAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InviteScreen())),
              ),
              const Gap(10),
              _MenuTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Account, notifications, privacy',
                color: AidColors.textSecondary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              const Gap(10),
              _MenuTile(
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Stream<int>? badgeStream;

  const _MenuTile({
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
                  if (count == 0) return const Icon(Icons.chevron_right_rounded, color: AidColors.textSecondary);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AidColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AidColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
