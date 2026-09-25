import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../services/firebase_service.dart';
import '../services/verification_service.dart';
import '../services/weather_service.dart';
import '../services/irrigation_advisor.dart';
import '../services/soil_moisture_service.dart';
import '../services/nutrition_api_service.dart';
import '../services/climate_intelligence_service.dart';
import '../models/climate_models.dart';
import '../../data/models/models.dart';

// ── AUTH ──────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());
final batchServiceProvider = Provider<BatchService>((_) => BatchService());
final verificationServiceProvider = Provider<VerificationService>((_) => VerificationService());

// ── VERIFICATION (Aggregator / Transporter / Distributor trust gate) ─────

/// Live status of the signed-in user's own access request — null if they
/// never submitted one (e.g. got in via an invite code instead).
final myRoleRequestProvider = StreamProvider.autoDispose<RoleRequest?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ref.read(verificationServiceProvider).watchMyRoleRequest(uid);
});

/// The admin review queue — every request still awaiting a decision.
final pendingRoleRequestsProvider =
    StreamProvider.autoDispose<List<RoleRequest>>((ref) {
  return ref.read(verificationServiceProvider).watchPendingRequests();
});

/// Whether the signed-in user is allowed into /admin/approvals.
final isAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return false;
  return ref.read(verificationServiceProvider).isAdmin(uid);
});

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.read(authServiceProvider).authStateChanges);

final currentUserIdProvider =
    Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

final appUserProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return ref.read(authServiceProvider).getAppUser(uid);
});

// ── FARMER DATA ───────────────────────────────────────

final farmerBatchesProvider =
    StreamProvider.autoDispose<List<CropBatch>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.read(batchServiceProvider).watchBatches(uid);
});

final activeBatchesProvider = Provider.autoDispose<List<CropBatch>>((ref) {
  final batches = ref.watch(farmerBatchesProvider).value ?? [];
  return batches.where((b) => b.stage != CropStage.harvested).toList();
});

final phiLockedBatchesProvider = Provider.autoDispose<List<CropBatch>>((ref) {
  final batches = ref.watch(farmerBatchesProvider).value ?? [];
  return batches.where((b) => b.harvestLockedByPHI).toList();
});

final readyToHarvestProvider = Provider.autoDispose<List<CropBatch>>((ref) {
  final batches = ref.watch(farmerBatchesProvider).value ?? [];
  return batches
      .where((b) => b.stage == CropStage.readyToHarvest && !b.harvestLockedByPHI)
      .toList();
});

final totalYieldProvider = Provider.autoDispose<double>((ref) {
  final batches = ref.watch(farmerBatchesProvider).value ?? [];
  return batches.fold(0.0, (total, b) => total + (b.verifiedWeightKg ?? 0));
});

/// Looks up a single real batch by id from the farmer's live batch stream —
/// used by the batch detail screen so tapping different crops actually
/// shows different data instead of one hardcoded sample batch.
final batchByIdProvider =
    Provider.autoDispose.family<AsyncValue<CropBatch?>, String>((ref, id) {
  final batchesAsync = ref.watch(farmerBatchesProvider);
  return batchesAsync.whenData(
      (batches) => batches.where((b) => b.id == id).firstOrNull);
});

// ── SUPPLY CHAIN (Aggregator / Transporter / Distributor) ────────────────
// These three roles need visibility across every farmer's batches, not
// just their own — so they watch the whole `batches` collection and filter
// client-side by custodyStage rather than a scoped `where(farmerId: ...)`.

final allBatchesProvider = StreamProvider.autoDispose<List<CropBatch>>((ref) {
  return ref.read(batchServiceProvider).watchAllBatches();
});

/// Harvested batches still sitting at the farm, waiting to be picked up
/// by an Aggregator.
final incomingForAggregatorProvider =
    Provider.autoDispose<List<CropBatch>>((ref) {
  final batches = ref.watch(allBatchesProvider).value ?? [];
  return batches
      .where((b) =>
          b.stage == CropStage.harvested &&
          b.custodyStage == CustodyStage.atFarm)
      .toList();
});

/// Batches currently held by *this* aggregator.
final aggregatorHeldBatchesProvider =
    Provider.autoDispose<List<CropBatch>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final batches = ref.watch(allBatchesProvider).value ?? [];
  return batches
      .where((b) =>
          b.custodyStage == CustodyStage.withAggregator &&
          b.currentHolderId == uid)
      .toList();
});

/// Batches an aggregator has released, waiting for a Transporter pickup.
final incomingForTransporterProvider =
    Provider.autoDispose<List<CropBatch>>((ref) {
  final batches = ref.watch(allBatchesProvider).value ?? [];
  return batches
      .where((b) => b.custodyStage == CustodyStage.withAggregator)
      .toList();
});

/// Batches currently in transit with *this* transporter.
final transporterHeldBatchesProvider =
    Provider.autoDispose<List<CropBatch>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final batches = ref.watch(allBatchesProvider).value ?? [];
  return batches
      .where((b) =>
          b.custodyStage == CustodyStage.inTransit &&
          b.currentHolderId == uid)
      .toList();
});

/// Batches in transit, waiting for a Distributor to receive them.
final incomingForDistributorProvider =
    Provider.autoDispose<List<CropBatch>>((ref) {
  final batches = ref.watch(allBatchesProvider).value ?? [];
  return batches
      .where((b) => b.custodyStage == CustodyStage.inTransit)
      .toList();
});

/// Batches currently held by *this* distributor, ready to hand off to a
/// Chef or Grocery Shopper.
final distributorHeldBatchesProvider =
    Provider.autoDispose<List<CropBatch>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final batches = ref.watch(allBatchesProvider).value ?? [];
  return batches
      .where((b) =>
          b.custodyStage == CustodyStage.withDistributor &&
          b.currentHolderId == uid)
      .toList();
});

/// Full custody trail for one batch — Aggregator/Transporter/Distributor
/// handoffs in chronological order.
final custodyChainProvider =
    StreamProvider.autoDispose.family<List<CustodyEvent>, String>((ref, id) {
  return ref.read(batchServiceProvider).watchCustodyChain(id);
});

// ── WEATHER + IRRIGATION ADVISOR (AI feature) ─────────
// Uses the plot of the farmer's most recently planted active batch as the
// forecast location, falling back to a default farm location so the card
// still has something sensible to show for a brand-new account.

const _defaultFarmLocation = GeoPoint(-1.286389, 36.817223); // Nairobi

final farmLocationProvider = Provider.autoDispose<GeoPoint>((ref) {
  final batches = ref.watch(activeBatchesProvider);
  return batches.isNotEmpty ? batches.first.plotLocation : _defaultFarmLocation;
});

final weatherServiceProvider = Provider<WeatherService>((_) => WeatherService());

final weatherProvider = FutureProvider.autoDispose<WeatherSnapshot>((ref) {
  final loc = ref.watch(farmLocationProvider);
  return ref
      .read(weatherServiceProvider)
      .fetchCurrent(lat: loc.lat, lng: loc.lng);
});

// Sentinel-1 SAR soil moisture for the farmer's plot — null when no
// Sentinel Hub credentials are configured or no recent satellite pass is
// available; the Farm Zone card hides its tile in that case rather than
// showing an error.
final soilMoistureProvider =
    FutureProvider.autoDispose<SoilMoistureReading?>((ref) {
  final loc = ref.watch(farmLocationProvider);
  return SoilMoistureService.instance.fetchFor(loc.lat, loc.lng);
});

final irrigationAdviceProvider =
    Provider.autoDispose<AsyncValue<List<IrrigationAdvice>>>((ref) {
  final weatherAsync = ref.watch(weatherProvider);
  final batches = ref.watch(activeBatchesProvider);
  return weatherAsync.whenData(
      (weather) => IrrigationAdvisor.adviseAll(batches, weather));
});

// ── CLIMATE INTELLIGENCE (Hack The Weather — JKUAT/JHUB station) ────
// See core/services/climate_intelligence_service.dart: tries live
// Firestore data first, falls back to the bundled historical/demo
// snapshot — never mislabeled either way.

final climateIntelligenceServiceProvider =
    Provider<ClimateIntelligenceService>((_) => ClimateIntelligenceService());

final climateSnapshotProvider = FutureProvider.autoDispose<ClimateSnapshot>((ref) {
  return ref.read(climateIntelligenceServiceProvider).getSnapshot();
});

// ── QR TRACE (consumer-side) ─────────────────────────

final traceResultProvider =
    FutureProvider.autoDispose.family<BatchTraceResult?, String>(
  (ref, batchId) => ref.read(batchServiceProvider).traceByQr(batchId),
);

final mealTraceResultProvider =
    FutureProvider.autoDispose.family<Meal?, String>(
  (ref, mealId) => ref.read(mealServiceProvider).getMeal(mealId),
);

// ── CHEF DATA (MEALS) ─────────────────────────────────

final mealServiceProvider = Provider<MealService>((_) => MealService());
final nutritionApiServiceProvider =
    Provider<NutritionApiService>((_) => NutritionApiService());

final chefMealsProvider = StreamProvider.autoDispose<List<Meal>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.read(mealServiceProvider).watchMeals(uid);
});

/// Looks up a single meal by id from the chef's own live meal stream —
/// same "derive from the list already being watched" pattern as
/// batchByIdProvider, so the detail screen updates live with the list.
final mealByIdProvider =
    Provider.autoDispose.family<AsyncValue<Meal?>, String>((ref, id) {
  final mealsAsync = ref.watch(chefMealsProvider);
  return mealsAsync.whenData(
      (meals) => meals.where((m) => m.id == id).firstOrNull);
});

// ── FARM DOCUMENTATION ────────────────────────────────

final documentServiceProvider = Provider<DocumentService>((_) => DocumentService());

final farmerDocumentsProvider = StreamProvider.autoDispose<List<FarmDocument>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const Stream.empty();
  return ref.read(documentServiceProvider).watchDocuments(uid);
});
