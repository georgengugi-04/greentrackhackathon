import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:greentrack/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _progress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)));
    _ctrl.forward();
    // The background video (see assets/videos/growth_loop.mp4 — seed →
    // farm rows → leaf-QR) tells the "growth" story on its own now, so
    // the splash just needs to hold long enough to read as intentional,
    // not race the video's full 10s loop.
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fade,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Lottie.asset(
                      'assets/lottie/produce_loading.json',
                      repeat: true,
                      // The source composition has a lot of empty
                      // vertical canvas above/below the actual hand+
                      // produce artwork — cover (rather than contain)
                      // with an upward alignment crops that empty space
                      // out instead of rendering the icon tiny in the
                      // middle of the screen.
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.56),
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/images/logo_icon.png',
                              fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fade,
                  child: Column(children: [
                    // Brand name
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'green',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: 'track',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.appTagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]),
                ),
                const Spacer(flex: 3),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'v2.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
