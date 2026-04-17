import 'package:cloud_firestore/cloud_firestore.dart';

enum ImpactGroupType { children, elderly, women, general }

extension ImpactGroupTypeX on ImpactGroupType {
  String get label {
    switch (this) {
      case ImpactGroupType.children: return 'Children (0–10 yrs)';
      case ImpactGroupType.elderly:  return 'Elderly Care';
      case ImpactGroupType.women:    return 'Women Support';
      case ImpactGroupType.general:  return 'General';
    }
  }
  String get emoji {
    switch (this) {
      case ImpactGroupType.children: return '👶';
      case ImpactGroupType.elderly:  return '👴';
      case ImpactGroupType.women:    return '👩';
      case ImpactGroupType.general:  return '🤝';
    }
  }
}

class ImpactUpdate {
  final String text;
  final String? imageUrl;
  final DateTime date;

  ImpactUpdate({required this.text, this.imageUrl, required this.date});

  factory ImpactUpdate.fromMap(Map<String, dynamic> m) => ImpactUpdate(
    text: m['text'] ?? '',
    imageUrl: m['imageUrl'],
    date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'date': Timestamp.fromDate(date),
  };
}

class ImpactGroup {
  final String id;
  final String ngoId;
  final String ngoName;
  final ImpactGroupType type;
  final String title;          // e.g. "Support 12 children with daily meals"
  final String story;          // emotional narrative
  final int beneficiaryCount;
  final List<String> needs;    // e.g. ["Daily meals", "Winter clothes"]
  final List<String> imageUrls;
  final List<ImpactUpdate> updates;
  final String? linkedPostId;  // links to a donation post
  final bool consentConfirmed;
  final double totalRaised;
  final DateTime createdAt;

  ImpactGroup({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.type,
    required this.title,
    required this.story,
    required this.beneficiaryCount,
    required this.needs,
    required this.imageUrls,
    required this.updates,
    this.linkedPostId,
    this.consentConfirmed = false,
    this.totalRaised = 0,
    required this.createdAt,
  });

  factory ImpactGroup.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ImpactGroup(
      id: doc.id,
      ngoId: m['ngoId'] ?? '',
      ngoName: m['ngoName'] ?? '',
      type: ImpactGroupType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => ImpactGroupType.general,
      ),
      title: m['title'] ?? '',
      story: m['story'] ?? '',
      beneficiaryCount: m['beneficiaryCount'] ?? 0,
      needs: List<String>.from(m['needs'] ?? []),
      imageUrls: List<String>.from(m['imageUrls'] ?? []),
      updates: (m['updates'] as List<dynamic>? ?? [])
          .map((e) => ImpactUpdate.fromMap(e as Map<String, dynamic>))
          .toList(),
      linkedPostId: m['linkedPostId'],
      consentConfirmed: m['consentConfirmed'] ?? false,
      totalRaised: (m['totalRaised'] ?? 0).toDouble(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ngoId': ngoId,
    'ngoName': ngoName,
    'type': type.name,
    'title': title,
    'story': story,
    'beneficiaryCount': beneficiaryCount,
    'needs': needs,
    'imageUrls': imageUrls,
    'updates': updates.map((u) => u.toMap()).toList(),
    if (linkedPostId != null) 'linkedPostId': linkedPostId,
    'consentConfirmed': consentConfirmed,
    'totalRaised': totalRaised,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
