import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supplier_service.dart';
import '../session/session_provider.dart';
import '../../data/models/models.dart';

final supplierServiceProvider =
    Provider<SupplierService>((_) => SupplierService());

// ── MY SUPPLIER PROFILE ──────────────────────────────────────────────────

final myMaybeSupplierProfileProvider =
    StreamProvider.autoDispose<SupplierProfile?>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(supplierServiceProvider).watchProfileForUser(user.id);
});

// ── ADMIN VERIFICATION QUEUE ─────────────────────────────────────────────

final pendingSupplierProfilesProvider =
    StreamProvider.autoDispose<List<SupplierProfile>>(
        (ref) => ref.read(supplierServiceProvider).watchPendingProfiles());

// ── BROWSING ─────────────────────────────────────────────────────────────

final supplierDirectoryProvider = StreamProvider.autoDispose
    .family<List<SupplierListing>, SupplierCategory?>(
        (ref, category) => ref
            .read(supplierServiceProvider)
            .watchDirectoryListings(category: category));

final verifiedSuppliersProvider = StreamProvider.autoDispose
    .family<List<SupplierProfile>, SupplierCategory?>((ref, category) => ref
        .read(supplierServiceProvider)
        .watchVerifiedSuppliers(category: category));

final supplierProfileByIdProvider = FutureProvider.autoDispose
    .family<SupplierProfile?, String>(
        (ref, id) => ref.read(supplierServiceProvider).getProfile(id));

final supplierListingByIdProvider = FutureProvider.autoDispose
    .family<SupplierListing?, String>(
        (ref, id) => ref.read(supplierServiceProvider).getListing(id));

// ── SUPPLIER SIDE (managing my own listings/requests) ───────────────────

final mySupplierListingsProvider =
    StreamProvider.autoDispose.family<List<SupplierListing>, String>(
        (ref, supplierId) =>
            ref.read(supplierServiceProvider).watchMyListings(supplierId));

final requestsForMySupplierProvider =
    StreamProvider.autoDispose.family<List<MarketplaceRequest>, String>(
        (ref, supplierUserId) => ref
            .read(supplierServiceProvider)
            .watchRequestsForSupplier(supplierUserId));

// ── FARMER SIDE (my requests to suppliers) ───────────────────────────────

final myRequestsToSuppliersProvider =
    StreamProvider.autoDispose<List<MarketplaceRequest>>((ref) {
  final user = ref.watch(sessionProvider);
  if (user == null) return const Stream.empty();
  return ref.read(supplierServiceProvider).watchMyRequestsToSuppliers(user.id);
});
