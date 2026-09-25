import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// The rounded corner-bracket used on QR scan frames throughout the app.
/// Public/shared so every role's scan screen draws the exact same shape,
/// just recolored to that role's accent — one visual language, not three.
class ScanCorner extends StatelessWidget {
  final double size, thickness;
  final Color color;
  final bool top, left;
  const ScanCorner(
    this.size,
    this.thickness,
    this.color, {
    required this.top,
    required this.left,
    super.key,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ScanCornerPainter(thickness, color, top, left)));
}

class _ScanCornerPainter extends CustomPainter {
  final double t;
  final Color c;
  final bool top, left;
  _ScanCornerPainter(this.t, this.c, this.top, this.left);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = c
      ..strokeWidth = t
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const r = 8.0;
    if (top && left) {
      canvas.drawLine(Offset(0, size.height), const Offset(0, r), p);
      canvas.drawLine(const Offset(0, r), const Offset(r, 0), p);
      canvas.drawLine(const Offset(r, 0), Offset(size.width, 0), p);
    } else if (top && !left) {
      canvas.drawLine(const Offset(0, 0), Offset(size.width - r, 0), p);
      canvas.drawLine(Offset(size.width - r, 0), Offset(size.width, r), p);
      canvas.drawLine(Offset(size.width, r), Offset(size.width, size.height), p);
    } else if (!top && left) {
      canvas.drawLine(const Offset(0, 0), Offset(0, size.height - r), p);
      canvas.drawLine(Offset(0, size.height - r), Offset(r, size.height), p);
      canvas.drawLine(Offset(r, size.height), Offset(size.width, size.height), p);
    } else {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height - r), p);
      canvas.drawLine(Offset(size.width, size.height - r),
          Offset(size.width - r, size.height), p);
      canvas.drawLine(Offset(size.width - r, size.height), Offset(0, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_ScanCornerPainter oldDelegate) =>
      oldDelegate.c != c || oldDelegate.t != t;
}

/// The full dark "trace mode" scan target: charcoal card, glowing border,
/// four corner brackets, a ghost QR icon, and an animated scan line while
/// [scanning] is true. Recolor via [accent] to give each role (chef=amber,
/// consumer/diner=mint, etc.) its own identity within one shared layout.
class DarkScanFrame extends StatelessWidget {
  final Color accent;
  final bool scanning;
  final double size;
  const DarkScanFrame({
    required this.accent,
    this.scanning = false,
    this.size = 238,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 32)],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        ..._corners(),
        const Icon(Icons.qr_code_2_rounded, color: Colors.white12, size: 112),
        if (scanning)
          Container(
            width: size - 34,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.7), blurRadius: 14)],
            ),
          ),
      ]),
    );
  }

  List<Widget> _corners() {
    const s = 28.0;
    const t = 3.0;
    return [
      Positioned(top: 0, left: 0, child: ScanCorner(s, t, accent, top: true, left: true)),
      Positioned(top: 0, right: 0, child: ScanCorner(s, t, accent, top: true, left: false)),
      Positioned(bottom: 0, left: 0, child: ScanCorner(s, t, accent, top: false, left: true)),
      Positioned(bottom: 0, right: 0, child: ScanCorner(s, t, accent, top: false, left: false)),
    ];
  }
}

/// A small pill badge like "Trace mode" / "Verify mode" seen at the top of
/// scan screens — shared so the styling matches everywhere it appears.
class TraceModeBadge extends StatelessWidget {
  final String label;
  final Color accent;
  const TraceModeBadge({required this.label, required this.accent, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          style: AppTextStyles.sans(12, color: Colors.white, weight: FontWeight.w700)),
    );
  }
}
