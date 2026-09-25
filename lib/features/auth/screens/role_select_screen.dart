import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/animated_emoji.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  // Tracks which *card* is highlighted — kept separate from UserRole
  // because "Grocery Shopper" and "Diner" are two distinct cards that both
  // currently map to the single UserRole.consumer experience. Using the
  // role directly here would light up both cards at once when either is
  // tapped, since both would satisfy `_selected == UserRole.consumer`.
  String? _selectedCard; // 'farmer' | 'shopper' | 'chef' | 'diner' | 'aggregator' | 'transporter' | 'distributor'
  bool _loading = false;

  UserRole? get _selected => switch (_selectedCard) {
        'farmer' => UserRole.farmer,
        'shopper' => UserRole.consumer,
        'chef' => UserRole.chef,
        'diner' => UserRole.consumer,
        'aggregator' => UserRole.aggregator,
        'transporter' => UserRole.transporter,
        'distributor' => UserRole.distributor,
        _ => null,
      };

  Future<void> _confirm() async {
    if (_selected == null) return;

    // Aggregator/Transporter/Distributor need to clear verification first
    // (invite code or admin approval) — don't call setRole yet, the
    // verification screen does that once the account is actually vetted.
    if (kSupplyChainRoles.contains(_selected)) {
      context.push('/verify-role/${_selected!.name}');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).setRole(_selected!);
      // Router auto-redirects once session updates
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save role. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('From soil to\nyour plate.',
                style: AppTextStyles.poppins(28, color: Colors.white, weight: FontWeight.w800)
                    .copyWith(fontSize: 32, height: 1.15, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Full farm-to-table traceability for everyone in the chain.',
                style: AppTextStyles.sans(14, color: Colors.white60)),
            const SizedBox(height: 20),
            Text('I AM A...',
                style: AppTextStyles.sans(12, color: AppColors.glow,
                    weight: FontWeight.w800).copyWith(letterSpacing: 1.2)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
                children: [
                  _GridRoleCard(
                    icon: Icons.grass_rounded,
                    title: 'Farmer',
                    subtitle: 'Track batches, log irrigation, manage pest control & generate QR codes',
                    accent: AppColors.farmerAccent,
                    selected: _selectedCard == 'farmer',
                    delayMs: 0,
                    onTap: () => setState(() => _selectedCard = 'farmer'),
                  ),
                  _GridRoleCard(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Grocery Shopper',
                    subtitle: 'Scan QR codes to verify origin, freshness & journey of your produce',
                    accent: AppColors.consumerAccent,
                    selected: _selectedCard == 'shopper',
                    delayMs: 70,
                    onTap: () => setState(() => _selectedCard = 'shopper'),
                  ),
                  _GridRoleCard(
                    icon: Icons.restaurant_outlined,
                    title: 'Chef',
                    subtitle: 'Confirm suppliers deliver what they promise — freshness verified',
                    accent: AppColors.chefAccent,
                    selected: _selectedCard == 'chef',
                    delayMs: 140,
                    onTap: () => setState(() => _selectedCard = 'chef'),
                  ),
                  _GridRoleCard(
                    icon: Icons.dinner_dining_outlined,
                    title: 'Diner',
                    subtitle: "Know exactly what's in your meal — nutrients, origin, freshness",
                    accent: AppColors.mint,
                    selected: _selectedCard == 'diner',
                    delayMs: 210,
                    onTap: () => setState(() => _selectedCard = 'diner'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('JOIN THE SUPPLY CHAIN',
                  style: AppTextStyles.sans(11, color: Colors.white38,
                      weight: FontWeight.w800).copyWith(letterSpacing: 1.1))
                  .animate().fadeIn(delay: 280.ms, duration: 350.ms),
              const SizedBox(height: 12),
              // The connected journey — this is the thing that makes it
              // read as "network" rather than "list of unrelated jobs".
              const _JourneyStrip().animate()
                  .fadeIn(delay: 320.ms, duration: 450.ms)
                  .slideY(begin: 0.15, end: 0, delay: 320.ms, duration: 450.ms),
              const SizedBox(height: 16),
              _IconRoleCard(
                icon: Icons.inventory_2_outlined,
                title: 'Aggregator',
                subtitle: 'Combine harvests from multiple farmers into trade-ready batches',
                accent: AppColors.aggregatorAccent,
                selected: _selectedCard == 'aggregator',
                delayMs: 380,
                onTap: () => setState(() => _selectedCard = 'aggregator'),
              ),
              _IconRoleCard(
                icon: Icons.local_shipping_outlined,
                title: 'Transporter',
                subtitle: 'Move batches between farm, aggregator, distributor & market',
                accent: AppColors.transporterAccent,
                selected: _selectedCard == 'transporter',
                delayMs: 440,
                onTap: () => setState(() => _selectedCard = 'transporter'),
              ),
              _IconRoleCard(
                icon: Icons.storefront_outlined,
                title: 'Distributor',
                subtitle: 'Receive bulk batches and route them to chefs & retailers',
                accent: AppColors.distributorAccent,
                selected: _selectedCard == 'distributor',
                delayMs: 500,
                onTap: () => setState(() => _selectedCard = 'distributor'),
              ),
            ],
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selected == null
                ? const SizedBox(height: 0)
                : SizedBox(
                    key: ValueKey(_selectedCard),
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.glow,
                        foregroundColor: AppColors.night,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: AppColors.night, strokeWidth: 2))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Text('Continue as ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(_selectedLabel(),
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 4),
                              AnimatedEmoji(_selectedEmoji(), size: 16),
                            ]),
                    ),
                  ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account? ',
                style: TextStyle(color: Colors.white54)),
            GestureDetector(onTap: () => context.go('/login'),
              child: const Text('Sign In', style: TextStyle(
                  color: AppColors.glow, fontWeight: FontWeight.w700))),
          ]),
        ),
      ])),
    );
  }

  String _selectedLabel() {
    switch (_selectedCard) {
      case 'farmer': return 'Farmer';
      case 'shopper': return 'Grocery Shopper';
      case 'chef': return 'Chef';
      case 'diner': return 'Diner';
      case 'aggregator': return 'Aggregator';
      case 'transporter': return 'Transporter';
      case 'distributor': return 'Distributor';
      default: return '';
    }
  }

  String _selectedEmoji() {
    switch (_selectedCard) {
      case 'farmer': return '🌾';
      case 'shopper': return '🛒';
      case 'chef': return '👨\u200d🍳';
      case 'diner': return '🥗';
      case 'aggregator': return '📦';
      case 'transporter': return '🚚';
      case 'distributor': return '🏬';
      default: return '';
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String image, title, subtitle;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        height: 132,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.08),
              width: selected ? 2.5 : 1),
          boxShadow: selected
              ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 20)]
              : null,
        ),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(image, fit: BoxFit.cover),
          // Darken for text legibility, tinted with the role's accent when
          // selected so each card keeps its own identity rather than all
          // four looking the same once picked.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.18)),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: AppTextStyles.poppins(20, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                SizedBox(
                  width: 210,
                  child: Text(subtitle,
                      maxLines: 3,
                      style: AppTextStyles.sans(12.5, color: Colors.white70)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.black.withValues(alpha: 0.35),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Icon(
                selected ? Icons.check : Icons.arrow_forward_ios_rounded,
                size: selected ? 16 : 12,
                color: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Compact role card for the supply-chain partner roles (Aggregator,
/// Transporter, Distributor), which don't have a dedicated illustration
/// asset yet — uses an icon + accent tint instead of [_RoleCard]'s photo.
class _IconRoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color accent;
  final bool selected;
  final int delayMs;
  final VoidCallback onTap;
  const _IconRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.08),
              width: selected ? 2.5 : 1),
          boxShadow: selected
              ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 20)]
              : null,
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.poppins(18, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 3),
              Text(subtitle,
                  maxLines: 2,
                  style: AppTextStyles.sans(12.5, color: Colors.white70)),
            ],
          )),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accent : Colors.black.withValues(alpha: 0.25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Icon(
              selected ? Icons.check : Icons.arrow_forward_ios_rounded,
              size: selected ? 15 : 11,
              color: Colors.white,
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.12, end: 0, delay: delayMs.ms, duration: 400.ms, curve: Curves.easeOut);
  }
}

/// Compact vertical card for the 2-column "I AM A..." grid — real
/// glassmorphism (frosted blur, not just a translucent fill) plus a soft
/// radial glow behind the icon tinted to that role's own accent color.
class _GridRoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color accent;
  final bool selected;
  final int delayMs;
  final VoidCallback onTap;
  const _GridRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: selected ? 0.22 : 0.10),
                  Colors.white.withValues(alpha: selected ? 0.08 : 0.03),
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: selected ? accent : Colors.white.withValues(alpha: 0.14),
                  width: selected ? 2 : 1),
              boxShadow: selected
                  ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 18)]
                  : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25),
                      blurRadius: 14, spreadRadius: 1)],
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const Spacer(),
              Text(title, style: AppTextStyles.poppins(15.5,
                  weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Expanded(
                child: Text(subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sans(11, color: Colors.white70, height: 1.3)),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.black.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    selected ? Icons.check : Icons.arrow_forward_ios_rounded,
                    size: selected ? 13 : 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideY(begin: 0.15, end: 0, delay: delayMs.ms, duration: 400.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1),
            delay: delayMs.ms, duration: 400.ms, curve: Curves.easeOut);
  }
}

/// The connected-network visual: farmer → aggregator → transporter →
/// distributor → chef → diner, as a small horizontal chain of icons.
/// This is the piece that turns "here's a list of six unrelated jobs"
/// into "you're joining one connected system."
class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip();

  static const _steps = [
    (Icons.grass_rounded, AppColors.farmerAccent),
    (Icons.inventory_2_outlined, AppColors.aggregatorAccent),
    (Icons.local_shipping_outlined, AppColors.transporterAccent),
    (Icons.storefront_outlined, AppColors.distributorAccent),
    (Icons.restaurant_outlined, AppColors.chefAccent),
    (Icons.dinner_dining_outlined, AppColors.mint),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 1.5, color: Colors.white.withValues(alpha: 0.15)),
            );
          }
          final (icon, color) = _steps[i ~/ 2];
          return Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, size: 15, color: color),
          );
        }),
      ),
    );
  }
}
