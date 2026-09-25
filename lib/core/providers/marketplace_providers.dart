import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/marketplace_service.dart';
import '../session/session_provider.dart';
import '../../data/models/models.dart';

final marketplaceServiceProvider =
    Provider<MarketplaceService>((_) => MarketplaceService());

// ── BROWSING ───────────────────────────────────────────────────────────────

final freshProduceProvider =
    StreamProvider.autoDispose<List<MarketplaceListing>>(
        (ref) => ref.read(marketplaceServiceProvider).watchFreshProduce());

final harvestingSoonProvider =
    StreamProvider.autoDispose<List<MarketplaceListing>>(
        (ref) => ref.read(marketplaceServiceProvider).watchHarvestingSoon());

final listingByIdProvider = FutureProvider.autoDispose
    .family<MarketplaceListing?, String>(
        (ref, id) => ref.read(marketplaceServiceProvider).getListing(id));

// ── FARMER SIDE ──────────────────────────────────────────────────────────

final myListingsProvider =
    StreamProvider.autoDispose<List<MarketplaceListing>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(marketplaceServiceProvider).watchMyListings(user.id);
});

final requestsForMyListingsProvider =
    StreamProvider.autoDispose<List<MarketplaceRequest>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(marketplaceServiceProvider).watchRequestsForSeller(user.id);
});

/// Whether the given batch already has a live marketplace listing —
/// drives "Publish to Marketplace" vs "Already listed" in the UI.
final listingForBatchProvider = FutureProvider.autoDispose
    .family<MarketplaceListing?, String>((ref, batchId) =>
        ref.read(marketplaceServiceProvider).listingForBatch(batchId));

// ── BUYER SIDE ───────────────────────────────────────────────────────────

final myRequestsProvider =
    StreamProvider.autoDispose<List<MarketplaceRequest>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(marketplaceServiceProvider).watchMyRequests(user.id);
});

final myFollowedListingsProvider =
    StreamProvider.autoDispose<List<MarketplaceListing>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(marketplaceServiceProvider).watchMyFollowedListings(user.id);
});

final isFollowingListingProvider =
    StreamProvider.autoDispose.family<bool, String>((ref, listingId) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref
      .read(marketplaceServiceProvider)
      .watchIsFollowing(listingId, user.id);
});

final requestsForListingProvider = StreamProvider.autoDispose
    .family<List<MarketplaceRequest>, String>((ref, listingId) => ref
        .read(marketplaceServiceProvider)
        .watchRequestsForListing(listingId));

// ── SINGLE REQUEST (used by messaging — works for both produce and
// supplier requests, since they share one collection) ──────────────────────

final requestByIdProvider = StreamProvider.autoDispose.family<MarketplaceRequest?, String>(
    (ref, id) => ref.read(marketplaceServiceProvider).watchRequest(id));
