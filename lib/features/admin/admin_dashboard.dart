import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_verification.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'verification_queue_screen.dart';
import 'user_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final _pages = const [
    _OverviewTab(),
    VerificationQueueScreen(),
    UserManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Verify NGOs',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Panel', style: AidTextStyles.displaySm),
                  Text('AidBridge Platform', style: AidTextStyles.bodySm),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: AidColors.error,
                onPressed: () => AuthService.instance.signOut(),
              ),
            ],
          ),
          const Gap(28),

          // Platform stats
          FutureBuilder<Map<String, int>>(
            future: UserService.platformUserStats(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = snap.data!;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Users',
                          value: '${stats['total']}',
                          icon: Icons.people_rounded,
                          color: AidColors.info,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _StatCard(
                          label: 'Donors',
                          value: '${stats['donors']}',
                          icon: Icons.favorite_rounded,
                          color: AidColors.donorAccent,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Volunteers',
                          value: '${stats['volunteers']}',
                          icon: Icons.volunteer_activism_rounded,
                          color: AidColors.volunteerAccent,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _StatCard(
                          label: 'NGOs',
                          value: '${stats['ngos']}',
                          icon: Icons.business_rounded,
                          color: AidColors.ngoAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Gap(28),

          Text('Pending Verifications', style: AidTextStyles.headingMd),
          const Gap(12),
          _PendingVerificationsWidget(),

          const Gap(28),
          Text('Recent Activity', style: AidTextStyles.headingMd),
          const Gap(12),
          _RecentUsersWidget(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Text(value, style: AidTextStyles.displaySm.copyWith(fontSize: 28)),
          const Gap(4),
          Text(label, style: AidTextStyles.bodySm),
        ],
      ),
    );
  }
}

class _PendingVerificationsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verifications')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AidColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AidColors.success, size: 20),
                const Gap(12),
                Text('No pending verifications', style: AidTextStyles.bodyMd),
              ],
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _VerificationTile(
              orgName: data['orgName'] ?? 'Unknown',
              regNumber: data['regNumber'] ?? '',
              verificationId: doc.id,
              ngoId: data['ngoId'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final String orgName;
  final String regNumber;
  final String verificationId;
  final String ngoId;

  const _VerificationTile({
    required this.orgName,
    required this.regNumber,
    required this.verificationId,
    required this.ngoId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AidColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pending_outlined, color: AidColors.warning, size: 18),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orgName, style: AidTextStyles.headingSm),
                Text('Reg: $regNumber', style: AidTextStyles.bodySm),
              ],
            ),
          ),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.check_rounded,
                color: AidColors.success,
                onTap: () => _approve(context),
              ),
              const Gap(6),
              _ActionBtn(
                icon: Icons.close_rounded,
                color: AidColors.error,
                onTap: () => _reject(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    await VerificationService.updateVerification(
      verificationId,
      VerificationStatus.approved,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$orgName approved!'),
          backgroundColor: AidColors.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject NGO?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add a reason for rejection (optional):',
                style: AidTextStyles.bodySm),
            const Gap(12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(hintText: 'Reason...'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AidColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await VerificationService.updateVerification(
        verificationId,
        VerificationStatus.rejected,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _RecentUsersWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        return Container(
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AidColors.borderSubtle),
          ),
          child: Column(
            children: docs.asMap().entries.map((entry) {
              final data = entry.value.data() as Map<String, dynamic>;
              final role = data['role'] ?? 'user';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                  child: Text(
                    (data['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                    style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(data['name'] ?? 'Unknown', style: AidTextStyles.headingSm),
                subtitle: Text(role.toUpperCase(), style: AidTextStyles.bodySm),
                trailing: Text(
                  data['email'] ?? '',
                  style: AidTextStyles.labelSm,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
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
