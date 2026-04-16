import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation.dart';

class DonationService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'donations';

  // ── Create ─────────────────────────────────────────────────────────────────

  static Future<String> submitDonation(Donation donation) async {
    final doc = await _db.collection(_col).add(donation.toFirestore());

    // Increment donor's totalDonations counter
    await _db.collection('users').doc(donation.donorId).update({
      'totalDonations': FieldValue.increment(1),
      if (donation.monetaryAmount != null)
        'totalMonetaryDonated': FieldValue.increment(donation.monetaryAmount!),
    });

    // If linked to a post, record the donor on the post
    if (donation.postId != null) {
      await _db.collection('posts').doc(donation.postId).update({
        'donorCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Create notification for the NGO
    if (donation.ngoId != null) {
      await _db.collection('notifications').add({
        'userId': donation.ngoId,
        'type': 'donationReceived',
        'title': 'New donation received!',
        'body': '${donation.donorName} wants to donate ${donation.typeLabel}.',
        'isRead': false,
        'deepLinkId': doc.id,
        'deepLinkType': 'donation',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return doc.id;
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Stream all donations for a specific donor
  static Stream<List<Donation>> donorHistory(String donorId) => _db
      .collection(_col)
      .where('donorId', isEqualTo: donorId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Donation.fromFirestore(d)).toList());

  /// Stream all donations received by an NGO
  static Stream<List<Donation>> ngoReceivedDonations(String ngoId) => _db
      .collection(_col)
      .where('ngoId', isEqualTo: ngoId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Donation.fromFirestore(d)).toList());

  /// Donations linked to a specific post
  static Stream<List<Donation>> postDonations(String postId) => _db
      .collection(_col)
      .where('postId', isEqualTo: postId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Donation.fromFirestore(d)).toList());

  /// Get platform-wide donation stats (for admin/manager)
  static Future<Map<String, dynamic>> platformStats() async {
    final snapshot = await _db.collection(_col).get();
    double totalMoney = 0;
    int totalDonations = snapshot.docs.length;
    for (final doc in snapshot.docs) {
      final amount = (doc.data()['monetaryAmount'] as num?)?.toDouble() ?? 0;
      totalMoney += amount;
    }
    return {
      'totalDonations': totalDonations,
      'totalMonetaryAmount': totalMoney,
    };
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  static Future<void> updateStatus(String donationId, DonationStatus status) async {
    await _db.collection(_col).doc(donationId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// NGO confirms a pending donation — notifies the donor
  static Future<void> confirmDonation(String donationId) async {
    final doc = await _db.collection(_col).doc(donationId).get();
    final data = doc.data() as Map<String, dynamic>;

    await _db.collection(_col).doc(donationId).update({
      'status': DonationStatus.confirmed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify the donor
    final donorId = data['donorId'] as String?;
    if (donorId != null) {
      await _db.collection('notifications').add({
        'userId': donorId,
        'type': 'donationConfirmed',
        'title': 'Donation confirmed!',
        'body': 'An NGO has confirmed your donation. Thank you for your generosity!',
        'isRead': false,
        'deepLinkId': donationId,
        'deepLinkType': 'donation',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
