import 'package:flutter/material.dart';
import '../../models/ngo_post.dart';
import '../../services/post_service.dart';
import 'donation_detail_screen.dart';

class DonorFeedScreen extends StatefulWidget {
  const DonorFeedScreen({super.key});

  @override
  State<DonorFeedScreen> createState() => _DonorFeedScreenState();
}

class _DonorFeedScreenState extends State<DonorFeedScreen> {
  String? _filterCategory;

  final _categories = [null, 'food', 'clothes', 'medical', 'education', 'funds', 'other'];
  final _categoryLabels = {
    null: 'All',
    'food': 'Food',
    'clothes': 'Clothes',
    'medical': 'Medical',
    'education': 'Education',
    'funds': 'Funds',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation feed'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_categoryLabels[c]!),
                      selected: _filterCategory == c,
                      onSelected: (_) => setState(() => _filterCategory = c),
                    ),
                  )).toList(),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<NgoPost>>(
        stream: PostService.verifiedFeed(category: _filterCategory),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final posts = snap.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Text('No verified posts right now. Check back soon!'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PostCard(post: posts[i]),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final NgoPost post;
  const _PostCard({required this.post});

  Color _urgencyColor(double score) {
    if (score >= 0.8) return Colors.red.shade100;
    if (score >= 0.5) return Colors.orange.shade50;
    return Colors.green.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonationDetailScreen(post: post)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media carousel
            if (post.mediaUrls.isNotEmpty)
              SizedBox(
                height: 180,
                child: PageView.builder(
                  itemCount: post.mediaUrls.length,
                  itemBuilder: (_, i) => Image.network(
                    post.mediaUrls[i],
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                color: Colors.grey.shade100,
                child: const Center(child: Icon(Icons.volunteer_activism, size: 48, color: Colors.grey)),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NGO name + verified badge
                  Row(
                    children: [
                      Text(
                        post.ngoName,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      if (post.ngoVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: Colors.blue),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _urgencyColor(post.urgencyScore),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),

                  // Required items progress
                  if (post.requiredItems.isNotEmpty) ...[
                    ...post.requiredItems.take(2).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.name} (${item.unit})',
                                      style: const TextStyle(fontSize: 12)),
                                  Text(
                                    '${item.fulfilledQty.toInt()} / ${item.targetQty.toInt()}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    if (post.requiredItems.length > 2)
                      Text(
                        '+${post.requiredItems.length - 2} more items',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DonationDetailScreen(post: post)),
                      ),
                      child: const Text('Donate now'),
                    ),
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