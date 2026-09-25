import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A subtly animated emoji glyph — a slow, continuous breathing scale, not
/// the jiggle/wiggle/bounce this used to do (that read as cartoonish and
/// was deliberately reverted). This is closer to how a premium app uses
/// motion: quiet, restrained, barely-there until you notice it, rather
/// than something that grabs attention on every frame.
class AnimatedEmoji extends StatelessWidget {
  final String emoji;
  final double size;

  const AnimatedEmoji(this.emoji, {this.size = 24, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: TextStyle(fontSize: size))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          duration: 1800.ms,
          curve: Curves.easeInOut,
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
        );
  }
}
