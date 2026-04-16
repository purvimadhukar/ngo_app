import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../features/auth/login_screen.dart';
import '../features/ngo/ngo_dashboard.dart';
import '../features/donor/donor_dashboard.dart';
import '../features/volunteer/volunteer_dashboard.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/manager/manager_dashboard.dart';

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
              default:
                return _ErrorScaffold(
                  message: 'Unknown role: "${roleSnap.data}". Must be ngo, donor, volunteer, admin, or manager.',
                  onSignOut: () => AuthService.instance.signOut(),
                );
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
    if (!doc.exists) throw Exception('User document not found for uid=$uid');
    final role = doc.data()?['role'] as String?;
    if (role == null || role.isEmpty) throw Exception('Role not set for uid=$uid');
    return role;
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
