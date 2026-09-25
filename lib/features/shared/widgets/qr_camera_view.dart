import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import 'scan_frame.dart';

/// Live-camera version of [DarkScanFrame] — same charcoal card, glowing
/// border, and corner brackets, but with the actual camera feed clipped
/// into the frame instead of the static ghost QR icon. Keeps every scan
/// screen's existing look once the camera is wired in behind it.
class LiveScanFrame extends StatelessWidget {
  final MobileScannerController controller;
  final Color accent;
  final double size;
  const LiveScanFrame({
    required this.controller,
    required this.accent,
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
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: size,
            height: size,
            child: MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              errorBuilder: (context, error, child) =>
                  _CameraProblem(error: error),
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        ..._corners(),
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

class _CameraProblem extends StatelessWidget {
  final MobileScannerException error;
  const _CameraProblem({required this.error});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
            const SizedBox(height: 8),
            Text(
              _message(error.errorCode),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ]),
        ),
      ),
    );
  }

  String _message(MobileScannerErrorCode code) {
    switch (code) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied.\nEnable it in your device Settings to scan.';
      case MobileScannerErrorCode.unsupported:
        return 'Camera scanning isn\'t supported on this device.';
      default:
        return 'Could not access the camera.';
    }
  }
}

/// Wraps a [MobileScannerController] and fires [onCode] exactly once per
/// scan session — the controller detects continuously (many times a
/// second) while a code is in frame, so this de-dupes down to a single
/// callback instead of the caller having to guard against repeats itself.
class QrDetector extends StatefulWidget {
  final MobileScannerController controller;
  final ValueChanged<String> onCode;
  final Widget child;
  const QrDetector({
    required this.controller,
    required this.onCode,
    required this.child,
    super.key,
  });

  @override
  State<QrDetector> createState() => _QrDetectorState();
}

class _QrDetectorState extends State<QrDetector> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.barcodes.listen(_onBarcodeCapture);
  }

  void _onBarcodeCapture(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    widget.onCode(value);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
