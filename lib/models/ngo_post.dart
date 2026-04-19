import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { donation, activity, emergency }
enum PostStatus { pending, active, fulfilled, cancelled }

class RequiredItem {
  final String name;       // e.g. "Rice", "Winter clothes", "Funds"
  final String unit;       // e.g. "kg", "pieces", "INR"
  final double targetQty;
  final double fulfilledQty;

  RequiredItem({
    required this.name,
    required this.unit,
    required this.targetQty,
    this.fulfilledQty = 0,
  });

  factory RequiredItem.fromMap(Map<String, dynamic> m) => RequiredItem(
        name: m['name'] ?? '',
        unit: m['unit'] ?? '',
        targetQty: (m['targetQty'] ?? 0).toDouble(),
        fulfilledQty: (m['fulfilledQty'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'unit': unit,
        'targetQty': targetQty,
        'fulfilledQty': fulfilledQty,
      };

  double get progressPercent =>
      targetQty > 0 ? (fulfilledQty / targetQty).clamp(0.0, 1.0) : 0;
}

class EventDetails {
  final DateTime eventDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final int volunteersNeeded;
  final int volunteersJoined;
  final String contactName;
  final String contactPhone;

  EventDetails({
    required this.eventDate,
    required this.location,
    this.latitude,
    this.longitude,
    required this.volunteersNeeded,
    this.volunteersJoined = 0,
    required this.contactName,
    required this.contactPhone,
  });

  factory EventDetails.fromMap(Map<String, dynamic> m) => EventDetails(
        eventDate: (m['eventDate'] as Timestamp).toDate(),
        location: m['location'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        volunteersNeeded: m['volunteersNeeded'] ?? 0,
        volunteersJoined: m['volunteersJoined'] ?? 0,
        contactName: m['contactName'] ?? '',
        contactPhone: m['contactPhone'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'eventDate': Timestamp.fromDate(eventDate),
        'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'volunteersNeeded': volunteersNeeded,
        'volunteersJoined': volunteersJoined,
        'contactName': contactName,
        'contactPhone': contactPhone,
      };
}

class NgoPost {
  final String id;
  final String ngoId;
  final String ngoName;
  final bool ngoVerified;

  final String title;
  final String description;
  final String category;         // auto-tagged: food, medical, education, clothes, funds
  final PostType type;
  final PostStatus status;

  final List<String> mediaUrls;   // Firebase Storage download URLs
  final List<String> proofUrls;   // Post-event proof photos
  final List<RequiredItem> requiredItems;
  final EventDetails? eventDetails; // null if type == donation

  final DateTime createdAt;
  final DateTime? updatedAt;

  // Fundraising goal
  final double targetAmount;      // monetary goal in ₹ (0 = no target set)
  final double raisedAmount;      // total ₹ raised so far

  // ML fields
  final double urgencyScore;      // 0.0 – 1.0, set by ML or manually
  final bool flaggedForReview;    // fraud detection flag

  NgoPost({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.ngoVerified,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.status,
    required this.mediaUrls,
    required this.proofUrls,
    required this.requiredItems,
    this.eventDetails,
    required this.createdAt,
    this.updatedAt,
    this.targetAmount = 0,
    this.raisedAmount = 0,
    this.urgencyScore = 0.5,
    this.flaggedForReview = false,
  });

  factory NgoPost.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return NgoPost(
      id: doc.id,
      ngoId: m['ngoId'] ?? '',
      ngoName: m['ngoName'] ?? '',
      ngoVerified: m['ngoVerified'] ?? false,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      category: m['category'] ?? 'general',
      type: PostType.values.firstWhere(
        (e) => e.name == m['type'],
        orElse: () => PostType.donation,
      ),
      status: PostStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => PostStatus.active,
      ),
      mediaUrls: List<String>.from(m['mediaUrls'] ?? []),
      proofUrls: List<String>.from(m['proofUrls'] ?? []),
      requiredItems: (m['requiredItems'] as List<dynamic>? ?? [])
          .map((e) => RequiredItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      eventDetails: m['eventDetails'] != null
          ? EventDetails.fromMap(m['eventDetails'] as Map<String, dynamic>)
          : null,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
      targetAmount: (m['targetAmount'] ?? 0).toDouble(),
      raisedAmount: (m['raisedAmount'] ?? 0).toDouble(),
      urgencyScore: (m['urgencyScore'] ?? 0.5).toDouble(),
      flaggedForReview: m['flaggedForReview'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ngoId': ngoId,
        'ngoName': ngoName,
        'ngoVerified': ngoVerified,
        'title': title,
        'description': description,
        'category': category,
        'type': type.name,
        'status': status.name,
        'mediaUrls': mediaUrls,
        'proofUrls': proofUrls,
        'requiredItems': requiredItems.map((e) => e.toMap()).toList(),
        if (eventDetails != null) 'eventDetails': eventDetails!.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'targetAmount': targetAmount,
        'raisedAmount': raisedAmount,
        'urgencyScore': urgencyScore,
        'flaggedForReview': flaggedForReview,
        'donationCount': 0,
      };

  NgoPost copyWith({
    PostStatus? status,
    List<String>? proofUrls,
    List<RequiredItem>? requiredItems,
    double? urgencyScore,
    bool? flaggedForReview,
  }) =>
      NgoPost(
        id: id,
        ngoId: ngoId,
        ngoName: ngoName,
        ngoVerified: ngoVerified,
        title: title,
        description: description,
        category: category,
        type: type,
        status: status ?? this.status,
        mediaUrls: mediaUrls,
        proofUrls: proofUrls ?? this.proofUrls,
        requiredItems: requiredItems ?? this.requiredItems,
        eventDetails: eventDetails,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        urgencyScore: urgencyScore ?? this.urgencyScore,
        flaggedForReview: flaggedForReview ?? this.flaggedForReview,
      );
}