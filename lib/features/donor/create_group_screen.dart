import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../services/user_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPublic = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final uid = AuthService.instance.currentUser?.uid ?? '';
    final profile = await UserService.getProfile(uid);

    await GroupService.createGroup(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      creatorId: uid,
      creatorName: profile?.name ?? 'Unknown',
      isPublic: _isPublic,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        title: const Text('Create a Group'),
        backgroundColor: AidColors.background,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AidColors.donorAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_rounded,
                      color: AidColors.donorAccent, size: 36),
                ),
              ),
              const Gap(24),
              Text('Group Name',
                  style: AidTextStyles.labelMd
                      .copyWith(color: AidColors.textSecondary)),
              const Gap(8),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                decoration: const InputDecoration(
                  hintText: 'e.g. Weekend Warriors, Office Donors',
                  prefixIcon: Icon(Icons.group_rounded, size: 20),
                ),
              ),
              const Gap(20),
              Text('Description',
                  style: AidTextStyles.labelMd
                      .copyWith(color: AidColors.textSecondary)),
              const Gap(8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                decoration: const InputDecoration(
                  hintText: 'What is this group about? What will you donate together?',
                  alignLabelWithHint: true,
                ),
              ),
              const Gap(20),

              // Public/private toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AidColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AidColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Public Group', style: AidTextStyles.headingSm),
                          Text(
                            _isPublic
                                ? 'Anyone can discover and join this group'
                                : 'Only invited members can join',
                            style: AidTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                      activeThumbColor: AidColors.donorAccent,
                    ),
                  ],
                ),
              ),
              const Gap(32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AidColors.donorAccent,
                    foregroundColor: AidColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Group',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
