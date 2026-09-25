import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/models.dart';

/// Lets a farmer log a fertilizer/pesticide bottle, an organic
/// certificate, or any other input/progress photo, for traceability.
/// Reached from the dashboard's Quick Actions — optionally pre-filtered
/// to a specific [initialType] (e.g. the dedicated "Fertilizer" and
/// "Organic Certification" quick actions both open this same screen with
/// their type pre-selected, rather than needing their own separate forms).
class FarmDocumentationScreen extends ConsumerStatefulWidget {
  final FarmDocumentType initialType;
  const FarmDocumentationScreen({this.initialType = FarmDocumentType.fertilizer, super.key});

  @override
  ConsumerState<FarmDocumentationScreen> createState() => _FarmDocumentationScreenState();
}

class _FarmDocumentationScreenState extends ConsumerState<FarmDocumentationScreen> {
  late FarmDocumentType _type;
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Uint8List? _photoBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardOf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1280);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photoBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not read that photo: $e')));
    }
  }

  Future<void> _save() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You need to be signed in with a real account to save documents.')));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Give it a name first — e.g. the product on the label.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final doc = await ref.read(documentServiceProvider).createDocument(
            farmerId: uid,
            type: _type,
            itemName: _nameCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            photoBytes: _photoBytes,
          );
      if (!mounted) return;
      setState(() => _loading = false);
      final photoFailed = _photoBytes != null && doc.photoUrl == null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: photoFailed ? const Duration(seconds: 6) : const Duration(seconds: 4),
          content: Text(photoFailed
              ? '${doc.type.emoji} Saved, but the photo didn\'t upload — likely a '
                  'Storage permissions issue, not your connection. The document '
                  'itself is safe either way.'
              : '${doc.type.emoji} ${doc.itemName} logged.')));
      // Guaranteed navigation home regardless of how this screen was
      // reached — a plain Navigator.pop(context) can silently no-op if
      // there's nothing on this navigator to pop to.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/farmer');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save that: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Documentation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _loading
              ? null
              : () => context.canPop() ? context.pop() : context.go('/farmer'),
        ),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What are you logging?', style: AppTextStyles.label),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: FarmDocumentType.values.map((t) {
              final selected = t == _type;
              return ChoiceChip(
                label: Text('${t.emoji} ${t.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.leaf.withValues(alpha: 0.18),
                labelStyle: TextStyle(
                    color: selected ? AppColors.leaf : AppColors.textSecondaryOf(context),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                side: BorderSide(
                    color: selected ? AppColors.leaf : AppColors.borderOf(context)),
              );
            }).toList()),
            const SizedBox(height: 20),
            Text('Photo', style: AppTextStyles.label),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBytes == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: AppColors.textSecondaryOf(context), size: 32),
                        const SizedBox(height: 8),
                        Text('Photograph the label or bottle',
                            style: AppTextStyles.bodyMuted),
                      ])
                    : Stack(fit: StackFit.expand, children: [
                        Image.memory(_photoBytes!, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              onPressed: _pickPhoto,
                            ),
                          ),
                        ),
                      ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('Item name', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: switch (_type) {
                  FarmDocumentType.fertilizer => 'e.g. NPK 17-17-17',
                  FarmDocumentType.pesticide => 'e.g. Neem oil spray',
                  FarmDocumentType.organicCertificate => 'e.g. KOAN Organic Cert 2026',
                  FarmDocumentType.other => 'What is this?',
                },
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Notes (optional)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Application rate, supplier, batch/lot number...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 100),
          ]),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Save Document'),
          ),
        ),
      ]),
    );
  }
}
