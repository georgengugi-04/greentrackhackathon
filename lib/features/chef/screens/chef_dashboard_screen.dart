import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../core/session/session_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../shared/widgets/scan_frame.dart';
import '../../shared/widgets/qr_camera_view.dart';
import '../../shared/widgets/animated_emoji.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../shared/widgets/premium_widgets.dart';

const _cropImages = {
  'Tomatoes':    'https://images.unsplash.com/photo-1546470427-f5dcc18e4b0d?w=600&q=80',
  'Lettuce':     'https://images.unsplash.com/photo-1622205313162-be1d5712a43f?w=600&q=80',
  'Carrots':     'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&q=80',
  'Avocado':     'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=600&q=80',
  'Basil':       'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?w=600&q=80',
};

class ChefDashboardScreen extends ConsumerStatefulWidget {
  const ChefDashboardScreen({super.key});

  @override
  ConsumerState<ChefDashboardScreen> createState() =>
      _ChefDashboardScreenState();
}

class _ChefDashboardScreenState extends ConsumerState<ChefDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final name = user?.restaurantName ?? user?.name ?? 'Chef';

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: IndexedStack(index: _navIndex, children: [
        _KitchenTab(
          restaurantName: name,
          onScanTap: () => setState(() => _navIndex = 1),
          onSeeAllMeals: () => setState(() => _navIndex = 2),
        ),
        const _VerifyTab(),
        _MealsTab(onMealTap: (mealId) => context.push('/chef/meal/$mealId')),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.chefAccent,
        icon: const Icon(Icons.restaurant, color: Colors.white),
        label: const Text('Build Meal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => context.push('/chef/meal-builder'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        selectedItemColor: AppColors.chefAccent,
        unselectedItemColor: AppColors.textSecondaryOf(context),
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Verify'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Meals'),
        ],
      ),
    );
  }
}

// ── KITCHEN TAB ───────────────────────────────────────────────────────────────

class _KitchenTab extends ConsumerWidget {
  final String restaurantName;
  final VoidCallback onScanTap;
  final VoidCallback onSeeAllMeals;
  const _KitchenTab({required this.restaurantName, required this.onScanTap,
      required this.onSeeAllMeals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(chefMealsProvider);
    final meals = mealsAsync.value ?? [];

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _ChefHeader(restaurantName: restaurantName)),
      // Stats row — only real, chef-specific counts. "Batches in" and
      // "Verified" were previously fixed at 3 / 100% regardless of what was
      // actually happening, which is exactly the kind of fake-looking-real
      // item this pass is meant to remove.
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          ModernStatCard(
            icon: Icons.restaurant_menu_rounded,
            color: AppColors.chefAccent,
            label: 'Meals',
            value: meals.length,
            caption: 'On menu',
          ),
        ]),
      )),
      // Scan banner
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GestureDetector(
          onTap: onScanTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.chefAccent.withValues(alpha: 0.8),
                    AppColors.chefAccent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.xl - 6),
              boxShadow: [BoxShadow(
                  color: AppColors.chefAccent.withValues(alpha: 0.4),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 28))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Scan Incoming Batch',
                    style: AppTextStyles.poppins(16, color: Colors.white, weight: FontWeight.w700)),
                Text('Verify farm origin, harvest time & certification',
                    style: AppTextStyles.poppins(12.5, color: Colors.white.withValues(alpha: 0.8))),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ]),
          ),
        ),
      )),
      // Meals
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(children: [
          Text('Your Meals', style: AppTextStyles.h2),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/chef/meal-builder'),
            child: const Text('Add new', style: TextStyle(
                color: AppColors.chefAccent, fontSize: 13,
                fontWeight: FontWeight.w600)),
          ),
        ]),
      )),
      if (meals.isEmpty)
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(children: [
              const Icon(Icons.restaurant_menu,
                  size: 30, color: AppColors.chefAccent),
              const SizedBox(height: 8),
              Text('No meals yet', style: AppTextStyles.poppins(14, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Tap "Add new" to build your first meal from real batches.',
                  style: AppTextStyles.poppins(12, color: AppColors.textSecondaryOf(context)),
                  textAlign: TextAlign.center),
            ]),
          ),
        ))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 0.86),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => context.push('/chef/meal/${meals[i].id}'),
                child: _MealGridCard(meal: meals[i]),
              ),
              childCount: meals.length > 4 ? 4 : meals.length,
            ),
          ),
        ),
      if (meals.length > 4)
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: GestureDetector(
            onTap: onSeeAllMeals,
            child: Text('View all ${meals.length} meals →',
                style: const TextStyle(color: AppColors.chefAccent,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        )),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }
}

class _ChefHeader extends ConsumerWidget {
  final String restaurantName;
  const _ChefHeader({required this.restaurantName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kitchen Dashboard',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondaryOf(context), fontSize: 12)),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: restaurantName,
                  style: AppTextStyles.poppins(24, weight: FontWeight.w800,
                      color: AppColors.chefAccent).copyWith(letterSpacing: -0.3)),
              const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: AnimatedEmoji('👨\u200d🍳', size: 22))),
            ])),
          ])),
          Consumer(builder: (context, ref, _) {
            final count = ref.watch(unreadNotificationCountProvider);
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/notifications'),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.chefAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.chefAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.chefAccent, size: 22),
                ),
                if (count > 0)
                  Positioned(top: -3, right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                          color: AppColors.red, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5)),
                      alignment: Alignment.center,
                      child: Text(count > 9 ? '9+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w800, height: 1)),
                    )),
              ]),
            );
          }),
          const SizedBox(width: 10),
          // The kitchen dashboard had no way at all to reach Profile/Settings,
          // which is where sign-out lives — tapping this was the missing
          // path that made it look like chefs "couldn't sign out".
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.push('/settings'),
            child: RingAvatar(
              photoUrl: user?.photoUrl,
              fallbackText: restaurantName,
              size: 48,
              completion: 1.0,
            ),
          ),
        ]),
      ),
    );
  }
}

class _MealGridCard extends StatelessWidget {
  final Meal meal;
  const _MealGridCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final n = meal.nutrition;
    return Container(
      decoration: BoxDecoration(color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card),
      clipBehavior: Clip.hardEdge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: Stack(fit: StackFit.expand, children: [
            meal.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: meal.photoUrl!, fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.chefAccent.withValues(alpha: 0.1)),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.chefAccent.withValues(alpha: 0.1),
                            child: const Icon(Icons.restaurant, size: 28)),
                  )
                : Container(color: AppColors.chefAccent.withValues(alpha: 0.1),
                    child: const Icon(Icons.restaurant, size: 28,
                        color: AppColors.chefAccent)),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                stops: const [0.5, 1.0],
              ),
            ))),
            Positioned(top: 8, right: 8, child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.leaf, shape: BoxShape.circle),
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meal.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTextStyles.poppins(13.5, weight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 2),
            Text('${n.calories.toStringAsFixed(0)} kcal',
                style: AppTextStyles.poppins(11, color: AppColors.textSecondaryOf(context))),
          ]),
        ),
      ]),
    );
  }
}

class _MealPhotoCard extends StatelessWidget {
  final Meal meal;
  const _MealPhotoCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final n = meal.nutrition;
    return Container(
      decoration: BoxDecoration(color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Meal photo — the chef's own upload if there is one, otherwise an
        // honest "no photo yet" placeholder rather than a stand-in stock
        // photo pretending to be this dish.
        SizedBox(height: 160, child: Stack(children: [
          Positioned.fill(child: meal.photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: meal.photoUrl!, fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.chefAccent.withValues(alpha: 0.1)),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.chefAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.restaurant, size: 40)),
                )
              : Container(color: AppColors.chefAccent.withValues(alpha: 0.1),
                  child: const Icon(Icons.restaurant, size: 40,
                      color: AppColors.chefAccent)),
          ),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
              stops: const [0.4, 1.0],
            ),
          ))),
          Positioned(bottom: 12, left: 14, right: 14, child: Row(children: [
            Expanded(child: Text(meal.name, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Published',
                  style: TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ])),
        ])),
        // Nutrition row
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _NutrChip('🔥', n.calories.toStringAsFixed(0), 'kcal'),
              _NutrChip('💪', '${n.proteinG.toStringAsFixed(1)}g', 'protein'),
              _NutrChip('🌾', '${n.carbsG.toStringAsFixed(1)}g', 'carbs'),
              _NutrChip('🥑', '${n.fatG.toStringAsFixed(1)}g', 'fat'),
            ]),
            const SizedBox(height: 10),
            // Ingredient photo strip
            Text('Ingredients from your batches',
                style: AppTextStyles.label.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            SizedBox(height: 50, child: ListView(
              scrollDirection: Axis.horizontal,
              children: meal.ingredients.map((ing) {
                final img = _cropImages[ing.cropName];
                return Container(
                  width: 50, height: 50, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderOf(context))),
                  clipBehavior: Clip.hardEdge,
                  child: img != null
                      ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.mint.withValues(alpha: 0.2)),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.eco, size: 20))
                      : Container(color: AppColors.mint.withValues(alpha: 0.2),
                          child: const Icon(Icons.eco, size: 20,
                              color: AppColors.leaf)),
                );
              }).toList(),
            )),
            const SizedBox(height: 10),
            // Allergen chips
            Wrap(spacing: 6, runSpacing: 6, children: meal.allergens.map((a) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: a.contains
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: a.contains
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${a.contains ? "⚠️ Contains" : "May contain"}: ${a.allergenId.label}',
                  style: TextStyle(fontSize: 11,
                      color: a.contains ? AppColors.error : AppColors.amber,
                      fontWeight: FontWeight.w600),
                ),
              )).toList(),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _NutrChip extends StatelessWidget {
  final String emoji, value, label;
  const _NutrChip(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    AnimatedEmoji(emoji, size: 18),
    Text(value, style: TextStyle(
        fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimaryOf(context))),
    Text(label, style: AppTextStyles.bodyMuted.copyWith(fontSize: 10)),
  ]);
}

// ── VERIFY & MEALS TABS ───────────────────────────────────────────────────────

class _VerifyTab extends ConsumerStatefulWidget {
  const _VerifyTab();
  @override
  ConsumerState<_VerifyTab> createState() => _VerifyTabState();
}

class _VerifyTabState extends ConsumerState<_VerifyTab> {
  bool _scanning = false;
  MobileScannerController? _controller;
  String? _scannedBatchId;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates);
    });
  }

  void _stopScan() {
    setState(() {
      _scanning = false;
      _controller?.dispose();
      _controller = null;
    });
  }

  void _onCodeDetected(String raw) {
    // Codes are printed as 'greentrack://batch/<id>' (see CropBatch.qrCodeData)
    // — same format the farmer/consumer scanner expects, so a chef and a
    // diner scanning the same crate get the same batch id out of it.
    _controller?.stop();
    final id = raw.startsWith('greentrack://batch/')
        ? raw.substring('greentrack://batch/'.length)
        : raw;
    setState(() {
      _scanning = false;
      _scannedBatchId = id;
    });
  }

  void _reset() {
    _controller?.dispose();
    setState(() {
      _controller = null;
      _scannedBatchId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Owns its own dark background regardless of app theme — this is the
    // shared "trace mode" visual identity (see ScannerScreen), just
    // recolored to the chef's amber accent instead of consumer mint.
    return ColoredBox(
      color: AppColors.night,
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: _scannedBatchId == null
            ? _ScanPrompt(
                scanning: _scanning,
                controller: _controller,
                onScan: _startScan,
                onStop: _stopScan,
                onCode: _onCodeDetected,
              )
            : Consumer(builder: (context, ref, _) {
                final traceAsync = ref.watch(traceResultProvider(_scannedBatchId!));
                return traceAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                  error: (e, _) => _VerifyNotFound(onReset: _reset, message: '$e'),
                  data: (result) => result == null
                      ? _VerifyNotFound(onReset: _reset)
                      : _VerifiedResult(result: result, onReset: _reset),
                );
              }),
      )),
    );
  }
}

class _VerifyNotFound extends StatelessWidget {
  final VoidCallback onReset;
  final String? message;
  const _VerifyNotFound({required this.onReset, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.qr_code_2_rounded, size: 56, color: Colors.white38),
        const SizedBox(height: 16),
        const Text('No batch found for that code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(message!, style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        FilledButton(onPressed: onReset, child: const Text('Try again')),
      ]),
    );
  }
}

class _ScanPrompt extends StatelessWidget {
  final bool scanning;
  final MobileScannerController? controller;
  final VoidCallback onScan;
  final VoidCallback onStop;
  final ValueChanged<String> onCode;
  const _ScanPrompt({
    required this.scanning,
    required this.controller,
    required this.onScan,
    required this.onStop,
    required this.onCode,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
    const Align(
      alignment: Alignment.centerRight,
      child: TraceModeBadge(label: 'Verify mode', accent: AppColors.chefAccent),
    ),
    const Spacer(),
    scanning && controller != null
        ? QrDetector(
            controller: controller!,
            onCode: onCode,
            child: LiveScanFrame(
                controller: controller!, accent: AppColors.chefAccent, size: 200),
          )
        : const DarkScanFrame(accent: AppColors.chefAccent, size: 200),
    const SizedBox(height: 24),
    Text(scanning ? 'Point the camera at the crate QR' : 'Scan incoming batch QR',
        style: AppTextStyles.poppins(20, weight: FontWeight.w700, color: Colors.white)),
    const SizedBox(height: 6),
    Text('Verify farm origin & certification',
        style: AppTextStyles.sans(13, color: Colors.white54)),
    const SizedBox(height: 32),
    ElevatedButton.icon(
      icon: Icon(scanning ? Icons.close_rounded : Icons.qr_code_scanner),
      label: Text(scanning ? 'Stop Scanning' : 'Scan QR Code'),
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.chefAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))),
      onPressed: scanning ? onStop : onScan,
    ),
    const Spacer(),
  ]);
}

class _VerifiedResult extends StatelessWidget {
  final BatchTraceResult result;
  final VoidCallback onReset;
  const _VerifiedResult({required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final imgUrl = _cropImages[result.cropName] ??
        'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=600&q=80';

    return SingleChildScrollView(child: Column(children: [
      // Batch photo
      Container(height: 200, width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          Positioned.fill(child: CachedNetworkImage(
              imageUrl: imgUrl, fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.chefAccent.withValues(alpha: 0.15)),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.chefAccent.withValues(alpha: 0.15)))),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  stops: const [0.4, 1.0])))),
          Positioned(bottom: 14, left: 14, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.verified, color: AppColors.mint, size: 18),
              SizedBox(width: 6),
              Text('Batch Verified', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            Text('Authentic GreenTrack supply chain',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      ...[
        ('Crop', result.cropName),
        ('Batch ID', result.batchId),
        ('Farm', result.farmName),
        ('Farmer', result.farmerName),
        ('Harvested', result.harvestedAt.toString().split(' ').first),
        ('Weight', '${result.actualYieldKg} kg'),
        ('Method', result.farmingMethod.name),
        ('Organic', result.isOrganicCertified ? 'Certified ✓' : 'No'),
      ].map((r) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12)),
        child: Row(children: [
          Text(r.$1, style: AppTextStyles.sans(13, color: Colors.white54)),
          const Spacer(),
          Text(r.$2, style: AppTextStyles.sans(14, color: Colors.white,
              weight: FontWeight.w700)),
        ]),
      )),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chefAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: onReset,
          child: const Text('Accept into Kitchen',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(width: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: onReset,
          child: const Text('Flag Issue'),
        ),
      ]),
    ]));
  }
}

class _MealsTab extends ConsumerWidget {
  final ValueChanged<String> onMealTap;
  const _MealsTab({required this.onMealTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(chefMealsProvider);
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('My Meals', style: AppTextStyles.h1),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.chefAccent),
            onPressed: () => context.push('/chef/meal-builder'),
          ),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(
                color: AppColors.chefAccent)),
            error: (e, _) => Center(child: Text('Could not load meals: $e')),
            data: (meals) {
              if (meals.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.restaurant_menu,
                        size: 36, color: AppColors.chefAccent),
                    const SizedBox(height: 10),
                    Text('No meals on your menu yet',
                        style: AppTextStyles.body(15)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Tap + to build your first one.',
                        style: AppTextStyles.bodyMuted),
                  ]),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 0.86),
                itemCount: meals.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => onMealTap(meals[i].id),
                  child: _MealGridCard(meal: meals[i]),
                ),
              );
            },
          ),
        ),
      ]),
    ));
  }
}
