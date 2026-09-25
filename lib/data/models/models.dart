// GreenTrack core domain models
// Covers: Users (Farmer/Chef/Consumer), CropBatch, TransportRecord, Meal,
// NutritionReference, MealNutritionSnapshot, Allergen, MealAllergen,
// QRCode, Notifications.
//
// These are plain Dart model classes (fromJson/toJson included) so they map
// cleanly onto Firestore documents later. MockData at the bottom seeds a
// realistic, interconnected dataset for screen-building before real
// persistence is wired in via Riverpod providers.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;

// ---------------------------------------------------------------------------
// ENUMS
// ---------------------------------------------------------------------------

enum UserRole { farmer, aggregator, transporter, distributor, chef, consumer }

extension UserRoleX on UserRole {
  /// Display name shown on role-select cards, headers, and custody events.
  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.aggregator:
        return 'Aggregator';
      case UserRole.transporter:
        return 'Transporter';
      case UserRole.distributor:
        return 'Distributor';
      case UserRole.chef:
        return 'Chef';
      case UserRole.consumer:
        return 'Grocery Shopper';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.farmer:
        return '🌾';
      case UserRole.aggregator:
        return '📦';
      case UserRole.transporter:
        return '🚚';
      case UserRole.distributor:
        return '🏬';
      case UserRole.chef:
        return '👨\u200d🍳';
      case UserRole.consumer:
        return '🛒';
    }
  }

  /// Root dashboard route for this role — kept in one place so the router
  /// redirect logic and any "go home" actions can't drift out of sync.
  String get homePath {
    switch (this) {
      case UserRole.farmer:
        return '/farmer';
      case UserRole.aggregator:
        return '/aggregator';
      case UserRole.transporter:
        return '/transporter';
      case UserRole.distributor:
        return '/distributor';
      case UserRole.chef:
        return '/chef';
      case UserRole.consumer:
        return '/consumer';
    }
  }
}

enum CropStage {
  planned,
  planted,
  sprouting,
  vegetative,
  flowering,
  fruiting,
  readyToHarvest,
  harvested,
  concern,
  failed,
}

extension CropStageLabel on CropStage {
  String get emoji {
    switch (this) {
      case CropStage.planned:
        return '📋';
      case CropStage.planted:
        return '🌱';
      case CropStage.sprouting:
        return '🌿';
      case CropStage.vegetative:
        return '🍃';
      case CropStage.flowering:
        return '🌸';
      case CropStage.fruiting:
        return '🍅';
      case CropStage.readyToHarvest:
        return '✅';
      case CropStage.harvested:
        return '🌾';
      case CropStage.concern:
        return '⚠️';
      case CropStage.failed:
        return '❌';
    }
  }

  String get label {
    switch (this) {
      case CropStage.readyToHarvest:
        return 'Ready to Harvest';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

enum FarmingMethod { organic, conventional, hydroponic, permaculture, agroforestry }

extension FarmingMethodLabel on FarmingMethod {
  String get label => switch (this) {
        FarmingMethod.organic => 'Organic',
        FarmingMethod.conventional => 'Conventional',
        FarmingMethod.hydroponic => 'Hydroponic',
        FarmingMethod.permaculture => 'Permaculture',
        FarmingMethod.agroforestry => 'Agroforestry',
      };
}

enum SunExposure { fullSun, partialSun, shade }

enum IrrigationSource { rain, borehole, municipal, river, storedTank }

extension IrrigationSourceLabel on IrrigationSource {
  String get label => switch (this) {
        IrrigationSource.rain => 'Rainwater',
        IrrigationSource.borehole => 'Borehole',
        IrrigationSource.municipal => 'Municipal supply',
        IrrigationSource.river => 'River',
        IrrigationSource.storedTank => 'Stored tank',
      };
}

enum PestSeverity { low, moderate, severe }

enum HarvestDestination { consumed, sold, donated, stored, composted }

enum TransportMode { road, rail, air, sea }

/// Where a harvested batch currently sits in the post-harvest chain.
/// Farmer -> Aggregator -> Transporter -> Distributor -> Chef/Grocery
/// Shopper. `atFarm` also covers batches still growing/not yet harvested.
enum CustodyStage { atFarm, withAggregator, inTransit, withDistributor, delivered }

extension CustodyStageX on CustodyStage {
  String get label {
    switch (this) {
      case CustodyStage.atFarm:
        return 'At Farm';
      case CustodyStage.withAggregator:
        return 'With Aggregator';
      case CustodyStage.inTransit:
        return 'In Transit';
      case CustodyStage.withDistributor:
        return 'With Distributor';
      case CustodyStage.delivered:
        return 'Delivered';
    }
  }
}

enum NotificationType {
  phiCountdown,
  harvestReminder,
  irrigationReminder,
  buyerAvailability,
  chefInventoryAlert,
  scanConfirmation,
  general,
}

// 14 EU/UK recognized major allergens, plus "none".
enum AllergenType {
  gluten,
  milk,
  eggs,
  peanuts,
  treeNuts,
  soybeans,
  fish,
  crustaceans,
  molluscs,
  sesame,
  mustard,
  celery,
  lupin,
  sulphites,
  none,
}

extension AllergenTypeLabel on AllergenType {
  String get label {
    switch (this) {
      case AllergenType.gluten:
        return 'Cereals containing gluten';
      case AllergenType.milk:
        return 'Milk (Dairy)';
      case AllergenType.eggs:
        return 'Eggs';
      case AllergenType.peanuts:
        return 'Peanuts';
      case AllergenType.treeNuts:
        return 'Tree nuts';
      case AllergenType.soybeans:
        return 'Soybeans (Soy)';
      case AllergenType.fish:
        return 'Fish';
      case AllergenType.crustaceans:
        return 'Crustaceans';
      case AllergenType.molluscs:
        return 'Molluscs';
      case AllergenType.sesame:
        return 'Sesame';
      case AllergenType.mustard:
        return 'Mustard';
      case AllergenType.celery:
        return 'Celery';
      case AllergenType.lupin:
        return 'Lupin';
      case AllergenType.sulphites:
        return 'Sulphites/Sulfur dioxide';
      case AllergenType.none:
        return 'None';
    }
  }
}

// ---------------------------------------------------------------------------
// USER
// ---------------------------------------------------------------------------

/// Whether a supply-chain account (Aggregator/Transporter/Distributor) has
/// been vetted. Farmer/Chef/Grocery Shopper are self-service — anyone can
/// grow food or cook it — but a stranger claiming "Distributor" means they
/// can receive OTHER people's produce, so that trust boundary needs a real
/// gate: either a pre-issued invite code, or manual admin approval.
enum VerificationStatus {
  none, // not applicable — farmer/chef/consumer roles
  pending, // requested access, awaiting admin review
  approved, // invite-code verified, or admin-approved
  rejected,
}

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
        VerificationStatus.none => 'N/A',
        VerificationStatus.pending => 'Pending Review',
        VerificationStatus.approved => 'Verified',
        VerificationStatus.rejected => 'Not Approved',
      };
}

/// Roles that touch other people's produce as it moves through the chain —
/// these are the ones that require verification before the dashboard
/// unlocks. Farmer/Chef/Grocery Shopper don't: you're only ever handling
/// your own crops, your own kitchen, your own shopping list.
const kSupplyChainRoles = {UserRole.aggregator, UserRole.transporter, UserRole.distributor};

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  // Role-specific extras
  final String? farmName; // farmer
  final String? restaurantName; // chef
  final String? organicCertificationUrl; // farmer
  final String? organizationName; // aggregator / distributor business name
  final String? vehicleInfo; // transporter — vehicle/registration details
  final VerificationStatus verificationStatus;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.farmName,
    this.restaurantName,
    this.organicCertificationUrl,
    this.organizationName,
    this.vehicleInfo,
    this.verificationStatus = VerificationStatus.none,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.values.byName(json['role'] as String),
        photoUrl: json['photoUrl'] as String?,
        farmName: json['farmName'] as String?,
        restaurantName: json['restaurantName'] as String?,
        organicCertificationUrl: json['organicCertificationUrl'] as String?,
        organizationName: json['organizationName'] as String?,
        vehicleInfo: json['vehicleInfo'] as String?,
        verificationStatus: VerificationStatus.values
            .byName(json['verificationStatus'] as String? ?? 'none'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'photoUrl': photoUrl,
        'farmName': farmName,
        'restaurantName': restaurantName,
        'organicCertificationUrl': organicCertificationUrl,
        'organizationName': organizationName,
        'vehicleInfo': vehicleInfo,
        'verificationStatus': verificationStatus.name,
      };

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromJson({...doc.data()!, 'id': doc.id});

  Map<String, dynamic> toFirestore() => toJson();

  AppUser copyWith({String? photoUrl, String? name, VerificationStatus? verificationStatus}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        role: role,
        photoUrl: photoUrl ?? this.photoUrl,
        farmName: farmName,
        restaurantName: restaurantName,
        organicCertificationUrl: organicCertificationUrl,
        organizationName: organizationName,
        vehicleInfo: vehicleInfo,
        verificationStatus: verificationStatus ?? this.verificationStatus,
      );
}

// ---------------------------------------------------------------------------
// CROP BATCH  (Plan -> Plant -> Nurture -> Track -> Harvest)
// ---------------------------------------------------------------------------

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);

  factory GeoPoint.fromJson(Map<String, dynamic> json) =>
      GeoPoint((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class IrrigationLog {
  final String id;
  final DateTime timestamp;
  final IrrigationSource source;
  final double? liters;
  final int? durationMinutes;
  final String? method;
  final DateTime? nextScheduled;
  final String? notes;

  IrrigationLog({
    required this.id,
    required this.timestamp,
    required this.source,
    this.liters,
    this.durationMinutes,
    this.method,
    this.nextScheduled,
    this.notes,
  });

  factory IrrigationLog.fromJson(Map<String, dynamic> json) => IrrigationLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        source: IrrigationSource.values.byName(json['source'] as String),
        liters: (json['liters'] as num?)?.toDouble(),
        durationMinutes: json['durationMinutes'] as int?,
        method: json['method'] as String?,
        nextScheduled: json['nextScheduled'] == null
            ? null
            : DateTime.parse(json['nextScheduled'] as String),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'source': source.name,
        'liters': liters,
        'durationMinutes': durationMinutes,
        'method': method,
        'nextScheduled': nextScheduled?.toIso8601String(),
        'notes': notes,
      };
}

class PestDiagnosis {
  final String id;
  final DateTime timestamp;
  final String photoUrl;
  final String detectedPest;
  final PestSeverity severity;
  final String recommendedPesticide;
  final String applicationInstructions;
  final int phiDays; // pre-harvest interval triggered by this treatment
  final DateTime? treatedAt;

  PestDiagnosis({
    required this.id,
    required this.timestamp,
    required this.photoUrl,
    required this.detectedPest,
    required this.severity,
    required this.recommendedPesticide,
    required this.applicationInstructions,
    required this.phiDays,
    this.treatedAt,
  });

  /// Date after which harvest is safe, or null if untreated.
  DateTime? get phiClearDate =>
      treatedAt?.add(Duration(days: phiDays));

  bool get isHarvestLocked =>
      phiClearDate != null && DateTime.now().isBefore(phiClearDate!);

  int get daysRemaining {
    final clear = phiClearDate;
    if (clear == null) return 0;
    final remaining = clear.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  factory PestDiagnosis.fromJson(Map<String, dynamic> json) => PestDiagnosis(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        photoUrl: json['photoUrl'] as String? ?? '',
        detectedPest: json['detectedPest'] as String,
        severity: PestSeverity.values.byName(json['severity'] as String),
        recommendedPesticide: json['recommendedPesticide'] as String,
        applicationInstructions: json['applicationInstructions'] as String,
        phiDays: json['phiDays'] as int,
        treatedAt: json['treatedAt'] == null
            ? null
            : DateTime.parse(json['treatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'photoUrl': photoUrl,
        'detectedPest': detectedPest,
        'severity': severity.name,
        'recommendedPesticide': recommendedPesticide,
        'applicationInstructions': applicationInstructions,
        'phiDays': phiDays,
        'treatedAt': treatedAt?.toIso8601String(),
      };
}

class CropBatch {
  final String id;
  final String farmerId;
  final String cropName;
  final String? variety;
  final FarmingMethod farmingMethod;
  final GeoPoint plotLocation;
  final String? plotName;
  final SunExposure sunExposure;
  final CropStage stage;
  final DateTime plannedDate;
  final DateTime? plantedDate;
  final List<IrrigationLog> irrigationLogs;
  final List<PestDiagnosis> pestDiagnoses;
  final double? estimatedYieldKg;
  final DateTime? estimatedHarvestDate;
  final int? quantityPlanted;
  final String? notes;
  final double? verifiedWeightKg;
  final DateTime? harvestedAt;
  final String? harvestWeatherConditions;
  final bool organicCertified;
  final String? organicCertificationUrl;
  final String? qrCodeId;
  final String? photoUrl;
  // Post-harvest custody — who's holding this batch right now as it moves
  // Farmer -> Aggregator -> Transporter -> Distributor -> Chef/Shopper.
  final CustodyStage custodyStage;
  final String? currentHolderId;
  final String? currentHolderName;

  CropBatch({
    required this.id,
    required this.farmerId,
    required this.cropName,
    this.variety,
    required this.farmingMethod,
    required this.plotLocation,
    this.plotName,
    required this.sunExposure,
    required this.stage,
    required this.plannedDate,
    this.plantedDate,
    this.irrigationLogs = const [],
    this.pestDiagnoses = const [],
    this.estimatedYieldKg,
    this.estimatedHarvestDate,
    this.quantityPlanted,
    this.notes,
    this.verifiedWeightKg,
    this.harvestedAt,
    this.harvestWeatherConditions,
    this.organicCertified = false,
    this.organicCertificationUrl,
    this.qrCodeId,
    this.photoUrl,
    this.custodyStage = CustodyStage.atFarm,
    this.currentHolderId,
    this.currentHolderName,
  });

  /// True if any active pest treatment is still within its PHI window.
  bool get harvestLockedByPHI =>
      pestDiagnoses.any((p) => p.isHarvestLocked);

  DateTime? get earliestPHIClearDate {
    final dates = pestDiagnoses
        .map((p) => p.phiClearDate)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }

  /// Days remaining on the longest-running active PHI lock (0 if none).
  int get phiDaysRemaining => pestDiagnoses
      .where((p) => p.isHarvestLocked)
      .map((p) => p.daysRemaining)
      .fold(0, (a, b) => b > a ? b : a);

  /// Deep-link payload encoded into the printed QR code for this batch.
  String get qrCodeData => 'greentrack://batch/$id';

  factory CropBatch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CropBatch(
      id: doc.id,
      farmerId: d['farmerId'] as String,
      cropName: d['cropName'] as String,
      variety: d['variety'] as String?,
      farmingMethod: FarmingMethod.values.byName(d['farmingMethod'] as String),
      plotLocation: GeoPoint.fromJson(
          Map<String, dynamic>.from(d['plotLocation'] as Map)),
      plotName: d['plotName'] as String?,
      sunExposure:
          SunExposure.values.byName(d['sunExposure'] as String? ?? 'fullSun'),
      stage: CropStage.values.byName(d['stage'] as String),
      plannedDate: (d['plannedDate'] as Timestamp).toDate(),
      plantedDate: (d['plantedDate'] as Timestamp?)?.toDate(),
      irrigationLogs: (d['irrigationLogs'] as List<dynamic>? ?? [])
          .map((e) => IrrigationLog.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pestDiagnoses: (d['pestDiagnoses'] as List<dynamic>? ?? [])
          .map((e) => PestDiagnosis.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      estimatedYieldKg: (d['estimatedYieldKg'] as num?)?.toDouble(),
      estimatedHarvestDate:
          (d['estimatedHarvestDate'] as Timestamp?)?.toDate(),
      quantityPlanted: d['quantityPlanted'] as int?,
      notes: d['notes'] as String?,
      verifiedWeightKg: (d['verifiedWeightKg'] as num?)?.toDouble(),
      harvestedAt: (d['harvestedAt'] as Timestamp?)?.toDate(),
      harvestWeatherConditions: d['harvestWeatherConditions'] as String?,
      organicCertified: d['organicCertified'] as bool? ?? false,
      organicCertificationUrl: d['organicCertificationUrl'] as String?,
      qrCodeId: d['qrCodeId'] as String?,
      photoUrl: d['photoUrl'] as String?,
      custodyStage: CustodyStage.values
          .byName(d['custodyStage'] as String? ?? 'atFarm'),
      currentHolderId: d['currentHolderId'] as String?,
      currentHolderName: d['currentHolderName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'farmerId': farmerId,
        'cropName': cropName,
        'variety': variety,
        'farmingMethod': farmingMethod.name,
        'plotLocation': plotLocation.toJson(),
        'plotName': plotName,
        'sunExposure': sunExposure.name,
        'stage': stage.name,
        'plannedDate': Timestamp.fromDate(plannedDate),
        'plantedDate':
            plantedDate == null ? null : Timestamp.fromDate(plantedDate!),
        'irrigationLogs': irrigationLogs.map((l) => l.toJson()).toList(),
        'pestDiagnoses': pestDiagnoses.map((p) => p.toJson()).toList(),
        'estimatedYieldKg': estimatedYieldKg,
        'estimatedHarvestDate': estimatedHarvestDate == null
            ? null
            : Timestamp.fromDate(estimatedHarvestDate!),
        'quantityPlanted': quantityPlanted,
        'notes': notes,
        'verifiedWeightKg': verifiedWeightKg,
        'harvestedAt':
            harvestedAt == null ? null : Timestamp.fromDate(harvestedAt!),
        'harvestWeatherConditions': harvestWeatherConditions,
        'organicCertified': organicCertified,
        'organicCertificationUrl': organicCertificationUrl,
        'qrCodeId': qrCodeId,
        'photoUrl': photoUrl,
        'custodyStage': custodyStage.name,
        'currentHolderId': currentHolderId,
        'currentHolderName': currentHolderName,
      };
}

// ---------------------------------------------------------------------------
// TRACE  (QR scan result assembled from a CropBatch + its farmer)
// ---------------------------------------------------------------------------

class TransitEvent {
  final String location;
  final String description;
  final DateTime timestamp;
  final String emoji;

  TransitEvent({
    required this.location,
    required this.description,
    required this.timestamp,
    required this.emoji,
  });
}

/// A real custody handoff, logged by whichever account (Aggregator,
/// Transporter, or Distributor) received or released a batch. Stored in
/// `batches/{batchId}/custody_events`, ordered by timestamp, and folded
/// into the consumer-facing trace as [TransitEvent]s so a Diner scanning
/// the final QR code sees the batch's real journey, not just "grown by X".
class CustodyEvent {
  final String id;
  final String batchId;
  final UserRole role;
  final String actorId;
  final String actorName;
  final String? organizationName;
  final String action; // e.g. "Received from farm", "Picked up", "Delivered"
  final String? location;
  final DateTime timestamp;
  final String? notes;

  CustodyEvent({
    required this.id,
    required this.batchId,
    required this.role,
    required this.actorId,
    required this.actorName,
    this.organizationName,
    required this.action,
    this.location,
    required this.timestamp,
    this.notes,
  });

  String get emoji => role.emoji;

  factory CustodyEvent.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc, String batchId) {
    final d = doc.data()!;
    return CustodyEvent(
      id: doc.id,
      batchId: batchId,
      role: UserRole.values.byName(d['role'] as String),
      actorId: d['actorId'] as String,
      actorName: d['actorName'] as String,
      organizationName: d['organizationName'] as String?,
      action: d['action'] as String,
      location: d['location'] as String?,
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      notes: d['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'role': role.name,
        'actorId': actorId,
        'actorName': actorName,
        'organizationName': organizationName,
        'action': action,
        'location': location,
        'timestamp': Timestamp.fromDate(timestamp),
        'notes': notes,
      };

  TransitEvent toTransitEvent() => TransitEvent(
        location: organizationName ?? location ?? role.label,
        description: action,
        timestamp: timestamp,
        emoji: emoji,
      );
}

/// A pre-issued code that instantly activates a supply-chain role — the
/// "fast path" for a partner GreenTrack (or a co-op/JHUB program running
/// it) has already vetted offline. Stored at `role_invite_codes/{code}`.
/// One code = one use; `usedByUid` is set the moment it's redeemed so it
/// can't be reused by a second account.
class RoleInviteCode {
  final String code;
  final UserRole role;
  final String organizationLabel; // pre-set org/vehicle name for this code
  final bool used;
  final String? usedByUid;
  final DateTime createdAt;

  const RoleInviteCode({
    required this.code,
    required this.role,
    required this.organizationLabel,
    required this.used,
    this.usedByUid,
    required this.createdAt,
  });

  factory RoleInviteCode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RoleInviteCode(
      code: doc.id,
      role: UserRole.values.byName(d['role'] as String),
      organizationLabel: d['organizationLabel'] as String,
      used: d['used'] as bool? ?? false,
      usedByUid: d['usedByUid'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// A request from someone who doesn't have an invite code — falls into an
/// admin review queue instead of being auto-approved. Stored at
/// `role_requests/{uid}` (one open request per account).
class RoleRequest {
  final String uid;
  final String name;
  final String email;
  final UserRole requestedRole;
  final String? organizationDetail;
  final VerificationStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const RoleRequest({
    required this.uid,
    required this.name,
    required this.email,
    required this.requestedRole,
    this.organizationDetail,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory RoleRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RoleRequest(
      uid: doc.id,
      name: d['name'] as String,
      email: d['email'] as String,
      requestedRole: UserRole.values.byName(d['requestedRole'] as String),
      organizationDetail: d['organizationDetail'] as String?,
      status: VerificationStatus.values.byName(d['status'] as String? ?? 'pending'),
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: d['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'requestedRole': requestedRole.name,
        'organizationDetail': organizationDetail,
        'status': status.name,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
        'reviewedBy': reviewedBy,
      };
}
class NutritionInfo {
  final double caloriesPer100g;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fibreG;
  final Map<String, double> vitamins;

  const NutritionInfo({
    required this.caloriesPer100g,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fibreG,
    this.vitamins = const {},
  });

  factory NutritionInfo.fromReference(NutritionReference ref) => NutritionInfo(
        caloriesPer100g: ref.caloriesPer100g,
        proteinG: ref.proteinPer100g,
        carbsG: ref.carbsPer100g,
        fatG: ref.fatPer100g,
        fibreG: ref.fiberPer100g,
      );
}

/// Everything the QR-scan trace screen needs to render, assembled from a
/// CropBatch document plus its owning farmer's profile.
class BatchTraceResult {
  final String batchId;
  final String cropName;
  final String variety;
  final String farmName;
  final String farmerName;
  final String farmLocation;
  final FarmingMethod farmingMethod;
  final DateTime harvestedAt;
  final double actualYieldKg;
  final bool isOrganicCertified;
  final bool phiCompliant;
  final String? certificationNumber;
  final NutritionInfo? nutrition;
  final List<TransitEvent> transitEvents;

  BatchTraceResult({
    required this.batchId,
    required this.cropName,
    required this.variety,
    required this.farmName,
    required this.farmerName,
    required this.farmLocation,
    required this.farmingMethod,
    required this.harvestedAt,
    required this.actualYieldKg,
    required this.isOrganicCertified,
    required this.phiCompliant,
    this.certificationNumber,
    this.nutrition,
    this.transitEvents = const [],
  });
}

class TransportRecord {
  final String id;
  final String cropBatchId;
  final TransportMode mode;
  final String originLabel;
  final String destinationLabel;
  final DateTime departedAt;
  final DateTime? arrivedAt;
  final String? carrierName;
  final bool autoLogged;

  TransportRecord({
    required this.id,
    required this.cropBatchId,
    required this.mode,
    required this.originLabel,
    required this.destinationLabel,
    required this.departedAt,
    this.arrivedAt,
    this.carrierName,
    this.autoLogged = true,
  });

  Duration? get transitDuration =>
      arrivedAt?.difference(departedAt);
}

// ---------------------------------------------------------------------------
// NUTRITION
// ---------------------------------------------------------------------------

/// Per-100g nutrient density reference, keyed by crop name. Seeds the
/// system-calculated nutrition for meals built from verified batches.
class NutritionReference {
  final String cropName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;

  const NutritionReference({
    required this.cropName,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
  });
}

class MealIngredient {
  final String cropBatchId;
  final String cropName;
  final double quantityGrams;
  MealIngredient({
    required this.cropBatchId,
    required this.cropName,
    required this.quantityGrams,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> j) => MealIngredient(
        cropBatchId: j['cropBatchId'] as String,
        cropName: j['cropName'] as String,
        quantityGrams: (j['quantityGrams'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'cropBatchId': cropBatchId,
        'cropName': cropName,
        'quantityGrams': quantityGrams,
      };
}

/// Computed nutrition for a Meal — derived automatically from
/// NutritionReference x ingredient quantities, never entered manually.
class MealNutritionSnapshot {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const MealNutritionSnapshot({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  static MealNutritionSnapshot calculate(
    List<MealIngredient> ingredients,
    Map<String, NutritionReference> referenceByCrop,
  ) {
    double cal = 0, protein = 0, carbs = 0, fat = 0, fiber = 0;
    for (final ing in ingredients) {
      final ref = referenceByCrop[ing.cropName];
      if (ref == null) continue;
      final factor = ing.quantityGrams / 100.0;
      cal += ref.caloriesPer100g * factor;
      protein += ref.proteinPer100g * factor;
      carbs += ref.carbsPer100g * factor;
      fat += ref.fatPer100g * factor;
      fiber += ref.fiberPer100g * factor;
    }
    return MealNutritionSnapshot(
      calories: cal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
    );
  }

  factory MealNutritionSnapshot.fromJson(Map<String, dynamic> j) =>
      MealNutritionSnapshot(
        calories: (j['calories'] as num).toDouble(),
        proteinG: (j['proteinG'] as num).toDouble(),
        carbsG: (j['carbsG'] as num).toDouble(),
        fatG: (j['fatG'] as num).toDouble(),
        fiberG: (j['fiberG'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
      };
}

// ---------------------------------------------------------------------------
// ALLERGENS  (normalized: Allergen reference + MealAllergen join)
// ---------------------------------------------------------------------------

class Allergen {
  final AllergenType type;
  const Allergen(this.type);
  String get label => type.label;
}

class MealAllergen {
  final String mealId;
  final AllergenType allergenId;
  final bool contains;
  final bool mayContain;
  final String? notes;

  MealAllergen({
    required this.mealId,
    required this.allergenId,
    this.contains = false,
    this.mayContain = false,
    this.notes,
  });

  factory MealAllergen.fromJson(Map<String, dynamic> j) => MealAllergen(
        mealId: j['mealId'] as String,
        allergenId: AllergenType.values.byName(j['allergenId'] as String),
        contains: j['contains'] as bool? ?? false,
        mayContain: j['mayContain'] as bool? ?? false,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'mealId': mealId,
        'allergenId': allergenId.name,
        'contains': contains,
        'mayContain': mayContain,
        'notes': notes,
      };
}

// ---------------------------------------------------------------------------
// MEAL  (Chef module)
// ---------------------------------------------------------------------------

class Meal {
  final String id;
  final String chefId;
  final String restaurantName;
  final String name;
  final String? description;
  final String? photoUrl;
  final List<MealIngredient> ingredients;
  final MealNutritionSnapshot nutrition;
  final List<MealAllergen> allergens;
  final String? otherAllergenNote;
  final DateTime createdAt;
  final String? qrCodeId;

  Meal({
    required this.id,
    required this.chefId,
    required this.restaurantName,
    required this.name,
    this.description,
    this.photoUrl,
    required this.ingredients,
    required this.nutrition,
    required this.allergens,
    this.otherAllergenNote,
    required this.createdAt,
    this.qrCodeId,
  });

  /// Deep-link payload encoded into the printed QR code for this meal.
  String get qrCodeData => 'greentrack://meal/$id';

  factory Meal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Meal(
      id: doc.id,
      chefId: d['chefId'] as String,
      restaurantName: d['restaurantName'] as String,
      name: d['name'] as String,
      description: d['description'] as String?,
      photoUrl: d['photoUrl'] as String?,
      ingredients: (d['ingredients'] as List<dynamic>? ?? [])
          .map((e) => MealIngredient.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nutrition: MealNutritionSnapshot.fromJson(
          Map<String, dynamic>.from(d['nutrition'] as Map)),
      allergens: (d['allergens'] as List<dynamic>? ?? [])
          .map((e) => MealAllergen.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      otherAllergenNote: d['otherAllergenNote'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      qrCodeId: d['qrCodeId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'chefId': chefId,
        'restaurantName': restaurantName,
        'name': name,
        'description': description,
        'photoUrl': photoUrl,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'nutrition': nutrition.toJson(),
        'allergens': allergens.map((a) => a.toJson()).toList(),
        'otherAllergenNote': otherAllergenNote,
        'createdAt': Timestamp.fromDate(createdAt),
        'qrCodeId': qrCodeId,
      };

  Meal copyWith({String? photoUrl}) => Meal(
        id: id,
        chefId: chefId,
        restaurantName: restaurantName,
        name: name,
        description: description,
        photoUrl: photoUrl ?? this.photoUrl,
        ingredients: ingredients,
        nutrition: nutrition,
        allergens: allergens,
        otherAllergenNote: otherAllergenNote,
        createdAt: createdAt,
        qrCodeId: qrCodeId,
      );
}

// ---------------------------------------------------------------------------
// QR CODE  (shared resolver target for CropBatch or Meal)
// ---------------------------------------------------------------------------

enum QRTargetType { cropBatch, meal }

class QRCodeRecord {
  final String id; // encoded into the QR image itself
  final QRTargetType targetType;
  final String targetId; // cropBatchId or mealId
  final DateTime generatedAt;

  QRCodeRecord({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.generatedAt,
  });
}

// ---------------------------------------------------------------------------
// NOTIFICATIONS
// ---------------------------------------------------------------------------

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String emoji;
  final NotificationType type;
  final DateTime scheduledAt;
  final bool isRead;
  final String? cropId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.type,
    required this.scheduledAt,
    this.isRead = false,
    this.cropId,
  });
}

// ---------------------------------------------------------------------------
// MARKETPLACE
// ---------------------------------------------------------------------------
// Deliberately references CropBatch by id rather than copying crop/harvest
// fields onto a separate "MarketplaceCrop" — the batch is the single source
// of truth (see models above); a listing is just "this batch, made public,
// with the commercial fields (price/available quantity/status) it needs."

/// UPCOMING = published from a batch that hasn't been harvested yet
/// ("Harvesting Soon" — followable, not orderable).
/// AVAILABLE = the batch has been harvested; buyers can request produce.
/// PAUSED = farmer-hidden temporarily, not deleted.
/// SOLD_OUT = availableQuantity hit zero.
/// EXPIRED = never confirmed/harvested within a reasonable window (reserved
/// for a future scheduled job — not yet set anywhere).
/// REMOVED = farmer deleted the listing.
enum MarketplaceListingStatus { upcoming, available, paused, soldOut, expired, removed }

extension MarketplaceListingStatusX on MarketplaceListingStatus {
  String get label => switch (this) {
        MarketplaceListingStatus.upcoming => 'Harvesting Soon',
        MarketplaceListingStatus.available => 'Available Now',
        MarketplaceListingStatus.paused => 'Paused',
        MarketplaceListingStatus.soldOut => 'Sold Out',
        MarketplaceListingStatus.expired => 'Expired',
        MarketplaceListingStatus.removed => 'Removed',
      };
}

enum MarketplaceRequestStatus { pending, accepted, declined, negotiating, fulfilled, cancelled }

extension MarketplaceRequestStatusX on MarketplaceRequestStatus {
  String get label => switch (this) {
        MarketplaceRequestStatus.pending => 'Pending',
        MarketplaceRequestStatus.accepted => 'Accepted',
        MarketplaceRequestStatus.declined => 'Declined',
        MarketplaceRequestStatus.negotiating => 'Negotiating',
        MarketplaceRequestStatus.fulfilled => 'Fulfilled',
        MarketplaceRequestStatus.cancelled => 'Cancelled',
      };
}

enum IntendedUse { personal, restaurant, grocery, institution, resale, other }

extension IntendedUseX on IntendedUse {
  String get label => switch (this) {
        IntendedUse.personal => 'Personal consumption',
        IntendedUse.restaurant => 'Restaurant',
        IntendedUse.grocery => 'Grocery',
        IntendedUse.institution => 'School / institution',
        IntendedUse.resale => 'Resale',
        IntendedUse.other => 'Other',
      };
}

enum FulfilmentPreference { pickup, delivery, discuss }

extension FulfilmentPreferenceX on FulfilmentPreference {
  String get label => switch (this) {
        FulfilmentPreference.pickup => 'Pickup',
        FulfilmentPreference.delivery => 'Delivery',
        FulfilmentPreference.discuss => 'Discuss with farmer',
      };
}

// Lets MarketplaceRequest serve both produce requests (listingId ->
// MarketplaceListing) and supplier requests (listingId -> SupplierListing)
// out of the same collection/status machinery (section 21: "use the same
// general request architecture where practical") instead of a parallel
// SupplierRequest model. Defaults to `produce` for every request written
// before this field existed.
enum MarketplaceRequestTarget { produce, supplier }

class MarketplaceListing {
  final String id;
  final String batchId; // -> CropBatch.id (single source of truth)
  final String farmerId;
  final String farmerName;
  final String cropName;
  // General area only — never the exact plot GeoPoint. Section 16 of the
  // marketplace brief: exact farm coordinates are private until a request
  // is accepted, and that hand-off happens outside this field entirely.
  final String generalLocation;
  final double quantity; // originally listed quantity
  final double availableQuantity; // decremented as requests are accepted
  final String unit; // kg, crates, bags, bunches, ...
  final double? pricePerUnit; // null = farmer chose not to display a price
  final DateTime? expectedHarvestDate; // set while UPCOMING
  final DateTime? harvestedAt; // set once the batch is actually harvested
  final MarketplaceListingStatus status;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceListing({
    required this.id,
    required this.batchId,
    required this.farmerId,
    required this.farmerName,
    required this.cropName,
    required this.generalLocation,
    required this.quantity,
    required this.availableQuantity,
    required this.unit,
    this.pricePerUnit,
    this.expectedHarvestDate,
    this.harvestedAt,
    required this.status,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isHarvested => harvestedAt != null;

  MarketplaceListing copyWith({
    double? availableQuantity,
    MarketplaceListingStatus? status,
    DateTime? harvestedAt,
    DateTime? updatedAt,
  }) =>
      MarketplaceListing(
        id: id,
        batchId: batchId,
        farmerId: farmerId,
        farmerName: farmerName,
        cropName: cropName,
        generalLocation: generalLocation,
        quantity: quantity,
        availableQuantity: availableQuantity ?? this.availableQuantity,
        unit: unit,
        pricePerUnit: pricePerUnit,
        expectedHarvestDate: expectedHarvestDate,
        harvestedAt: harvestedAt ?? this.harvestedAt,
        status: status ?? this.status,
        photoUrl: photoUrl,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory MarketplaceListing.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MarketplaceListing(
      id: doc.id,
      batchId: d['batchId'] as String,
      farmerId: d['farmerId'] as String,
      farmerName: d['farmerName'] as String? ?? 'GreenTrack Farmer',
      cropName: d['cropName'] as String,
      generalLocation: d['generalLocation'] as String? ?? 'Location not specified',
      quantity: (d['quantity'] as num).toDouble(),
      availableQuantity: (d['availableQuantity'] as num).toDouble(),
      unit: d['unit'] as String? ?? 'kg',
      pricePerUnit: (d['pricePerUnit'] as num?)?.toDouble(),
      expectedHarvestDate: (d['expectedHarvestDate'] as Timestamp?)?.toDate(),
      harvestedAt: (d['harvestedAt'] as Timestamp?)?.toDate(),
      status: MarketplaceListingStatus.values
          .byName(d['status'] as String? ?? 'upcoming'),
      photoUrl: d['photoUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'batchId': batchId,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'cropName': cropName,
        'generalLocation': generalLocation,
        'quantity': quantity,
        'availableQuantity': availableQuantity,
        'unit': unit,
        'pricePerUnit': pricePerUnit,
        'expectedHarvestDate': expectedHarvestDate == null
            ? null
            : Timestamp.fromDate(expectedHarvestDate!),
        'harvestedAt':
            harvestedAt == null ? null : Timestamp.fromDate(harvestedAt!),
        'status': status.name,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

class MarketplaceRequest {
  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final double quantity;
  final String unit;
  final IntendedUse intendedUse;
  final DateTime? preferredDate;
  final FulfilmentPreference fulfilmentPreference;
  final String? message;
  final MarketplaceRequestStatus status;
  final MarketplaceRequestTarget targetType;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceRequest({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.quantity,
    required this.unit,
    required this.intendedUse,
    this.preferredDate,
    required this.fulfilmentPreference,
    this.message,
    required this.status,
    this.targetType = MarketplaceRequestTarget.produce,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MarketplaceRequest(
      id: doc.id,
      listingId: d['listingId'] as String,
      buyerId: d['buyerId'] as String,
      buyerName: d['buyerName'] as String? ?? 'GreenTrack User',
      sellerId: d['sellerId'] as String,
      quantity: (d['quantity'] as num).toDouble(),
      unit: d['unit'] as String? ?? 'kg',
      intendedUse:
          IntendedUse.values.byName(d['intendedUse'] as String? ?? 'personal'),
      preferredDate: (d['preferredDate'] as Timestamp?)?.toDate(),
      fulfilmentPreference: FulfilmentPreference.values
          .byName(d['fulfilmentPreference'] as String? ?? 'discuss'),
      message: d['message'] as String?,
      status: MarketplaceRequestStatus.values
          .byName(d['status'] as String? ?? 'pending'),
      targetType: MarketplaceRequestTarget.values
          .byName(d['targetType'] as String? ?? 'produce'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'sellerId': sellerId,
        'quantity': quantity,
        'unit': unit,
        'intendedUse': intendedUse.name,
        'preferredDate':
            preferredDate == null ? null : Timestamp.fromDate(preferredDate!),
        'fulfilmentPreference': fulfilmentPreference.name,
        'message': message,
        'status': status.name,
        'targetType': targetType.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// A user "Notify Me"-following an UPCOMING listing. One doc per
/// (listingId, userId) pair — existence = following.
class HarvestFollower {
  final String id;
  final String listingId;
  final String userId;
  final DateTime createdAt;

  HarvestFollower({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.createdAt,
  });

  factory HarvestFollower.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return HarvestFollower(
      id: doc.id,
      listingId: d['listingId'] as String,
      userId: d['userId'] as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'listingId': listingId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ── AGRICULTURAL SUPPLIERS ──────────────────────────────────────────────────
// Any signed-in user can register a SupplierProfile — this is deliberately
// NOT a new UserRole. Adding one would mean touching role-select, the
// invite-code/verification pipeline, and homePath routing for something
// that's really an optional extra capability (a farmer or anyone else can
// also sell inputs), matching the brief's own hedge: "create a supplier
// role IF the current architecture supports it... do not break the
// existing single farmer authentication model." Verification instead uses
// the same VerificationStatus enum already used for supply-chain roles.

enum SupplierCategory { seeds, fertilizer, cropProtection, equipment, irrigation, seedlings, services, other }

extension SupplierCategoryX on SupplierCategory {
  String get label => switch (this) {
        SupplierCategory.seeds => 'Seeds',
        SupplierCategory.fertilizer => 'Fertilizer',
        SupplierCategory.cropProtection => 'Crop Protection',
        SupplierCategory.equipment => 'Equipment',
        SupplierCategory.irrigation => 'Irrigation',
        SupplierCategory.seedlings => 'Seedlings',
        SupplierCategory.services => 'Agricultural Services',
        SupplierCategory.other => 'Other',
      };
}

/// A business/supplier account — one per userId. Verification is admin-
/// gated (VerificationStatus.approved) so the "Verified Supplier" badge
/// can't be self-claimed (section 19: "do not allow arbitrary users to
/// claim they are verified").
class SupplierProfile {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final SupplierCategory category;
  final String generalLocation;
  final String? contactPhone;
  final String? contactEmail;
  final String? logoUrl;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.category,
    required this.generalLocation,
    this.contactPhone,
    this.contactEmail,
    this.logoUrl,
    this.verificationStatus = VerificationStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified => verificationStatus == VerificationStatus.approved;

  factory SupplierProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SupplierProfile(
      id: doc.id,
      userId: d['userId'] as String,
      businessName: d['businessName'] as String? ?? 'Supplier',
      description: d['description'] as String? ?? '',
      category: SupplierCategory.values
          .byName(d['category'] as String? ?? 'other'),
      generalLocation: d['generalLocation'] as String? ?? 'Location not specified',
      contactPhone: d['contactPhone'] as String?,
      contactEmail: d['contactEmail'] as String?,
      logoUrl: d['logoUrl'] as String?,
      verificationStatus: VerificationStatus.values
          .byName(d['verificationStatus'] as String? ?? 'pending'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'businessName': businessName,
        'description': description,
        'category': category.name,
        'generalLocation': generalLocation,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'logoUrl': logoUrl,
        'verificationStatus': verificationStatus.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

enum SupplierListingStatus { active, paused, removed }

/// A single product/service a supplier offers. Deliberately no stock-
/// quantity tracking (unlike MarketplaceListing) — v1 suppliers list what
/// they generally offer, and availability/quantity gets discussed per
/// request, same as pricing sometimes is.
class SupplierListing {
  final String id;
  final String supplierId; // -> SupplierProfile.id
  final String supplierName; // denormalized, same pattern as farmerName above
  final SupplierCategory category;
  final String name;
  final String description;
  final String? photoUrl;
  final double? price;
  final String? unit;
  final SupplierListingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupplierListing({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.category,
    required this.name,
    required this.description,
    this.photoUrl,
    this.price,
    this.unit,
    this.status = SupplierListingStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierListing.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SupplierListing(
      id: doc.id,
      supplierId: d['supplierId'] as String,
      supplierName: d['supplierName'] as String? ?? 'Supplier',
      category: SupplierCategory.values
          .byName(d['category'] as String? ?? 'other'),
      name: d['name'] as String? ?? 'Product',
      description: d['description'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      price: (d['price'] as num?)?.toDouble(),
      unit: d['unit'] as String?,
      status: SupplierListingStatus.values
          .byName(d['status'] as String? ?? 'active'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'supplierId': supplierId,
        'supplierName': supplierName,
        'category': category.name,
        'name': name,
        'description': description,
        'photoUrl': photoUrl,
        'price': price,
        'unit': unit,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

// ── MESSAGING ────────────────────────────────────────────────────────────
// Section 13: communication is always anchored to a request — never a
// free-standing DM system. One Conversation per MarketplaceRequest (produce
// or supplier, via the same requestId), created lazily the first time
// either side sends a message.
class Conversation {
  final String id;
  final String requestId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.requestId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  List<String> get participantIds => [buyerId, sellerId];

  factory Conversation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Conversation(
      id: doc.id,
      requestId: d['requestId'] as String,
      buyerId: d['buyerId'] as String,
      sellerId: d['sellerId'] as String,
      lastMessage: d['lastMessage'] as String?,
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'requestId': requestId,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'participantIds': participantIds,
        'lastMessage': lastMessage,
        'lastMessageAt':
            lastMessageAt == null ? null : Timestamp.fromDate(lastMessageAt!),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Message(
      id: doc.id,
      conversationId: d['conversationId'] as String,
      senderId: d['senderId'] as String,
      message: d['message'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'conversationId': conversationId,
        'senderId': senderId,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ---------------------------------------------------------------------------
// MOCK DATA  (stand-in repository until Riverpod + Firestore wiring)
// ---------------------------------------------------------------------------

// ── CROPS (personal crop-planning feature) ────────────
// Distinct from CropBatch (supply-chain traceability). This is the
// lighter-weight "my crops" tracker shown on the farmer's home screen.

enum CropCategory { vegetable, fruit, herb, leafyGreen, root, legume }

extension CropCategoryLabel on CropCategory {
  String get label => switch (this) {
        CropCategory.vegetable => 'Vegetable',
        CropCategory.fruit => 'Fruit',
        CropCategory.herb => 'Herb',
        CropCategory.leafyGreen => 'Leafy Green',
        CropCategory.root => 'Root',
        CropCategory.legume => 'Legume',
      };
  String get emoji => switch (this) {
        CropCategory.vegetable => '🍅',
        CropCategory.fruit => '🍓',
        CropCategory.herb => '🌿',
        CropCategory.leafyGreen => '🥬',
        CropCategory.root => '🥕',
        CropCategory.legume => '🫘',
      };
}

enum WateringFrequency { daily, everyTwoDays, twiceWeekly, weekly }

extension WateringFrequencyLabel on WateringFrequency {
  String get label => switch (this) {
        WateringFrequency.daily => 'Daily',
        WateringFrequency.everyTwoDays => 'Every 2 days',
        WateringFrequency.twiceWeekly => 'Twice a week',
        WateringFrequency.weekly => 'Weekly',
      };
}

enum CropStatus {
  seedling,
  sprouting,
  vegetative,
  flowering,
  fruiting,
  readyToHarvest,
  harvested,
  concern,
}

extension CropStatusLabel on CropStatus {
  String get label => switch (this) {
        CropStatus.seedling => 'Seedling',
        CropStatus.sprouting => 'Sprouting',
        CropStatus.vegetative => 'Vegetative',
        CropStatus.flowering => 'Flowering',
        CropStatus.fruiting => 'Fruiting',
        CropStatus.readyToHarvest => 'Ready to Harvest',
        CropStatus.harvested => 'Harvested',
        CropStatus.concern => 'Needs Attention',
      };
  String get emoji => switch (this) {
        CropStatus.seedling => '🌱',
        CropStatus.sprouting => '🌿',
        CropStatus.vegetative => '🍃',
        CropStatus.flowering => '🌸',
        CropStatus.fruiting => '🍇',
        CropStatus.readyToHarvest => '✅',
        CropStatus.harvested => '📦',
        CropStatus.concern => '⚠️',
      };
  Color get color => switch (this) {
        CropStatus.seedling => const Color(0xFF95D5B2),
        CropStatus.sprouting => const Color(0xFF74C69D),
        CropStatus.vegetative => const Color(0xFF40916C),
        CropStatus.flowering => const Color(0xFFB07254),
        CropStatus.fruiting => const Color(0xFFD4A017),
        CropStatus.readyToHarvest => const Color(0xFF2D6A4F),
        CropStatus.harvested => const Color(0xFF8A968D),
        CropStatus.concern => const Color(0xFFD97706),
      };
}

class CropModel {
  final String id;
  final String name;
  final String variety;
  final CropCategory category;
  final String emoji;
  final String plotId;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final int quantityPlanted;
  final WateringFrequency wateringFrequency;
  final double estimatedYieldKg;
  final double actualYieldKg;
  final String? notes;
  final CropStatus status;
  final bool isFavorite;

  const CropModel({
    required this.id,
    required this.name,
    required this.variety,
    required this.category,
    required this.emoji,
    required this.plotId,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.quantityPlanted,
    required this.wateringFrequency,
    required this.estimatedYieldKg,
    this.actualYieldKg = 0,
    this.notes,
    required this.status,
    this.isFavorite = false,
  });

  int get daysInGround => DateTime.now().difference(plantingDate).inDays;

  int get daysToHarvest =>
      expectedHarvestDate.difference(DateTime.now()).inDays;

  bool get isNearHarvest =>
      status != CropStatus.harvested && daysToHarvest <= 3;

  double get harvestProgress {
    final total = expectedHarvestDate.difference(plantingDate).inMinutes;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(plantingDate).inMinutes;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  double get yieldProgress {
    if (estimatedYieldKg <= 0) return 0;
    return (actualYieldKg / estimatedYieldKg).clamp(0, 1).toDouble();
  }

  // Convenience display strings for compact crop cards.
  String get stage => status.label;
  Color get stageColor => status.color;
  double get progress => harvestProgress;
  String get daysLabel => daysToHarvest > 0 ? '${daysToHarvest}d' : 'Ready!';
  String get yieldLabel => '~${estimatedYieldKg.toStringAsFixed(1)}kg';

  CropModel copyWith({
    String? name,
    String? variety,
    CropCategory? category,
    String? plotId,
    DateTime? expectedHarvestDate,
    int? quantityPlanted,
    WateringFrequency? wateringFrequency,
    double? estimatedYieldKg,
    double? actualYieldKg,
    String? notes,
    CropStatus? status,
    bool? isFavorite,
  }) => CropModel(
        id: id,
        name: name ?? this.name,
        variety: variety ?? this.variety,
        category: category ?? this.category,
        emoji: emoji,
        plotId: plotId ?? this.plotId,
        plantingDate: plantingDate,
        expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
        quantityPlanted: quantityPlanted ?? this.quantityPlanted,
        wateringFrequency: wateringFrequency ?? this.wateringFrequency,
        estimatedYieldKg: estimatedYieldKg ?? this.estimatedYieldKg,
        actualYieldKg: actualYieldKg ?? this.actualYieldKg,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

enum SoilType { loam, clay, sandy, silt, chalky }

extension SoilTypeLabel on SoilType {
  String get label => switch (this) {
        SoilType.loam => 'Loam',
        SoilType.clay => 'Clay',
        SoilType.sandy => 'Sandy',
        SoilType.silt => 'Silt',
        SoilType.chalky => 'Chalky',
      };
}

class GardenPlot {
  final String id;
  final String name;
  final String emoji;
  final String? description;
  final double areaM2;
  final SoilType soilType;
  final SunExposure sunExposure;
  final bool hasIrrigation;
  final DateTime createdAt;

  const GardenPlot({
    required this.id,
    required this.name,
    required this.emoji,
    this.description,
    required this.areaM2,
    required this.soilType,
    required this.sunExposure,
    required this.hasIrrigation,
    required this.createdAt,
  });

  String get sizeLabel => '${areaM2.toStringAsFixed(0)} m²';

  int get activeCropCount => MockData.crops
      .where((c) => c.plotId == id && c.status != CropStatus.harvested)
      .length;
}

extension HarvestDestinationLabel on HarvestDestination {
  String get label => switch (this) {
        HarvestDestination.consumed => 'Consumed',
        HarvestDestination.sold => 'Sold',
        HarvestDestination.donated => 'Donated',
        HarvestDestination.stored => 'Stored',
        HarvestDestination.composted => 'Composted',
      };
  String get emoji => switch (this) {
        HarvestDestination.consumed => '🍽️',
        HarvestDestination.sold => '💰',
        HarvestDestination.donated => '🤝',
        HarvestDestination.stored => '📦',
        HarvestDestination.composted => '♻️',
      };
  Color get color => switch (this) {
        HarvestDestination.consumed => const Color(0xFF40916C),
        HarvestDestination.sold => const Color(0xFFD4A017),
        HarvestDestination.donated => const Color(0xFF2D6CDF),
        HarvestDestination.stored => const Color(0xFF8A968D),
        HarvestDestination.composted => const Color(0xFF6B4226),
      };
}

class HarvestRecord {
  final String id;
  final String cropId;
  final double quantityKg;
  final double estimatedValue;
  final HarvestDestination destination;
  final DateTime harvestDate;
  final String? notes;

  const HarvestRecord({
    required this.id,
    required this.cropId,
    required this.quantityKg,
    required this.estimatedValue,
    required this.destination,
    required this.harvestDate,
    this.notes,
  });
}

enum ActivityType { watering, harvesting, planting, pestTreatment, fertilizing, note }

extension ActivityTypeLabel on ActivityType {
  String get emoji => switch (this) {
        ActivityType.watering => '💧',
        ActivityType.harvesting => '🌾',
        ActivityType.planting => '🌱',
        ActivityType.pestTreatment => '🐛',
        ActivityType.fertilizing => '🧪',
        ActivityType.note => '📝',
      };
  Color get color => switch (this) {
        ActivityType.watering => const Color(0xFF2D6CDF),
        ActivityType.harvesting => const Color(0xFFD4A017),
        ActivityType.planting => const Color(0xFF40916C),
        ActivityType.pestTreatment => const Color(0xFFD97706),
        ActivityType.fertilizing => const Color(0xFF6B3FA0),
        ActivityType.note => const Color(0xFF8A968D),
      };
}

class ActivityLog {
  final String id;
  final String cropId;
  final ActivityType type;
  final String description;
  final DateTime performedAt;

  const ActivityLog({
    required this.id,
    required this.cropId,
    required this.type,
    required this.description,
    required this.performedAt,
  });
}

class GrowthRecord {
  final String id;
  final String cropId;
  final DateTime recordedAt;
  final double heightCm;
  final int leafCount;
  final bool floweringObserved;
  final String health; // e.g. 'Healthy', 'Concern'
  final String? notes;

  const GrowthRecord({
    required this.id,
    required this.cropId,
    required this.recordedAt,
    required this.heightCm,
    required this.leafCount,
    this.floweringObserved = false,
    this.health = 'Healthy',
    this.notes,
  });
}

class WeatherData {
  final String emoji;
  final double tempC;
  final String condition;
  final double humidity;
  final double windKph;
  final double rainfallMm;
  final bool isGoodForPlanting;
  final String tip;

  const WeatherData({
    required this.emoji,
    required this.tempC,
    required this.condition,
    required this.humidity,
    required this.windKph,
    required this.rainfallMm,
    required this.isGoodForPlanting,
    required this.tip,
  });
}

class GardenStats {
  final int totalCrops;
  final int activeCrops;
  final double totalHarvestKg;
  final double seasonGoalKg;
  final int totalHarvestCount;

  const GardenStats({
    required this.totalCrops,
    required this.activeCrops,
    required this.totalHarvestKg,
    required this.seasonGoalKg,
    required this.totalHarvestCount,
  });

  double get goalProgress =>
      seasonGoalKg <= 0 ? 0 : (totalHarvestKg / seasonGoalKg).clamp(0, 1).toDouble();
}

// ---------------------------------------------------------------------------
// FARM DOCUMENTATION  (fertilizer/pesticide bottles, organic certs, etc.)
// ---------------------------------------------------------------------------

enum FarmDocumentType { fertilizer, pesticide, organicCertificate, other }

extension FarmDocumentTypeLabel on FarmDocumentType {
  String get label => switch (this) {
        FarmDocumentType.fertilizer => 'Fertilizer',
        FarmDocumentType.pesticide => 'Pesticide',
        FarmDocumentType.organicCertificate => 'Organic Certificate',
        FarmDocumentType.other => 'Other',
      };

  String get emoji => switch (this) {
        FarmDocumentType.fertilizer => '🧪',
        FarmDocumentType.pesticide => '🐛',
        FarmDocumentType.organicCertificate => '📜',
        FarmDocumentType.other => '📸',
      };
}

/// A photographed farm input or record — the fertilizer/pesticide bottle
/// label, an organic certificate, or any other progress photo a farmer
/// wants on file for traceability. Backs the "Documentor" profile badge
/// and the Documentation quick action.
class FarmDocument {
  final String id;
  final String farmerId;
  final FarmDocumentType type;
  final String itemName;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  FarmDocument({
    required this.id,
    required this.farmerId,
    required this.type,
    required this.itemName,
    this.photoUrl,
    this.notes,
    required this.createdAt,
  });

  factory FarmDocument.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FarmDocument(
      id: doc.id,
      farmerId: d['farmerId'] as String,
      type: FarmDocumentType.values.byName(d['type'] as String),
      itemName: d['itemName'] as String,
      photoUrl: d['photoUrl'] as String?,
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'farmerId': farmerId,
        'type': type.name,
        'itemName': itemName,
        'photoUrl': photoUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class MockData {
  MockData._();

  static final List<AppUser> users = [
    const AppUser(
      id: 'u_mwangi',
      name: 'Mwangi',
      email: 'mwangi@greentrack.app',
      role: UserRole.farmer,
      farmName: "Mwangi's Garden",
    ),
    const AppUser(
      id: 'u_sarah',
      name: 'Sarah',
      email: 'sarah@greentrack.app',
      role: UserRole.chef,
      restaurantName: 'Fresh Bite Restaurant',
    ),
    const AppUser(
      id: 'u_mary',
      name: 'Mary',
      email: 'mary@greentrack.app',
      role: UserRole.consumer,
    ),
    const AppUser(
      id: 'u_faith',
      name: 'Faith',
      email: 'faith@greentrack.app',
      role: UserRole.consumer,
    ),
    const AppUser(
      id: 'u_kiptoo',
      name: 'Kiptoo',
      email: 'kiptoo@greentrack.app',
      role: UserRole.aggregator,
      organizationName: 'Kiambu Growers Cooperative',
      verificationStatus: VerificationStatus.approved,
    ),
    const AppUser(
      id: 'u_omondi',
      name: 'Omondi',
      email: 'omondi@greentrack.app',
      role: UserRole.transporter,
      vehicleInfo: 'KDA 245J — refrigerated pickup',
      verificationStatus: VerificationStatus.approved,
    ),
    const AppUser(
      id: 'u_wanjiru',
      name: 'Wanjiru',
      email: 'wanjiru@greentrack.app',
      role: UserRole.distributor,
      organizationName: 'Nairobi Fresh Distributors Ltd.',
      verificationStatus: VerificationStatus.approved,
    ),
  ];

  static AppUser get user => users.first;

  static final Map<String, NutritionReference> nutritionReference = {
    'Tomatoes': const NutritionReference(
      cropName: 'Tomatoes',
      caloriesPer100g: 18,
      proteinPer100g: 0.9,
      carbsPer100g: 3.9,
      fatPer100g: 0.2,
      fiberPer100g: 1.2,
    ),
    'Lettuce': const NutritionReference(
      cropName: 'Lettuce',
      caloriesPer100g: 15,
      proteinPer100g: 1.4,
      carbsPer100g: 2.9,
      fatPer100g: 0.2,
      fiberPer100g: 1.3,
    ),
    'Carrots': const NutritionReference(
      cropName: 'Carrots',
      caloriesPer100g: 41,
      proteinPer100g: 0.9,
      carbsPer100g: 9.6,
      fatPer100g: 0.2,
      fiberPer100g: 2.8,
    ),
    'Avocado': const NutritionReference(
      cropName: 'Avocado',
      caloriesPer100g: 160,
      proteinPer100g: 2.0,
      carbsPer100g: 8.5,
      fatPer100g: 14.7,
      fiberPer100g: 6.7,
    ),
    'Basil': const NutritionReference(
      cropName: 'Basil',
      caloriesPer100g: 23,
      proteinPer100g: 3.15,
      carbsPer100g: 2.65,
      fatPer100g: 0.64,
      fiberPer100g: 1.6,
    ),
    'Bell Pepper': const NutritionReference(
      cropName: 'Bell Pepper',
      caloriesPer100g: 31,
      proteinPer100g: 1.0,
      carbsPer100g: 6.0,
      fatPer100g: 0.3,
      fiberPer100g: 2.1,
    ),
    'Cucumber': const NutritionReference(
      cropName: 'Cucumber',
      caloriesPer100g: 15,
      proteinPer100g: 0.65,
      carbsPer100g: 3.6,
      fatPer100g: 0.11,
      fiberPer100g: 0.5,
    ),
    'Eggplant': const NutritionReference(
      cropName: 'Eggplant',
      caloriesPer100g: 25,
      proteinPer100g: 1.0,
      carbsPer100g: 5.9,
      fatPer100g: 0.2,
      fiberPer100g: 3.0,
    ),
    'Kale': const NutritionReference(
      cropName: 'Kale',
      caloriesPer100g: 49,
      proteinPer100g: 4.3,
      carbsPer100g: 8.8,
      fatPer100g: 0.9,
      fiberPer100g: 3.6,
    ),
  };

  static final CropBatch sampleBatch = CropBatch(
    id: 'batch_001',
    farmerId: 'u_mwangi',
    cropName: 'Tomatoes',
    farmingMethod: FarmingMethod.organic,
    plotLocation: const GeoPoint(-1.286389, 36.817223),
    plotName: 'Plot A',
    sunExposure: SunExposure.fullSun,
    stage: CropStage.harvested,
    plannedDate: DateTime(2026, 4, 1),
    plantedDate: DateTime(2026, 4, 5),
    verifiedWeightKg: 48.5,
    harvestedAt: DateTime(2026, 6, 20, 7, 30),
    harvestWeatherConditions: 'Clear, 24°C',
    organicCertified: true,
    qrCodeId: 'qr_batch_001',
  );

  static final List<MealIngredient> sampleMealIngredients = [
    MealIngredient(cropBatchId: 'batch_001', cropName: 'Tomatoes', quantityGrams: 80),
    MealIngredient(cropBatchId: 'batch_002', cropName: 'Lettuce', quantityGrams: 60),
    MealIngredient(cropBatchId: 'batch_003', cropName: 'Carrots', quantityGrams: 50),
    MealIngredient(cropBatchId: 'batch_004', cropName: 'Avocado', quantityGrams: 40),
  ];

  static final Meal sampleMeal = Meal(
    id: 'meal_001',
    chefId: 'u_sarah',
    restaurantName: 'Fresh Bite Restaurant',
    name: 'Grilled Vegetable Salad',
    ingredients: sampleMealIngredients,
    nutrition: MealNutritionSnapshot.calculate(
      sampleMealIngredients,
      nutritionReference,
    ),
    allergens: [
      MealAllergen(mealId: 'meal_001', allergenId: AllergenType.milk, contains: true),
      MealAllergen(mealId: 'meal_001', allergenId: AllergenType.sesame, contains: true),
      MealAllergen(
        mealId: 'meal_001',
        allergenId: AllergenType.treeNuts,
        mayContain: true,
      ),
    ],
    createdAt: DateTime(2026, 6, 28, 11, 0),
    qrCodeId: 'qr_meal_001',
  );

  static final List<CropModel> crops = [
    CropModel(
      id: 'crop_001',
      name: 'Cherry Tomatoes',
      variety: 'Sweet Million',
      category: CropCategory.vegetable,
      emoji: '🍅',
      plotId: 'plot_a',
      plantingDate: DateTime.now().subtract(const Duration(days: 58)),
      expectedHarvestDate: DateTime.now().add(const Duration(days: 2)),
      quantityPlanted: 24,
      wateringFrequency: WateringFrequency.daily,
      estimatedYieldKg: 3.5,
      actualYieldKg: 0,
      status: CropStatus.readyToHarvest,
      isFavorite: true,
    ),
    CropModel(
      id: 'crop_002',
      name: 'Carrots',
      variety: 'Nantes Half-Long',
      category: CropCategory.root,
      emoji: '🥕',
      plotId: 'plot_b',
      plantingDate: DateTime.now().subtract(const Duration(days: 32)),
      expectedHarvestDate: DateTime.now().add(const Duration(days: 28)),
      quantityPlanted: 60,
      wateringFrequency: WateringFrequency.everyTwoDays,
      estimatedYieldKg: 4.0,
      status: CropStatus.vegetative,
    ),
    CropModel(
      id: 'crop_003',
      name: 'Basil',
      variety: 'Italian Large Leaf',
      category: CropCategory.herb,
      emoji: '🌿',
      plotId: 'plot_c',
      plantingDate: DateTime.now().subtract(const Duration(days: 20)),
      expectedHarvestDate: DateTime.now(),
      quantityPlanted: 15,
      wateringFrequency: WateringFrequency.daily,
      estimatedYieldKg: 1.5,
      actualYieldKg: 0.8,
      status: CropStatus.readyToHarvest,
    ),
    CropModel(
      id: 'crop_004',
      name: 'Bell Peppers',
      variety: 'California Wonder',
      category: CropCategory.vegetable,
      emoji: '🫑',
      plotId: 'plot_a',
      plantingDate: DateTime.now().subtract(const Duration(days: 45)),
      expectedHarvestDate: DateTime.now().add(const Duration(days: 10)),
      quantityPlanted: 18,
      wateringFrequency: WateringFrequency.everyTwoDays,
      estimatedYieldKg: 5.0,
      status: CropStatus.fruiting,
    ),
    CropModel(
      id: 'crop_005',
      name: 'Lettuce',
      variety: 'Butterhead',
      category: CropCategory.leafyGreen,
      emoji: '🥬',
      plotId: 'plot_d',
      plantingDate: DateTime.now().subtract(const Duration(days: 90)),
      expectedHarvestDate: DateTime.now().subtract(const Duration(days: 20)),
      quantityPlanted: 40,
      wateringFrequency: WateringFrequency.daily,
      estimatedYieldKg: 6.0,
      actualYieldKg: 6.2,
      status: CropStatus.harvested,
    ),
  ];

  /// Chart-ready yield-by-crop-type breakdown for the analytics screen.
  static final List<Map<String, dynamic>> yieldByCrop = [
    {'crop': 'Tomatoes', 'emoji': '🍅', 'kg': 12.4, 'color': 0xFFD4A017},
    {'crop': 'Carrots', 'emoji': '🥕', 'kg': 8.1, 'color': 0xFFB07254},
    {'crop': 'Basil', 'emoji': '🌿', 'kg': 2.3, 'color': 0xFF40916C},
    {'crop': 'Peppers', 'emoji': '🫑', 'kg': 6.7, 'color': 0xFF95D5B2},
    {'crop': 'Lettuce', 'emoji': '🥬', 'kg': 6.2, 'color': 0xFF2D6A4F},
  ];

  static final List<GardenPlot> plots = [
    GardenPlot(
      id: 'plot_a',
      name: 'Plot A',
      emoji: '🅰️',
      description: 'South-facing raised bed, full sun most of the day.',
      areaM2: 12,
      soilType: SoilType.loam,
      sunExposure: SunExposure.fullSun,
      hasIrrigation: true,
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
    ),
    GardenPlot(
      id: 'plot_b',
      name: 'Plot B',
      emoji: '🅱️',
      description: 'Root vegetable bed, sandy loam.',
      areaM2: 8,
      soilType: SoilType.sandy,
      sunExposure: SunExposure.fullSun,
      hasIrrigation: false,
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
    GardenPlot(
      id: 'plot_c',
      name: 'Plot C',
      emoji: '🌿',
      description: 'Herb corner near the kitchen door.',
      areaM2: 4,
      soilType: SoilType.loam,
      sunExposure: SunExposure.partialSun,
      hasIrrigation: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    GardenPlot(
      id: 'plot_d',
      name: 'Plot D',
      emoji: '🥬',
      description: 'Shaded leafy-greens bed under the acacia tree.',
      areaM2: 6,
      soilType: SoilType.clay,
      sunExposure: SunExposure.shade,
      hasIrrigation: false,
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
    ),
  ];

  static final List<HarvestRecord> harvests = [
    HarvestRecord(
      id: 'harvest_001',
      cropId: 'crop_005',
      quantityKg: 6.2,
      estimatedValue: 18.5,
      destination: HarvestDestination.sold,
      harvestDate: DateTime.now().subtract(const Duration(days: 20)),
      notes: 'Sold at the Saturday farmers market.',
    ),
    HarvestRecord(
      id: 'harvest_002',
      cropId: 'crop_003',
      quantityKg: 0.8,
      estimatedValue: 4.0,
      destination: HarvestDestination.consumed,
      harvestDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<ActivityLog> activities = [
    ActivityLog(
      id: 'act_001',
      cropId: 'crop_001',
      type: ActivityType.watering,
      description: 'Watered Cherry Tomatoes (Plot A)',
      performedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ActivityLog(
      id: 'act_002',
      cropId: 'crop_004',
      type: ActivityType.pestTreatment,
      description: 'Treated Bell Peppers for aphids',
      performedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ActivityLog(
      id: 'act_003',
      cropId: 'crop_005',
      type: ActivityType.harvesting,
      description: 'Harvested 6.2kg of Lettuce',
      performedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    ActivityLog(
      id: 'act_004',
      cropId: 'crop_002',
      type: ActivityType.planting,
      description: 'Planted Carrots in Plot B',
      performedAt: DateTime.now().subtract(const Duration(days: 32)),
    ),
  ];

  static final List<GrowthRecord> growthRecords = [
    GrowthRecord(
      id: 'growth_001',
      cropId: 'crop_001',
      recordedAt: DateTime.now().subtract(const Duration(days: 14)),
      heightCm: 32,
      leafCount: 18,
      floweringObserved: true,
      health: 'Healthy',
    ),
    GrowthRecord(
      id: 'growth_002',
      cropId: 'crop_001',
      recordedAt: DateTime.now().subtract(const Duration(days: 7)),
      heightCm: 48,
      leafCount: 26,
      floweringObserved: true,
      health: 'Healthy',
      notes: 'First fruit clusters forming.',
    ),
  ];

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'notif_001',
      title: 'Ready to harvest',
      body: 'Cherry Tomatoes in Plot A are ready in 2 days.',
      emoji: '🍅',
      type: NotificationType.harvestReminder,
      scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
      cropId: 'crop_001',
    ),
    AppNotification(
      id: 'notif_002',
      title: 'PHI countdown',
      body: 'Bell Peppers are still within the pre-harvest interval.',
      emoji: '⏳',
      type: NotificationType.phiCountdown,
      scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      cropId: 'crop_004',
    ),
    AppNotification(
      id: 'notif_003',
      title: 'Batch scanned',
      body: 'A consumer scanned your Tomatoes batch_001.',
      emoji: '📷',
      type: NotificationType.scanConfirmation,
      scheduledAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  static const WeatherData weather = WeatherData(
    emoji: '⛅',
    tempC: 24,
    condition: 'Partly Cloudy',
    humidity: 68,
    windKph: 12,
    rainfallMm: 8.4,
    isGoodForPlanting: true,
    tip: 'Ideal conditions for transplanting seedlings. Water tomatoes deeply this morning.',
  );

  static final GardenStats stats = GardenStats(
    totalCrops: crops.length,
    activeCrops: crops.where((c) => c.status != CropStatus.harvested).length,
    totalHarvestKg: harvests.fold(0, (s, h) => s + h.quantityKg),
    seasonGoalKg: 72,
    totalHarvestCount: harvests.length,
  );
}
