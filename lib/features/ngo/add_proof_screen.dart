import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';

import '../../core/app_theme.dart';
import '../../models/ngo_post.dart';

class AddProofScreen extends StatefulWidget {
  final NgoPost post;
  const AddProofScreen({super.key, required this.post});

  @override
  State<AddProofScreen> createState() => _AddProofScreenState();
}

class _AddProofScreenState extends State<AddProofScreen> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selected = [];
  bool _uploading = false;
  double _progress = 0;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) setState(() => _selected.addAll(files));
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      _snack('Please select at least one photo');
      return;
    }
    setState(() { _uploading = true; _progress = 0; });

    try {
      final storage = FirebaseStorage.instance;
      final db = FirebaseFirestore.instance;
      final postId = widget.post.id;
      final proofUrls = <String>[];

      for (int i = 0; i < _selected.length; i++) {
        final file = _selected[i];
        final bytes = await file.readAsBytes();
        final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = storage.ref('posts/$postId/proof/$name');
        await ref.putData(bytes);
        proofUrls.add(await ref.getDownloadURL());
        if (mounted) setState(() => _progress = (i + 1) / _selected.length);
      }

      await db.collection('posts').doc(postId).update({
        'proofUrls': FieldValue.arrayUnion(proofUrls),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_captionCtrl.text.trim().isNotEmpty)
          'proofCaption': _captionCtrl.text.trim(),
      });

      if (mounted) {
        _snack('${proofUrls.length} proof photo(s) uploaded!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AidColors.background,
      appBar: AppBar(
        backgroundColor: AidColors.background,
        title: Text('Add Proof', style: AidTextStyles.headingMd),
        actions: [
          if (!_uploading)
            TextButton(
              onPressed: _submit,
              child: Text('Upload', style: AidTextStyles.bodyMd.copyWith(color: AidColors.ngoAccent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Post context
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AidColors.ngoAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AidColors.ngoAccent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, color: AidColors.ngoAccent, size: 18),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adding proof for:', style: AidTextStyles.caption.copyWith(color: AidColors.ngoAccent)),
                      Text(widget.post.title, style: AidTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // Explainer
          Text('What is proof?', style: AidTextStyles.headingMd),
          const Gap(6),
          Text(
            'Upload photos or screenshots showing the event happened — distribution of items, volunteering in action, beneficiaries receiving help. This builds donor trust and shows your NGO\'s credibility.',
            style: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
          ),
          const Gap(24),

          // Selected images grid
          if (_selected.isNotEmpty) ...[
            Text('Selected Photos (${_selected.length})', style: AidTextStyles.labelMd.copyWith(color: AidColors.textMuted)),
            const Gap(10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              itemCount: _selected.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _selected[i].path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AidColors.elevated,
                        child: const Icon(Icons.image, color: AidColors.textMuted),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
          ],

          // Pick button
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_selected.isEmpty ? 'Select proof photos' : 'Add more photos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AidColors.ngoAccent,
              side: BorderSide(color: AidColors.ngoAccent.withValues(alpha: 0.5)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Gap(16),

          // Caption
          TextField(
            controller: _captionCtrl,
            maxLines: 3,
            style: AidTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Add a caption (optional) — describe what happened...',
              hintStyle: AidTextStyles.bodyMd.copyWith(color: AidColors.textMuted),
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
            ),
          ),
          const Gap(24),

          // Upload progress
          if (_uploading) ...[
            Text('Uploading... ${(_progress * 100).toInt()}%', style: AidTextStyles.bodyMd.copyWith(color: AidColors.ngoAccent)),
            const Gap(8),
            LinearProgressIndicator(
              value: _progress,
              color: AidColors.ngoAccent,
              backgroundColor: AidColors.elevated,
              borderRadius: BorderRadius.circular(3),
              minHeight: 6,
            ),
            const Gap(24),
          ],

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AidColors.ngoAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _uploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upload Proof', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),

          const Gap(32),
        ],
      ),
    );
  }
}
