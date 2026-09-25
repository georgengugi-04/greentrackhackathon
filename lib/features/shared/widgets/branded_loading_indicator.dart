import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';

/// GreenTrack-branded loading indicator for the planting workflow.
///
/// Plays `assets/lottie/logo_intro.json` — the existing GreenTrack brand
/// animation (leaf mark draws in, then the "greentrack" wordmark and
/// tagline fade in). That asset already shipped in the project but wasn't
/// wired up anywhere; this is the first place it's actually used.
///
/// Falls back to a plain [CircularProgressIndicator] if the animation
/// can't load for any reason, so this can never render a broken screen.
class BrandedLoadingIndicator extends StatelessWidget {
  const BrandedLoadingIndicator({
    super.key,
    required this.message,
    this.size = 120,
    this.asset = 'assets/lottie/logo_intro.json',
    this.repeat = true,
  });

  final String message;
  final double size;
  final String asset;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          asset,
          repeat: repeat,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const CircularProgressIndicator(color: AppColors.leaf),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.sans(14,
            weight: FontWeight.w600, color: AppColors.textPrimaryOf(context)),
      ),
    ]);
  }
}
