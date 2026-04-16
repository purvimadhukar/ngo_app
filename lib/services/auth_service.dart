import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the three roles a user can hold in AidBridge.
enum UserRole { ngo, donor, volunteer }

/// Thin wrapper around FirebaseAuth + Firestore.
///
/// Responsibilities:
///   • sign in / sign out
///   • fetch the user's role from Firestore (`users/{uid}.role`)
///   • expose a stream so the UI can react to auth-state changes
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth state ──────────────────────────────────────────────────────────────

  /// Emits a [User?] every time the auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Sign in ─────────────────────────────────────────────────────────────────

  /// Signs in with email + password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  // ── Sign out ────────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ── Role ────────────────────────────────────────────────────────────────────

  /// Returns the [UserRole] stored in Firestore for [uid].
  ///
  /// Expected Firestore document shape:
  /// ```
  /// users/{uid} {
  ///   role: "ngo" | "donor" | "volunteer",
  ///   ...
  /// }
  /// ```
  Future<UserRole> fetchRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('User document not found for uid=$uid');
    }

    final raw = doc.data()?['role'] as String?;
    return _parseRole(raw);
  }

  /// Same as [fetchRole] but uses the currently signed-in user.
  Future<UserRole> fetchCurrentUserRole() async {
    final uid = currentUser?.uid;
    if (uid == null) throw Exception('No user is currently signed in.');
    return fetchRole(uid);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  UserRole _parseRole(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'ngo':
        return UserRole.ngo;
      case 'donor':
        return UserRole.donor;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        throw Exception('Unknown role value in Firestore: "$raw"');
    }
  }
}