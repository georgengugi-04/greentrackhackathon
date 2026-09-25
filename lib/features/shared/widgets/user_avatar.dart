import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/session/session_provider.dart';

/// Read-only avatar — shows the user's photo if they have one, otherwise
/// falls back to an initial letter on a gradient. Used everywhere a user's
/// identity is shown (profile page, every dashboard header) so all of them
/// automatically stay in sync once [photoUrl] changes.
///
/// Prefers a freshly-picked local photo (held in [localProfilePhotoProvider])
/// over the persisted [photoUrl] — that's what makes a newly chosen photo
/// show up immediately everywhere, even before (or without) a cloud upload
/// finishing.
class UserAvatar extends ConsumerWidget {
  final String? photoUrl;
  final String fallbackText;
  final double size;
  final bool circular;
  final List<Color> gradient;

  const UserAvatar({
    required this.photoUrl,
    required this.fallbackText,
    this.size = 46,
    this.circular = false,
    this.gradient = const [AppColors.leaf, AppColors.amber],
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = circular ? size / 2 : size * 0.28;
    final localBytes = ref.watch(localProfilePhotoProvider);
    final hasLocalBytes = localBytes != null && localBytes.isNotEmpty;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasLocalBytes
            ? Image.memory(localBytes, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials())
            : hasPhoto
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _initials(),
                    errorWidget: (_, __, ___) => _initials(),
                  )
                : _initials(),
      ),
    );
  }

  Widget _initials() => Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
        alignment: Alignment.center,
        child: Text(
          fallbackText.trim().isEmpty ? '?' : fallbackText.trim()[0].toUpperCase(),
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.42),
        ),
      );
}

/// Tappable version of [UserAvatar] with a small camera badge — lets the
/// person pick a new photo (camera or gallery) right from wherever this is
/// shown. [onPhotoPicked] receives the raw bytes; the caller decides how
/// to upload/store them (kept dumb on purpose so this widget has no
/// Firebase dependency of its own).
class EditableUserAvatar extends StatefulWidget {
  final String? photoUrl;
  final String fallbackText;
  final double size;
  final bool circular;
  final Future<void> Function(Uint8List bytes) onPhotoPicked;

  const EditableUserAvatar({
    required this.photoUrl,
    required this.fallbackText,
    required this.onPhotoPicked,
    this.size = 72,
    this.circular = true,
    super.key,
  });

  @override
  State<EditableUserAvatar> createState() => _EditableUserAvatarState();
}

class _EditableUserAvatarState extends State<EditableUserAvatar> {
  bool _uploading = false;

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardOf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderOf(ctx),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final file =
          await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 800);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _uploading = true);
      await widget.onPhotoPicked(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t update your photo: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _uploading ? null : _pick,
      child: Stack(children: [
        Opacity(
          opacity: _uploading ? 0.5 : 1,
          child: UserAvatar(
            photoUrl: widget.photoUrl,
            fallbackText: widget.fallbackText,
            size: widget.size,
            circular: widget.circular,
          ),
        ),
        if (_uploading)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  child: const CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: widget.size * 0.32,
            height: widget.size * 0.32,
            decoration: BoxDecoration(
              color: AppColors.leaf,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardOf(context), width: 2),
            ),
            child: Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: widget.size * 0.18),
          ),
        ),
      ]),
    );
  }
}
