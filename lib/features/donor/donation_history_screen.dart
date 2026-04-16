import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/donation.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        title: const Text('My Donation History'),
        backgroundColor: AidColors.background,
      ),
      body: StreamBuilder<List<Donation>>(
        stream: DonationService.donorHistory(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final donations = snap.data ?? [];

          if (donations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 52)),
                  const Gap(16),
                  Text('No donations yet', style: AidTextStyles.headingMd),
                  const Gap(8),
                  Text(
                    'Your donation history will appear here\nafter your first donation.',
                    style: AidTextStyles.bodyMd
                        .copyWith(color: AidColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Summary stats
          double totalMoney = 0;
          int totalCount = donations.length;
          for (final d in donations) {
            totalMoney += d.monetaryAmount ?? 0;
          }

          return Column(
            children: [
              // Stats banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AidColors.donorAccent.withValues(alpha: 0.2),
                      AidColors.donorAccentMuted.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AidColors.donorAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Total Donations',
                        value: '$totalCount',
                        icon: Icons.handshake_rounded,
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: AidColors.borderDefault),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Monetary Total',
                        value: '₹${totalMoney.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: donations.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (context, i) =>
                      _DonationCard(donation: donations[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AidColors.donorAccent, size: 24),
        const Gap(6),
        Text(value,
            style: AidTextStyles.headingLg.copyWith(color: AidColors.donorAccent)),
        Text(label, style: AidTextStyles.bodySm, textAlign: TextAlign.center),
      ],
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;
  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (donation.status) {
      case DonationStatus.pending:
        statusColor = AidColors.warning;
        break;
      case DonationStatus.confirmed:
      case DonationStatus.received:
        statusColor = AidColors.info;
        break;
      case DonationStatus.completed:
        statusColor = AidColors.success;
        break;
      case DonationStatus.cancelled:
        statusColor = AidColors.error;
        break;
    }

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
              color: AidColors.donorAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(donation.type),
                color: AidColors.donorAccent, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donation.typeLabel, style: AidTextStyles.headingSm),
                if (donation.ngoName != null)
                  Text('To: ${donation.ngoName}', style: AidTextStyles.bodySm),
                if (donation.monetaryAmount != null)
                  Text('₹${donation.monetaryAmount!.toStringAsFixed(0)}',
                      style: AidTextStyles.bodyMd
                          .copyWith(color: AidColors.donorAccent)),
                if (donation.goodsDescription != null)
                  Text(donation.goodsDescription!, style: AidTextStyles.bodySm),
                Text(
                  '${donation.createdAt.day}/${donation.createdAt.month}/${donation.createdAt.year}',
                  style: AidTextStyles.labelSm,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  donation.statusLabel,
                  style: AidTextStyles.labelSm.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(DonationType type) {
    switch (type) {
      case DonationType.monetary:
        return Icons.currency_rupee_rounded;
      case DonationType.food:
        return Icons.restaurant_rounded;
      case DonationType.clothes:
        return Icons.checkroom_rounded;
      case DonationType.groceries:
        return Icons.shopping_basket_rounded;
      case DonationType.medical:
        return Icons.medical_services_rounded;
      case DonationType.education:
        return Icons.school_rounded;
      case DonationType.other:
        return Icons.volunteer_activism_rounded;
    }
  }
}
