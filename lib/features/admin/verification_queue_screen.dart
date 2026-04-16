import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_verification.dart';

class VerificationQueueScreen extends StatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AidColors.background,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NGO Verifications', style: AidTextStyles.displaySm),
              const Gap(4),
              Text('Review and approve NGO registration requests',
                  style: AidTextStyles.bodySm),
              const Gap(16),
              TabBar(
                controller: _tab,
                labelColor: AidColors.ngoAccent,
                unselectedLabelColor: AidColors.textSecondary,
                indicatorColor: AidColors.ngoAccent,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Rejected'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _VerificationList(status: 'pending'),
              _VerificationList(status: 'approved'),
              _VerificationList(status: 'rejected'),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationList extends StatelessWidget {
  final String status;
  const _VerificationList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verifications')
          .where('status', isEqualTo: status)
          .orderBy('submittedAt', descending: true)
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
                Icon(
                  status == 'pending'
                      ? Icons.inbox_outlined
                      : status == 'approved'
                          ? Icons.verified_outlined
                          : Icons.cancel_outlined,
                  size: 48,
                  color: AidColors.textTertiary,
                ),
                const Gap(12),
                Text('No $status verifications', style: AidTextStyles.bodyMd),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, i) {
            final v = NgoVerification.fromFirestore(docs[i]);
            return _VerificationCard(verification: v);
          },
        );
      },
    );
  }
}

class _VerificationCard extends StatefulWidget {
  final NgoVerification verification;
  const _VerificationCard({required this.verification});

  @override
  State<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<_VerificationCard> {
  bool _expanded = false;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.verification;
    final isPending = v.status == VerificationStatus.pending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor(v.status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor(v.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _statusIcon(v.status),
                      color: _statusColor(v.status),
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.orgName, style: AidTextStyles.headingSm),
                        const Gap(2),
                        Text('Reg: ${v.regNumber}', style: AidTextStyles.bodySm),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AidColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submitted date
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Submitted',
                    value:
                        '${v.submittedAt.day}/${v.submittedAt.month}/${v.submittedAt.year}',
                  ),
                  const Gap(8),
                  _InfoRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'NGO ID',
                    value: v.ngoId,
                  ),

                  // Documents
                  if (v.docUrls.isNotEmpty) ...[
                    const Gap(16),
                    Text('Documents (${v.docUrls.length})',
                        style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary)),
                    const Gap(8),
                    ...v.docUrls.asMap().entries.map(
                          (e) => _DocChip(url: e.value, index: e.key + 1),
                        ),
                  ],

                  // Admin note (if rejected)
                  if (v.adminNote != null) ...[
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AidColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AidColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.note_rounded, color: AidColors.error, size: 16),
                          const Gap(8),
                          Expanded(
                            child: Text(v.adminNote!,
                                style: AidTextStyles.bodySm.copyWith(color: AidColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action buttons
                  if (isPending) ...[
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _processing ? null : () => _reject(context, v),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AidColors.error,
                              side: BorderSide(color: AidColors.error.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _processing ? null : () => _approve(context, v),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AidColors.success,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, NgoVerification v) async {
    setState(() => _processing = true);
    await VerificationService.updateVerification(
      v.id,
      VerificationStatus.approved,
    );
    // Send notification to NGO
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': v.ngoId,
      'type': 'ngoVerified',
      'title': 'Your NGO has been verified! 🎉',
      'body': '${v.orgName} is now verified on AidBridge. You can start posting.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _reject(BuildContext context, NgoVerification v) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                labelText: 'Admin Note',
              ),
              maxLines: 3,
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
      setState(() => _processing = true);
      await VerificationService.updateVerification(
        v.id,
        VerificationStatus.rejected,
        note: noteCtrl.text.trim().isEmpty ? 'Documents insufficient' : noteCtrl.text.trim(),
      );
      // Notify NGO
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': v.ngoId,
        'type': 'ngoRejected',
        'title': 'Verification update',
        'body': 'Your verification for ${v.orgName} was not approved. Please resubmit with correct documents.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _processing = false);
    }
  }

  Color _statusColor(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.pending:
        return AidColors.warning;
      case VerificationStatus.approved:
        return AidColors.success;
      case VerificationStatus.rejected:
        return AidColors.error;
    }
  }

  IconData _statusIcon(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.pending:
        return Icons.pending_outlined;
      case VerificationStatus.approved:
        return Icons.verified_rounded;
      case VerificationStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AidColors.textSecondary),
        const Gap(6),
        Text('$label: ', style: AidTextStyles.bodySm),
        Expanded(
          child: Text(
            value,
            style: AidTextStyles.bodySm.copyWith(color: AidColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DocChip extends StatelessWidget {
  final String url;
  final int index;

  const _DocChip({required this.url, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AidColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AidColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 16, color: AidColors.textSecondary),
          const Gap(8),
          Expanded(
            child: Text(
              'Document $index',
              style: AidTextStyles.bodyMd,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 14, color: AidColors.ngoAccent),
        ],
      ),
    );
  }
}
