import 'package:cloud_firestore/cloud_firestore.dart';

/// A donor group — multiple donors pool together to donate.
class DonorGroup {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final List<String> memberIds;
  final List<String> memberNames;
  final double totalContributed;
  final int donationCount;
  final String? groupImageUrl;
  final bool isPublic; // public groups can be joined by any donor
  final DateTime createdAt;
  final DateTime? updatedAt;

  DonorGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.memberIds,
    required this.memberNames,
    this.totalContributed = 0,
    this.donationCount = 0,
    this.groupImageUrl,
    this.isPublic = true,
    required this.createdAt,
    this.updatedAt,
  });

  int get memberCount => memberIds.length;

  factory DonorGroup.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return DonorGroup(
      id: doc.id,
      name: m['name'] ?? '',
      description: m['description'] ?? '',
      creatorId: m['creatorId'] ?? '',
      creatorName: m['creatorName'] ?? '',
      memberIds: List<String>.from(m['memberIds'] ?? []),
      memberNames: List<String>.from(m['memberNames'] ?? []),
      totalContributed: (m['totalContributed'] as num?)?.toDouble() ?? 0,
      donationCount: m['donationCount'] ?? 0,
      groupImageUrl: m['groupImageUrl'],
      isPublic: m['isPublic'] ?? true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'totalContributed': totalContributed,
        'donationCount': donationCount,
        if (groupImageUrl != null) 'groupImageUrl': groupImageUrl,
        'isPublic': isPublic,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
