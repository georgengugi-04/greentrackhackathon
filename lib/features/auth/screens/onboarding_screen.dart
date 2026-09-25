import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/animated_emoji.dart';
import '../../shared/widgets/chef_cooking_illustration.dart';
import '../../shared/widgets/farmer_growing_illustration.dart';
import '../../shared/widgets/diner_eating_illustration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final List<_Slide> _slides = const [
    _Slide(
      gradient: [Color(0xFF0D3320), Color(0xFF1B4332), Color(0xFF2D6A4F)],
      photoUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=900&q=80',
      emoji: '🌱',
      tag: 'FOR FARMERS',
      title: 'Log Every Batch',
      body:
          'Record every crop batch from planting to harvest, complete with irrigation, '
          'pest treatments, and PHI safety windows — then generate a QR code the whole '
          'supply chain can trust.',
      features: [
        _Feature('📸', 'AI Pest & Disease Scans'),
        _Feature('💧', 'Smart Irrigation Advice'),
        _Feature('🔖', 'One QR Per Batch'),
      ],
    ),
    _Slide(
      gradient: [Color(0xFF7A4200), Color(0xFFB7791F), Color(0xFFD4A017)],
      photoUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=900&q=80',
      emoji: '👨‍🍳',
      tag: 'FOR CHEFS',
      title: 'Verify What You Cook With',
      body:
          'Scan incoming batches to confirm farm origin, harvest date, and organic '
          'certification in seconds, then build meals with full nutrition and allergen '
          'info ready for the menu.',
      features: [
        _Feature('✅', 'Instant Batch Verification'),
        _Feature('🍽️', 'Meal & Allergen Builder'),
        _Feature('📊', 'Nutrition Snapshots'),
      ],
    ),
    _Slide(
      gradient: [Color(0xFF1A3A6B), Color(0xFF2D6CDF), Color(0xFF4D8FEF)],
      photoUrl: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=900&q=80',
      emoji: '🍽️',
      tag: 'FOR SHOPPERS & DINERS',
      title: 'Know Where It Came From',
      body:
          'Scan the QR code on your produce or your restaurant menu to trace it straight '
          'back to the farm — the plot, the farmer, the harvest date, all in one tap.',
      features: [
        _Feature('🔍', 'Farm-to-Table Trace'),
        _Feature('🌾', 'Real Harvest Data'),
        _Feature('🛡️', 'Verified Organic Claims'),
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      context.go('/welcome');
    }
  }

  void _back() {
    _controller.previousPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlidePage(key: ValueKey(i), slide: _slides[i]),
          ),
          // Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: () => context.go('/welcome'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Skip',
                      style: AppTextStyles.poppins(14, color: Colors.white,
                          weight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        if (_page > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _back,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Colors.white54, width: 1.5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                              child: Text('Back',
                                  style: AppTextStyles.poppins(15.5,
                                      color: Colors.white, weight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _page == _slides.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: AppTextStyles.poppins(16,
                                      weight: FontWeight.w700, color: Colors.black87),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _page == _slides.length - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: slide.gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real photo backdrop — given real presence (not a near-invisible
          // wash) but still clearly secondary to the gradient + content,
          // so it reads as "this is a real farm/kitchen/table" texture
          // rather than decoration nobody notices.
          Opacity(
            opacity: 0.4,
            child: CachedNetworkImage(
              imageUrl: slide.photoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  slide.gradient.first.withValues(alpha: 0.65),
                  slide.gradient.last.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Icon circle — soft glow behind it so it reads as the
                  // hero element instead of a flat translucent disc.
                  Center(
                    child: Container(
                      width: 172,
                      height: 172,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 30, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Center(
                        child: switch (slide.tag) {
                          'FOR CHEFS' => const ChefCookingIllustration(size: 145),
                          'FOR FARMERS' => const FarmerGrowingIllustration(size: 145),
                          'FOR SHOPPERS & DINERS' => const DinerEatingIllustration(size: 145),
                          _ => AnimatedEmoji(slide.emoji, size: 70),
                        },
                      ),
                    ),
                  ).animate().fadeIn(duration: 450.ms).scale(
                      begin: const Offset(0.85, 0.85), end: const Offset(1, 1),
                      duration: 450.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 32),
                  // Tag
                  Text(
                    slide.tag,
                    style: AppTextStyles.poppins(11.5,
                        color: Colors.white.withValues(alpha: 0.75),
                        weight: FontWeight.w700)
                        .copyWith(letterSpacing: 2),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, delay: 150.ms, duration: 400.ms,
                          curve: Curves.easeOut),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    slide.title,
                    style: AppTextStyles.poppins(33,
                        color: Colors.white, weight: FontWeight.w800, height: 1.12)
                        .copyWith(letterSpacing: -0.5),
                  ).animate().fadeIn(delay: 220.ms, duration: 450.ms)
                      .slideY(begin: 0.25, end: 0, delay: 220.ms, duration: 450.ms,
                          curve: Curves.easeOut),
                  const SizedBox(height: 16),
                  // Body
                  Text(
                    slide.body,
                    style: AppTextStyles.poppins(14.5,
                        color: Colors.white.withValues(alpha: 0.88), height: 1.55),
                  ).animate().fadeIn(delay: 300.ms, duration: 450.ms)
                      .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 450.ms,
                          curve: Curves.easeOut),
                  const SizedBox(height: 28),
                  // Features
                  ...slide.features.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: AnimatedEmoji(entry.value.emoji, size: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              entry.value.label,
                              style: AppTextStyles.poppins(14.5,
                                  color: Colors.white, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: (380 + entry.key * 80).ms, duration: 400.ms)
                          .slideX(begin: -0.1, end: 0,
                              delay: (380 + entry.key * 80).ms, duration: 400.ms,
                              curve: Curves.easeOut)),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final List<Color> gradient;
  final String photoUrl;
  final String emoji, tag, title, body;
  final List<_Feature> features;
  const _Slide({
    required this.gradient,
    required this.photoUrl,
    required this.emoji,
    required this.tag,
    required this.title,
    required this.body,
    required this.features,
  });
}

class _Feature {
  final String emoji, label;
  const _Feature(this.emoji, this.label);
}
