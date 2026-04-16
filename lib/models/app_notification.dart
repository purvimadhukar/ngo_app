import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  donationReceived,      // NGO gets notified when a donor submits
  donationConfirmed,     // Donor gets notified when NGO confirms
  activityJoined,        // NGO gets notified when volunteer joins
  activityReminder,      // Volunteer gets reminded about upcoming event
  ngoVerified,           // NGO gets notified when verified
  ngoRejected,           // NGO gets notified when rejected
  newPost,               // Donor gets notified about new NGO post
  badgeEarned,           // Volunteer gets notified of new badge
  groupInvite,           // Donor gets group invite
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? deepLinkId;   // postId, activityId, etc.
  final String? deepLinkType; // 'post' | 'activity' | 'group' etc.
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.deepLinkId,
    this.deepLinkType,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: m['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => NotificationType.general,
      ),
      title: m['title'] ?? '',
      body: m['body'] ?? '',
      isRead: m['isRead'] ?? false,
      deepLinkId: m['deepLinkId'],
      deepLinkType: m['deepLinkType'],
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'isRead': isRead,
        if (deepLinkId != null) 'deepLinkId': deepLinkId,
        if (deepLinkType != null) 'deepLinkType': deepLinkType,
        'createdAt': FieldValue.serverTimestamp(),
      };

  String get typeIcon {
    switch (type) {
      case NotificationType.donationReceived:
        return '💰';
      case NotificationType.donationConfirmed:
        return '✅';
      case NotificationType.activityJoined:
        return '🙌';
      case NotificationType.activityReminder:
        return '⏰';
      case NotificationType.ngoVerified:
        return '🎉';
      case NotificationType.ngoRejected:
        return '❌';
      case NotificationType.newPost:
        return '📢';
      case NotificationType.badgeEarned:
        return '🏅';
      case NotificationType.groupInvite:
        return '👥';
      case NotificationType.general:
        return '🔔';
    }
  }
}
