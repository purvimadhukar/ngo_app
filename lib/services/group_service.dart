import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class GroupService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'donor_groups';

  // ── Create ─────────────────────────────────────────────────────────────────

  static Future<String> createGroup({
    required String name,
    required String description,
    required String creatorId,
    required String creatorName,
    bool isPublic = true,
  }) async {
    final doc = await _db.collection(_col).add({
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'memberIds': [creatorId],
      'memberNames': [creatorName],
      'totalContributed': 0,
      'donationCount': 0,
      'isPublic': isPublic,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// All public groups (for discovery)
  static Stream<List<DonorGroup>> publicGroups() => _db
      .collection(_col)
      .where('isPublic', isEqualTo: true)
      .orderBy('totalContributed', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DonorGroup.fromFirestore(d)).toList());

  /// Groups the current user is a member of
  static Stream<List<DonorGroup>> myGroups(String userId) => _db
      .collection(_col)
      .where('memberIds', arrayContains: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DonorGroup.fromFirestore(d)).toList());

  static Future<DonorGroup?> getGroup(String groupId) async {
    final doc = await _db.collection(_col).doc(groupId).get();
    return doc.exists ? DonorGroup.fromFirestore(doc) : null;
  }

  // ── Join / Leave ───────────────────────────────────────────────────────────

  static Future<void> joinGroup(
      String groupId, String userId, String userName) async {
    await _db.collection(_col).doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberNames': FieldValue.arrayUnion([userName]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> leaveGroup(
      String groupId, String userId, String userName) async {
    await _db.collection(_col).doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberNames': FieldValue.arrayRemove([userName]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Invite ─────────────────────────────────────────────────────────────────

  static Future<void> inviteMember(
      String groupId, String groupName, String targetUserId) async {
    await _db.collection('notifications').add({
      'userId': targetUserId,
      'type': 'groupInvite',
      'title': 'You\'ve been invited to a group!',
      'body': 'Join "$groupName" to donate together.',
      'isRead': false,
      'deepLinkId': groupId,
      'deepLinkType': 'group',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Update stats ───────────────────────────────────────────────────────────

  static Future<void> recordGroupDonation(
      String groupId, double amount) async {
    await _db.collection(_col).doc(groupId).update({
      'totalContributed': FieldValue.increment(amount),
      'donationCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
