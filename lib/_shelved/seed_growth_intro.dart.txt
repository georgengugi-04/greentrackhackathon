import 'package:flutter/material.dart';

/// The splash intro from the motion concept doc, played once:
/// seed falls → roots grow → plant sprouts → done.
///
/// Built from plain shapes (same technique as the onboarding character
/// illustrations) so it doesn't depend on any external animation file —
/// no Lottie export to get right, no state machine to wire up. Calls
/// [onComplete] once, right when the sprout finishes unfurling, so the
/// splash screen can cross-fade into the brand name at exactly the right
/// moment.
class SeedGrowthIntro extends StatefulWidget {
  final double size;
  final VoidCallback? onComplete;
  const SeedGrowthIntro({this.size = 140, this.onComplete, super.key});

  @override
  State<SeedGrowthIntro> createState() => _SeedGrowthIntroState();
}

class _SeedGrowthIntroState extends State<SeedGrowthIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Phase windows within the single 0..1 run (not looped) — tuned so each
  // beat has room to read clearly instead of blurring into the next.
  static const _seedFall = Interval(0.0, 0.22, curve: Curves.easeIn);
  static const _seedSettle = Interval(0.18, 0.3, curve: Curves.elasticOut);
  static const _rootsGrow = Interval(0.28, 0.55, curve: Curves.easeOut);
  static const _stemGrow = Interval(0.5, 0.8, curve: Curves.easeOutBack);
  static const _leavesUnfurl = Interval(0.72, 1.0, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _c.forward();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete?.call();
    });
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
          final t = _c.value;

          final seedDropY = (1 - _seedFall.transform(t)) * -s * 0.5;
          final seedScale = _seedSettle.transform(t).clamp(0.0, 1.0);
          final rootsProgress = _rootsGrow.transform(t).clamp(0.0, 1.0);
          final stemProgress = _stemGrow.transform(t).clamp(0.0, 1.0);
          final leavesProgress = _leavesUnfurl.transform(t).clamp(0.0, 1.0);

          return Stack(alignment: Alignment.bottomCenter, children: [
            // Soil line
            Positioned(
              bottom: s * 0.28,
              child: Container(
                width: s * 0.7,
                height: 2,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            // Roots (simple splayed lines growing down from the seed)
            if (rootsProgress > 0)
              Positioned(
                bottom: s * 0.28 - (s * 0.001), // sit right at the soil line
                child: SizedBox(
                  width: s * 0.5,
                  height: s * 0.22 * rootsProgress,
                  child: CustomPaint(painter: _RootsPainter(rootsProgress)),
                ),
              ),
            // Stem
            if (stemProgress > 0)
              Positioned(
                bottom: s * 0.28,
                child: Container(
                  width: s * 0.035,
                  height: s * 0.32 * stemProgress,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5DA85D),
                    borderRadius: BorderRadius.circular(s * 0.02),
                  ),
                ),
              ),
            // Leaves (unfurl once the stem has grown)
            if (leavesProgress > 0)
              Positioned(
                bottom: s * 0.28 + s * 0.22,
                child: Transform.scale(
                  scale: leavesProgress,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: s * 0.34,
                    height: s * 0.16,
                    child: Stack(children: [
                      Positioned(
                        left: 0,
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Container(
                            width: s * 0.2,
                            height: s * 0.11,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7BC77B),
                              borderRadius: BorderRadius.circular(s * 0.09),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Container(
                            width: s * 0.2,
                            height: s * 0.11,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7BC77B),
                              borderRadius: BorderRadius.circular(s * 0.09),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            // Seed (falls in, settles on the soil line, then hides once
            // the sprout has grown past it)
            if (stemProgress < 0.15)
              Positioned(
                bottom: s * 0.28 - s * 0.03 + seedDropY,
                child: Transform.scale(
                  scale: seedScale,
                  child: Container(
                    width: s * 0.07,
                    height: s * 0.09,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A6242),
                      borderRadius: BorderRadius.circular(s * 0.04),
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

class _RootsPainter extends CustomPainter {
  final double progress;
  _RootsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final top = Offset(size.width / 2, 0);
    final spread = size.width / 2;
    final depth = size.height * progress;

    // Three simple splayed root lines, center one straight, outer two
    // curving outward — enough to read as "roots" without needing a
    // real bezier path model.
    canvas.drawLine(top, Offset(size.width / 2, depth), paint);
    final leftPath = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(top.dx - spread * 0.3, depth * 0.5,
          top.dx - spread * 0.75, depth);
    final rightPath = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(top.dx + spread * 0.3, depth * 0.5,
          top.dx + spread * 0.75, depth);
    canvas.drawPath(
        _trimPath(leftPath, progress), paint..color = Colors.white.withValues(alpha: 0.28));
    canvas.drawPath(
        _trimPath(rightPath, progress), paint..color = Colors.white.withValues(alpha: 0.28));
  }

  // Draws only the first [progress] fraction of the path's length, so the
  // roots visibly grow rather than just fading in at full length.
  Path _trimPath(Path path, double progress) {
    final metrics = path.computeMetrics().toList();
    final out = Path();
    for (final m in metrics) {
      out.addPath(m.extractPath(0, m.length * progress), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _RootsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
