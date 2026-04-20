import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../models/resident.dart';

class AddResidentScreen extends StatefulWidget {
  final String careHomeId;
  final String careHomeName;
  final Resident? existing; // non-null = edit mode
  const AddResidentScreen({
    super.key,
    required this.careHomeId,
    required this.careHomeName,
    this.existing,
  });

  @override
  State<AddResidentScreen> createState() => _AddResidentScreenState();
}

class _AddResidentScreenState extends State<AddResidentScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _storyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _targetCtrl   = TextEditingController();

  int    _age       = 7;
  String _gender    = 'other';
  String _urgency   = 'normal';
  String _careHomeName = '';
  Uint8List? _photoBytes;
  bool   _uploading = false;
  String? _error;
  double _uploadProgress = 0;

  final Set<String> _selectedNeeds = {};

  static const _allNeeds = [
    ('medical',       Icons.medical_services_rounded,  'Medical Care'),
    ('food',          Icons.restaurant_rounded,         'Food & Nutrition'),
    ('clothing',      Icons.checkroom_rounded,          'Clothing'),
    ('companionship', Icons.favorite_rounded,           'Companionship'),
    ('education',     Icons.school_rounded,             'Education'),
    ('physiotherapy', Icons.self_improvement_rounded,   'Physiotherapy'),
    ('shelter',       Icons.home_rounded,               'Shelter'),
    ('mental health', Icons.psychology_rounded,         'Mental Health'),
  ];

  static const _urgencyOptions = [
    ('normal',   'Normal',   Color(0xFF2B8CE6)),
    ('urgent',   'Urgent',   Color(0xFFF0A500)),
    ('critical', 'Critical', Color(0xFFE8514A)),
  ];

  String? _existingPhotoUrl; // used in edit mode

  @override
  void initState() {
    super.initState();
    _careHomeName = widget.careHomeName;
    // Pre-fill fields if editing
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text     = e.name;
      _storyCtrl.text    = e.story;
      _locationCtrl.text = e.careHomeLocation;
      _targetCtrl.text   = e.monthlyTarget == 0 ? '' : e.monthlyTarget.toStringAsFixed(0);
      _age               = e.age;
      _gender            = e.gender;
      _urgency           = e.urgency;
      _careHomeName      = e.careHomeName;
      _selectedNeeds.addAll(e.needs);
      _existingPhotoUrl  = e.photoUrl.isNotEmpty ? e.photoUrl : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _storyCtrl.dispose();
    _locationCtrl.dispose(); _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, maxHeight: 800, imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800, maxHeight: 800, imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final isEditing = widget.existing != null;
    if (!isEditing && _photoBytes == null) {
      setState(() => _error = 'Please add a photo first.');
      return;
    }
    if (_selectedNeeds.isEmpty) {
      setState(() => _error = 'Select at least one need.');
      return;
    }

    setState(() { _uploading = true; _error = null; _uploadProgress = 0; });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String photoUrl = _existingPhotoUrl ?? '';

      if (_photoBytes != null) {
        // Upload new or replacement photo
        final residentId = isEditing
            ? widget.existing!.id
            : FirebaseFirestore.instance.collection('residents').doc().id;
        final storageRef = FirebaseStorage.instance
            .ref('residents/$residentId/photo.jpg');
        final task = storageRef.putData(
          _photoBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            setState(() =>
              _uploadProgress = snap.bytesTransferred / snap.totalBytes);
          }
        });
        await task.timeout(const Duration(seconds: 30));
        photoUrl = await storageRef.getDownloadURL();
      }

      final data = {
        'name':             _nameCtrl.text.trim(),
        'age':              _age,
        'gender':           _gender,
        'photoUrl':         photoUrl,
        'careHomeName':     _careHomeName,
        'careHomeLocation': _locationCtrl.text.trim(),
        'careHomeId':       widget.careHomeId,
        'addedBy':          uid,
        'needs':            _selectedNeeds.toList(),
        'story':            _storyCtrl.text.trim(),
        'urgency':          _urgency,
        'monthlyTarget':    double.tryParse(_targetCtrl.text) ?? 0,
        'isActive':         true,
      };

      if (isEditing) {
        // Update existing document
        await FirebaseFirestore.instance
            .collection('residents')
            .doc(widget.existing!.id)
            .update(data);
      } else {
        // Create new document
        await FirebaseFirestore.instance.collection('residents').add({
          ...data,
          'monthlyRaised':  0,
          'totalDonations': 0,
          'sponsorsCount':  0,
          'createdAt':      FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AidColors.ngoAccent;

    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AidColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Edit Resident Profile' : 'Add Resident Profile',
          style: GoogleFonts.syne(
            color: AidColors.textPrimary,
            fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── Photo picker ──────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AidColors.elevated,
                    border: Border.all(
                      color: _photoBytes != null
                          ? accent
                          : AidColors.borderDefault,
                      width: 2,
                    ),
                    image: _photoBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_photoBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: _photoBytes != null
                        ? [BoxShadow(color: accent.withValues(alpha: 0.3),
                            blurRadius: 20)]
                        : [],
                  ),
                  child: _photoBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                color: AidColors.textMuted, size: 32),
                            const Gap(6),
                            Text('Add photo',
                              style: GoogleFonts.spaceGrotesk(
                                color: AidColors.textMuted, fontSize: 12)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accent, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                ),
              ),
            ),
            const Gap(28),

            // ── Name ──────────────────────────────────────────────────────────
            _label('Full Name (first name is fine)'),
            const Gap(8),
            _field(
              ctrl: _nameCtrl,
              hint: 'e.g. Raju',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Name is required' : null,
            ),
            const Gap(20),

            // ── Age ───────────────────────────────────────────────────────────
            _label('Age: $_age years'),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: accent,
                inactiveTrackColor: AidColors.elevated,
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _age.toDouble(),
                min: 1, max: 100, divisions: 99,
                onChanged: (v) => setState(() => _age = v.round()),
              ),
            ),
            const Gap(8),

            // ── Gender ────────────────────────────────────────────────────────
            _label('Gender'),
            const Gap(10),
            Row(
              children: [
                _chip('Male',   'male',   Icons.male_rounded),
                const Gap(8),
                _chip('Female', 'female', Icons.female_rounded),
                const Gap(8),
                _chip('Other',  'other',  Icons.person_rounded),
              ],
            ),
            const Gap(20),

            // ── Care home name ────────────────────────────────────────────────
            _label('Care Home Name'),
            const Gap(8),
            _field(
              hint: 'e.g. Manasa Medical Trust',
              initialValue: _careHomeName,
              onChanged: (v) => setState(() => _careHomeName = v),
            ),
            ),
            const Gap(20),

            // ── Location ──────────────────────────────────────────────────────
            _label('Location (City / Area)'),
            const Gap(8),
            _field(
              ctrl: _locationCtrl,
              hint: 'e.g. Bangalore, HSR Layout',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Location is required' : null,
            ),
            const Gap(20),

            // ── Needs ─────────────────────────────────────────────────────────
            _label('What does this person need?'),
            const Gap(10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _allNeeds.map((n) {
                final (id, icon, label) = n;
                final selected = _selectedNeeds.contains(id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) _selectedNeeds.remove(id);
                    else _selectedNeeds.add(id);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.15)
                          : AidColors.elevated,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected
                            ? accent.withValues(alpha: 0.7)
                            : AidColors.borderDefault,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon,
                        color: selected ? accent : AidColors.textMuted,
                        size: 14),
                      const Gap(6),
                      Text(label,
                        style: GoogleFonts.spaceGrotesk(
                          color: selected
                              ? AidColors.textPrimary
                              : AidColors.textMuted,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600 : FontWeight.w400,
                        )),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),

            // ── Story ─────────────────────────────────────────────────────────
            _label('Their Story'),
            const Gap(8),
            TextFormField(
              controller: _storyCtrl,
              maxLines: 4,
              style: GoogleFonts.spaceGrotesk(
                  color: AidColors.textPrimary, fontSize: 14),
              decoration: _inputDecoration(
                  'A few sentences about their background and situation...'),
              validator: (v) => v == null || v.trim().length < 10
                  ? 'Please write at least a sentence about them' : null,
            ),
            const Gap(20),

            // ── Urgency ───────────────────────────────────────────────────────
            _label('Urgency Level'),
            const Gap(10),
            Row(
              children: _urgencyOptions.map((opt) {
                final (id, label, color) = opt;
                final selected = _urgency == id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _urgency = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                          right: id != 'critical' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : AidColors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? color
                              : AidColors.borderDefault,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                        ),
                        const Gap(6),
                        Text(label,
                          style: GoogleFonts.spaceGrotesk(
                            color: selected
                                ? AidColors.textPrimary
                                : AidColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),

            // ── Monthly target (optional) ──────────────────────────────────
            _label('Monthly Sponsorship Target (₹) — optional'),
            const Gap(8),
            _field(
              ctrl: _targetCtrl,
              hint: 'e.g. 2000  (leave blank to skip)',
              keyboardType: TextInputType.number,
            ),
            const Gap(28),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AidColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AidColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: AidColors.error, size: 16),
                  const Gap(8),
                  Expanded(child: Text(_error!,
                    style: GoogleFonts.spaceGrotesk(
                        color: AidColors.error, fontSize: 13))),
                ]),
              ),
              const Gap(16),
            ],

            // ── Upload progress ───────────────────────────────────────────
            if (_uploading) ...[
              Text('Uploading... ${(_uploadProgress * 100).round()}%',
                style: GoogleFonts.spaceGrotesk(
                    color: AidColors.textMuted, fontSize: 12)),
              const Gap(6),
              LinearProgressIndicator(
                value: _uploadProgress,
                color: accent,
                backgroundColor: AidColors.elevated,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
              const Gap(16),
            ],

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _uploading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _uploading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text('Save Profile',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AidColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: AidColors.borderStrong,
                borderRadius: BorderRadius.circular(2))),
            const Gap(20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AidColors.textPrimary),
              title: Text('Take a photo',
                style: GoogleFonts.spaceGrotesk(color: AidColors.textPrimary)),
              onTap: () { Navigator.pop(context); _takePhoto(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AidColors.textPrimary),
              title: Text('Choose from gallery',
                style: GoogleFonts.spaceGrotesk(color: AidColors.textPrimary)),
              onTap: () { Navigator.pop(context); _pickPhoto(); },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: GoogleFonts.spaceGrotesk(
      color: AidColors.textMuted,
      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3));

  Widget _chip(String label, String value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AidColors.ngoAccent.withValues(alpha: 0.12)
                : AidColors.elevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AidColors.ngoAccent
                  : AidColors.borderDefault,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
              color: selected ? AidColors.ngoAccent : AidColors.textMuted,
              size: 18),
            const Gap(4),
            Text(label,
              style: GoogleFonts.spaceGrotesk(
                color: selected
                    ? AidColors.textPrimary : AidColors.textMuted,
                fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.spaceGrotesk(
        color: AidColors.textMuted.withValues(alpha: 0.5), fontSize: 14),
    filled: true,
    fillColor: AidColors.elevated,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AidColors.borderDefault)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AidColors.borderDefault)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AidColors.ngoAccent, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AidColors.error)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AidColors.error, width: 1.5)),
    errorStyle: GoogleFonts.spaceGrotesk(color: AidColors.error, fontSize: 12),
  );

  Widget _field({
    TextEditingController? ctrl,
    required String hint,
    String? initialValue,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      initialValue: ctrl == null ? initialValue : null,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.spaceGrotesk(
          color: AidColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: _inputDecoration(hint),
    );
  }
}
