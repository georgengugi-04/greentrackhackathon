import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small, flat-illustration-style chef flipping food in a pan, looping
/// forever — built entirely from basic shapes (no external image/Lottie
/// asset), so it's a genuine little drawn character rather than an
/// animated emoji glyph.
///
/// Motion per loop: the pan rocks side to side, the arm follows it with a
/// slight lag, a piece of food arcs up out of the pan and lands back down,
/// and a wisp of steam gently fades in and out above it.
class ChefCookingIllustration extends StatefulWidget {
  final double size;
  const ChefCookingIllustration({this.size = 160, super.key});

  @override
  State<ChefCookingIllustration> createState() => _ChefCookingIllustrationState();
}

class _ChefCookingIllustrationState extends State<ChefCookingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;

          final panTilt = math.sin(t) * 0.16;
          final armTilt = math.sin(t) * 0.10;
          // Food arcs up once per cycle, peaking a quarter-cycle after the
          // pan flicks — then falls back in time for the next flip.
          final flipHeight = math.max(0.0, math.sin(t - math.pi / 2));
          final foodY = -flipHeight * s * 0.24;
          final foodX = math.sin(t) * s * 0.04;
          final steamOpacity = 0.15 + (math.sin(t * 2) + 1) / 2 * 0.35;

          return Stack(alignment: Alignment.bottomCenter, children: [
            // Steam
            Positioned(
              top: s * 0.02,
              right: s * 0.28,
              child: Opacity(
                opacity: steamOpacity,
                child: Icon(Icons.cloud_outlined,
                    size: s * 0.16, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
            // Torso
            Positioned(
              bottom: s * 0.04,
              child: Container(
                width: s * 0.38,
                height: s * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(s * 0.12),
                ),
              ),
            ),
            // Apron stripe
            Positioned(
              bottom: s * 0.04,
              child: Container(
                width: s * 0.38,
                height: s * 0.1,
                decoration: BoxDecoration(
                  color: const Color(0xFFE05A47),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(s * 0.12)),
                ),
              ),
            ),
            // Head
            Positioned(
              bottom: s * 0.42,
              child: Container(
                width: s * 0.24,
                height: s * 0.24,
                decoration: const BoxDecoration(color: Color(0xFFF2C9A0), shape: BoxShape.circle),
              ),
            ),
            // Chef hat
            Positioned(
              bottom: s * 0.56,
              child: Container(
                width: s * 0.26,
                height: s * 0.22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(s * 0.16)),
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              ),
            ),
            // Pan (pivots like a wrist flick)
            Positioned(
              bottom: s * 0.16,
              right: s * 0.08,
              child: Transform.rotate(
                angle: panTilt,
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: s * 0.32,
                  height: s * 0.055,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A4A),
                    borderRadius: BorderRadius.circular(s * 0.03),
                  ),
                ),
              ),
            ),
            // Flipping food
            Positioned(
              bottom: s * 0.2,
              right: s * 0.2,
              child: Transform.translate(
                offset: Offset(foodX, foodY),
                child: Container(
                  width: s * 0.085,
                  height: s * 0.085,
                  decoration: const BoxDecoration(color: Color(0xFFEDC55A), shape: BoxShape.circle),
                ),
              ),
            ),
            // Arm swinging the pan
            Positioned(
              bottom: s * 0.3,
              right: s * 0.06,
              child: Transform.rotate(
                angle: armTilt,
                alignment: Alignment.topLeft,
                child: Container(
                  width: s * 0.055,
                  height: s * 0.18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2C9A0),
                    borderRadius: BorderRadius.circular(s * 0.03),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
