import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../services/auth_service.dart';
import '../features/auth/login_screen.dart';
import '../features/ngo/ngo_dashboard.dart';
import '../features/donor/donor_dashboard.dart';
import '../features/volunteer/volunteer_dashboard.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/manager/manager_dashboard.dart';
import '../features/care_home/care_home_dashboard.dart';

/// Listens to Firebase auth state and routes to the correct dashboard
/// based on the user's role: ngo | donor | volunteer | admin | manager
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<String>(
          future: _fetchRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold();
            }

            if (roleSnap.hasError || !roleSnap.hasData) {
              // Don't auto-signout — show error so user can see what's wrong
              return _ErrorScaffold(
                message: roleSnap.error?.toString() ?? 'Could not load role.',
                onSignOut: () => AuthService.instance.signOut(),
              );
            }

            switch (roleSnap.data!) {
              case 'ngo':
                return const NgoDashboard();
              case 'donor':
                return const DonorDashboard();
              case 'volunteer':
                return const VolunteerDashboard();
              case 'admin':
                return const AdminDashboard();
              case 'manager':
                return const ManagerDashboard();
              case 'careHome':
                return const CareHomeDashboard();
              case '__missing__':
                return _RolePickerScaffold(uid: user.uid, user: user);
              default:
                return _RolePickerScaffold(uid: user.uid, user: user);
            }
          },
        );
      },
    );
  }

  Future<String> _fetchRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return '__missing__';
    final role = doc.data()?['role'] as String?;
    if (role == null || role.isEmpty) return '__missing__';
    return role;
  }
}

// ── Role Picker (shown when Firestore doc is missing) ─────────────────────────

class _RolePickerScaffold extends StatefulWidget {
  final String uid;
  final User user;
  const _RolePickerScaffold({required this.uid, required this.user});

  @override
  State<_RolePickerScaffold> createState() => _RolePickerScaffoldState();
}

class _RolePickerScaffoldState extends State<_RolePickerScaffold> {
  String _role = 'donor';
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'email': widget.user.email ?? '',
      'name': widget.user.displayName ?? widget.user.email ?? 'User',
      'role': _role,
      'ngoVerified': false,
      'rewardPoints': 0,
      'activitiesJoined': 0,
      'badges': [],
      'totalDonations': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Auth state will auto-refresh and re-route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Welcome to AidBridge!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Gap(8),
              const Text('Choose your role to continue',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const Gap(32),
              _roleOption('donor', '💜', 'Donor', 'Donate food, clothes & more'),
              const Gap(12),
              _roleOption('volunteer', '🧡', 'Volunteer', 'Join activities & earn rewards'),
              const Gap(12),
              _roleOption('ngo', '💚', 'Organisation', 'NGO, care home, or welfare centre'),
              // Sub-options when Organisation is selected
              if (_role == 'ngo' || _role == 'careHome') ...[
                const Gap(10),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: [
                      _subOption('ngo', '🏢', 'NGO / Trust', 'Post drives & manage campaigns'),
                      const Gap(8),
                      _subOption('careHome', '🏠', 'Welfare Home', 'Old age home, shelter, care centre'),
                    ],
                  ),
                ),
              ],
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB884),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(16),
              TextButton(
                onPressed: () => AuthService.instance.signOut(),
                child: const Text('Sign out', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subOption(String value, String emoji, String label, String subtitle) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C3AED).withValues(alpha: 0.1) : const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFF2A2A30),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(String value, String emoji, String label, String subtitle) {
    final selected = _role == value || (value == 'ngo' && (_role == 'ngo' || _role == 'careHome'));
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1DB884).withValues(alpha: 0.1) : const Color(0xFF141416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1DB884) : const Color(0xFF222228),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFF1DB884)),
          ],
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB884)),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String? message;
  final VoidCallback? onSignOut;
  const _ErrorScaffold({this.message, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Could not load your account.',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Show full error so we can debug
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  message ?? 'Unknown error',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onSignOut ?? () => AuthService.instance.signOut(),
                child: const Text('Sign out & try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
