import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/donation.dart';
import '../../services/auth_service.dart';
import '../../services/donation_service.dart';
import '../../services/user_service.dart';

/// Shown when a donor taps on a request post to make a donation.
class OfferDonationScreen extends StatefulWidget {
  /// Pass the Firestore document ID of the NGO post (request).
  final String? postId;
  final String? postTitle;
  final String? ngoId;
  final String? ngoName;

  const OfferDonationScreen({
    super.key,
    this.postId,
    this.postTitle,
    this.ngoId,
    this.ngoName,
  });

  @override
  State<OfferDonationScreen> createState() => _OfferDonationScreenState();
}

class _OfferDonationScreenState extends State<OfferDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _goodsController = TextEditingController();
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();

  DonationType _selectedType = DonationType.monetary;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _amountController.dispose();
    _goodsController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final uid = AuthService.instance.currentUser?.uid ?? '';
      final profile = await UserService.getProfile(uid);

      final donation = Donation(
        id: '',
        donorId: uid,
        donorName: profile?.name ?? 'Anonymous',
        ngoId: widget.ngoId,
        ngoName: widget.ngoName,
        postId: widget.postId,
        type: _selectedType,
        status: DonationStatus.pending,
        monetaryAmount: _selectedType == DonationType.monetary
            ? double.tryParse(_amountController.text.trim())
            : null,
        goodsDescription: _selectedType != DonationType.monetary
            ? _goodsController.text.trim()
            : null,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        pickupAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        createdAt: DateTime.now(),
      );

      await DonationService.submitDonation(donation);

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
        title: const Text('Make a Donation'),
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
                color: AidColors.donorAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  size: 40, color: AidColors.donorAccent),
            ),
            const Gap(24),
            Text('Thank You!',
                style: AidTextStyles.heading.copyWith(color: AidColors.donorAccent)),
            const Gap(12),
            Text(
              'Your donation has been submitted. The NGO will confirm receipt and get in touch.',
              style: AidTextStyles.body.copyWith(color: AidColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AidColors.donorAccent,
                  side: const BorderSide(color: AidColors.donorAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back'),
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
            // Context banner
            if (widget.postTitle != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AidColors.donorAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AidColors.donorAccent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Donating toward',
                        style: AidTextStyles.caption
                            .copyWith(color: AidColors.donorAccent)),
                    const Gap(6),
                    Text(widget.postTitle!,
                        style:
                            AidTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    if (widget.ngoName != null)
                      Text('by ${widget.ngoName}',
                          style: AidTextStyles.caption
                              .copyWith(color: AidColors.textMuted)),
                  ],
                ),
              ),
            const Gap(24),

            // Donation type chips
            Text('What are you donating?',
                style: AidTextStyles.caption
                    .copyWith(color: AidColors.textMuted, letterSpacing: 0.5)),
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DonationType.values.map((t) {
                final selected = t == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AidColors.donorAccent
                          : AidColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AidColors.donorAccent
                            : AidColors.borderDefault,
                      ),
                    ),
                    child: Text(
                      _typeLabel(t),
                      style: AidTextStyles.caption.copyWith(
                        color: selected ? Colors.white : AidColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(24),

            if (_selectedType == DonationType.monetary) ...[
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'e.g. 500',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _goodsController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please describe what you\'re donating' : null,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. 5 kg rice, winter clothes (sizes S-M)',
                  prefixIcon: const Icon(Icons.description_outlined, size: 20),
                ),
              ),
            ],
            const Gap(16),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Pickup Address (optional)',
                hintText: 'Where can the NGO collect from?',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
            ),
            const Gap(16),

            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Any additional details...',
                alignLabelWithHint: true,
              ),
            ),
            const Gap(32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AidColors.donorAccent,
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
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Donation',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(DonationType t) {
    switch (t) {
      case DonationType.monetary:
        return 'Money';
      case DonationType.food:
        return 'Food';
      case DonationType.clothes:
        return 'Clothes';
      case DonationType.groceries:
        return 'Groceries';
      case DonationType.medical:
        return 'Medical';
      case DonationType.education:
        return 'Education';
      case DonationType.other:
        return 'Other';
    }
  }
}
