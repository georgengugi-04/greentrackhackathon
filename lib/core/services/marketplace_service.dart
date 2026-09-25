import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';

// ── MARKETPLACE SERVICE ─────────────────────────────────────
// Listings reference an existing CropBatch by id rather than copying its
// crop/harvest fields — see the comment above MarketplaceListing in
// models.dart. This service never creates a second harvest record; it only
// ever reads batch data to seed a listing, and later reads it again to
// confirm the harvest actually happened.
class MarketplaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('marketplace_listings');

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('marketplace_requests');

  CollectionReference<Map<String, dynamic>> get _followers =>
      _db.collection('harvest_followers');

  CollectionReference<Map<String, dynamic>> get _batches =>
      _db.collection('batches');

  // ── PUBLISHING ─────────────────────────────────────────────────────────

  /// Publishes a batch to the marketplace. Farmer-initiated only — nothing
  /// in this service auto-publishes a batch (section 4: "the farmer must
  /// always have control over whether a harvest becomes public").
  Future<MarketplaceListing> publishBatch({
    required CropBatch batch,
    required String farmerName,
    required String generalLocation,
    double? pricePerUnit,
    String unit = 'kg',
  }) async {
    final now = DateTime.now();
    final alreadyHarvested = batch.harvestedAt != null;
    final quantity =
        batch.verifiedWeightKg ?? batch.estimatedYieldKg ?? 0.0;

    final listing = MarketplaceListing(
      id: _uuid.v4(),
      batchId: batch.id,
      farmerId: batch.farmerId,
      farmerName: farmerName,
      cropName: batch.cropName,
      generalLocation: generalLocation,
      quantity: quantity,
      availableQuantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
      expectedHarvestDate: batch.estimatedHarvestDate,
      harvestedAt: batch.harvestedAt,
      status: alreadyHarvested
          ? MarketplaceListingStatus.available
          : MarketplaceListingStatus.upcoming,
      photoUrl: batch.photoUrl,
      createdAt: now,
      updatedAt: now,
    );
    await _listings.doc(listing.id).set(listing.toFirestore());
    return listing;
  }

  /// True if this batch already has a live (non-removed) listing — used to
  /// show "Publish to Marketplace" vs "Already listed" and to stop a
  /// farmer accidentally double-publishing the same batch.
  Future<MarketplaceListing?> listingForBatch(String batchId) async {
    final snap = await _listings.where('batchId', isEqualTo: batchId).get();
    final live = snap.docs
        .map(MarketplaceListing.fromFirestore)
        .where((l) => l.status != MarketplaceListingStatus.removed);
    return live.isEmpty ? null : live.first;
  }

  Future<void> setStatus(String listingId, MarketplaceListingStatus status) =>
      _listings.doc(listingId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

  Future<void> removeListing(String listingId) =>
      setStatus(listingId, MarketplaceListingStatus.removed);

  /// Called once the linked batch's harvest is actually logged — transitions
  /// HARVESTING SOON -> AVAILABLE NOW using the batch's own confirmed
  /// yield, and notifies followers via the existing live-notification
  /// pipeline (see notifications_provider.dart) rather than a new one.
  Future<void> confirmHarvestOnListing(String listingId) async {
    final doc = await _listings.doc(listingId).get();
    if (!doc.exists) return;
    final listing = MarketplaceListing.fromFirestore(doc);
    final batchDoc = await _batches.doc(listing.batchId).get();
    if (!batchDoc.exists) return;
    final batch = CropBatch.fromFirestore(batchDoc);
    if (batch.harvestedAt == null) return;

    final confirmedQty = batch.verifiedWeightKg ?? listing.quantity;
    await _listings.doc(listingId).update({
      'status': MarketplaceListingStatus.available.name,
      'quantity': confirmedQty,
      'availableQuantity': confirmedQty,
      'harvestedAt': Timestamp.fromDate(batch.harvestedAt!),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── BROWSING ───────────────────────────────────────────────────────────

  Stream<List<MarketplaceListing>> watchFreshProduce() => _listings
      .where('status', isEqualTo: MarketplaceListingStatus.available.name)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(MarketplaceListing.fromFirestore).toList());

  Stream<List<MarketplaceListing>> watchHarvestingSoon() => _listings
      .where('status', isEqualTo: MarketplaceListingStatus.upcoming.name)
      .orderBy('expectedHarvestDate')
      .snapshots()
      .map((s) => s.docs.map(MarketplaceListing.fromFirestore).toList());

  Stream<List<MarketplaceListing>> watchMyListings(String farmerId) =>
      _listings
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(MarketplaceListing.fromFirestore).toList());

  Future<MarketplaceListing?> getListing(String id) async {
    final doc = await _listings.doc(id).get();
    return doc.exists ? MarketplaceListing.fromFirestore(doc) : null;
  }

  // ── SINGLE REQUEST LOOKUP ────────────────────────────────────────────────
  // `_requests` is the same `marketplace_requests` collection used for both
  // produce and supplier requests (see MarketplaceRequestTarget) — this is
  // the one place messaging needs a request regardless of which kind it is.

  Future<MarketplaceRequest?> getRequest(String id) async {
    final doc = await _requests.doc(id).get();
    return doc.exists ? MarketplaceRequest.fromFirestore(doc) : null;
  }

  Stream<MarketplaceRequest?> watchRequest(String id) => _requests
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? MarketplaceRequest.fromFirestore(d) : null);

  // ── FOLLOWING ("Notify Me") ─────────────────────────────────────────────

  Stream<bool> watchIsFollowing(String listingId, String userId) => _followers
      .where('listingId', isEqualTo: listingId)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.isNotEmpty);

  Future<void> follow(String listingId, String userId) async {
    final existing = await _followers
        .where('listingId', isEqualTo: listingId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    final follower = HarvestFollower(
      id: _uuid.v4(),
      listingId: listingId,
      userId: userId,
      createdAt: DateTime.now(),
    );
    await _followers.doc(follower.id).set(follower.toFirestore());
  }

  Future<void> unfollow(String listingId, String userId) async {
    final existing = await _followers
        .where('listingId', isEqualTo: listingId)
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
  }

  /// Listings a user follows that are UPCOMING (still "Harvesting Soon") —
  /// used to build the "followed harvest is now available" notification by
  /// comparing against [watchMyFollowedListings] results once harvested.
  Stream<List<MarketplaceListing>> watchMyFollowedListings(
      String userId) async* {
    final followSnap =
        await _followers.where('userId', isEqualTo: userId).get();
    final listingIds =
        followSnap.docs.map((d) => d['listingId'] as String).toSet().toList();
    if (listingIds.isEmpty) {
      yield const [];
      return;
    }
    // Firestore whereIn caps at 30 — fine for a personal follow list.
    yield* _listings
        .where(FieldPath.documentId, whereIn: listingIds.take(30).toList())
        .snapshots()
        .map((s) => s.docs.map(MarketplaceListing.fromFirestore).toList());
  }

  // ── REQUESTS ───────────────────────────────────────────────────────────

  Future<MarketplaceRequest> createRequest({
    required MarketplaceListing listing,
    required String buyerId,
    required String buyerName,
    required double quantity,
    required IntendedUse intendedUse,
    required FulfilmentPreference fulfilmentPreference,
    DateTime? preferredDate,
    String? message,
  }) async {
    if (quantity <= 0 || quantity > listing.availableQuantity) {
      throw Exception(
          'Requested quantity is greater than the available quantity.');
    }
    final now = DateTime.now();
    final request = MarketplaceRequest(
      id: _uuid.v4(),
      listingId: listing.id,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: listing.farmerId,
      quantity: quantity,
      unit: listing.unit,
      intendedUse: intendedUse,
      preferredDate: preferredDate,
      fulfilmentPreference: fulfilmentPreference,
      message: message,
      status: MarketplaceRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _requests.doc(request.id).set(request.toFirestore());
    return request;
  }

  Stream<List<MarketplaceRequest>> watchRequestsForListing(String listingId) =>
      _requests
          .where('listingId', isEqualTo: listingId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(MarketplaceRequest.fromFirestore).toList());

  /// Every request across every listing a farmer/seller owns.
  Stream<List<MarketplaceRequest>> watchRequestsForSeller(String sellerId) =>
      _requests
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(MarketplaceRequest.fromFirestore).toList());

  Stream<List<MarketplaceRequest>> watchMyRequests(String buyerId) =>
      _requests
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(MarketplaceRequest.fromFirestore).toList());

  /// Accepting a request is the one place quantity actually moves — done as
  /// a transaction so two near-simultaneous accepts can't both succeed past
  /// the available quantity (section 24: partial-quantity requests).
  Future<void> acceptRequest(String requestId) async {
    await _db.runTransaction((tx) async {
      final reqDoc = await tx.get(_requests.doc(requestId));
      if (!reqDoc.exists) return;
      final request = MarketplaceRequest.fromFirestore(reqDoc);
      final listingRef = _listings.doc(request.listingId);
      final listingDoc = await tx.get(listingRef);
      if (!listingDoc.exists) return;
      final listing = MarketplaceListing.fromFirestore(listingDoc);

      if (request.quantity > listing.availableQuantity) {
        throw Exception(
            'Requested quantity is greater than the available quantity.');
      }
      final remaining = listing.availableQuantity - request.quantity;
      tx.update(listingRef, {
        'availableQuantity': remaining,
        'status': remaining <= 0
            ? MarketplaceListingStatus.soldOut.name
            : listing.status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      tx.update(_requests.doc(requestId), {
        'status': MarketplaceRequestStatus.accepted.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> updateRequestStatus(
          String requestId, MarketplaceRequestStatus status) =>
      _requests.doc(requestId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
}
