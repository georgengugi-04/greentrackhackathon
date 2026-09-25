// Verification for the three "touches other people's produce" roles —
// Aggregator, Transporter, Distributor. Farmer/Chef/Grocery Shopper are
// self-service by design (see kSupplyChainRoles in models.dart for why),
// so nothing here applies to them.
//
// Two paths to get verified:
//   1. Invite code — a code someone already vetted offline (a co-op lead,
//      JHUB program staff, etc.) issued ahead of time. Redeeming one
//      approves the account instantly.
//   2. Request access — no code, so the account sits in `role_requests`
//      as `pending` until an admin approves or rejects it from
//      /admin/approvals.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/models.dart';

class VerificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _db.collection('role_invite_codes');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('role_requests');
  CollectionReference<Map<String, dynamic>> get _admins =>
      _db.collection('admins');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Redeems an invite code for [role]. Returns the matched code's
  /// organization label on success (already-verified, so the caller can
  /// use it directly as the account's org/vehicle name), or null if the
  /// code doesn't exist, is already used, or is for a different role.
  /// Uses a transaction so two people racing to redeem the same code
  /// can't both succeed.
  Future<String?> redeemInviteCode({
    required String code,
    required UserRole role,
    required String uid,
  }) async {
    final ref = _inviteCodes.doc(code.trim().toUpperCase());
    try {
      return await _db.runTransaction<String?>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return null;
        final data = snap.data()!;
        final used = data['used'] as bool? ?? false;
        final codeRole = UserRole.values.byName(data['role'] as String);
        if (used || codeRole != role) return null;

        tx.update(ref, {'used': true, 'usedByUid': uid});
        return data['organizationLabel'] as String;
      });
    } catch (e) {
      return null;
    }
  }

  /// Opens (or refreshes) a pending access request for [uid] — one
  /// request per account, so re-submitting just overwrites the old one
  /// rather than piling up duplicates.
  Future<void> submitRoleRequest(RoleRequest request) async {
    await _requests.doc(request.uid).set(request.toFirestore());
  }

  /// Live status of the current user's own request — drives the "Pending
  /// Review" screen so it updates the instant an admin acts, no refresh
  /// needed.
  Stream<RoleRequest?> watchMyRoleRequest(String uid) =>
      _requests.doc(uid).snapshots().map(
          (d) => d.exists ? RoleRequest.fromFirestore(d) : null);

  /// Every request still awaiting review — the admin queue.
  Stream<List<RoleRequest>> watchPendingRequests() => _requests
      .where('status', isEqualTo: VerificationStatus.pending.name)
      .snapshots()
      .map((s) => s.docs.map(RoleRequest.fromFirestore).toList());

  /// Approves or rejects a request. On approval, also flips the user's own
  /// `verificationStatus` so the router unlocks their dashboard on the
  /// next auth-state/session read — the two documents (`role_requests` and
  /// `users`) are updated together so they can't drift out of sync.
  Future<void> reviewRequest({
    required String uid,
    required bool approve,
    required String reviewerUid,
  }) async {
    final status = approve ? VerificationStatus.approved : VerificationStatus.rejected;
    final batch = _db.batch();
    batch.update(_requests.doc(uid), {
      'status': status.name,
      'reviewedAt': Timestamp.now(),
      'reviewedBy': reviewerUid,
    });
    batch.update(_users.doc(uid), {'verificationStatus': status.name});
    await batch.commit();
  }

  /// Whether [uid] is allowed into /admin/approvals. Backed by a real
  /// Firestore doc (`admins/{uid}`) rather than a client-side allowlist —
  /// security rules restrict who can even read that collection, so this
  /// can't be spoofed by editing local app state.
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _admins.doc(uid).get();
      return doc.exists;
    } catch (e) {
      // Rules deny read for non-admins by design — that failure IS the
      // answer "not an admin", not an error to surface.
      return false;
    }
  }
}
