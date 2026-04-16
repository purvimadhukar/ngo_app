import 'package:flutter/material.dart';
import '../../models/ngo_post.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';

class VolunteerEventsScreen extends StatelessWidget {
  const VolunteerEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming events')),
      body: StreamBuilder<List<NgoPost>>(
        stream: PostService.upcomingEvents(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No upcoming events. Check back soon!'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _EventCard(post: events[i]),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final NgoPost post;
  const _EventCard({required this.post});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _joining = false;

  Future<void> _toggleJoin(bool hasJoined) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _joining = true);
    try {
      if (hasJoined) {
        await PostService.leaveEvent(widget.post.id, uid);
      } else {
        await PostService.joinEvent(widget.post.id, uid);
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.post.eventDetails;
    if (ev == null) return const SizedBox.shrink();

    // We'd normally check joinedVolunteers array from Firestore — simplified here
    final spotsLeft = ev.volunteersNeeded - ev.volunteersJoined;
    final isFull = spotsLeft <= 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.mediaUrls.isNotEmpty)
            Image.network(
              widget.post.mediaUrls.first,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NGO + date row
                Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(widget.post.ngoName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ev.eventDate.day}/${ev.eventDate.month}/${ev.eventDate.year}',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.post.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ev.location,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${ev.eventDate.hour}:${ev.eventDate.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Volunteers progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFull ? 'Full' : '$spotsLeft spots left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isFull ? Colors.red : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      '${ev.volunteersJoined}/${ev.volunteersNeeded} volunteers',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: ev.volunteersNeeded > 0
                      ? ev.volunteersJoined / ev.volunteersNeeded
                      : 0,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  color: isFull ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 10),

                // Contact + join row
                Row(
                  children: [
                    if (ev.contactPhone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // launch phone dialer
                          },
                          icon: const Icon(Icons.phone, size: 14),
                          label: Text(ev.contactPhone, style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: isFull || _joining ? null : () => _toggleJoin(false),
                        child: _joining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isFull ? 'Full' : 'Join event'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}