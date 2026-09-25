import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';

// ── SUPPLIER SERVICE ────────────────────────────────────────────────────────
// Agricultural Suppliers (spec sections 18-22). Supplier requests reuse the
// same `marketplace_requests` collection and MarketplaceRequest model as
// produce requests — see MarketplaceRequestTarget in models.dart — so there
// is one request/status machinery for the whole marketplace, not two.
class SupplierService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection('supplier_profiles');

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('supplier_listings');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('marketplace_requests');

  // ── PROFILE ────────────────────────────────────────────────────────────

  /// One profile per userId — creating a second one for the same user
  /// would just fork "who is this supplier" across two docs, so this
  /// always updates the existing profile if the user already has one.
  Future<SupplierProfile> createOrUpdateProfile({
    required String userId,
    required String businessName,
    required String description,
    required SupplierCategory category,
    required String generalLocation,
    String? contactPhone,
    String? contactEmail,
    String? logoUrl,
  }) async {
    final now = DateTime.now();
    final existing = await getProfileForUser(userId);
    final profile = SupplierProfile(
      id: existing?.id ?? _uuid.v4(),
      userId: userId,
      businessName: businessName,
      description: description,
      category: category,
      generalLocation: generalLocation,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      logoUrl: logoUrl,
      // Editing an existing profile doesn't reset its verification; a
      // brand-new one always starts pending (section 19 — nobody can
      // self-claim verified).
      verificationStatus:
          existing?.verificationStatus ?? VerificationStatus.pending,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _profiles.doc(profile.id).set(profile.toFirestore());
    return profile;
  }

  Future<SupplierProfile?> getProfileForUser(String userId) async {
    final snap =
        await _profiles.where('userId', isEqualTo: userId).limit(1).get();
    return snap.docs.isEmpty
        ? null
        : SupplierProfile.fromFirestore(snap.docs.first);
  }

  Stream<SupplierProfile?> watchProfileForUser(String userId) => _profiles
      .where('userId', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : SupplierProfile.fromFirestore(s.docs.first));

  Future<SupplierProfile?> getProfile(String id) async {
    final doc = await _profiles.doc(id).get();
    return doc.exists ? SupplierProfile.fromFirestore(doc) : null;
  }

  // ── ADMIN VERIFICATION ───────────────────────────────────────────────────
  // Mirrors the existing supply-chain RoleRequest approve/reject pattern
  // (verification_service.dart) — separate here because a SupplierProfile
  // isn't a RoleRequest (see the design note in models.dart: supplier is
  // an add-on capability, not a new UserRole).

  Stream<List<SupplierProfile>> watchPendingProfiles() => _profiles
      .where('verificationStatus', isEqualTo: VerificationStatus.pending.name)
      .snapshots()
      .map((s) => s.docs.map(SupplierProfile.fromFirestore).toList());

  Future<void> setVerificationStatus(String profileId, VerificationStatus status) =>
      _profiles.doc(profileId).update({
        'verificationStatus': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

  // ── BROWSING SUPPLIERS ───────────────────────────────────────────────────

  Stream<List<SupplierProfile>> watchVerifiedSuppliers({SupplierCategory? category}) {
    Query<Map<String, dynamic>> q = _profiles.where('verificationStatus',
        isEqualTo: VerificationStatus.approved.name);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    return q.snapshots().map((s) => s.docs.map(SupplierProfile.fromFirestore).toList());
  }

  // ── LISTINGS ───────────────────────────────────────────────────────────

  Future<SupplierListing> createListing({
    required String supplierId,
    required String supplierName,
    required SupplierCategory category,
    required String name,
    required String description,
    String? photoUrl,
    double? price,
    String? unit,
  }) async {
    final now = DateTime.now();
    final listing = SupplierListing(
      id: _uuid.v4(),
      supplierId: supplierId,
      supplierName: supplierName,
      category: category,
      name: name,
      description: description,
      photoUrl: photoUrl,
      price: price,
      unit: unit,
      createdAt: now,
      updatedAt: now,
    );
    await _listings.doc(listing.id).set(listing.toFirestore());
    return listing;
  }

  Future<void> setListingStatus(String listingId, SupplierListingStatus status) =>
      _listings.doc(listingId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

  Future<SupplierListing?> getListing(String id) async {
    final doc = await _listings.doc(id).get();
    return doc.exists ? SupplierListing.fromFirestore(doc) : null;
  }

  Stream<List<SupplierListing>> watchMyListings(String supplierId) => _listings
      .where('supplierId', isEqualTo: supplierId)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SupplierListing.fromFirestore).toList());

  /// Active listings across all *verified* suppliers only — an unverified
  /// supplier's listings simply don't surface in the public directory yet
  /// (their "My Listings" screen still shows them, just not Agri Suppliers).
  Stream<List<SupplierListing>> watchDirectoryListings({SupplierCategory? category}) {
    Query<Map<String, dynamic>> q =
        _listings.where('status', isEqualTo: SupplierListingStatus.active.name);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    return q.snapshots().map((s) => s.docs.map(SupplierListing.fromFirestore).toList());
  }

  // ── REQUESTS (farmer -> supplier) ────────────────────────────────────────

  Future<MarketplaceRequest> createRequest({
    required SupplierListing listing,
    required String supplierUserId,
    required String buyerId,
    required String buyerName,
    required double quantity,
    required String unit,
    DateTime? preferredDate,
    String? message,
  }) async {
    final now = DateTime.now();
    final request = MarketplaceRequest(
      id: _uuid.v4(),
      listingId: listing.id,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: supplierUserId,
      quantity: quantity,
      unit: unit,
      intendedUse: IntendedUse.other,
      preferredDate: preferredDate,
      fulfilmentPreference: FulfilmentPreference.discuss,
      message: message,
      status: MarketplaceRequestStatus.pending,
      targetType: MarketplaceRequestTarget.supplier,
      createdAt: now,
      updatedAt: now,
    );
    await _requests.doc(request.id).set(request.toFirestore());
    return request;
  }

  // NOTE: sorted client-side rather than with an .orderBy() in the query —
  // two .where() equality filters plus an .orderBy() on a third field
  // requires a manually-created Firestore composite index. Fine at this
  // scale (a supplier's or buyer's own request list).
  Stream<List<MarketplaceRequest>> watchRequestsForSupplier(String supplierUserId) =>
      _requests
          .where('sellerId', isEqualTo: supplierUserId)
          .where('targetType', isEqualTo: MarketplaceRequestTarget.supplier.name)
          .snapshots()
          .map((s) {
        final list = s.docs.map(MarketplaceRequest.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Stream<List<MarketplaceRequest>> watchMyRequestsToSuppliers(String buyerId) =>
      _requests
          .where('buyerId', isEqualTo: buyerId)
          .where('targetType', isEqualTo: MarketplaceRequestTarget.supplier.name)
          .snapshots()
          .map((s) {
        final list = s.docs.map(MarketplaceRequest.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> updateRequestStatus(String requestId, MarketplaceRequestStatus status) =>
      _requests.doc(requestId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
}
