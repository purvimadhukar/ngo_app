import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';

class RequestHistory extends StatelessWidget {
  const RequestHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        elevation: 0,
        title: Text(
          'Request History',
          style: AidTextStyles.heading.copyWith(fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AidColors.textPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('postedBy', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color: AidColors.textMuted.withValues(alpha: 0.4)),
                  const Gap(16),
                  Text('No requests yet',
                      style: AidTextStyles.body.copyWith(color: AidColors.textMuted)),
                  const Gap(8),
                  Text('Your posted requests will appear here',
                      style: AidTextStyles.caption
                          .copyWith(color: AidColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _RequestHistoryCard(
                docId: docs[index].id,
                title: data['title'] ?? 'Untitled',
                description: data['description'] ?? '',
                category: data['category'] ?? '',
                volunteersNeeded: data['volunteersNeeded'] ?? 0,
                status: data['status'] ?? 'open',
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestHistoryCard extends StatelessWidget {
  final String docId;
  final String title;
  final String description;
  final String category;
  final int volunteersNeeded;
  final String status;

  const _RequestHistoryCard({
    required this.docId,
    required this.title,
    required this.description,
    required this.category,
    required this.volunteersNeeded,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'open':
        return AidColors.ngoAccent;
      case 'fulfilled':
        return AidColors.volunteerAccent;
      case 'closed':
        return AidColors.textMuted;
      default:
        return AidColors.textMuted;
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case 'open':
        return Icons.radio_button_checked_rounded;
      case 'fulfilled':
        return Icons.check_circle_rounded;
      case 'closed':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor().withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AidTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AidColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(), size: 12, color: _statusColor()),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: AidTextStyles.caption.copyWith(
                        color: _statusColor(),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const Gap(8),
            Text(
              description,
              style: AidTextStyles.caption.copyWith(color: AidColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Gap(12),
          Row(
            children: [
              _Chip(
                icon: Icons.category_rounded,
                label: category,
                color: AidColors.ngoAccent,
              ),
              const Gap(8),
              _Chip(
                icon: Icons.volunteer_activism_rounded,
                label: '$volunteersNeeded volunteers',
                color: AidColors.volunteerAccent,
              ),
              const Spacer(),
              // Quick close button
              GestureDetector(
                onTap: () => FirebaseFirestore.instance
                    .collection('requests')
                    .doc(docId)
                    .update({'status': 'closed'}),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AidColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Close',
                    style: AidTextStyles.caption
                        .copyWith(color: AidColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AidTextStyles.caption
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
