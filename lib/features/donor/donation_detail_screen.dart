import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';

class DonationDetailScreen extends StatefulWidget {
  final NgoPost post;
  const DonationDetailScreen({super.key, required this.post});

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  final _moneyCtrl = TextEditingController();

  // item index → quantity the donor is pledging
  late final Map<int, TextEditingController> _qtyControllers;

  bool _loading = false;
  bool _donated = false;
  int _currentImageIndex = 0;
  bool _includeMoney = false;

  NgoPost get post => widget.post;

  bool get _isDonation => post.type == PostType.donation;
  bool get _isActivity => post.type == PostType.activity;
  bool get _isEmergency => post.type == PostType.emergency;

  Color get _typeColor {
    if (_isEmergency) return AidColors.error;
    if (_isActivity) return AidColors.volunteerAccent;
    return AidColors.donorAccent;
  }

  String get _typeLabel {
    if (_isEmergency) return 'EMERGENCY';
    if (_isActivity) return 'VOLUNTEER EVENT';
    return 'DONATION DRIVE';
  }

  IconData get _typeIcon {
    if (_isEmergency) return Icons.warning_rounded;
    if (_isActivity) return Icons.volunteer_activism_rounded;
    return Icons.favorite_rounded;
  }

  @override
  void initState() {
    super.initState();
    _qtyControllers = {
      for (var i = 0; i < post.requiredItems.length; i++)
        i: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _moneyCtrl.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitDonation() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Build donated items list
    final List<Map<String, dynamic>> donatedItems = [];
    for (var i = 0; i < post.requiredItems.length; i++) {
      final qty = double.tryParse(_qtyControllers[i]?.text ?? '') ?? 0;
      if (qty > 0) {
        donatedItems.add({
          'name': post.requiredItems[i].name,
          'unit': post.requiredItems[i].unit,
          'quantity': qty,
        });
      }
    }

    final money = double.tryParse(_moneyCtrl.text) ?? 0;
    if (donatedItems.isEmpty && money == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least one item quantity or a monetary amount.'),
          backgroundColor: AidColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Write to posts/{id}/donations
      final donRef = db.collection('posts').doc(post.id).collection('donations').doc();
      batch.set(donRef, {
        'donorId': user.uid,
        'donorName': user.displayName ?? user.email ?? 'Anonymous',
        'donorEmail': user.email ?? '',
        'donatedItems': donatedItems,
        'monetaryAmount': money,
        'note': _noteCtrl.text.trim(),
        'status': 'pending',
        'donatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update fulfilledQty for each donated item in the post
      if (donatedItems.isNotEmpty) {
        final postRef = db.collection('posts').doc(post.id);
        // Increment each item's fulfilledQty
        for (var i = 0; i < post.requiredItems.length; i++) {
          final qty = double.tryParse(_qtyControllers[i]?.text ?? '') ?? 0;
          if (qty > 0) {
            // We'll update this separately since Firestore batch doesn't support array element updates well
          }
        }
        // Use a transaction for the requiredItems array update
        await db.runTransaction((tx) async {
          final snap = await tx.get(db.collection('posts').doc(post.id));
          if (!snap.exists) return;
          final data = snap.data()!;
          final items = List<Map<String, dynamic>>.from(
            (data['requiredItems'] as List<dynamic>? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map)),
          );
          for (var di in donatedItems) {
            final idx = items.indexWhere((item) => item['name'] == di['name']);
            if (idx != -1) {
              final current = (items[idx]['fulfilledQty'] ?? 0).toDouble();
              items[idx]['fulfilledQty'] = current + (di['quantity'] as double);
            }
          }
          tx.update(db.collection('posts').doc(post.id), {'requiredItems': items});
        });
      }

      // 3. Update donor user stats
      final userRef = db.collection('users').doc(user.uid);
      batch.update(userRef, {
        'totalDonations': FieldValue.increment(1),
        'totalMonetaryDonated': FieldValue.increment(money),
        'rewardPoints': FieldValue.increment(20),
      });

      await batch.commit();

      if (mounted) {
        setState(() {
          _loading = false;
          _donated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                Gap(8),
                Text('Donation submitted! +20 points earned 🎉'),
              ],
            ),
            backgroundColor: AidColors.donorAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AidColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Gap(20),
                    _buildDescription(),
                    if (_isDonation || _isEmergency) ...[
                      const Gap(24),
                      _buildItemsSection(),
                      const Gap(24),
                      _buildMoneySection(),
                    ],
                    if (_isActivity) ...[
                      const Gap(24),
                      _buildEventDetails(),
                    ],
                    const Gap(24),
                    _buildNoteField(),
                    if (_donated) ...[
                      const Gap(20),
                      _buildSuccessBanner(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: post.mediaUrls.isNotEmpty ? 280 : 120,
      pinned: true,
      backgroundColor: AidColors.background,
      foregroundColor: AidColors.textPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: post.mediaUrls.isNotEmpty
            ? _buildImageGallery()
            : Container(
                color: _typeColor.withValues(alpha: 0.1),
                child: Center(
                  child: Icon(_typeIcon, color: _typeColor, size: 64),
                ),
              ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: post.mediaUrls.length,
          onPageChanged: (i) => setState(() => _currentImageIndex = i),
          itemBuilder: (_, i) => Image.network(
            post.mediaUrls[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AidColors.surface,
              child: const Icon(Icons.image_not_supported, color: AidColors.textSecondary),
            ),
          ),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AidColors.background],
              ),
            ),
          ),
        ),
        // Page indicator dots
        if (post.mediaUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                post.mediaUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImageIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type badge + urgency
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_typeIcon, color: _typeColor, size: 12),
                  const Gap(4),
                  Text(
                    _typeLabel,
                    style: AidTextStyles.labelSm.copyWith(
                      color: _typeColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AidColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AidColors.borderDefault),
              ),
              child: Text(
                post.category.toUpperCase(),
                style: AidTextStyles.labelSm.copyWith(
                  color: AidColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            // Urgency dot
            if (post.urgencyScore > 0.7)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AidColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AidColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'URGENT',
                      style: AidTextStyles.labelSm.copyWith(
                        color: AidColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const Gap(14),

        // Title
        Text(post.title, style: AidTextStyles.displaySm),
        const Gap(8),

        // NGO info
        Row(
          children: [
            const Icon(Icons.business_rounded, size: 14, color: AidColors.textSecondary),
            const Gap(5),
            Text(
              post.ngoName,
              style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
            ),
            if (post.ngoVerified) ...[
              const Gap(4),
              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF80FFD0)),
            ],
            const Spacer(),
            Text(
              _timeAgo(post.createdAt),
              style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.borderDefault),
      ),
      child: Text(
        post.description,
        style: AidTextStyles.bodyMd.copyWith(
          color: AidColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    if (post.requiredItems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AidColors.donorAccent, size: 18),
            const Gap(8),
            Text('Items Needed', style: AidTextStyles.headingSm),
          ],
        ),
        const Gap(4),
        Text(
          'Enter how much you can donate for each item',
          style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
        ),
        const Gap(14),
        ...List.generate(post.requiredItems.length, (i) {
          final item = post.requiredItems[i];
          final progress = item.progressPercent;
          final remaining = (item.targetQty - item.fulfilledQty).clamp(0, item.targetQty);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AidColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AidColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AidTextStyles.bodyMd.copyWith(
                              color: AidColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            '${item.fulfilledQty.toInt()} / ${item.targetQty.toInt()} ${item.unit} collected',
                            style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    // Qty input
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _qtyControllers[i],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: item.unit,
                          hintStyle: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            final n = double.tryParse(v);
                            if (n == null || n < 0) return 'Invalid';
                            if (n > remaining.toDouble()) return 'Max: ${remaining.toInt()}';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AidColors.borderDefault,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: progress >= 1
                              ? AidColors.ngoAccent
                              : AidColors.donorAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  progress >= 1
                      ? '✅ Fully collected'
                      : '${(progress * 100).toInt()}% collected · ${remaining.toInt()} ${item.unit} still needed',
                  style: AidTextStyles.bodySm.copyWith(
                    color: progress >= 1 ? AidColors.ngoAccent : AidColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMoneySection() {
    return Container(
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.borderDefault),
      ),
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _includeMoney = !_includeMoney),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AidColors.donorAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.currency_rupee_rounded,
                        color: AidColors.donorAccent, size: 18),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monetary Donation', style: AidTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AidColors.textPrimary,
                        )),
                        Text('Send money directly to this cause',
                          style: AidTextStyles.bodySm.copyWith(color: AidColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeMoney,
                    onChanged: (v) => setState(() => _includeMoney = v),
                    activeColor: AidColors.donorAccent,
                  ),
                ],
              ),
            ),
          ),
          if (_includeMoney) ...[
            Divider(color: AidColors.borderDefault, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextFormField(
                controller: _moneyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'e.g. 500',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                ),
                validator: (v) {
                  if (_includeMoney) {
                    if (v == null || v.isEmpty) return 'Enter an amount';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    if (double.parse(v) <= 0) return 'Must be greater than 0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    final ev = post.eventDetails;
    if (ev == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.volunteerAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.volunteerAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Details', style: AidTextStyles.headingSm.copyWith(color: AidColors.volunteerAccent)),
          const Gap(14),
          _evDetail(Icons.calendar_month_rounded,
              DateFormat('EEE, d MMM yyyy • h:mm a').format(ev.eventDate)),
          const Gap(10),
          _evDetail(Icons.location_on_rounded, ev.location),
          const Gap(10),
          _evDetail(Icons.people_rounded,
              '${ev.volunteersJoined} / ${ev.volunteersNeeded} volunteers joined'),
          const Gap(10),
          _evDetail(Icons.person_outlined, '${ev.contactName}  •  ${ev.contactPhone}'),
        ],
      ),
    );
  }

  Widget _evDetail(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AidColors.volunteerAccent, size: 16),
        const Gap(10),
        Expanded(
          child: Text(
            text,
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteCtrl,
      maxLines: 3,
      style: AidTextStyles.bodyMd.copyWith(color: AidColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Message to NGO (optional)',
        hintText: 'Add a note, special instructions, or a kind message…',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Icon(Icons.message_outlined, size: 18),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.ngoAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AidColors.ngoAccent, size: 24),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donation submitted!',
                  style: AidTextStyles.bodyMd.copyWith(
                    color: AidColors.ngoAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'The NGO has been notified and will confirm your donation.',
                  style: AidTextStyles.bodySm.copyWith(color: AidColors.ngoAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_donated) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AidColors.textPrimary,
                side: const BorderSide(color: AidColors.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Feed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reward teaser
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: AidColors.donorAccent, size: 16),
                const Gap(5),
                Text(
                  'Earn +20 reward points with this donation',
                  style: AidTextStyles.bodySm.copyWith(color: AidColors.donorAccent),
                ),
              ],
            ),
            const Gap(10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: AidColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  disabledBackgroundColor: _typeColor.withValues(alpha: 0.4),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_typeIcon, size: 18),
                          const Gap(8),
                          Text(
                            _isActivity ? 'Register as Volunteer' : 'Submit Donation',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
