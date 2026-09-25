import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/models.dart';

// ── Raw Firebase auth state ────────────────────────────────────────────────
// true = signed in to Firebase, false = signed out
final firebaseSignedInProvider = StreamProvider<bool>((ref) {
  return FirebaseAuth.instance
      .authStateChanges()
      .map((user) => user != null);
});

// ── Full session (AppUser with role, loaded from Firestore) ───────────────
class SessionController extends Notifier<AppUser?> {
  StreamSubscription<User?>? _authSub;
  bool _googleInitialized = false;

  @override
  AppUser? build() {
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthChange);
    ref.onDispose(() => _authSub?.cancel());
    return null;
  }

  Future<void> _onAuthChange(User? firebaseUser) async {
    if (firebaseUser == null) {
      state = null;
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 8));

      if (doc.exists && (doc.data()?.containsKey('role') ?? false)) {
        // Returning user — load their role from Firestore
        state = AppUser.fromJson({
          ...doc.data()!,
          'id': firebaseUser.uid,
        });
      } else {
        // First time sign-in — needs role selection
        // Leave state null so router redirects to /role-select
        state = null;
      }
    } catch (e) {
      debugPrint('_onAuthChange: Firestore read failed/timed out ($e); '
          'treating as first-time sign-in so the user can still pick a role.');
      state = null;
    }
  }

  // ── Email / Password ─────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw TimeoutException(
          'Sign-in timed out — check your connection (an ad blocker or '
          'privacy extension can also block this) and try again.');
    });
    // _onAuthChange fires automatically
  }

  Future<void> signUpWithEmail(
      String email, String password, String name) async {
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw TimeoutException(
          'Sign-up timed out — check your connection (an ad blocker or '
          'privacy extension can also block this) and try again.');
    });
    await cred.user?.updateDisplayName(name);
    // _onAuthChange fires automatically
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: use popup flow — no google_sign_in package needed
      final provider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(provider).timeout(
          const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException(
            'Sign-in timed out — check your connection (an ad blocker or '
            'privacy extension can also block this) and try again.');
      });
    } else {
      // Mobile: use google_sign_in package
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        // serverClientId (the "Web client" OAuth ID from google-services.json,
        // client_type 3) is required on Android with this package version --
        // without it, authenticate() returns a user but idToken stays null,
        // so the Firebase credential below is empty and sign-in silently
        // fails/refuses every time.
        await googleSignIn.initialize(
          serverClientId:
              '1070542599755-67jbke844t9tug95j04pvesisig1nl9r.apps.googleusercontent.com',
        );
        _googleInitialized = true;
      }
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    // _onAuthChange fires automatically after sign-in
  }

  // ── Role selection (saves to Firestore) ───────────────────────────────────

  Future<void> setRole(
    UserRole role, {
    String? farmName,
    String? restaurantName,
    String? organizationName,
    String? vehicleInfo,
    VerificationStatus verificationStatus = VerificationStatus.none,
    String? verifiedByCode,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      // Mock mode — just set state directly
      state = MockData.users.firstWhere((u) => u.role == role,
          orElse: () => AppUser(
                id: 'mock',
                name: 'User',
                email: '',
                role: role,
                farmName: farmName,
                restaurantName: restaurantName,
                organizationName: organizationName,
                vehicleInfo: vehicleInfo,
                verificationStatus: verificationStatus,
              ));
      return;
    }

    final displayName =
        firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User';

    final data = {
      'id': firebaseUser.uid,
      'name': displayName,
      'email': firebaseUser.email ?? '',
      'role': role.name,
      'photoUrl': firebaseUser.photoURL,
      if (farmName != null) 'farmName': farmName,
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (organizationName != null) 'organizationName': organizationName,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      'verificationStatus': verificationStatus.name,
      if (verifiedByCode != null) 'verifiedByCode': verifiedByCode,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // Guard against a hung write (missing Firestore database, locked-down
      // security rules, or no network) — without this, an unresponsive
      // backend leaves the Continue button spinning forever with no way
      // for the user to proceed or even see an error.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      // Couldn't reach Firestore — proceed with a local session anyway so
      // the app isn't blocked. It'll sync next time this succeeds or the
      // profile is edited. Logged, not silent, but doesn't block the user.
      debugPrint('setRole: Firestore write failed/timed out, continuing '
          'with local session only. Cause: $e');
    }

    state = AppUser(
      id: firebaseUser.uid,
      name: displayName,
      email: firebaseUser.email ?? '',
      role: role,
      photoUrl: firebaseUser.photoURL,
      farmName: farmName,
      restaurantName: restaurantName,
      organizationName: organizationName,
      vehicleInfo: vehicleInfo,
      verificationStatus: verificationStatus,
    );
  }

  // ── Mock sign-in (dev / testing) ─────────────────────────────────────────

  void signInAs(UserRole role) {
    state = MockData.users.firstWhere((u) => u.role == role);
  }

  // ── Profile photo ─────────────────────────────────────────────────────────

  /// Uploads [bytes] to Storage as this user's profile photo, saves the
  /// resulting URL to Firestore, and updates local session state so every
  /// screen watching [sessionProvider] (profile page, dashboard header)
  /// picks it up immediately — no manual refresh needed.
  Future<void> updateProfilePhoto(Uint8List bytes) async {
    final current = state;
    if (current == null) return;

    // Reflect the picked photo immediately, everywhere the session is
    // watched (profile page, every dashboard header) — this used to wait
    // on a cloud round trip first, which is exactly why it looked like it
    // "did nothing" for dev/mock accounts with no real Storage to upload
    // to, and could hang for real accounts on a slow connection too.
    ref.read(localProfilePhotoProvider.notifier).state = bytes;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      // Mock/dev mode — no real backend to persist to. The local preview
      // above is already reflected everywhere for this session, which is
      // as far as it can go without a real account.
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${firebaseUser.uid}/profile.jpg');
      await storageRef
          .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 15));
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));

      state = current.copyWith(photoUrl: url);
    } catch (e) {
      // Local preview still stands for this session even if the upload
      // failed or timed out — nothing left visibly stuck.
      // ignore: avoid_print
      print('updateProfilePhoto: cloud sync failed, keeping local preview ($e)');
    }
  }

  // ── Password reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email);

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    state = null;
  }

}

final sessionProvider = NotifierProvider<SessionController, AppUser?>(SessionController.new);

/// Holds the just-picked profile photo in memory for this session, shown
/// instantly by [UserAvatar] ahead of (or in place of) a persisted
/// `photoUrl` — see [SessionController.updateProfilePhoto].
class LocalProfilePhotoController extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;
}

final localProfilePhotoProvider =
    NotifierProvider<LocalProfilePhotoController, Uint8List?>(
        LocalProfilePhotoController.new);
