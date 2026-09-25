import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import 'user_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────
// PremiumProfileHeader
// Gradient hero header: avatar, time-aware greeting, motivational
// subtitle, level badge, profile-completion ring, settings/notification
// icons. Used by the farmer profile tab (and reusable anywhere a person
// header is needed).
// ─────────────────────────────────────────────────────────────────────────
class PremiumProfileHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String subtitle;
  final String levelLabel;
  final double profileCompletion; // 0.0–1.0
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;
  final bool hasUnreadNotifications;
  // A real photo behind the gradient rather than a flat fill — defaults to
  // a farm-field shot so every screen using this header gets it "for
  // free," but a role-specific photo can be passed in instead (e.g. a
  // kitchen scene for the chef header).
  final String backgroundPhotoUrl;

  const PremiumProfileHeader({
    super.key,
    required this.name,
    this.photoUrl,
    required this.subtitle,
    this.levelLabel = 'Grower',
    this.profileCompletion = 0.0,
    this.onSettingsTap,
    this.onNotificationsTap,
    this.hasUnreadNotifications = false,
    this.backgroundPhotoUrl =
        'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=900&q=80',
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: backgroundPhotoUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: Color(0xFF1B4332)),
            errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1B4332)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.80),
                  const Color(0xFF2E7D32).withValues(alpha: 0.72),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    _GlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: onNotificationsTap,
                      showDot: hasUnreadNotifications,
                    ),
                    const SizedBox(width: 10),
                    _GlassIconButton(icon: Icons.settings_outlined, onTap: onSettingsTap),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RingAvatar(
                  photoUrl: photoUrl,
                  fallbackText: name.isNotEmpty ? name : 'F',
                  completion: profileCompletion,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_greeting,',
                          style: AppTextStyles.poppins(14,
                              color: Colors.white.withValues(alpha: 0.78),
                              weight: FontWeight.w500))
                          .animate()
                          .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                          .slideX(begin: -0.15, end: 0, duration: 450.ms, curve: Curves.easeOut),
                      const SizedBox(height: 2),
                      Text(name,
                          style: AppTextStyles.poppins(25,
                              color: Colors.white, weight: FontWeight.w800)
                              .copyWith(letterSpacing: -0.3))
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 500.ms, curve: Curves.easeOut)
                          .slideX(begin: -0.15, end: 0,
                              delay: 120.ms, duration: 500.ms, curve: Curves.easeOut),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.eco_rounded,
                                size: 12, color: AppColors.premiumSuccess),
                            const SizedBox(width: 4),
                            Text(levelLabel,
                                style: AppTextStyles.poppins(10.5,
                                    color: Colors.white, weight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Growing sustainably every day 🌱',
                style: AppTextStyles.poppins(12.5,
                    color: Colors.white.withValues(alpha: 0.72), weight: FontWeight.w500)),
          ],
        ),
      ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }
}

/// The ring-avatar look from the profile header, exposed for reuse
/// anywhere a compact identity/avatar is needed (chef/distributor
/// dashboard top bars, etc.) — not just inside [PremiumProfileHeader].
class RingAvatar extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;
  final double completion;
  final double size;
  const RingAvatar({
    required this.photoUrl,
    required this.fallbackText,
    this.completion = 1.0,
    this.size = 76,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size * 0.82;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: completion.clamp(0, 1)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: value),
          ),
        ),
        UserAvatar(photoUrl: photoUrl, fallbackText: fallbackText, size: avatarSize, circular: true),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = AppColors.premiumSuccess
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708,
        6.2832 * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;
  const _GlassIconButton({required this.icon, this.onTap, this.showDot = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Icon(icon, color: Colors.white, size: 20),
                if (showDot)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.premiumWarning, shape: BoxShape.circle),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// AnimatedCounter — counts up from 0 to [value] once, on first build.
// ─────────────────────────────────────────────────────────────────────────
class AnimatedCounter extends StatelessWidget {
  final num value;
  final String suffix;
  final int decimals;
  final TextStyle style;
  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.decimals = 0,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ModernStatCard — gradient-tinted analytics card with animated counter.
// ─────────────────────────────────────────────────────────────────────────
class ModernStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final num value;
  final String suffix;
  final int decimals;
  final String caption;
  const ModernStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.suffix = '',
    this.decimals = 0,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.09), color.withValues(alpha: 0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl - 6),
          border: Border.all(color: color.withValues(alpha: 0.14)),
          boxShadow: AppShadows.card,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: value,
            suffix: suffix,
            decimals: decimals,
            style: AppTextStyles.poppins(20, weight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.poppins(11, weight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context))),
          Text(caption,
              style: AppTextStyles.poppins(9.5, color: AppColors.textSecondaryOf(context))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// AchievementBadge — rounded-square, gradient when earned, grayscale with
// a progress ring hint when locked.
// ─────────────────────────────────────────────────────────────────────────
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool earned;
  final double progress; // 0..1, shown only when locked
  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.earned,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = AppColors.premiumWarning;
    return Container(
      width: 82,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: earned
            ? LinearGradient(colors: [
                glowColor.withValues(alpha: 0.20),
                glowColor.withValues(alpha: 0.06),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: earned ? null : AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: earned ? glowColor.withValues(alpha: 0.35) : AppColors.borderOf(context)),
        boxShadow: earned
            ? [BoxShadow(color: glowColor.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 4))]
            : AppShadows.subtle,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 34, height: 34,
          child: Stack(alignment: Alignment.center, children: [
            if (!earned && progress > 0)
              CustomPaint(size: const Size(34, 34), painter: _RingPainter(progress: progress)),
            ColorFiltered(
              colorFilter: earned
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
              child: Opacity(
                opacity: earned ? 1 : 0.45,
                child: Icon(icon, size: 22, color: earned ? glowColor : AppColors.textSecondaryOf(context)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: AppTextStyles.poppins(9, weight: FontWeight.w600,
                color: earned ? const Color(0xFFB7791F) : AppColors.textSecondaryOf(context)),
            textAlign: TextAlign.center,
            maxLines: 2),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SectionHeader — small uppercase label with an optional trailing action.
// ─────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  const SectionHeader({super.key, required this.title, this.action, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
      child: Row(children: [
        Expanded(
          child: Text(title.toUpperCase(),
              style: AppTextStyles.poppins(12, weight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.8)),
        ),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(action!,
                style: AppTextStyles.poppins(12, weight: FontWeight.w600,
                    color: AppColors.premiumEmerald)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// QuickActionCard — Farm Tools / Planning style card: icon, title,
// subtitle, small description, chevron.
// ─────────────────────────────────────────────────────────────────────────
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? description;
  final VoidCallback onTap;
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.card,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: AppTextStyles.poppins(13.5, weight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: AppTextStyles.poppins(11.5, weight: FontWeight.w500,
                        color: color)),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(description!,
                      style: AppTextStyles.poppins(10.5, color: AppColors.textSecondaryOf(context)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryOf(context), size: 19),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PremiumSettingsTile — grouped iOS-style settings row with description.
// ─────────────────────────────────────────────────────────────────────────
class PremiumSettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? description;
  final VoidCallback onTap;
  final Widget? trailing;
  const PremiumSettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.description,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: AppTextStyles.poppins(14.5, weight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context))),
                if (description != null)
                  Text(description!,
                      style: AppTextStyles.poppins(11.5,
                          color: AppColors.textSecondaryOf(context))),
              ]),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondaryOf(context), size: 20),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// GlassSectionCard — rounded, elevated container wrapping a group of
// PremiumSettingsTile rows with dividers between them.
// ─────────────────────────────────────────────────────────────────────────
class GlassSectionCard extends StatelessWidget {
  final List<Widget> children;
  const GlassSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(AppRadius.xl - 6),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(height: 1, indent: 68, color: AppColors.borderOf(context));
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ProfileCompletionCard — standalone progress card (used when the header
// ring alone isn't enough detail, e.g. an onboarding nudge).
// ─────────────────────────────────────────────────────────────────────────
class ProfileCompletionCard extends StatelessWidget {
  final double completion; // 0..1
  final VoidCallback onTap;
  const ProfileCompletionCard({super.key, required this.completion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (completion * 100).round();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: AppShadows.card,
          ),
          child: Row(children: [
            SizedBox(
              width: 44, height: 44,
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: const Size(44, 44), painter: _CompletionRingPainter(progress: completion)),
                Text('$pct%',
                    style: AppTextStyles.poppins(11, weight: FontWeight.w800,
                        color: AppColors.premiumEmerald)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Complete your profile',
                    style: AppTextStyles.poppins(13.5, weight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context))),
                Text(pct >= 100 ? 'All set!' : 'A complete profile builds more trust',
                    style: AppTextStyles.poppins(11.5, color: AppColors.textSecondaryOf(context))),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryOf(context), size: 20),
          ]),
        ),
      ),
    );
  }
}

class _CompletionRingPainter extends CustomPainter {
  final double progress;
  _CompletionRingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final track = Paint()
      ..color = AppColors.premiumEmerald.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final arc = Paint()
      ..color = AppColors.premiumEmerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708,
        6.2832 * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
