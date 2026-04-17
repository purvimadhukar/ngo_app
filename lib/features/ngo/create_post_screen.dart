import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _locationCtrl     = TextEditingController();
  final _contactNameCtrl  = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _volunteersCtrl   = TextEditingController(text: '10');

  PostType _postType  = PostType.donation;
  String   _category  = 'food';
  double   _urgency   = 0.5;
  bool     _loading   = false;
  String   _loadingMsg = 'Publishing…';

  final List<XFile>    _selectedMedia  = [];
  final List<Uint8List> _previewBytes  = [];
  final List<_ItemEntry> _items        = [];
  DateTime? _eventDate;

  final _categories = ['food', 'clothes', 'medical', 'education', 'funds', 'other'];
  final _picker     = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _locationCtrl.dispose();
    _contactNameCtrl.dispose(); _contactPhoneCtrl.dispose(); _volunteersCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final files = await _picker.pickMultiImage(imageQuality: 75);
    for (final f in files) {
      final bytes = await f.readAsBytes();
      setState(() { _selectedMedia.add(f); _previewBytes.add(bytes); });
    }
  }

  void _addItem() => setState(() => _items.add(_ItemEntry()));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_postType == PostType.activity && _eventDate == null) {
      _snack('Please pick an event date', AidColors.warning);
      return;
    }
    if (_items.isEmpty && _postType == PostType.donation) {
      _snack('Add at least one item you need', AidColors.warning);
      return;
    }

    setState(() { _loading = true; _loadingMsg = 'Saving post…'; });
    try {
      final user = AuthService.instance.currentUser!;

      // Try image upload — if it fails (CORS/Storage rules), post without images
      List<String> mediaUrls = [];
      if (_selectedMedia.isNotEmpty) {
        if (mounted) setState(() => _loadingMsg = 'Uploading images…');
        try {
          mediaUrls = await Future.wait(
            _selectedMedia.map((f) => PostService.uploadMedia(f, user.uid)),
          ).timeout(const Duration(seconds: 30));
        } catch (uploadErr) {
          // Image upload failed — continue posting without images
          mediaUrls = [];
          if (mounted) setState(() => _loadingMsg = 'Saving post (no images)…');
        }
      }

      if (mounted) setState(() => _loadingMsg = 'Saving post…');

      // Get NGO name from Firestore profile
      String ngoName = user.displayName ?? 'NGO';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        ngoName = doc.data()?['orgName'] ?? doc.data()?['name'] ?? ngoName;
      } catch (_) {}

      final post = NgoPost(
        id: '',
        ngoId:      user.uid,
        ngoName:    ngoName,
        ngoVerified: false,
        title:       _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _category,
        type:        _postType,
        status:      PostStatus.active,
        mediaUrls:   mediaUrls,
        proofUrls:   [],
        requiredItems: _items
            .where((i) => i.nameCtrl.text.isNotEmpty)
            .map((i) => RequiredItem(
                  name:      i.nameCtrl.text.trim(),
                  unit:      i.unitCtrl.text.trim().isEmpty ? 'pcs' : i.unitCtrl.text.trim(),
                  targetQty: double.tryParse(i.qtyCtrl.text) ?? 1,
                ))
            .toList(),
        eventDetails: _postType == PostType.activity
            ? EventDetails(
                eventDate:        _eventDate!,
                location:         _locationCtrl.text.trim(),
                volunteersNeeded: int.tryParse(_volunteersCtrl.text) ?? 10,
                contactName:      _contactNameCtrl.text.trim(),
                contactPhone:     _contactPhoneCtrl.text.trim(),
              )
            : null,
        urgencyScore: _urgency,
        createdAt:   DateTime.now(),
      );

      await PostService.createPost(post);
      if (mounted) {
        _snack('Post published! 🎉', AidColors.success);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Failed to post: ${e.toString().substring(0, e.toString().length.clamp(0, 120))}', AidColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Color get _accentColor => _postType == PostType.donation
      ? AidColors.donorAccent
      : _postType == PostType.activity
          ? AidColors.volunteerAccent
          : AidColors.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.surface,
        foregroundColor: AidColors.textPrimary,
        elevation: 0,
        title: Text('New Post', style: AidTextStyles.headingMd),
        actions: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AidColors.ngoAccent)),
                  const Gap(8),
                  Text(_loadingMsg, style: AidTextStyles.labelMd.copyWith(color: AidColors.ngoAccent)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AidColors.ngoAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Post type ─────────────────────────────────────────────────────
            _sectionLabel('Post type'),
            Row(
              children: PostType.values.map((t) {
                final info = {
                  PostType.donation:  ('💜', 'Donation drive'),
                  PostType.activity:  ('🧡', 'Volunteer event'),
                  PostType.emergency: ('🔴', 'Emergency'),
                };
                final (emoji, label) = info[t]!;
                final selected = _postType == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _postType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? _accentColor.withValues(alpha: 0.12) : AidColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _accentColor : AidColors.borderDefault,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const Gap(4),
                          Text(label,
                              style: AidTextStyles.labelMd.copyWith(
                                color: selected ? _accentColor : AidColors.textMuted,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),

            // ── Category ──────────────────────────────────────────────────────
            _sectionLabel('Category'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _categories.map((c) {
                final selected = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AidColors.ngoAccent : AidColors.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? AidColors.ngoAccent : AidColors.borderDefault,
                      ),
                    ),
                    child: Text(
                      c[0].toUpperCase() + c.substring(1),
                      style: AidTextStyles.labelMd.copyWith(
                        color: selected ? Colors.white : AidColors.textMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),

            // ── Title & description ───────────────────────────────────────────
            _sectionLabel('Details'),
            _field(controller: _titleCtrl, label: 'Title *',
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const Gap(12),
            _field(controller: _descCtrl, label: 'Description *',
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const Gap(20),

            // ── Urgency ───────────────────────────────────────────────────────
            _sectionLabel('Urgency level'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AidColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AidColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Low', style: AidTextStyles.labelMd.copyWith(color: AidColors.success)),
                      Text(
                        _urgency >= 0.8 ? '🔴 URGENT' : _urgency >= 0.5 ? '🟡 MODERATE' : '🟢 LOW',
                        style: AidTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text('Urgent', style: AidTextStyles.labelMd.copyWith(color: AidColors.error)),
                    ],
                  ),
                  Slider(
                    value: _urgency,
                    onChanged: (v) => setState(() => _urgency = v),
                    activeColor: _urgency >= 0.8 ? AidColors.error : _urgency >= 0.5 ? AidColors.warning : AidColors.success,
                    inactiveColor: AidColors.elevated,
                  ),
                ],
              ),
            ),
            const Gap(20),

            // ── Media ─────────────────────────────────────────────────────────
            _sectionLabel('Photos'),
            if (_previewBytes.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _previewBytes.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_previewBytes[i],
                            width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedMedia.removeAt(i);
                            _previewBytes.removeAt(i);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Gap(8),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AidColors.ngoAccent),
              label: Text('Add photos',
                  style: AidTextStyles.labelMd.copyWith(color: AidColors.ngoAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AidColors.ngoAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Gap(20),

            // ── Items needed ──────────────────────────────────────────────────
            _sectionLabel('What do you need?'),
            ..._items.asMap().entries.map((e) => _ItemRow(
                  entry: e.value,
                  onRemove: () => setState(() => _items.removeAt(e.key)),
                )),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_outline, color: AidColors.ngoAccent),
              label: Text('Add item (food / clothes / rice…)',
                  style: AidTextStyles.labelMd.copyWith(color: AidColors.ngoAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AidColors.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Gap(20),

            // ── Event details ─────────────────────────────────────────────────
            if (_postType == PostType.activity) ...[
              _sectionLabel('Event details'),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      // ignore: use_build_context_synchronously
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && mounted) {
                      setState(() => _eventDate = DateTime(
                            date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AidColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _eventDate != null ? AidColors.volunteerAccent : AidColors.borderDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: _eventDate != null ? AidColors.volunteerAccent : AidColors.textMuted,
                          size: 18),
                      const Gap(10),
                      Text(
                        _eventDate == null
                            ? 'Pick date & time *'
                            : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}  ${_eventDate!.hour}:${_eventDate!.minute.toString().padLeft(2, '0')}',
                        style: AidTextStyles.bodyMd.copyWith(
                          color: _eventDate != null ? AidColors.textPrimary : AidColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              _field(
                controller: _locationCtrl,
                label: 'Location / address *',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => _postType == PostType.activity && v!.isEmpty ? 'Required' : null,
              ),
              const Gap(12),
              Row(children: [
                Expanded(child: _field(controller: _contactNameCtrl, label: 'Contact name')),
                const Gap(12),
                Expanded(child: _field(controller: _contactPhoneCtrl, label: 'Phone',
                    keyboardType: TextInputType.phone)),
              ]),
              const Gap(12),
              _field(
                controller: _volunteersCtrl,
                label: 'Volunteers needed',
                prefixIcon: Icons.people_outline_rounded,
                keyboardType: TextInputType.number,
              ),
              const Gap(20),
            ],

            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AidTextStyles.headingSm),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: AidTextStyles.bodyMd,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AidColors.textMuted, size: 18)
              : null,
          filled: true,
          fillColor: AidColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AidColors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AidColors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AidColors.ngoAccent, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
        ),
      );
}

// ─── Item Entry ───────────────────────────────────────────────────────────────

class _ItemEntry {
  final nameCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final qtyCtrl  = TextEditingController();
}

class _ItemRow extends StatelessWidget {
  final _ItemEntry entry;
  final VoidCallback onRemove;
  const _ItemRow({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AidColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AidColors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: entry.nameCtrl,
                  style: AidTextStyles.bodyMd,
                  decoration: _dec('Item (e.g. Rice)'),
                ),
              ),
              const Gap(8),
              Expanded(
                child: TextFormField(
                  controller: entry.qtyCtrl,
                  style: AidTextStyles.bodyMd,
                  decoration: _dec('Qty'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Gap(8),
              Expanded(
                child: TextFormField(
                  controller: entry.unitCtrl,
                  style: AidTextStyles.bodyMd,
                  decoration: _dec('Unit (kg)'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    size: 20, color: AidColors.error),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted),
        isDense: true,
        border: InputBorder.none,
      );
}
