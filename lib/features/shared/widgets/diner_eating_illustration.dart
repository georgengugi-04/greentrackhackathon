import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small, flat-illustration-style diner enjoying a plate of food — same
/// technique as [ChefCookingIllustration]/[FarmerGrowingIllustration] (plain
/// shapes + motion, no external asset).
///
/// Motion per loop: a fork lifts a bite from the plate up toward the
/// diner's mouth and back down, and a little heart pops above the plate
/// every other loop — a nod to "favoriting" a meal.
class DinerEatingIllustration extends StatefulWidget {
  final double size;
  const DinerEatingIllustration({this.size = 160, super.key});

  @override
  State<DinerEatingIllustration> createState() => _DinerEatingIllustrationState();
}

class _DinerEatingIllustrationState extends State<DinerEatingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
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

          // Fork rises toward the mouth then dips back to the plate.
          final forkLift = math.max(0.0, math.sin(t)) * s * 0.22;
          final forkTilt = math.sin(t) * 0.25;

          // Heart pops once per loop, shortly after the fork reaches the top.
          final heartPhase = _c.value;
          final inWindow = heartPhase > 0.55 && heartPhase < 0.9;
          final heartProgress = inWindow ? (heartPhase - 0.55) / 0.35 : 0.0;
          final heartScale = inWindow ? math.sin(heartProgress * math.pi).clamp(0.0, 1.0) : 0.0;
          final heartY = -heartProgress * s * 0.14;

          return Stack(alignment: Alignment.bottomCenter, children: [
            // Table surface
            Positioned(
              bottom: 0,
              child: Container(
                width: s,
                height: s * 0.08,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A6242),
                  borderRadius: BorderRadius.circular(s * 0.02),
                ),
              ),
            ),
            // Plate
            Positioned(
              bottom: s * 0.08,
              child: Container(
                width: s * 0.5,
                height: s * 0.5 * 0.32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              ),
            ),
            // Food on the plate
            Positioned(
              bottom: s * 0.14,
              child: Container(
                width: s * 0.26,
                height: s * 0.14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE05A47),
                  borderRadius: BorderRadius.circular(s * 0.06),
                ),
              ),
            ),
            // Diner head
            Positioned(
              bottom: s * 0.5,
              child: Container(
                width: s * 0.26,
                height: s * 0.26,
                decoration: const BoxDecoration(color: Color(0xFFF2C9A0), shape: BoxShape.circle),
              ),
            ),
            // Hair
            Positioned(
              bottom: s * 0.64,
              child: Container(
                width: s * 0.28,
                height: s * 0.12,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A342A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(s * 0.14)),
                ),
              ),
            ),
            // Fork (rises from the plate toward the mouth)
            Positioned(
              bottom: s * 0.2 + forkLift,
              right: s * 0.28,
              child: Transform.rotate(
                angle: forkTilt,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: s * 0.03,
                  height: s * 0.22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9AA0A6),
                    borderRadius: BorderRadius.circular(s * 0.02),
                  ),
                ),
              ),
            ),
            // Heart pop (favoriting nod)
            Positioned(
              bottom: s * 0.5 + heartY,
              right: s * 0.22,
              child: Opacity(
                opacity: heartScale,
                child: Transform.scale(
                  scale: 0.4 + heartScale * 0.8,
                  child: Icon(Icons.favorite_rounded,
                      color: const Color(0xFFE05A47), size: s * 0.14),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
