import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'notifications';

  // ── Read ───────────────────────────────────────────────────────────────────

  static Stream<List<AppNotification>> userNotifications(String userId) => _db
      .collection(_col)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => AppNotification.fromFirestore(d)).toList());

  static Stream<int> unreadCount(String userId) => _db
      .collection(_col)
      .where('userId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  // ── Update ─────────────────────────────────────────────────────────────────

  static Future<void> markAsRead(String notificationId) =>
      _db.collection(_col).doc(notificationId).update({'isRead': true});

  static Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final query = await _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  static Future<void> send({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? deepLinkId,
    String? deepLinkType,
  }) async {
    await _db.collection(_col).add({
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': false,
      if (deepLinkId != null) 'deepLinkId': deepLinkId,
      if (deepLinkType != null) 'deepLinkType': deepLinkType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
