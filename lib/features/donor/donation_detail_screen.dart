import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ngo_post.dart';

class DonationDetailScreen extends StatelessWidget {
  final NgoPost post;
  const DonationDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Media
          if (post.mediaUrls.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: post.mediaUrls.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(post.mediaUrls[i], fit: BoxFit.cover),
                ),
              ),
            ),
          if (post.mediaUrls.isNotEmpty) const SizedBox(height: 16),

          // NGO info
          Row(
            children: [
              Text(
                post.ngoName,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.grey),
              ),
              if (post.ngoVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 14, color: Colors.blue),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Title & description
          Text(
            post.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(post.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),

          // Category chip
          Chip(label: Text(post.category)),
          const SizedBox(height: 16),

          // Required items
          if (post.requiredItems.isNotEmpty) ...[
            Text('Items needed',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...post.requiredItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.name} (${item.unit})'),
                          Text(
                            '${item.fulfilledQty.toInt()} / ${item.targetQty.toInt()}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: item.progressPercent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Donate button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showDonateDialog(context),
              child: const Text('Donate now'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDonateDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final itemCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: itemCtrl,
              decoration:
                  const InputDecoration(labelText: 'Item description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(post.id)
                  .collection('donations')
                  .add({
                'donorId': user.uid,
                'donorEmail': user.email,
                'amount': double.tryParse(amountCtrl.text) ?? 0,
                'item': itemCtrl.text,
                'status': 'pending',
                'donatedAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Donation submitted!')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
