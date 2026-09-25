import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/session/session_provider.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';
import '../../shared/widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _GlassCircleButton(
              icon: Icons.settings_outlined,
              onTap: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(user: user),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACHIEVEMENTS',
                    style: AppTextStyles.poppins(11.5,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.8),
                  ),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _Badge('🏆', 'Top Grower', true, [Color(0xFFFFD54F), Color(0xFFF9A825)]),
                    _Badge('🌾', '50kg Club', true, [Color(0xFF81C784), Color(0xFF388E3C)]),
                    _Badge('💧', 'Water Wise', true, [Color(0xFF64B5F6), Color(0xFF1976D2)]),
                    _Badge('📸', 'Documentor', false, [Color(0xFFBA68C8), Color(0xFF7B1FA2)]),
                    _Badge('♻️', 'Zero Waste', false, [Color(0xFF4DB6AC), Color(0xFF00695C)]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _ProfileSection(title: 'Account', children: [
                _ProfileTile(
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.leaf,
                  title: 'Settings',
                  subtitle: 'Theme, password, notifications',
                  onTap: () => context.push('/settings'),
                ),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.amber,
                  title: 'Notifications',
                  onTap: () => context.push('/notifications'),
                ),
              ]),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).signOut();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
                  label: Text('Sign Out',
                      style: AppTextStyles.poppins(14.5,
                          color: AppColors.red, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.redLight, width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('GreenTrack v1.0.0',
                    style: AppTextStyles.poppins(10.5, color: AppColors.slateLight)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40, height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final AppUser user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = user.farmName ?? user.restaurantName ??
        user.organizationName ?? user.vehicleInfo ?? user.role.label;

    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36))),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl:
                'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=900&q=80',
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
                  const Color(0xFF1B5E20).withValues(alpha: 0.86),
                  const Color(0xFF2E7D32).withValues(alpha: 0.78),
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 64),
              EditableUserAvatar(
                photoUrl: user.photoUrl,
                fallbackText: user.name,
                size: 88,
                onPhotoPicked: (bytes) =>
                    ref.read(sessionProvider.notifier).updateProfilePhoto(bytes),
              ).animate().scale(curve: Curves.elasticOut, duration: 550.ms),
              const SizedBox(height: 14),
              Text(user.name,
                  style: AppTextStyles.poppins(22, weight: FontWeight.w800,
                      color: Colors.white).copyWith(letterSpacing: -0.3))
                  .animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(subtitle,
                      style: AppTextStyles.poppins(12.5,
                          color: Colors.white, weight: FontWeight.w600)),
                ]),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String emoji, label;
  final bool unlocked;
  final List<Color> gradient;
  const _Badge(this.emoji, this.label, this.unlocked, this.gradient);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 12),
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unlocked
                ? LinearGradient(colors: gradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: unlocked ? null : AppColors.cardOf(context),
            border: unlocked ? null : Border.all(color: AppColors.borderOf(context)),
            boxShadow: unlocked
                ? [BoxShadow(color: gradient.last.withValues(alpha: 0.35),
                    blurRadius: 12, offset: const Offset(0, 5))]
                : null,
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: unlocked ? 1 : 0.35,
            child: AnimatedEmoji(emoji, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: AppTextStyles.poppins(9.5,
                weight: FontWeight.w600,
                color: unlocked
                    ? AppColors.textPrimaryOf(context)
                    : AppColors.textSecondaryOf(context)),
            textAlign: TextAlign.center,
            maxLines: 2),
      ]),
    );
  }
}

// ── Below: mirrors Settings screen's _SettingsSection / _SettingsTile
// exactly (same card style, icon badges, section header typography) so
// Profile and Settings read as one consistent design language.

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.poppins(11.5,
                weight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context)).copyWith(letterSpacing: 0.8),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: List.generate(children.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Divider(height: 1, indent: 56, color: AppColors.borderOf(context));
              }
              return children[i ~/ 2];
            }),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: iconColor),
      ),
      title: Text(title,
          style: AppTextStyles.poppins(14.5, weight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context))),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: AppTextStyles.poppins(11.5, color: AppColors.textSecondaryOf(context))),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppColors.textSecondaryOf(context), size: 20),
      onTap: onTap,
    );
  }
}
