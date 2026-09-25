import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const Color forest = Color(0xFF1B4332);
  static const Color leaf = Color(0xFF40916C);
  static const Color mint = Color(0xFF95D5B2);
  // Unified brand accent — CTAs, highlights, active states across every
  // role's dashboard (farmer, chef, distributor, consumer). Previously
  // each role had its own accent (farmer green, chef amber/orange,
  // distributor purple) which read as three different products; this is
  // the one color used for that job everywhere now.
  static const Color growthAccent = Color(0xFF52B788);
  static const Color amber = Color(0xFFD4A017);
  static const Color parchment = Color(0xFFF7FAF8); // "clean agricultural white" per brand spec
  static const Color error = Color(0xFFB3261E);
  static const Color textPrimary = Color(0xFF1B2420);
  static const Color textSecondary = Color(0xFF5C6B62);
  static const Color border = Color(0xFFE2DED2);

  // Role accents
  static const Color farmerAccent = leaf;
  static const Color chefAccent = growthAccent;
  static const Color consumerAccent = Color(0xFF2D6CDF);
  static const Color aggregatorAccent = Color(0xFFB07254);
  static const Color transporterAccent = Color(0xFF1B7A93);
  static const Color distributorAccent = Color(0xFF6B3FA0);

  // ── Extended tokens ────────────────────────────────────────────────
  // Additive aliases so every screen in the app (including the dark/glassy
  // "trace" screens and the crops/dashboard/analytics screens) resolves to
  // one consistent palette instead of each referencing colors that were
  // never defined.
  static const Color night = Color(0xFF0F1B14); // dark screen background
  static const Color canopy = forest; // dark hero gradient top
  static const Color glow = mint; // accent glow on dark backgrounds
  static const Color soil = textPrimary; // dark text on light cards
  static const Color slate = textSecondary;
  static const Color slateLight = Color(0xFF8A968D);
  static const Color slateMid = Color(0xFF6E7B72);
  static const Color mist = Color(0xFFEFF3EE);
  static const Color harvest = amber;
  static const Color bark = Color(0xFF6B4226);
  static const Color sprout = mint;
  static const Color clay = Color(0xFFB07254);
  static const Color charcoal = Color(0xFF2A2E2B);
  static const Color alert = Color(0xFFD97706);
  static const Color cream = parchment;
  static const Color paleGreen = Color(0xFFE8F3EA);
  static const Color amberPale = Color(0xFFFBEFD2);
  static const Color borderLight = Color(0xFFEFECE3);
  static const Color blue = Color(0xFF2D6CDF);
  static const Color blueLight = Color(0xFFE3ECFB);
  static const Color purple = Color(0xFF6B3FA0);
  static const Color purpleLight = Color(0xFFEDE3F5);
  static const Color red = error;
  static const Color redLight = Color(0xFFF6E1DF);
  static const Color success = Color(0xFF2E7D46);
  static const Color successLight = Color(0xFFE1F0E5);
  static const Color errorLight = Color(0xFFF6E1DF);

  // ── Premium design-system tokens ──────────────────────────────────
  // Scoped to the new Premium* widgets (profile/settings/dashboard
  // redesign) rather than swapped in as the app-wide primary/secondary —
  // doing that blindly would ripple into every chef/consumer/farmer
  // screen with no visual QA pass. These give those specific widgets the
  // requested Notion/Revolut-style palette without that blast radius.
  static const Color premiumForest = Color(0xFF1B5E20);
  static const Color premiumEmerald = Color(0xFF2E7D32);
  static const Color premiumSuccess = Color(0xFF4CAF50);
  static const Color premiumWarning = Color(0xFFF9A825);
  static const LinearGradient premiumBackground = LinearGradient(
    colors: [Color(0xFFF8FAF6), Color(0xFFEEF6EC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient premiumHeaderGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradient = heroGradient;
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF8F4EE), Color(0xFFEFF3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF95D5B2), Color(0xFF40916C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Dark theme palette ────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D1B12); // spec: neutral dark mode surface
  static const Color darkSurface = Color(0xFF17221A);
  static const Color darkCard = Color(0xFF1D2A21);
  static const Color darkBorder = Color(0xFF2C3A31);
  static const Color darkTextPrimary = Color(0xFFEDF3EE);
  static const Color darkTextSecondary = Color(0xFFA3B5AA);

  /// Screen/scaffold background — swaps between the light parchment and
  /// the dark palette based on the active theme. Screens should call this
  /// (or [card]/[textPrimaryOf]/[textSecondaryOf]/[borderOf]) instead of
  /// hardcoding `AppColors.parchment` / `Colors.white` directly, since
  /// those are compile-time constants and can't respond to a runtime
  /// theme toggle.
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : parchment;

  /// Card/elevated-surface background.
  static Color cardOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : Colors.white;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : border;

  // Farmer's own light-mode background — a soft sage rather than white or
  // parchment, so white cards actually stand out instead of blending in.
  static const Color farmerSurfaceLight = Color(0xFFE1EAD9);

  static Color farmerSurfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : farmerSurfaceLight;
}

class AppTextStyles {
  AppTextStyles._();
  static TextStyle display(double size, {Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color,
        height: height,
      );
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );
  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static TextStyle body(double size, {Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        height: height,
      );
  static TextStyle bodyMuted = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );
  static TextStyle mono(double size, {Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  /// General sans-serif text at an arbitrary size — used by screens that
  /// need finer control than the fixed h1/h2/body/label sizes above.
  static TextStyle sans(double size, {Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight ?? FontWeight.w400,
        height: height,
      );

  /// Display/serif text at an arbitrary size (headlines, hero text).
  static TextStyle serif(double size, {Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        color: color,
        fontWeight: weight ?? FontWeight.w600,
        height: height,
      );

  /// Poppins — used specifically by the Premium* widgets (profile header,
  /// stat cards, achievement badges, settings tiles) per the redesign
  /// brief. Kept separate from [sans]/[body] (Inter) rather than swapping
  /// the whole app's font, since that's a much bigger, riskier change
  /// than what was actually asked for on these screens.
  static TextStyle poppins(double size, {Color? color, FontWeight? weight, double? height}) =>
      GoogleFonts.poppins(
        fontSize: size,
        color: color,
        fontWeight: weight ?? FontWeight.w400,
        height: height,
      );
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;
  static const double xl = 28; // Premium* widgets — profile/stat/badge cards
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> large = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
  static List<BoxShadow> fab = [
    BoxShadow(
      color: AppColors.forest.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.parchment,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      secondary: AppColors.leaf,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.parchment,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: AppTextStyles.poppins(20,
          weight: FontWeight.w700, color: AppColors.textPrimary)
          .copyWith(letterSpacing: -0.2),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: Brightness.dark,
      primary: AppColors.mint,
      secondary: AppColors.leaf,
      error: const Color(0xFFE28B87),
      surface: AppColors.darkSurface,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: AppTextStyles.poppins(20,
          weight: FontWeight.w700, color: AppColors.darkTextPrimary)
          .copyWith(letterSpacing: -0.2),
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.darkBg,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: AppTextStyles.body(14).copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}
