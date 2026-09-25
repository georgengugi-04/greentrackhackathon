import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Sits between onboarding and the actual email/password form. The old
/// flow dropped people straight onto a login form defaulted to "Sign In,"
/// which reads oddly for a brand-new user — this makes the choice explicit
/// up front, then hands off to LoginScreen already in the right mode.
class WelcomeChoiceScreen extends StatelessWidget {
  const WelcomeChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Stack(children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.20,
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.night.withValues(alpha: 0.55),
                  AppColors.night,
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 42)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('GreenTrack',
                    style: AppTextStyles.poppins(30,
                        color: Colors.white, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('From garden to table — every crop, verified.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.poppins(13.5,
                        color: Colors.white.withValues(alpha: 0.72))),
                const Spacer(flex: 4),
                _ChoiceCard(
                  icon: Icons.person_add_alt_1_rounded,
                  iconColor: AppColors.premiumSuccess,
                  title: 'Create an account',
                  subtitle: 'New here? Set up your GreenTrack account',
                  onTap: () => context.push('/login', extra: true),
                ),
                const SizedBox(height: 14),
                _ChoiceCard(
                  icon: Icons.login_rounded,
                  iconColor: AppColors.consumerAccent,
                  title: 'Log in',
                  subtitle: 'Already have an account? Welcome back',
                  onTap: () => context.push('/login', extra: false),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.poppins(15.5,
                          color: Colors.white, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.poppins(12,
                          color: Colors.white.withValues(alpha: 0.65))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.6)),
          ]),
        ),
      ),
    );
  }
}
