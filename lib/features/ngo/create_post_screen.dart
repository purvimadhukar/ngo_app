import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();

  PostType _postType = PostType.donation;
  String _category = 'food';
  bool _loading = false;

  final List<XFile> _selectedMedia = [];
  final List<_ItemEntry> _items = [];
  DateTime? _eventDate;

  final _categories = ['food', 'clothes', 'medical', 'education', 'funds', 'other'];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final files = await _picker.pickMultiImage(imageQuality: 75);
    if (files.isNotEmpty) {
      setState(() => _selectedMedia.addAll(files));
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemEntry()));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_postType == PostType.activity && _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an event date')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = AuthService.instance.currentUser!;

      // Upload media
      final mediaUrls = <String>[];
      for (final file in _selectedMedia) {
        final url = await PostService.uploadMedia(file, user.uid);
        mediaUrls.add(url);
      }

      final post = NgoPost(
        id: '',
        ngoId: user.uid,
        ngoName: user.displayName ?? 'NGO',
        ngoVerified: false, // will be set true after admin verifies the NGO
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        type: _postType,
        status: PostStatus.active,
        mediaUrls: mediaUrls,
        proofUrls: [],
        requiredItems: _items
            .where((i) => i.nameCtrl.text.isNotEmpty)
            .map((i) => RequiredItem(
                  name: i.nameCtrl.text.trim(),
                  unit: i.unitCtrl.text.trim(),
                  targetQty: double.tryParse(i.qtyCtrl.text) ?? 0,
                ))
            .toList(),
        eventDetails: _postType == PostType.activity
            ? EventDetails(
                eventDate: _eventDate!,
                location: _locationCtrl.text.trim(),
                volunteersNeeded: 10,
                contactName: _contactNameCtrl.text.trim(),
                contactPhone: _contactPhoneCtrl.text.trim(),
              )
            : null,
        createdAt: DateTime.now(),
      );

      await PostService.createPost(post);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create post'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Publish'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Post type
            _SectionHeader('Post type'),
            Row(
              children: PostType.values.map((t) {
                final labels = {
                  PostType.donation: 'Donation drive',
                  PostType.activity: 'Volunteer event',
                  PostType.emergency: 'Emergency need',
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(labels[t]!, style: const TextStyle(fontSize: 12)),
                      selected: _postType == t,
                      onSelected: (_) => setState(() => _postType = t),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category
            _SectionHeader('Category'),
            Wrap(
              spacing: 8,
              children: _categories.map((c) => FilterChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  )).toList(),
            ),
            const SizedBox(height: 16),

            // Title & description
            _SectionHeader('Details'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Media
            _SectionHeader('Photos / Videos'),
            if (_selectedMedia.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _selectedMedia[i].path,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMedia.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add photos'),
            ),
            const SizedBox(height: 16),

            // Required items
            _SectionHeader('What do you need?'),
            ..._items.asMap().entries.map((e) => _ItemRow(
                  entry: e.value,
                  onRemove: () => setState(() => _items.removeAt(e.key)),
                )),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
            const SizedBox(height: 16),

            // Event details (activity only)
            if (_postType == PostType.activity) ...[
              _SectionHeader('Event details'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _eventDate == null
                      ? 'Pick event date & time'
                      : 'Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}  ${_eventDate!.hour}:${_eventDate!.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
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
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          ));
                    }
                  }
                },
              ),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / address *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    _postType == PostType.activity && v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactNameCtrl,
                      decoration: const InputDecoration(labelText: 'Contact name'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _contactPhoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
}

class _ItemEntry {
  final nameCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
}

class _ItemRow extends StatelessWidget {
  final _ItemEntry entry;
  final VoidCallback onRemove;
  const _ItemRow({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: entry.nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: entry.qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: entry.unitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: onRemove,
              color: Colors.red,
            ),
          ],
        ),
      );
}