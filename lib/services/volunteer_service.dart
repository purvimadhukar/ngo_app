import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward.dart';
import '../models/user_profile.dart';

class VolunteerService {
  static final _db = FirebaseFirestore.instance;

  // ── Activity join / leave ──────────────────────────────────────────────────

  static Future<void> joinActivity(String postId, String userId, String ngoId) async {
    // Update post volunteer count
    await _db.collection('posts').doc(postId).update({
      'eventDetails.volunteersJoined': FieldValue.increment(1),
      'joinedVolunteers': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Award points and log event
    await _awardPoints(
      userId: userId,
      type: RewardEventType.activityJoined,
      points: RewardPoints.activityJoined,
      description: 'Joined an activity',
      relatedId: postId,
    );

    // Check for first-join badge
    final userDoc = await _db.collection('users').doc(userId).get();
    final profile = UserProfile.fromFirestore(userDoc);
    if (!profile.badges.contains('first_step') && profile.activitiesJoined == 0) {
      await _awardBadge(userId, 'first_step');
    }

    // Increment user activitiesJoined
    await _db.collection('users').doc(userId).update({
      'activitiesJoined': FieldValue.increment(1),
    });

    // Notify NGO
    await _db.collection('notifications').add({
      'userId': ngoId,
      'type': 'activityJoined',
      'title': 'A volunteer joined your activity!',
      'body': 'Someone signed up for your event.',
      'isRead': false,
      'deepLinkId': postId,
      'deepLinkType': 'activity',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> leaveActivity(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'eventDetails.volunteersJoined': FieldValue.increment(-1),
      'joinedVolunteers': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Invite friends ─────────────────────────────────────────────────────────

  static Future<void> recordInviteSent(String userId) async {
    await _awardPoints(
      userId: userId,
      type: RewardEventType.friendInvited,
      points: RewardPoints.friendInvited,
      description: 'Invited a friend to AidBridge',
    );

    // Check recruiter badge (5 invites)
    final events = await _db
        .collection('reward_events')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'friendInvited')
        .get();
    if (events.docs.length >= 5) {
      await _awardBadge(userId, 'recruiter');
    }
    if (events.docs.length >= 20) {
      await _awardBadge(userId, 'organiser');
    }
  }

  // ── Rewards & badges ───────────────────────────────────────────────────────

  static Future<void> _awardPoints({
    required String userId,
    required RewardEventType type,
    required int points,
    required String description,
    String? relatedId,
  }) async {
    await _db.collection('reward_events').add({
      'userId': userId,
      'type': type.name,
      'points': points,
      'description': description,
      if (relatedId != null) 'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(userId).update({
      'rewardPoints': FieldValue.increment(points),
    });

    // Check milestone badges based on total points
    final userDoc = await _db.collection('users').doc(userId).get();
    final totalPoints = (userDoc.data()?['rewardPoints'] as int?) ?? 0;
    for (final badge in BadgeCatalog.all) {
      if (badge.pointsRequired > 0 && totalPoints >= badge.pointsRequired) {
        await _awardBadge(userId, badge.id);
      }
    }
  }

  static Future<void> _awardBadge(String userId, String badgeId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final badges = List<String>.from(doc.data()?['badges'] ?? []);
    if (badges.contains(badgeId)) return; // Already awarded

    await _db.collection('users').doc(userId).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });

    final badge = BadgeCatalog.findById(badgeId);
    if (badge != null) {
      await _db.collection('notifications').add({
        'userId': userId,
        'type': 'badgeEarned',
        'title': 'New badge: ${badge.name}!',
        'body': badge.description,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  static Stream<List<UserProfile>> leaderboard({int limit = 20}) => _db
      .collection('users')
      .where('role', isEqualTo: 'volunteer')
      .orderBy('rewardPoints', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => UserProfile.fromFirestore(d)).toList());

  // ── Reward history ─────────────────────────────────────────────────────────

  static Stream<List<RewardEvent>> rewardHistory(String userId) => _db
      .collection('reward_events')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => RewardEvent.fromFirestore(d)).toList());
}
