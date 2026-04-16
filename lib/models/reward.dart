import 'package:cloud_firestore/cloud_firestore.dart';

// ── Badge definitions ─────────────────────────────────────────────────────────

class RewardBadge {
  final String id;
  final String name;
  final String description;
  final String icon;    // emoji icon
  final int pointsRequired;
  final String tier; // 'bronze' | 'silver' | 'gold' | 'platinum'

  const RewardBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsRequired,
    required this.tier,
  });
}

// Pre-defined badge catalog
class BadgeCatalog {
  static const List<RewardBadge> all = [
    RewardBadge(id: 'first_step',   name: 'First Step',       description: 'Joined your first activity',  icon: '👣', pointsRequired: 10,   tier: 'bronze'),
    RewardBadge(id: 'helper',       name: 'Helper',            description: 'Completed 3 activities',      icon: '🤝', pointsRequired: 50,   tier: 'bronze'),
    RewardBadge(id: 'volunteer',    name: 'Volunteer',         description: 'Completed 10 activities',     icon: '🌱', pointsRequired: 150,  tier: 'silver'),
    RewardBadge(id: 'champion',     name: 'Champion',          description: 'Completed 25 activities',     icon: '🏅', pointsRequired: 400,  tier: 'silver'),
    RewardBadge(id: 'hero',         name: 'Community Hero',    description: 'Completed 50 activities',     icon: '🦸', pointsRequired: 900,  tier: 'gold'),
    RewardBadge(id: 'legend',       name: 'Legend',            description: 'Completed 100 activities',    icon: '🏆', pointsRequired: 2000, tier: 'platinum'),
    RewardBadge(id: 'recruiter',    name: 'Recruiter',         description: 'Invited 5 friends',           icon: '📣', pointsRequired: 100,  tier: 'silver'),
    RewardBadge(id: 'organiser',    name: 'Organiser',         description: 'Invited 20 friends',          icon: '🎯', pointsRequired: 500,  tier: 'gold'),
    RewardBadge(id: 'early_bird',   name: 'Early Bird',        description: 'First 50 volunteers',         icon: '🐦', pointsRequired: 0,    tier: 'silver'),
    RewardBadge(id: 'consistent',   name: 'Consistent',        description: '3 activities in a row',       icon: '🔥', pointsRequired: 75,   tier: 'bronze'),
  ];

  static RewardBadge? findById(String id) =>
      all.where((b) => b.id == id).firstOrNull;
}

// ── Reward Event (log of points earned) ──────────────────────────────────────

enum RewardEventType {
  activityJoined,
  activityCompleted,
  friendInvited,
  friendJoined,
  donationMade,
  profileCompleted,
  firstLogin,
  milestone,
}

class RewardEvent {
  final String id;
  final String userId;
  final RewardEventType type;
  final int points;
  final String description;
  final String? relatedId; // postId, activityId, etc.
  final DateTime createdAt;

  RewardEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    this.relatedId,
    required this.createdAt,
  });

  factory RewardEvent.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return RewardEvent(
      id: doc.id,
      userId: m['userId'] ?? '',
      type: RewardEventType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => RewardEventType.activityJoined,
      ),
      points: m['points'] ?? 0,
      description: m['description'] ?? '',
      relatedId: m['relatedId'],
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.name,
        'points': points,
        'description': description,
        if (relatedId != null) 'relatedId': relatedId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ── Point values per event ────────────────────────────────────────────────────

class RewardPoints {
  static const activityJoined    = 10;
  static const activityCompleted = 25;
  static const friendInvited     = 15;
  static const friendJoined      = 30;
  static const donationMade      = 20;
  static const profileCompleted  = 50;
  static const firstLogin        = 10;
}
