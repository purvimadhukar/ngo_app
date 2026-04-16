import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';

class DonorHome extends StatelessWidget {
  const DonorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        title: const Text('Donation Requests'),
        backgroundColor: AidColors.surface,
        foregroundColor: AidColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('type', isEqualTo: 'donation')
            .where('status', isEqualTo: 'open')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }

          if (snapshot.hasError) {
            return _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Something went wrong',
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.volunteer_activism_outlined,
              message: 'No open requests right now',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _RequestCard(
                docId: docId,
                title: data['title'] ?? 'Untitled',
                description: data['description'] ?? '',
                location: data['location'] ?? 'Unknown location',
                createdBy: data['createdBy'] ?? '',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AidColors.surface,
          highlightColor: AidColors.elevated,
          child: Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AidColors.textSecondary),
          const Gap(16),
          Text(
            message,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String docId;
  final String title;
  final String description;
  final String location;
  final String createdBy;

  const _RequestCard({
    required this.docId,
    required this.title,
    required this.description,
    required this.location,
    required this.createdBy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AidColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AidTextStyles.headingMd),
          const Gap(8),
          Text(
            description,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(12),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: AidColors.textSecondary),
              const Gap(4),
              Expanded(
                child: Text(
                  location,
                  style: AidTextStyles.labelSm,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDonateDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AidColors.donorAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Donate'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDonateDialog(BuildContext context) {
    final amountController = TextEditingController();
    final itemController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AidColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Donate', style: AidTextStyles.headingLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: AidTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: 'Amount (optional)',
                labelStyle: AidTextStyles.labelMd,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AidColors.borderDefault),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AidColors.donorAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Gap(12),
            TextField(
              controller: itemController,
              style: AidTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: 'Item description (optional)',
                labelStyle: AidTextStyles.labelMd,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AidColors.borderDefault),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AidColors.donorAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              await FirebaseFirestore.instance
                  .collection('requests')
                  .doc(docId)
                  .collection('donations')
                  .add({
                'donorId': user.uid,
                'donorEmail': user.email,
                'amount': double.tryParse(amountController.text) ?? 0,
                'item': itemController.text,
                'status': 'pending',
                'donatedAt': FieldValue.serverTimestamp(),
              });

              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Donation submitted!'),
                  backgroundColor: AidColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AidColors.donorAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
