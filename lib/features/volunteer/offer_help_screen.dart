import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/volunteer_service.dart';
import '../../services/user_service.dart';

/// Shown when a volunteer taps to offer help for an activity/event.
class OfferHelpScreen extends StatefulWidget {
  final String postId;
  final String postTitle;
  final String ngoId;
  final String ngoName;

  const OfferHelpScreen({
    super.key,
    required this.postId,
    required this.postTitle,
    required this.ngoId,
    required this.ngoName,
  });

  @override
  State<OfferHelpScreen> createState() => _OfferHelpScreenState();
}

class _OfferHelpScreenState extends State<OfferHelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _availabilityController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final uid = AuthService.instance.currentUser?.uid ?? '';
      final profile = await UserService.getProfile(uid);

      // Join the event through VolunteerService (awards points + notifications)
      await VolunteerService.joinActivity(
          widget.postId, uid, widget.ngoId);

      // Also record the offer message in Firestore
      await FirebaseFirestore.instance
          .collection('volunteer_offers')
          .add({
        'postId': widget.postId,
        'volunteerId': uid,
        'volunteerName': profile?.name ?? 'Unknown',
        'message': _messageController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        elevation: 0,
        title: const Text('Offer Help'),
        iconTheme: const IconThemeData(color: AidColors.textPrimary),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AidColors.volunteerAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volunteer_activism_rounded,
                  size: 40, color: AidColors.volunteerAccent),
            ),
            const Gap(24),
            Text('You\'re in!',
                style: AidTextStyles.heading.copyWith(color: AidColors.volunteerAccent)),
            const Gap(12),
            Text(
              'You\'ve joined this activity. You earned 10 reward points! The NGO will be in touch.',
              style: AidTextStyles.body.copyWith(color: AidColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.volunteerAccent,
                  side: const BorderSide(color: AidColors.volunteerAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Events'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AidColors.volunteerAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AidColors.volunteerAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Volunteering for',
                      style: AidTextStyles.caption
                          .copyWith(color: AidColors.volunteerAccent)),
                  const Gap(6),
                  Text(widget.postTitle,
                      style: AidTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text('by ${widget.ngoName}',
                      style: AidTextStyles.caption
                          .copyWith(color: AidColors.textMuted)),
                ],
              ),
            ),
            const Gap(28),

            // Reward info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AidColors.volunteerAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AidColors.volunteerAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AidColors.volunteerAccent, size: 18),
                  const Gap(8),
                  Text(
                    'You\'ll earn +10 reward points for joining!',
                    style: AidTextStyles.bodySm
                        .copyWith(color: AidColors.volunteerAccent),
                  ),
                ],
              ),
            ),
            const Gap(24),

            TextFormField(
              controller: _messageController,
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please add a message' : null,
              decoration: const InputDecoration(
                labelText: 'Why do you want to help?',
                hintText: 'Tell the NGO about yourself and your skills...',
                alignLabelWithHint: true,
              ),
            ),
            const Gap(16),

            TextFormField(
              controller: _availabilityController,
              decoration: const InputDecoration(
                labelText: 'Availability (optional)',
                hintText: 'e.g. Weekends, 9am-1pm',
                prefixIcon: Icon(Icons.access_time_rounded, size: 20),
              ),
            ),
            const Gap(32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AidColors.volunteerAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Join & Submit Offer',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
