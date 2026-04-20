import 'package:cloud_firestore/cloud_firestore.dart';

class Resident {
  final String id;
  final String name;
  final int age;
  final String gender;          // 'male' | 'female' | 'other'
  final String photoUrl;
  final String careHomeName;
  final String careHomeLocation;
  final String careHomeId;      // uid of the NGO who added them
  final String addedBy;
  final List<String> needs;     // ['medical','food','clothing','companionship','education','physiotherapy']
  final String story;
  final String urgency;         // 'normal' | 'urgent' | 'critical'
  final double monthlyTarget;   // 0 = no sponsorship target
  final double monthlyRaised;
  final int totalDonations;
  final int sponsorsCount;
  final DateTime createdAt;
  final bool isActive;

  const Resident({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.photoUrl,
    required this.careHomeName,
    required this.careHomeLocation,
    required this.careHomeId,
    required this.addedBy,
    required this.needs,
    required this.story,
    required this.urgency,
    required this.monthlyTarget,
    required this.monthlyRaised,
    required this.totalDonations,
    required this.sponsorsCount,
    required this.createdAt,
    required this.isActive,
  });

  factory Resident.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Resident(
      id:                doc.id,
      name:              d['name'] ?? '',
      age:               (d['age'] ?? 0) as int,
      gender:            d['gender'] ?? 'other',
      photoUrl:          d['photoUrl'] ?? '',
      careHomeName:      d['careHomeName'] ?? '',
      careHomeLocation:  d['careHomeLocation'] ?? '',
      careHomeId:        d['careHomeId'] ?? '',
      addedBy:           d['addedBy'] ?? '',
      needs:             List<String>.from(d['needs'] ?? []),
      story:             d['story'] ?? '',
      urgency:           d['urgency'] ?? 'normal',
      monthlyTarget:     (d['monthlyTarget'] ?? 0).toDouble(),
      monthlyRaised:     (d['monthlyRaised'] ?? 0).toDouble(),
      totalDonations:    (d['totalDonations'] ?? 0) as int,
      sponsorsCount:     (d['sponsorsCount'] ?? 0) as int,
      createdAt:         (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive:          d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':              name,
    'age':               age,
    'gender':            gender,
    'photoUrl':          photoUrl,
    'careHomeName':      careHomeName,
    'careHomeLocation':  careHomeLocation,
    'careHomeId':        careHomeId,
    'addedBy':           addedBy,
    'needs':             needs,
    'story':             story,
    'urgency':           urgency,
    'monthlyTarget':     monthlyTarget,
    'monthlyRaised':     monthlyRaised,
    'totalDonations':    totalDonations,
    'sponsorsCount':     sponsorsCount,
    'createdAt':         FieldValue.serverTimestamp(),
    'isActive':          isActive,
  };

  // Urgency color helper (used in UI)
  static const urgencyColors = {
    'normal':   0xFF2B8CE6,
    'urgent':   0xFFF0A500,
    'critical': 0xFFE8514A,
  };

  // Need icon helper
  static const needIcons = {
    'medical':       0xE548,  // medical_services
    'food':          0xE25A,  // restaurant
    'clothing':      0xE59C,  // checkroom
    'companionship': 0xE87D,  // favorite
    'education':     0xE80C,  // school
    'physiotherapy': 0xE1BC,  // self_improvement
    'shelter':       0xE88A,  // home
    'mental health': 0xF044,  // psychology
  };
}
