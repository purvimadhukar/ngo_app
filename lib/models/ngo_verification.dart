// ─── model/ngo_verification.dart ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

enum VerificationStatus { pending, approved, rejected }

class NgoVerification {
  final String id;
  final String ngoId;
  final String orgName;
  final String regNumber;         // government registration number
  final List<String> docUrls;     // uploaded documents
  final VerificationStatus status;
  final String? adminNote;
  final DateTime submittedAt;

  NgoVerification({
    required this.id,
    required this.ngoId,
    required this.orgName,
    required this.regNumber,
    required this.docUrls,
    required this.status,
    this.adminNote,
    required this.submittedAt,
  });

  factory NgoVerification.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return NgoVerification(
      id: doc.id,
      ngoId: m['ngoId'] ?? '',
      orgName: m['orgName'] ?? '',
      regNumber: m['regNumber'] ?? '',
      docUrls: List<String>.from(m['docUrls'] ?? []),
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => VerificationStatus.pending,
      ),
      adminNote: m['adminNote'],
      submittedAt: (m['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ngoId': ngoId,
        'orgName': orgName,
        'regNumber': regNumber,
        'docUrls': docUrls,
        'status': status.name,
        if (adminNote != null) 'adminNote': adminNote,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };
}

// ─── service ─────────────────────────────────────────────────────────────────

class VerificationService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadDoc(XFile file, String ngoId) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref('verification/$ngoId/$name');
    final bytes = await file.readAsBytes();
    final task = await ref.putData(bytes);
    return await task.ref.getDownloadURL();
  }

  static Future<void> submitVerification({
    required String ngoId,
    required String orgName,
    required String regNumber,
    required List<String> docUrls,
  }) async {
    await _db.collection('verifications').add({
      'ngoId': ngoId,
      'orgName': orgName,
      'regNumber': regNumber,
      'docUrls': docUrls,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    // Update user doc to mark verification submitted
    await _db.collection('users').doc(ngoId).update({
      'verificationStatus': 'pending',
    });
  }

  static Stream<NgoVerification?> watchStatus(String ngoId) => _db
      .collection('verifications')
      .where('ngoId', isEqualTo: ngoId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : NgoVerification.fromFirestore(s.docs.first));

  /// Admin only: approve or reject
  static Future<void> updateVerification(
    String verificationId,
    VerificationStatus status, {
    String? note,
  }) async {
    await _db.collection('verifications').doc(verificationId).update({
      'status': status.name,
      if (note != null) 'adminNote': note,
    });
    if (status == VerificationStatus.approved) {
      final doc = await _db.collection('verifications').doc(verificationId).get();
      final ngoId = (doc.data() as Map)['ngoId'] as String;
      // Set ngoVerified = true on the user doc
      await _db.collection('users').doc(ngoId).update({'ngoVerified': true});
    }
  }
}