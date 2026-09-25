import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A muted, auto-looping background video — the seed→farm-rows→leaf-QR
/// clip generated for the splash screen, or the cropped header banner
/// variant. Fades in once the first frame is ready so there's never a
/// flash of black, and falls back to [fallbackColor] permanently if the
/// video fails to load (bad network on web, codec issue, etc.) rather
/// than leaving a broken player on screen.
class LoopingBackgroundVideo extends StatefulWidget {
  final String assetPath;
  final Color fallbackColor;
  final BoxFit fit;
  const LoopingBackgroundVideo({
    required this.assetPath,
    this.fallbackColor = const Color(0xFF1B4332),
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  State<LoopingBackgroundVideo> createState() => _LoopingBackgroundVideoState();
}

class _LoopingBackgroundVideoState extends State<LoopingBackgroundVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // background decoration, never audio
      await controller.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      // Asset missing, unsupported codec on this platform, etc. — degrade
      // to a plain color rather than showing a broken player.
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _controller == null) {
      return ColoredBox(color: widget.fallbackColor);
    }
    return ColoredBox(
      color: widget.fallbackColor,
      child: AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _controller!.value.size.width == 0
                ? 1
                : _controller!.value.size.width,
            height: _controller!.value.size.height == 0
                ? 1
                : _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
