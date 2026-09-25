import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';

// ── AUTH SERVICE ──────────────────────────────────────
// Rewritten to match the real AppUser model in data/models/models.dart
// (previously referenced a FarmerProfile collection that no longer exists —
// farm-specific info now just lives on AppUser.farmName).

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? farmName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);

    final user = AppUser(
      id: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      farmName: role == UserRole.farmer ? farmName : null,
    );
    await _db
        .collection('users')
        .doc(cred.user!.uid)
        .set(user.toFirestore());
    return user;
  }

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<AppUser?> getAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }
}

// ── BATCH SERVICE ─────────────────────────────────────
// Rewritten to operate on the current CropBatch model (stage/verifiedWeightKg/
// pestDiagnoses/irrigationLogs) instead of the old, no-longer-existing
// CropBatchStatus / WaterSource / PestTreatment / FarmerProfile schema.

class BatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _batches =>
      _db.collection('batches');

  /// Deletes a batch the farmer owns, along with its custody trail
  /// (`custody_events` subcollection) so nothing orphaned is left behind.
  /// Firestore rules already restrict this to the owning farmer
  /// (`allow delete: if request.auth.uid == resource.data.farmerId`), so a
  /// permission error here means the batch belongs to someone else.
  Future<void> deleteBatch(String batchId) async {
    final custodyDocs = await _custodyEvents(batchId).get();
    final writeBatch = _db.batch();
    for (final doc in custodyDocs.docs) {
      writeBatch.delete(doc.reference);
    }
    writeBatch.delete(_batches.doc(batchId));
    await writeBatch.commit();
    // Note: this doesn't remove a Storage-hosted cover photo — a minor,
    // low-cost orphan (Unsplash photos are hotlinked and cost nothing;
    // camera-uploaded ones are a small leftover file, safe to clean up
    // later with a scheduled Storage lifecycle rule if it matters).
  }


  Stream<List<CropBatch>> watchBatches(String farmerId) => _batches
      .where('farmerId', isEqualTo: farmerId)
      .orderBy('plannedDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CropBatch.fromFirestore).toList());

  // Stream every batch in the system — used by the Aggregator/Transporter/
  // Distributor dashboards, which need to see batches across all farmers
  // rather than just their own. Filtered client-side by custodyStage
  // instead of a Firestore `where` so this demo doesn't require standing
  // up composite indexes for every stage/holder combination.
  Stream<List<CropBatch>> watchAllBatches() => _batches
      .orderBy('plannedDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(CropBatch.fromFirestore).toList());

  CollectionReference<Map<String, dynamic>> _custodyEvents(String batchId) =>
      _batches.doc(batchId).collection('custody_events');

  // Full custody trail for one batch, oldest first — this is what the
  // consumer trace screen and any "batch history" view render.
  Stream<List<CustodyEvent>> watchCustodyChain(String batchId) =>
      _custodyEvents(batchId).orderBy('timestamp').snapshots().map((s) => s
          .docs
          .map((d) => CustodyEvent.fromFirestore(d, batchId))
          .toList());

  // Aggregator/Transporter/Distributor scans or taps to take custody of a
  // batch that's currently one step behind them in the chain. Logs the
  // handoff and moves the batch's custodyStage/currentHolder forward.
  Future<void> receiveBatch({
    required String batchId,
    required AppUser actor,
    required CustodyStage newStage,
    required String action,
    String? location,
    String? notes,
  }) async {
    await _custodyEvents(batchId).add(CustodyEvent(
      id: '',
      batchId: batchId,
      role: actor.role,
      actorId: actor.id,
      actorName: actor.name,
      organizationName: actor.organizationName ?? actor.vehicleInfo,
      action: action,
      location: location,
      timestamp: DateTime.now(),
      notes: notes,
    ).toFirestore());

    await _batches.doc(batchId).update({
      'custodyStage': newStage.name,
      'currentHolderId': actor.id,
      'currentHolderName': actor.organizationName ?? actor.name,
    });
  }

  // Distributor (or any holder) hands a batch onward — clears current
  // holder and advances custodyStage without a new holder taking it yet
  // (e.g. "delivered" means it's now with the Chef/Grocery Shopper, who
  // isn't tracked via custody events since they're the final destination).
  Future<void> handOffBatch({
    required String batchId,
    required AppUser actor,
    required CustodyStage newStage,
    required String action,
    String? location,
    String? notes,
  }) async {
    await _custodyEvents(batchId).add(CustodyEvent(
      id: '',
      batchId: batchId,
      role: actor.role,
      actorId: actor.id,
      actorName: actor.name,
      organizationName: actor.organizationName ?? actor.vehicleInfo,
      action: action,
      location: location,
      timestamp: DateTime.now(),
      notes: notes,
    ).toFirestore());

    await _batches.doc(batchId).update({
      'custodyStage': newStage.name,
      'currentHolderId': null,
      'currentHolderName': null,
    });
  }

  // Create new crop batch, planted immediately.
  Future<CropBatch> createBatch({
    required String farmerId,
    required String cropName,
    required String variety,
    required String plotLocation,
    required double latitude,
    required double longitude,
    required FarmingMethod farmingMethod,
    required DateTime plantedDate,
    required DateTime expectedHarvestDate,
    required double estimatedYieldKg,
    required int quantityPlanted,
    String? notes,
    List<int>? photoBytes,
    String? photoUrl, // pre-hosted URL (e.g. Unsplash) — skips Storage upload
  }) async {
    final id = _uuid.v4();

    // Upload the photo (if provided) before writing the batch document, so
    // the URL can be included in the same write rather than a follow-up
    // patch. If the upload fails — Storage not provisioned, permission
    // rules, network — that must NOT take the whole batch down with it.
    // Before this fix, an upload failure threw here and the batch was
    // never created at all, which is exactly the "with a photo, nothing
    // gets added; without one, it works" bug.
    if (photoUrl == null && photoBytes != null && photoBytes.isNotEmpty) {
      try {
        photoUrl = await uploadBatchPhoto(
          batchId: id,
          imageBytes: photoBytes,
          fileName: 'cover.jpg',
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // Proceed without a photo rather than losing the whole batch.
        // ignore: avoid_print
        print('createBatch: photo upload failed, continuing without it ($e)');
      }
    }

    final batch = CropBatch(
      id: id,
      farmerId: farmerId,
      cropName: cropName,
      variety: variety,
      farmingMethod: farmingMethod,
      plotLocation: GeoPoint(latitude, longitude),
      plotName: plotLocation,
      sunExposure: SunExposure.fullSun,
      stage: CropStage.planted,
      plannedDate: plantedDate,
      plantedDate: plantedDate,
      estimatedYieldKg: estimatedYieldKg,
      estimatedHarvestDate: expectedHarvestDate,
      quantityPlanted: quantityPlanted,
      notes: notes,
      photoUrl: photoUrl,
    );
    await _batches.doc(id).set(batch.toFirestore()).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        // Firestore applies this write to the local cache immediately and
        // only keeps the Future pending until the server acknowledges it.
        // A flaky connection can stall that ack for a long time even
        // though the batch is already saved locally (and will sync once
        // connectivity is back) — don't leave the "Planting..." screen
        // stuck waiting on a round trip that may never come.
        // ignore: avoid_print
        print('createBatch: Firestore write is slow to confirm — '
            'continuing optimistically, it will sync in the background.');
      },
    );
    return batch;
  }

  // Log irrigation for a batch. Volume/duration are no longer collected
  // from the farmer — manual entries were consistently inaccurate — so
  // this just records that watering happened, via what source and method.
  Future<void> logIrrigation({
    required String batchId,
    required IrrigationSource source,
    required String method,
    required DateTime nextScheduled,
    double? volumeLiters,
    int? durationMinutes,
  }) async {
    final log = IrrigationLog(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      source: source,
      liters: volumeLiters,
      durationMinutes: durationMinutes,
      method: method,
      nextScheduled: nextScheduled,
    );
    await _batches.doc(batchId).update({
      'irrigationLogs': FieldValue.arrayUnion([log.toJson()]),
    });
  }

  // Log a pest diagnosis + treatment — starts the PHI countdown automatically
  // (CropBatch.harvestLockedByPHI derives from PestDiagnosis.treatedAt/phiDays).
  Future<void> logPestTreatment({
    required String batchId,
    required String pestName,
    required String diagnosis,
    required String pesticide,
    required String applicationMethod,
    required int phiDays,
    PestSeverity severity = PestSeverity.moderate,
  }) async {
    final entry = PestDiagnosis(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      photoUrl: '',
      detectedPest: pestName,
      severity: severity,
      recommendedPesticide: pesticide,
      applicationInstructions: applicationMethod,
      phiDays: phiDays,
      treatedAt: DateTime.now(),
    );
    await _batches.doc(batchId).update({
      'pestDiagnoses': FieldValue.arrayUnion([entry.toJson()]),
      'stage': CropStage.concern.name,
    });
  }

  // Mark ready to harvest.
  Future<void> markReadyToHarvest({
    required String batchId,
    required double estimatedKg,
  }) =>
      _batches.doc(batchId).update({
        'stage': CropStage.readyToHarvest.name,
        'estimatedYieldKg': estimatedKg,
      });

  // Log harvest — records the verified weight and timestamp used to
  // generate/print the batch's QR code.
  Future<void> logHarvest({
    required String batchId,
    required double actualYieldKg,
    String? weatherConditions,
  }) =>
      _batches.doc(batchId).update({
        'stage': CropStage.harvested.name,
        'verifiedWeightKg': actualYieldKg,
        'harvestedAt': Timestamp.fromDate(DateTime.now()),
        if (weatherConditions != null)
          'harvestWeatherConditions': weatherConditions,
      });

  // Generic stage update.
  Future<void> updateStage(String batchId, CropStage stage) =>
      _batches.doc(batchId).update({'stage': stage.name});

  // QR scan trace (consumer-side) — reads the batch + its farmer's profile.
  Future<BatchTraceResult?> traceByQr(String batchId) async {
    final batchDoc = await _batches.doc(batchId).get();
    if (!batchDoc.exists) return null;
    final batch = CropBatch.fromFirestore(batchDoc);

    final farmerDoc =
        await _db.collection('users').doc(batch.farmerId).get();
    final farmer = farmerDoc.exists ? AppUser.fromFirestore(farmerDoc) : null;

    final transit = <TransitEvent>[
      TransitEvent(
        location: batch.plotName ?? 'Farm plot',
        description: 'Planted',
        timestamp: batch.plantedDate ?? batch.plannedDate,
        emoji: '🌱',
      ),
      if (batch.harvestedAt != null)
        TransitEvent(
          location: batch.plotName ?? 'Farm plot',
          description: 'Harvested and QR-coded',
          timestamp: batch.harvestedAt!,
          emoji: '✅',
        ),
    ];

    // Real custody handoffs (Aggregator -> Transporter -> Distributor),
    // logged by each account as it received/released the batch — appended
    // in chronological order after the farm-side events above.
    final custodySnap =
        await _custodyEvents(batch.id).orderBy('timestamp').get();
    transit.addAll(custodySnap.docs
        .map((d) => CustodyEvent.fromFirestore(d, batch.id).toTransitEvent()));

    final nutritionRef = MockData.nutritionReference[batch.cropName];

    return BatchTraceResult(
      batchId: batch.id,
      cropName: batch.cropName,
      variety: batch.variety ?? 'Standard',
      farmName: farmer?.farmName ?? 'Unknown Farm',
      farmerName: farmer?.name ?? 'Unknown Farmer',
      farmLocation: batch.plotName ??
          '${batch.plotLocation.lat.toStringAsFixed(4)}, '
              '${batch.plotLocation.lng.toStringAsFixed(4)}',
      farmingMethod: batch.farmingMethod,
      harvestedAt: batch.harvestedAt ??
          batch.estimatedHarvestDate ??
          batch.plannedDate,
      actualYieldKg: batch.verifiedWeightKg ?? batch.estimatedYieldKg ?? 0,
      isOrganicCertified: batch.organicCertified,
      phiCompliant: !batch.harvestLockedByPHI,
      certificationNumber: batch.organicCertificationUrl,
      nutrition: nutritionRef == null
          ? null
          : NutritionInfo.fromReference(nutritionRef),
      transitEvents: transit,
    );
  }

  // Upload a photo (e.g. a pest-diagnosis leaf photo) to Firebase Storage.
  Future<String> uploadBatchPhoto({
    required String batchId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('batches/$batchId/$fileName');
    final task = await ref.putData(Uint8List.fromList(imageBytes),
        SettableMetadata(contentType: 'image/jpeg'));
    return task.ref.getDownloadURL();
  }
}

// ── MEAL SERVICE ──────────────────────────────────────
// Chef module — creates/streams Meal documents, same shape as BatchService
// (photo upload best-effort so a failed upload never loses the meal).

class MealService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _meals =>
      _db.collection('meals');

  // Stream all meals for a chef, most recently created first.
  Stream<List<Meal>> watchMeals(String chefId) => _meals
      .where('chefId', isEqualTo: chefId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Meal.fromFirestore).toList());

  // Single meal lookup — used by the QR-resolved detail/trace screens.
  Future<Meal?> getMeal(String mealId) async {
    final doc = await _meals.doc(mealId).get();
    return doc.exists ? Meal.fromFirestore(doc) : null;
  }

  Future<Meal> createMeal({
    required String chefId,
    required String restaurantName,
    required String name,
    String? description,
    required List<MealIngredient> ingredients,
    required MealNutritionSnapshot nutrition,
    required List<MealAllergen> allergens,
    String? otherAllergenNote,
    Uint8List? photoBytes,
    String? autoPhotoUrl,
  }) async {
    final id = _uuid.v4();

    // Same trade-off as BatchService.createBatch: a failed photo upload
    // must not take the whole meal down with it.
    String? photoUrl = autoPhotoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      try {
        photoUrl = await uploadMealPhoto(
          mealId: id,
          imageBytes: photoBytes,
          fileName: 'cover.jpg',
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // ignore: avoid_print
        print('createMeal: photo upload failed, continuing without it ($e)');
      }
    }

    final meal = Meal(
      id: id,
      chefId: chefId,
      restaurantName: restaurantName,
      name: name,
      description: description,
      photoUrl: photoUrl,
      ingredients: ingredients,
      nutrition: nutrition,
      allergens: allergens
          .map((a) => MealAllergen(
                mealId: id,
                allergenId: a.allergenId,
                contains: a.contains,
                mayContain: a.mayContain,
                notes: a.notes,
              ))
          .toList(),
      otherAllergenNote: otherAllergenNote,
      createdAt: DateTime.now(),
      qrCodeId: id,
    );
    await _meals.doc(id).set(meal.toFirestore()).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        // Same reasoning as BatchService.createBatch — a stuck server ack
        // shouldn't leave "Saving your meal…" spinning forever when the
        // write already landed in the local cache.
        // ignore: avoid_print
        print('createMeal: Firestore write is slow to confirm — '
            'continuing optimistically, it will sync in the background.');
      },
    );
    return meal;
  }

  Future<String> uploadMealPhoto({
    required String mealId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('meals/$mealId/$fileName');
    final task = await ref.putData(Uint8List.fromList(imageBytes),
        SettableMetadata(contentType: 'image/jpeg'));
    return task.ref.getDownloadURL();
  }
}

// ── FARM DOCUMENT SERVICE ─────────────────────────────
// Fertilizer/pesticide bottle photos, organic certificates, and general
// progress documentation — same shape as MealService/BatchService
// (best-effort photo upload, defensive Firestore-write timeout).

class DocumentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _docs =>
      _db.collection('farm_documents');

  Stream<List<FarmDocument>> watchDocuments(String farmerId) => _docs
      .where('farmerId', isEqualTo: farmerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FarmDocument.fromFirestore).toList());

  Future<FarmDocument> createDocument({
    required String farmerId,
    required FarmDocumentType type,
    required String itemName,
    String? notes,
    Uint8List? photoBytes,
  }) async {
    final id = _uuid.v4();

    String? photoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('farm_documents/$id/photo.jpg');
        await ref
            .putData(photoBytes, SettableMetadata(contentType: 'image/jpeg'))
            .timeout(const Duration(seconds: 15));
        photoUrl = await ref.getDownloadURL();
      } catch (e) {
        // ignore: avoid_print
        print('createDocument: photo upload failed, continuing without it ($e)');
      }
    }

    final document = FarmDocument(
      id: id,
      farmerId: farmerId,
      type: type,
      itemName: itemName,
      photoUrl: photoUrl,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _docs.doc(id).set(document.toFirestore()).timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        // ignore: avoid_print
        print('createDocument: Firestore write is slow to confirm — '
            'continuing optimistically, it will sync in the background.');
      },
    );
    return document;
  }
}
