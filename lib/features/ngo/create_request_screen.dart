import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/app_theme.dart';
// request_store kept for backward compat but Firestore is the source of truth

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _volunteersController = TextEditingController(text: '1');

  String _selectedCategory = 'Food & Nutrition';
  bool _needsDonation = false;
  bool _needsVolunteers = true;
  bool _submitting = false;

  static const _categories = [
    'Food & Nutrition',
    'Medical Aid',
    'Education',
    'Shelter',
    'Clothing',
    'Disaster Relief',
    'Child Welfare',
    'Elder Care',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _volunteersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_needsDonation && !_needsVolunteers) {
      _showError('Please select at least one: Needs Donation or Needs Volunteers.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final docRef = FirebaseFirestore.instance.collection('requests').doc();

      final data = {
        'id': docRef.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'volunteersNeeded': int.tryParse(_volunteersController.text.trim()) ?? 1,
        'needsDonation': _needsDonation,
        'needsVolunteers': _needsVolunteers,
        'status': 'open',
        'postedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      // Firestore is the source of truth — local store no longer needed

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request posted successfully!'),
            backgroundColor: AidColors.ngoAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to post request. Please try again.');
      setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        elevation: 0,
        title: Text('New Request',
            style: AidTextStyles.heading.copyWith(fontSize: 20)),
        iconTheme: const IconThemeData(color: AidColors.textPrimary),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AidColors.ngoAccent),
                  )
                : Text('Post',
                    style: AidTextStyles.body.copyWith(
                        color: AidColors.ngoAccent,
                        fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Request Title'),
              const Gap(8),
              _buildField(
                controller: _titleController,
                hint: 'e.g. Flood relief volunteers needed',
                icon: Icons.title_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const Gap(20),

              _SectionLabel('Description'),
              const Gap(8),
              _buildField(
                controller: _descController,
                hint:
                    'Describe the situation, what is needed, and how volunteers/donors can help...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const Gap(20),

              _SectionLabel('Category'),
              const Gap(10),
              _buildCategoryGrid(),
              const Gap(20),

              _SectionLabel('Location'),
              const Gap(8),
              _buildField(
                controller: _locationController,
                hint: 'City, district or address',
                icon: Icons.location_on_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const Gap(20),

              _SectionLabel('What do you need?'),
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: _ToggleChip(
                      label: 'Volunteers',
                      icon: Icons.group_outlined,
                      selected: _needsVolunteers,
                      color: AidColors.volunteerAccent,
                      onTap: () =>
                          setState(() => _needsVolunteers = !_needsVolunteers),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _ToggleChip(
                      label: 'Donations',
                      icon: Icons.favorite_outline_rounded,
                      selected: _needsDonation,
                      color: AidColors.donorAccent,
                      onTap: () =>
                          setState(() => _needsDonation = !_needsDonation),
                    ),
                  ),
                ],
              ),
              const Gap(20),

              if (_needsVolunteers) ...[
                _SectionLabel('Volunteers Needed'),
                const Gap(8),
                _buildField(
                  controller: _volunteersController,
                  hint: 'Number of volunteers',
                  icon: Icons.people_outline_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1) return 'Enter a valid number';
                    return null;
                  },
                ),
                const Gap(20),
              ],

              const Gap(12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Posting...' : 'Post Request',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AidColors.ngoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = cat == _selectedCategory;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AidColors.ngoAccent
                  : AidColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AidColors.ngoAccent
                    : AidColors.textMuted.withValues(alpha:0.2),
              ),
            ),
            child: Text(
              cat,
              style: AidTextStyles.caption.copyWith(
                color: selected ? Colors.white : AidColors.textMuted,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: AidTextStyles.body.copyWith(color: AidColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AidTextStyles.body.copyWith(color: AidColors.textMuted),
        prefixIcon: (icon != null && maxLines == 1)
            ? Icon(icon, color: AidColors.textMuted, size: 20)
            : null,
        filled: true,
        fillColor: AidColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AidColors.textMuted.withValues(alpha:0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AidColors.textMuted.withValues(alpha:0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AidColors.ngoAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AidTextStyles.caption.copyWith(
          color: AidColors.textMuted, letterSpacing: 0.5),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha:0.15) : AidColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AidColors.textMuted.withValues(alpha:0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AidColors.textMuted, size: 22),
            const Gap(6),
            Text(
              label,
              style: AidTextStyles.caption.copyWith(
                color: selected ? color : AidColors.textMuted,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}