import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small, flat-illustration-style farmer watering a plant that keeps
/// growing and gently swaying — same technique as [ChefCookingIllustration]
/// (plain shapes + motion, no external asset), so it drops in anywhere a
/// static emoji used to sit.
///
/// Motion per loop: the watering can tips forward, a couple of drops fall
/// from its spout, the plant stem grows a little taller and its leaves
/// unfurl, then everything settles back for the next loop — like a single
/// breath of the whole scene.
class FarmerGrowingIllustration extends StatefulWidget {
  final double size;
  const FarmerGrowingIllustration({this.size = 160, super.key});

  @override
  State<FarmerGrowingIllustration> createState() => _FarmerGrowingIllustrationState();
}

class _FarmerGrowingIllustrationState extends State<FarmerGrowingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
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

          // Can tips forward once per loop, drops fall just after the tip.
          final canTilt = math.max(0.0, math.sin(t)) * 0.5;
          final dropFall = ((_c.value * 2) % 1.0);
          final dropOpacity = dropFall < 0.7 ? 1.0 - dropFall : 0.0;
          final dropY = dropFall * s * 0.18;

          // Plant grows and settles back — breathing rather than one-shot.
          final growth = 0.85 + math.sin(t) * 0.15;
          final sway = math.sin(t * 0.7) * 0.05;

          return Stack(alignment: Alignment.bottomCenter, children: [
            // Soil mound
            Positioned(
              bottom: 0,
              child: Container(
                width: s * 0.5,
                height: s * 0.1,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4A2F),
                  borderRadius: BorderRadius.circular(s * 0.05),
                ),
              ),
            ),
            // Stem + leaves (grows from the soil)
            Positioned(
              bottom: s * 0.08,
              left: s * 0.42,
              child: Transform.rotate(
                angle: sway,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: growth,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: s * 0.28,
                    height: s * 0.42,
                    child: Stack(alignment: Alignment.bottomCenter, children: [
                      Container(
                        width: s * 0.035,
                        height: s * 0.38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E7A3E),
                          borderRadius: BorderRadius.circular(s * 0.02),
                        ),
                      ),
                      Positioned(
                        bottom: s * 0.22,
                        left: 0,
                        child: Transform.rotate(
                          angle: -0.6,
                          child: Container(
                            width: s * 0.18,
                            height: s * 0.1,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5DA85D),
                              borderRadius: BorderRadius.circular(s * 0.08),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: s * 0.26,
                        right: 0,
                        child: Transform.rotate(
                          angle: 0.6,
                          child: Container(
                            width: s * 0.18,
                            height: s * 0.1,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5DA85D),
                              borderRadius: BorderRadius.circular(s * 0.08),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            // Water drops
            Positioned(
              bottom: s * 0.16 - dropY,
              left: s * 0.3,
              child: Opacity(
                opacity: dropOpacity,
                child: Container(
                  width: s * 0.035,
                  height: s * 0.05,
                  decoration: const BoxDecoration(
                      color: Color(0xFF6FB7E0), shape: BoxShape.circle),
                ),
              ),
            ),
            // Farmer body
            Positioned(
              bottom: s * 0.04,
              left: s * 0.02,
              child: Container(
                width: s * 0.3,
                height: s * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E7A3E),
                  borderRadius: BorderRadius.circular(s * 0.1),
                ),
              ),
            ),
            // Farmer head
            Positioned(
              bottom: s * 0.36,
              left: s * 0.06,
              child: Container(
                width: s * 0.2,
                height: s * 0.2,
                decoration: const BoxDecoration(color: Color(0xFFF2C9A0), shape: BoxShape.circle),
              ),
            ),
            // Sun hat
            Positioned(
              bottom: s * 0.46,
              left: s * 0.01,
              child: Container(
                width: s * 0.3,
                height: s * 0.06,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9A441),
                  borderRadius: BorderRadius.circular(s * 0.04),
                ),
              ),
            ),
            // Watering can (tips toward the plant)
            Positioned(
              bottom: s * 0.2,
              left: s * 0.22,
              child: Transform.rotate(
                angle: canTilt,
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: s * 0.16,
                  height: s * 0.12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A4A),
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
