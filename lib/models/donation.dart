import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationType { monetary, food, clothes, groceries, medical, education, other }

enum DonationStatus { pending, confirmed, received, completed, cancelled }

class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String? ngoId;
  final String? ngoName;
  final String? postId;          // linked NGO post (optional - could be open donation)
  final DonationType type;
  final DonationStatus status;
  final double? monetaryAmount;  // for monetary donations
  final String? goodsDescription; // for in-kind donations
  final double? quantityKg;      // e.g. 5 kg rice
  final String? note;
  final String? pickupAddress;
  final DateTime? scheduledPickup;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    this.ngoId,
    this.ngoName,
    this.postId,
    required this.type,
    required this.status,
    this.monetaryAmount,
    this.goodsDescription,
    this.quantityKg,
    this.note,
    this.pickupAddress,
    this.scheduledPickup,
    required this.createdAt,
    this.updatedAt,
  });

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      donorId: m['donorId'] ?? '',
      donorName: m['donorName'] ?? '',
      ngoId: m['ngoId'],
      ngoName: m['ngoName'],
      postId: m['postId'],
      type: DonationType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => DonationType.other,
      ),
      status: DonationStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => DonationStatus.pending,
      ),
      monetaryAmount: (m['monetaryAmount'] as num?)?.toDouble(),
      goodsDescription: m['goodsDescription'],
      quantityKg: (m['quantityKg'] as num?)?.toDouble(),
      note: m['note'],
      pickupAddress: m['pickupAddress'],
      scheduledPickup: m['scheduledPickup'] != null
          ? (m['scheduledPickup'] as Timestamp).toDate()
          : null,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'donorId': donorId,
        'donorName': donorName,
        if (ngoId != null) 'ngoId': ngoId,
        if (ngoName != null) 'ngoName': ngoName,
        if (postId != null) 'postId': postId,
        'type': type.name,
        'status': status.name,
        if (monetaryAmount != null) 'monetaryAmount': monetaryAmount,
        if (goodsDescription != null) 'goodsDescription': goodsDescription,
        if (quantityKg != null) 'quantityKg': quantityKg,
        if (note != null) 'note': note,
        if (pickupAddress != null) 'pickupAddress': pickupAddress,
        if (scheduledPickup != null)
          'scheduledPickup': Timestamp.fromDate(scheduledPickup!),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  String get typeLabel {
    switch (type) {
      case DonationType.monetary:
        return 'Monetary';
      case DonationType.food:
        return 'Food';
      case DonationType.clothes:
        return 'Clothes';
      case DonationType.groceries:
        return 'Groceries';
      case DonationType.medical:
        return 'Medical';
      case DonationType.education:
        return 'Education';
      case DonationType.other:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case DonationStatus.pending:
        return 'Pending';
      case DonationStatus.confirmed:
        return 'Confirmed';
      case DonationStatus.received:
        return 'Received';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.cancelled:
        return 'Cancelled';
    }
  }
}
