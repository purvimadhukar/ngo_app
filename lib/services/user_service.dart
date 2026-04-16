import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  // ── Read ───────────────────────────────────────────────────────────────────

  static Stream<UserProfile?> watchProfile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? UserProfile.fromFirestore(d) : null);

  static Future<UserProfile?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserProfile.fromFirestore(doc) : null;
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  static Future<void> updateProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<String> uploadAvatar(String uid, XFile file) async {
    final ref = _storage.ref('avatars/$uid/profile.jpg');
    final bytes = await file.readAsBytes();
    await ref.putData(bytes);
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({'photoUrl': url});
    return url;
  }

  // ── NGO list (for donors/admin to browse) ──────────────────────────────────

  static Stream<List<UserProfile>> verifiedNGOs() => _db
      .collection('users')
      .where('role', isEqualTo: 'ngo')
      .where('ngoVerified', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => UserProfile.fromFirestore(d)).toList());

  static Stream<List<UserProfile>> allNGOs() => _db
      .collection('users')
      .where('role', isEqualTo: 'ngo')
      .snapshots()
      .map((s) => s.docs.map((d) => UserProfile.fromFirestore(d)).toList());

  // ── Platform stats (admin/manager) ─────────────────────────────────────────

  static Future<Map<String, int>> platformUserStats() async {
    final all = await _db.collection('users').get();
    int donors = 0, volunteers = 0, ngos = 0, admins = 0, managers = 0;
    for (final doc in all.docs) {
      switch (doc.data()['role'] as String?) {
        case 'donor':
          donors++;
          break;
        case 'volunteer':
          volunteers++;
          break;
        case 'ngo':
          ngos++;
          break;
        case 'admin':
          admins++;
          break;
        case 'manager':
          managers++;
          break;
      }
    }
    return {
      'donors': donors,
      'volunteers': volunteers,
      'ngos': ngos,
      'admins': admins,
      'managers': managers,
      'total': all.docs.length,
    };
  }

  /// Search users by name (simple prefix match via Firestore)
  static Future<List<UserProfile>> searchUsers(String query) async {
    final snap = await _db
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .limit(20)
        .get();
    return snap.docs.map((d) => UserProfile.fromFirestore(d)).toList();
  }
}
