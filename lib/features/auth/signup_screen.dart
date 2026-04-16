import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Step 1 controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Step 2 (NGO only)
  final _orgNameCtrl = TextEditingController();
  final _regNumberCtrl = TextEditingController();
  final _orgBioCtrl = TextEditingController();

  String _role = 'donor';
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  int _currentStep = 0;

  // Role accent colours
  static const _roleColors = {
    'donor': AidColors.donorAccent,
    'volunteer': AidColors.volunteerAccent,
    'ngo': AidColors.ngoAccent,
  };

  Color get _accent => _roleColors[_role] ?? AidColors.ngoAccent;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _orgNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _orgBioCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    UserCredential? cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      await cred.user?.updateDisplayName(_nameCtrl.text.trim());

      final Map<String, dynamic> userData = {
        'email': _emailCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'role': _role,
        'phone': _phoneCtrl.text.trim(),
        'ngoVerified': false,
        'totalDonations': 0,
        'totalMonetaryDonated': 0,
        'rewardPoints': 0,
        'activitiesJoined': 0,
        'badges': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_role == 'ngo') {
        userData['orgName'] = _orgNameCtrl.text.trim();
        userData['regNumber'] = _regNumberCtrl.text.trim();
        userData['bio'] = _orgBioCtrl.text.trim();
        userData['verificationStatus'] = 'unsubmitted';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set(userData);

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // Firestore write failed — delete the Auth account so user can retry cleanly
      await cred?.user?.delete();
      setState(() => _error = 'Account setup failed. Please try again. ($e)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nextStep() {
    if (_role == 'ngo' && _currentStep == 0) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  bool get _isNgoStep2 => _role == 'ngo' && _currentStep == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AidColors.textPrimary,
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1(),
            _buildStep2NGO(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create account', style: AidTextStyles.displaySm),
          const Gap(6),
          Text(
            'Join AidBridge and start making a difference.',
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
          ),
          const Gap(32),

          // Role selector
          Text('I am a...', style: AidTextStyles.labelMd.copyWith(color: AidColors.textSecondary)),
          const Gap(12),
          Row(
            children: [
              _RoleChip(
                label: 'Donor',
                icon: Icons.favorite_rounded,
                color: AidColors.donorAccent,
                selected: _role == 'donor',
                onTap: () => setState(() => _role = 'donor'),
              ),
              const Gap(10),
              _RoleChip(
                label: 'Volunteer',
                icon: Icons.volunteer_activism_rounded,
                color: AidColors.volunteerAccent,
                selected: _role == 'volunteer',
                onTap: () => setState(() => _role = 'volunteer'),
              ),
              const Gap(10),
              _RoleChip(
                label: 'NGO',
                icon: Icons.business_rounded,
                color: AidColors.ngoAccent,
                selected: _role == 'ngo',
                onTap: () => setState(() => _role = 'ngo'),
              ),
            ],
          ),
          const Gap(28),

          _field(
            controller: _nameCtrl,
            label: _role == 'ngo' ? 'Contact Person Name' : 'Full Name',
            hint: 'Your name',
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const Gap(16),
          _field(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const Gap(16),
          _field(
            controller: _phoneCtrl,
            label: 'Phone Number',
            hint: '+91 98765 43210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Min. 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                color: AidColors.textSecondary,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_error != null) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AidColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AidColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AidColors.error, size: 18),
                  const Gap(8),
                  Expanded(
                    child: Text(_error!, style: AidTextStyles.bodySm.copyWith(color: AidColors.error)),
                  ),
                ],
              ),
            ),
          ],
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AidColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _role == 'ngo' ? 'Next: Organisation Details →' : 'Create Account',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
          ),
          const Gap(24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: AidTextStyles.bodySm.copyWith(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2NGO() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(
            children: [
              _StepDot(active: false, color: _accent),
              const Gap(6),
              _StepDot(active: true, color: _accent),
            ],
          ),
          const Gap(20),
          Text('Organisation Details', style: AidTextStyles.displaySm),
          const Gap(6),
          Text(
            'Tell us about your NGO so donors can find you.',
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
          ),
          const Gap(32),

          _field(
            controller: _orgNameCtrl,
            label: 'Organisation Name',
            hint: 'e.g. Helping Hands Foundation',
            icon: Icons.business_outlined,
            validator: _isNgoStep2
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
          ),
          const Gap(16),
          _field(
            controller: _regNumberCtrl,
            label: 'Registration Number',
            hint: 'Government registration / trust number',
            icon: Icons.numbers_rounded,
            validator: _isNgoStep2
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
          ),
          const Gap(16),
          TextFormField(
            controller: _orgBioCtrl,
            maxLines: 4,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'About your NGO',
              hintText: 'What does your organisation do? Who do you help?',
              alignLabelWithHint: true,
            ),
          ),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AidColors.ngoAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AidColors.ngoAccent, size: 18),
                const Gap(10),
                Expanded(
                  child: Text(
                    'Your account will be pending verification. You can submit documents from your dashboard after signing up.',
                    style: AidTextStyles.bodySm.copyWith(color: AidColors.ngoAccent),
                  ),
                ),
              ],
            ),
          ),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AidColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Create NGO Account',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AidColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AidColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AidColors.textSecondary, size: 22),
            const Gap(4),
            Text(
              label,
              style: AidTextStyles.labelSm.copyWith(
                color: selected ? color : AidColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final Color color;
  const _StepDot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : AidColors.borderDefault,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
