import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';

class NgoVerificationScreen extends StatefulWidget {
  const NgoVerificationScreen({super.key});

  @override
  State<NgoVerificationScreen> createState() => _NgoVerificationScreenState();
}

class _NgoVerificationScreenState extends State<NgoVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameCtrl = TextEditingController();
  final _regNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _existingStatus;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('verifications')
        .where('ngoId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      final data = snap.docs.first.data();
      setState(() {
        _existingStatus = data['status'] ?? 'pending';
        _orgNameCtrl.text = data['orgName'] ?? '';
        _regNumberCtrl.text = data['regNumber'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _websiteCtrl.text = data['website'] ?? '';
        _descCtrl.text = data['description'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final db = FirebaseFirestore.instance;

      // Delete existing if rejected
      if (_existingStatus == 'rejected') {
        final snap = await db.collection('verifications')
            .where('ngoId', isEqualTo: uid)
            .limit(1)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }

      await db.collection('verifications').add({
        'ngoId': uid,
        'orgName': _orgNameCtrl.text.trim(),
        'regNumber': _regNumberCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Update user doc
      await db.collection('users').doc(uid).update({'verificationStatus': 'pending'});

      if (mounted) setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        title: Text('NGO Verification', style: AidTextStyles.headingMd),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AidColors.ngoAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined, size: 48, color: AidColors.ngoAccent),
            ),
            const Gap(24),
            Text('Application Submitted!', style: AidTextStyles.headingLg, textAlign: TextAlign.center),
            const Gap(12),
            Text(
              'Our team will review your information and verify your NGO within 2–5 business days. You\'ll be notified once approved.',
              style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.ngoAccent,
                  side: const BorderSide(color: AidColors.ngoAccent),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isPending = _existingStatus == 'pending';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Status banner
        if (_existingStatus != null) ...[
          _StatusBanner(status: _existingStatus!),
          const Gap(20),
        ],

        if (!isPending) ...[
          // What verification means
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AidColors.ngoAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why verify?', style: AidTextStyles.headingMd.copyWith(color: AidColors.ngoAccent)),
                const Gap(8),
                ...[
                  '✓ Blue verified badge on all your posts',
                  '✓ Show up in the donor feed (unverified posts are hidden)',
                  '✓ Build trust with donors and volunteers',
                  '✓ Access to advanced analytics',
                ].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(s, style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary)),
                )),
              ],
            ),
          ),
          const Gap(24),

          Text('Organisation Details', style: AidTextStyles.headingMd),
          const Gap(16),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Organisation Name *'),
                const Gap(8),
                _Field(
                  controller: _orgNameCtrl,
                  hint: 'Registered name of your NGO',
                  icon: Icons.business_outlined,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const Gap(16),

                _Label('Registration Number *'),
                const Gap(8),
                _Field(
                  controller: _regNumberCtrl,
                  hint: 'Government registration / trust deed number',
                  icon: Icons.numbers_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const Gap(16),

                _Label('Office Address'),
                const Gap(8),
                _Field(
                  controller: _addressCtrl,
                  hint: 'Full address of your registered office',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const Gap(16),

                _Label('Website / Social Media'),
                const Gap(8),
                _Field(
                  controller: _websiteCtrl,
                  hint: 'https://yourngoo.org or Instagram link',
                  icon: Icons.language_outlined,
                ),
                const Gap(16),

                _Label('About Your NGO *'),
                const Gap(8),
                _Field(
                  controller: _descCtrl,
                  hint: 'Describe your mission, work areas, and number of beneficiaries served...',
                  maxLines: 4,
                  validator: (v) => v!.trim().length < 30 ? 'Please write at least 30 characters' : null,
                ),
                const Gap(12),

                // Document note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AidColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AidColors.info.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AidColors.info, size: 18),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'After submitting, our team may contact you via email to request registration certificates or 80G documents for verification.',
                          style: AidTextStyles.bodyMd.copyWith(color: AidColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AidColors.ngoAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _existingStatus == 'rejected' ? 'Re-submit Application' : 'Submit for Verification',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                  ),
                ),
                const Gap(40),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';
    final color = isPending ? AidColors.warning : isRejected ? AidColors.error : AidColors.success;
    final icon = isPending ? Icons.hourglass_top_rounded : isRejected ? Icons.cancel_rounded : Icons.verified_rounded;
    final msg = isPending
        ? 'Your application is under review. We\'ll notify you when it\'s approved.'
        : isRejected
            ? 'Your application was rejected. Please review and re-submit with accurate information.'
            : 'Your NGO is verified!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'Under Review' : isRejected ? 'Rejected' : 'Verified',
                  style: AidTextStyles.headingSm.copyWith(color: color),
                ),
                const Gap(2),
                Text(msg, style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted, letterSpacing: 0.3),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: AidTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
          prefixIcon: maxLines == 1 && icon != null
              ? Icon(icon, size: 18, color: AidColors.textMuted)
              : null,
          filled: true,
          fillColor: AidColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AidColors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AidColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AidColors.ngoAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AidColors.error),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
        ),
      );
}