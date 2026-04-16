import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ngo_post.dart';

class PostService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static const _col = 'posts';

  // ─── Create ───────────────────────────────────────────────────────────────

  static Future<String> createPost(NgoPost post) async {
    final doc = await _db.collection(_col).add(post.toFirestore());
    return doc.id;
  }

  // ─── Upload media (images/videos) ─────────────────────────────────────────

  static Future<String> uploadMedia(XFile file, String ngoId) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref('posts/$ngoId/media/$name');
    final bytes = await file.readAsBytes();
    final task = await ref.putData(bytes);
    return await task.ref.getDownloadURL();
  }

  static Future<String> uploadProof(XFile file, String postId) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_proof.jpg';
    final ref = _storage.ref('posts/$postId/proof/$name');
    final bytes = await file.readAsBytes();
    final task = await ref.putData(bytes);
    return await task.ref.getDownloadURL();
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Donor feed: only verified NGOs, active posts, sorted by urgency
  static Stream<List<NgoPost>> verifiedFeed({String? category}) {
    Query q = _db
        .collection(_col)
        .where('ngoVerified', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('flaggedForReview', isEqualTo: false)
        .orderBy('urgencyScore', descending: true);
    if (category != null) q = q.where('category', isEqualTo: category);
    return q.snapshots().map(
          (s) => s.docs.map((d) => NgoPost.fromFirestore(d)).toList(),
        );
  }

  /// NGO's own posts
  static Stream<List<NgoPost>> postsForNgo(String ngoId) => _db
      .collection(_col)
      .where('ngoId', isEqualTo: ngoId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => NgoPost.fromFirestore(d)).toList());

  /// Volunteer event feed: only activity posts with future dates
  static Stream<List<NgoPost>> upcomingEvents() => _db
      .collection(_col)
      .where('type', isEqualTo: 'activity')
      .where('status', isEqualTo: 'active')
      .where('ngoVerified', isEqualTo: true)
      .orderBy('eventDetails.eventDate')
      .snapshots()
      .map((s) => s.docs.map((d) => NgoPost.fromFirestore(d)).toList());

  static Future<NgoPost?> getPost(String postId) async {
    final doc = await _db.collection(_col).doc(postId).get();
    return doc.exists ? NgoPost.fromFirestore(doc) : null;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  static Future<void> addProofPhoto(String postId, String proofUrl) =>
      _db.collection(_col).doc(postId).update({
        'proofUrls': FieldValue.arrayUnion([proofUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateStatus(String postId, PostStatus status) =>
      _db.collection(_col).doc(postId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateItemProgress(
    String postId,
    int itemIndex,
    double newFulfilledQty,
  ) async {
    final doc = await _db.collection(_col).doc(postId).get();
    final post = NgoPost.fromFirestore(doc);
    final items = post.requiredItems;
    items[itemIndex] = RequiredItem(
      name: items[itemIndex].name,
      unit: items[itemIndex].unit,
      targetQty: items[itemIndex].targetQty,
      fulfilledQty: newFulfilledQty,
    );
    await _db.collection(_col).doc(postId).update({
      'requiredItems': items.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Volunteer join/leave ─────────────────────────────────────────────────

  static Future<void> joinEvent(String postId, String userId) =>
      _db.collection(_col).doc(postId).update({
        'eventDetails.volunteersJoined': FieldValue.increment(1),
        'joinedVolunteers': FieldValue.arrayUnion([userId]),
      });

  static Future<void> leaveEvent(String postId, String userId) =>
      _db.collection(_col).doc(postId).update({
        'eventDetails.volunteersJoined': FieldValue.increment(-1),
        'joinedVolunteers': FieldValue.arrayRemove([userId]),
      });

  // ─── Fraud flag (used by ML layer or admin) ───────────────────────────────

  static Future<void> flagPost(String postId, {bool flag = true}) =>
      _db.collection(_col).doc(postId).update({'flaggedForReview': flag});
}