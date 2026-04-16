import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role; // 'donor' | 'volunteer' | 'ngo' | 'admin' | 'manager'
  final String? photoUrl;
  final String? phone;
  final String? address;
  final String? bio;

  // NGO-specific
  final String? orgName;
  final String? regNumber;
  final String? orgLogoUrl;
  final bool ngoVerified;
  final String? verificationStatus; // 'pending' | 'approved' | 'rejected'

  // Donor-specific
  final int totalDonations;
  final double totalMonetaryDonated;

  // Volunteer-specific
  final int rewardPoints;
  final int activitiesJoined;
  final List<String> badges;

  // Metadata
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.phone,
    this.address,
    this.bio,
    this.orgName,
    this.regNumber,
    this.orgLogoUrl,
    this.ngoVerified = false,
    this.verificationStatus,
    this.totalDonations = 0,
    this.totalMonetaryDonated = 0,
    this.rewardPoints = 0,
    this.activitiesJoined = 0,
    this.badges = const [],
    this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      role: m['role'] ?? 'donor',
      photoUrl: m['photoUrl'],
      phone: m['phone'],
      address: m['address'],
      bio: m['bio'],
      orgName: m['orgName'],
      regNumber: m['regNumber'],
      orgLogoUrl: m['orgLogoUrl'],
      ngoVerified: m['ngoVerified'] ?? false,
      verificationStatus: m['verificationStatus'],
      totalDonations: m['totalDonations'] ?? 0,
      totalMonetaryDonated: (m['totalMonetaryDonated'] as num?)?.toDouble() ?? 0,
      rewardPoints: m['rewardPoints'] ?? 0,
      activitiesJoined: m['activitiesJoined'] ?? 0,
      badges: List<String>.from(m['badges'] ?? []),
      createdAt: m['createdAt'] != null
          ? (m['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (bio != null) 'bio': bio,
        if (orgName != null) 'orgName': orgName,
        if (regNumber != null) 'regNumber': regNumber,
        if (orgLogoUrl != null) 'orgLogoUrl': orgLogoUrl,
        'ngoVerified': ngoVerified,
        if (verificationStatus != null) 'verificationStatus': verificationStatus,
        'totalDonations': totalDonations,
        'totalMonetaryDonated': totalMonetaryDonated,
        'rewardPoints': rewardPoints,
        'activitiesJoined': activitiesJoined,
        'badges': badges,
        'createdAt': FieldValue.serverTimestamp(),
      };

  UserProfile copyWith({
    String? name,
    String? phone,
    String? address,
    String? bio,
    String? photoUrl,
    String? orgName,
    String? regNumber,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      orgName: orgName ?? this.orgName,
      regNumber: regNumber ?? this.regNumber,
      orgLogoUrl: orgLogoUrl,
      ngoVerified: ngoVerified,
      verificationStatus: verificationStatus,
      totalDonations: totalDonations,
      totalMonetaryDonated: totalMonetaryDonated,
      rewardPoints: rewardPoints,
      activitiesJoined: activitiesJoined,
      badges: badges,
      createdAt: createdAt,
    );
  }
}
