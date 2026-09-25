import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/locale/locale_provider.dart';
import 'core/services/ai_vision_service.dart';
import 'core/services/unsplash_service.dart';
import 'core/services/soil_moisture_service.dart';
import 'firebase_options.dart';
import 'l10n/gen/app_localizations.dart';

// Supply at build/run time, e.g.:
//   flutter run --dart-define=VISION_API_KEY=your_key_here --dart-define=UNSPLASH_ACCESS_KEY=your_key_here --dart-define=SENTINEL_HUB_CLIENT_ID=xxx --dart-define=SENTINEL_HUB_CLIENT_SECRET=xxx
// Never hard-code a real key here — these constants are empty unless one is
// passed in on the command line, and are baked into the compiled app either
// way (see the AiVisionService/UnsplashService/SoilMoistureService doc
// comments for what that does and doesn't protect against).
const _visionApiKey = String.fromEnvironment('VISION_API_KEY');
const _unsplashAccessKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY');
const _sentinelHubClientId = String.fromEnvironment('SENTINEL_HUB_CLIENT_ID');
const _sentinelHubClientSecret = String.fromEnvironment('SENTINEL_HUB_CLIENT_SECRET');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (_visionApiKey.isNotEmpty) {
    AiVisionService.instance =
        FallbackVisionService(primary: RemoteVisionService(apiKey: _visionApiKey));
  }
  // else: AiVisionService.instance keeps its default, HeuristicVisionService.

  if (_unsplashAccessKey.isNotEmpty) {
    UnsplashService.instance = RemoteUnsplashService(accessKey: _unsplashAccessKey);
  }
  // else: UnsplashService.instance keeps its default, no-op (no auto photo).

  if (_sentinelHubClientId.isNotEmpty && _sentinelHubClientSecret.isNotEmpty) {
    SoilMoistureService.instance = RemoteSoilMoistureService(
      clientId: _sentinelHubClientId,
      clientSecret: _sentinelHubClientSecret,
    );
  }
  // else: SoilMoistureService.instance keeps its default, no-op (tile hidden).

  runApp(const ProviderScope(child: GreenTrackApp()));
}

class GreenTrackApp extends ConsumerWidget {
  const GreenTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'GreenTrack',
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
