import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════
// MODERN CARD — generic reusable card wrapper. The more specific
// ModernStatCard/GlassSectionCard in premium_widgets.dart cover their own
// use cases; this is the plain "wrap anything in a premium-feeling card"
// building block the modernization brief asks every screen to use instead
// of ad-hoc Container/BoxDecoration combos.
// ═══════════════════════════════════════════════════════════════════════

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final List<BoxShadow>? shadow;
  final Border? border;

  const ModernCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
    this.radius = AppRadius.lg,
    this.shadow,
    this.border,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? AppShadows.subtle,
        border: border ?? Border.all(color: AppColors.borderOf(context)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MODERN BUTTON — primary / secondary / gradient / icon-only, each with
// built-in loading and disabled states so screens stop hand-rolling
// their own CircularProgressIndicator-in-a-button logic.
// ═══════════════════════════════════════════════════════════════════════

enum ModernButtonVariant { primary, secondary, gradient, icon }

class ModernButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final ModernButtonVariant variant;
  final Color? color;
  final double height;
  final bool expand;

  const ModernButton({
    this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.variant = ModernButtonVariant.primary,
    this.color,
    this.height = 52,
    this.expand = true,
    super.key,
  });

  const ModernButton.icon({
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.color,
    this.height = 44,
    super.key,
  })  : label = null,
        variant = ModernButtonVariant.icon,
        expand = false;

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.forest;

    if (variant == ModernButtonVariant.icon) {
      return _AnimatedTap(
        onTap: _disabled ? null : onPressed,
        child: Container(
          width: height,
          height: height,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: _disabled ? 0.08 : 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: height * 0.4, height: height * 0.4,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accent))
              : Icon(icon, color: _disabled ? accent.withValues(alpha: 0.4) : accent,
                  size: height * 0.46),
        ),
      );
    }

    Widget content = loading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: variant == ModernButtonVariant.secondary ? accent : Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            if (label != null) Text(label!, style: AppTextStyles.body(15, weight: FontWeight.w700)),
          ]);

    BoxDecoration decoration;
    Color textColor;
    switch (variant) {
      case ModernButtonVariant.secondary:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: _disabled ? AppColors.borderOf(context) : accent, width: 1.5),
        );
        textColor = _disabled ? AppColors.textSecondaryOf(context) : accent;
        break;
      case ModernButtonVariant.gradient:
        decoration = BoxDecoration(
          gradient: _disabled
              ? null
              : LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: _disabled ? AppColors.borderOf(context) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: _disabled ? null : [
            BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        );
        textColor = Colors.white;
        break;
      case ModernButtonVariant.primary:
      case ModernButtonVariant.icon:
        decoration = BoxDecoration(
          color: _disabled ? AppColors.borderOf(context) : accent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        );
        textColor = Colors.white;
    }

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: height,
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: decoration,
      alignment: Alignment.center,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: textColor),
        child: IconTheme.merge(data: IconThemeData(color: textColor), child: content),
      ),
    );

    return _AnimatedTap(onTap: _disabled ? null : onPressed, child: button);
  }
}

/// Shared press-scale micro-interaction for every button variant above —
/// the "animations should be subtle and professional" bit of the brief.
class _AnimatedTap extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _AnimatedTap({required this.onTap, required this.child});

  @override
  State<_AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<_AnimatedTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MODERN LIST ITEM — replaces plain ListTile: icon-in-a-container,
// title/subtitle, trailing slot, subtle press animation.
// ═══════════════════════════════════════════════════════════════════════

class ModernListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ModernListItem({
    required this.icon,
    required this.title,
    this.iconColor = AppColors.forest,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.body(14, weight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context))),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
              ],
            ]),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondaryOf(context)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHIMMER / SKELETON LOADING — "never display blank screens" from the
// brief. Drop one of these in wherever a screen currently shows a bare
// CircularProgressIndicator while data loads.
// ═══════════════════════════════════════════════════════════════════════

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const ShimmerBox({this.width, this.height = 16, this.radius = 8, super.key});

  @override
  Widget build(BuildContext context) {
    final base = AppColors.borderOf(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: Colors.white.withValues(alpha: 0.6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

/// A skeleton stand-in for a [ModernCard] — icon circle + two text lines
/// — for lists that are still loading their first page of real data.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        const ShimmerBox(width: 44, height: 44, radius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ShimmerBox(width: 140, height: 14),
            const SizedBox(height: 8),
            ShimmerBox(width: MediaQuery.of(context).size.width * 0.3, height: 12),
          ]),
        ),
      ]),
    );
  }
}

/// Several [ShimmerCard]s stacked — drop this in wherever a `.when(loading:
/// ...)` branch currently returns a bare spinner.
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({this.count = 3, super.key});

  @override
  Widget build(BuildContext context) => Column(
      children: List.generate(count, (_) => const ShimmerCard()));
}

// ═══════════════════════════════════════════════════════════════════════
// EMPTY / ERROR STATES — with a retry action, so a `.when(error: ...)`
// branch never just prints an exception string into a Text widget again.
// ═══════════════════════════════════════════════════════════════════════

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
              color: AppColors.forest.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(icon, size: 30, color: AppColors.forest.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.body(15, weight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context)), textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 20),
          ModernButton(
              label: actionLabel, onPressed: onAction,
              variant: ModernButtonVariant.secondary, expand: false, height: 44),
        ],
      ]),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.wifi_off_rounded,
      title: 'Something went wrong',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}
